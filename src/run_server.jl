## ------------------------------------------------------------------
function _reset_server()
    # Events
    reset!(getstate(OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY))

    return nothing
end

# -------------------------------------------------------------------
# TODO: create the AST cache, at least one per iter. Maybe empty at the iter's end.
# Keep a record of runnable/non-runnable 

# -------------------------------------------------------------------
function _run_obascripts(notefiles::Vector)

    t0 = now()

    for notefile in notefiles
        run_notefile!(notefile) || return
    end

    _info("Done", ""; time = Dates.canonicalize(now() - t0))

    return nothing

end

## ------------------------------------------------------------------
function run_notefile!(notefile::AbstractString)

    vault = getstate!(VAULT_GLOBAL_KEY) do
        dirname(notefile)
    end
    
    upstate!(PROCESSED_SCRIPTS_CACHE, UInt64[])
    upstate!(PER_FILE_LOOP_ITER_SERVER_KEY, 1)

    # mtime
    mtimereg = getstate!(LAST_UPDATE_REGISTRY) do
        Dict{String, Float64}()
    end
    lastmtime = get!(mtimereg, notefile, -1)
    currmtime = mtime(notefile)
    
    while true
        
        upstate!(RUN_FILE_AGAIN_SIGNAL, false)
        AST = nothing
        try
            AST = parse_file(notefile)
            
            # set global
            currast!(AST)
            
        catch err
            _error("ERROR PARSING", err, "!"; 
                notefile, 
                obsidian = _obsidian_url(vault, notefile)
            )
            return false
        end

        # on parse
        _run_callbacks!(AST, :on_parse) || return false
        # on_modified
        lastmtime != currmtime && (_run_callbacks!(AST, :on_modified) || return false)

        # handle ignore file tags
        doignore = false
        for toignore in ignore_tags()
            if hastag(AST, toignore) 
                doignore = true
                break
            end
        end
        doignore && return true

        # before execution
        _run_callbacks!(AST, :before_exec) || return false
        
        for child in AST
            
            # check type
            isscriptblock(child) || continue
            
            # set global
            currast!(AST)
            currscript!(child)

            # handle flags
            # ignore
            hasflag(child, "i") && continue
            # startup
            isstartup = getstate(IS_STARTUP_SERVER_KEY, false)
            !xor(isstartup, hasflag(child, "s")) || continue
            # on update
            lastmtime == currmtime && hasflag(child, "u") && continue
            
            # refactor if script_id is missing
            refactored = _handle_script_id_refactoring!(child, notefile)
            if refactored
                upstate!(RUN_FILE_AGAIN_SIGNAL, true)
                break # for child in AST 
            end

            didrun = false
            try
                # run script
                didrun = _run_obascript!(child;
                    processed = getstate(PROCESSED_SCRIPTS_CACHE)
                )

                if didrun
                    upstate!(RUN_FILE_AGAIN_SIGNAL, didrun)
                
                    # because an script can modified its own file
                    # I rerun the whole file 
                    break # for child in AST
                end

            catch err
                _error("ERROR", err, "!"; 
                    notefile = string(notefile, ":", child.line), 
                    obsidian = _obsidian_url(vault, notefile),
                    child
                )
                return false
            end
        
        end # for child in AST

        run_again = getstate!(RUN_FILE_AGAIN_SIGNAL, false) 
        if !run_again
            # after execution
            _run_callbacks!(AST, :after_exec) || return false
            break
        end

        getstate(PER_FILE_LOOP_ITER_SERVER_KEY) >= getstate!(PER_FILE_LOOP_NITERS_SERVER_KEY, 1000) && break
        upstate!(PER_FILE_LOOP_ITER_SERVER_KEY,
            getstate(PER_FILE_LOOP_ITER_SERVER_KEY) + 1
        )

    end # The run deep 

    # mtime
    mtimereg[notefile] = mtime(notefile)

    return true

end

## ------------------------------------------------------------------
function run_server(vault=pwd();
        niters = typemax(Int), 
        note_ext = ".md",
        force_trigger = false, 
        trigger_file = _oba_plugin_trigger_file(vault), 
        msg_file = _oba_plugin_msg_file(vault), 
    )

    # reset state
    empty!(serverstate())
    
    # up state
    init_server_defaults()
    upstate!(VAULT_GLOBAL_KEY, abspath(vault))
    upstate!(SERVER_LOOP_NITERS_SERVER_KEY, niters)
    upstate!(FORCE_TRIGGER_SERVER_KEY, force_trigger)
    upstate!(TRIGGER_FILE_SERVER_KEY, abspath(trigger_file))
    upstate!(MSG_FILE_SERVER_KEY, abspath(msg_file))
    upstate!(NOTE_EXT_SERVER_KEY, note_ext)
    
    try
        
        # startup
        run_startup()
        
        # startup
        upstate!(SERVER_LOOP_ITER_SERVER_KEY, 1)
        while true

            # trigger
            _wait_for_trigger()
            
            # run notefiles
            vault = vaultdir()
            note_ext = getstate(NOTE_EXT_SERVER_KEY)
            notefiles = findall_files(vault, note_ext; 
                keepout = ignore_folders()
            )
            _info("Running notes, looking ($(note_ext)) files", "=")
            _run_obascripts(notefiles)

            getstate(SERVER_LOOP_ITER_SERVER_KEY) >= getstate(SERVER_LOOP_NITERS_SERVER_KEY, typemax(Int)) && break
            upstate!(SERVER_LOOP_ITER_SERVER_KEY, 
                getstate(SERVER_LOOP_ITER_SERVER_KEY) + 1
            )
        end

    catch err
        (err isa InterruptException) && return
        rethrow(err)
    end

    return nothing

    
end

## ------------------------------------------------------------------
const START_UP_FILE_NAME = "startup.oba"
startup_name(note_ext) = string(START_UP_FILE_NAME, note_ext)

function run_startup()
    
    vault = vaultdir()
    note_ext = getstate(NOTE_EXT_SERVER_KEY)

    _info("Start up, looking ($(note_ext)) files", "=")
    
    # find startup.oba
    name = startup_name(note_ext)
    stfile = find_file(vault, name)
    if isfile(stfile)
        try
            upstate!(IS_STARTUP_SERVER_KEY, true)
            _run_obascripts([stfile])
        finally
            upstate!(IS_STARTUP_SERVER_KEY, false)
        end
    end

    # run the rest
    notefiles = findall_files(vault, note_ext; 
        keepout = ignore_folders()
    )
    isfile(stfile) && filter!(isequal(stfile), notefiles)

    try
        upstate!(IS_STARTUP_SERVER_KEY, true)
        _run_obascripts(notefiles)
    finally
        upstate!(IS_STARTUP_SERVER_KEY, false)
    end

    
end