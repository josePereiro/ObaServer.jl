## ------------------------------------------------------------------
function _reset_server()
    # Events
    EasyEvents.reset!(getstate(OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY))

    return nothing
end

## ------------------------------------------------------------------
function _run_notefile!(notefile::AbstractString)

    vault = getstate!(() -> dirname(notefile), VAULT_GLOBAL_KEY)
    
    upstate!(PROCESSED_SCRIPTS_CACHE_KEY, UInt64[])
    upstate!(PER_FILE_LOOP_ITER_SERVER_KEY, 1)

    # mtime
    mtimereg = getstate!(LAST_UPDATE_REGISTRY) do
        Dict{String, Float64}()
    end
    upstate!(CURR_AST_MTIME_KEY, mtime(notefile))
    upstate!(LAST_AST_MTIME_KEY, get!(mtimereg, notefile, -1))
    
    while true
        
        upstate!(RUN_FILE_AGAIN_SIGNAL, false)
        AST = nothing
        try
            AST = parse_file(notefile)
            # set global
            _currast!(AST)
        catch err
            _error("ERROR PARSING", err, "!"; 
                notefile, 
                obsidian = _obsidian_url(vault, notefile)
            )
            return false
        end

        # on parse
        _run_callbacks!(AST, :on_parse) || return false
        !is_modified(0.0) && (_run_callbacks!(AST, :on_modified) || return false)

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
            _currscript!(child)

            # handle flags
            # ignore
            hasflag(child, "i") && continue
            # startup
            isstartup = getstate(IS_STARTUP_SERVER_KEY, false)
            !xor(isstartup, hasflag(child, "s")) || continue
            # on update
            !is_modified(0.0) && hasflag(child, "u") && continue
            
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
                    processed = getstate(PROCESSED_SCRIPTS_CACHE_KEY)
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

        iter = getstate(PER_FILE_LOOP_ITER_SERVER_KEY)
        niters = getstate!(PER_FILE_LOOP_NITERS_SERVER_KEY, 1000)
        iter >= niters && break
        upstate!(PER_FILE_LOOP_ITER_SERVER_KEY, iter + 1)

    end # The run deep 

    # mtime
    mtimereg[notefile] = mtime(notefile)

    return true

end

# -------------------------------------------------------------------
function _run_obascripts(notefiles::Vector)

    t0 = now()

    for notefile in notefiles
        _run_notefile!(notefile) || return
    end

    _info("Done", ""; 
        time = ObaBase._canonicalize(now() - t0)
    )

    return nothing

end

## ------------------------------------------------------------------
const START_UP_FILE_NAME = "startup.oba"
startup_name(note_ext) = string(START_UP_FILE_NAME, note_ext)

function _run_startup_round()
    
    vault = getstate(VAULT_GLOBAL_KEY)
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
    notefiles = findall_notefiles()
    isfile(stfile) && filter!(isequal(stfile), notefiles)

    try
        upstate!(IS_STARTUP_SERVER_KEY, true)
        _run_obascripts(notefiles)
    finally
        upstate!(IS_STARTUP_SERVER_KEY, false)
    end

    
end

## ------------------------------------------------------------------
function _run_update_round()
    note_ext = getstate(NOTE_EXT_SERVER_KEY)
    notefiles = findall_notefiles()
    _info("Running notes, looking ($(note_ext)) files", "=")
    _run_obascripts(notefiles)
end

## ------------------------------------------------------------------
function run_server(vault=pwd();
        niters = typemax(Int), 
        note_ext = ".md",
        force_trigger = false, 
        trigger_file = _oba_plugin_trigger_file(vault), 
        msg_file = _oba_plugin_msg_file(vault), 
        clear_state = true
    )

    # reset state
    clear_state && empty!(serverstate())
    clear_state && init_server_defaults()
    
    # up state
    upstate!(VAULT_GLOBAL_KEY, abspath(vault))
    upstate!(SERVER_LOOP_NITERS_SERVER_KEY, niters)
    upstate!(FORCE_TRIGGER_SERVER_KEY, force_trigger)
    upstate!(TRIGGER_FILE_SERVER_KEY, abspath(trigger_file))
    upstate!(MSG_FILE_SERVER_KEY, abspath(msg_file))
    upstate!(NOTE_EXT_SERVER_KEY, note_ext)
    
    _run_server()

end

function _run_server()

    try
        # startup
        _run_startup_round()
        
        # iter
        upstate!(SERVER_LOOP_ITER_SERVER_KEY, 1)

        while true

            # trigger
            _wait_for_trigger()
            
            # run notefiles
            _run_update_round()

            # Loop iter
            iter = getstate(SERVER_LOOP_ITER_SERVER_KEY)
            maxiter = getstate(SERVER_LOOP_NITERS_SERVER_KEY, typemax(Int))
            iter >= maxiter && break

            upstate!(SERVER_LOOP_ITER_SERVER_KEY, iter + 1)
        end

    catch err
        (err isa InterruptException) && return
        rethrow(err)
    end

    return nothing
end