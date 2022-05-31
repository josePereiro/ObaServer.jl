## ------------------------------------------------------------------
function _reset_server()
    # Events
    reset!(getstate(OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY))

    return nothing
end

# -------------------------------------------------------------------
const START_UP_FILE_NAME = "startup.oba"
startup_name() = 
    string(START_UP_FILE_NAME, getstate(NOTE_EXT_SERVER_KEY))

function run_oba_startup()

    # find startup.oba
    name = startup_name()
    file = find_file(vaultdir(), name)
    isempty(file) && return
    
    _info("Running $(name)", "="; file)

    AST = parse_file(file)
                
    for child in AST
        
        iscodeblock(child) || continue

        # set global
        currast!(AST)
        currscript!(child) 

        # run
        _run_codeblock!(child)
        
    end

    return nothing
end

# -------------------------------------------------------------------
# TODO: create the AST cache, at least one per iter. Maybe empty at the iter's end.
# Keep a record of runnable/non-runnable 

# -------------------------------------------------------------------
function _run_notefiles()

    note_ext = getstate(NOTE_EXT_SERVER_KEY)
    vault = vaultdir()

    _info("Running note ($(note_ext)) files", "=")

    notefiles = findall_files(vault, note_ext; 
        keepout = ignore_folders()
    )
    for notefile in notefiles

            processed = UInt64[]
            upstate!(PER_FILE_LOOP_ITER_SERVER_KEY, 1)
            while true
                
                upstate!(RUN_FILE_AGAIN_SIGNAL, false)
                AST = parse_file(notefile)

                # handle ignore flags
                doignore = false
                for toignore in ignore_tags()
                    if hastag(AST, toignore) 
                        doignore = true
                        break
                    end
                end
                doignore && break
                
                for child in AST
                    
                    # check type
                    isscriptblock(child) || continue
                    
                    # set global
                    currast!(AST)
                    currscript!(child)

                    # handle ignore flag
                    hasflag(child, "i") && continue
                    
                    # refactor if script_id is missing
                    refactored = _handle_script_id_refactoring!(child, notefile)
                    if refactored
                        upstate!(RUN_FILE_AGAIN_SIGNAL, true)
                        break # for child in AST 
                    end

                    didrun = false
                    try
                        # run script
                        didrun = _run_obascript!(child; processed)
                    catch err
                        _error("ERROR", err, "!"; notefile, child)
                        return
                    end

                    # signal out
                    upstate!(PER_FILE_LOOP_ITER_SERVER_KEY, didrun)
                    
                    # because an script can modified its own file
                    # I rerun the file 
                    break # for child in AST
                
                end # for child in AST

                getstate!(RUN_FILE_AGAIN_SIGNAL, false) || break
            
                getstate(PER_FILE_LOOP_ITER_SERVER_KEY) >= getstate(PER_FILE_LOOP_NITERS_SERVER_KEY, 1000) && break
                upstate!(PER_FILE_LOOP_ITER_SERVER_KEY,
                    getstate(PER_FILE_LOOP_ITER_SERVER_KEY) + 1
                )

            end # The run deep  

    end # for notefile
end

## ------------------------------------------------------------------
function run_server(vault=pwd();
        niters = typemax(Int), 
        note_ext = ".md",
        force_trigger = false, 
        trigger_file = _oba_plugin_trigger_file(vault)
    )

    # up state
    upstate!(VAULT_GLOBAL_KEY, abspath(vault))
    upstate!(SERVER_LOOP_NITERS_SERVER_KEY, niters)
    upstate!(FORCE_TRIGGER_SERVER_KEY, force_trigger)
    upstate!(TRIGGER_FILE_SERVER_KEY, abspath(trigger_file))
    upstate!(NOTE_EXT_SERVER_KEY, note_ext)

    # pre-warm
    _up_trigger_event()

    # run
    _run_server_loop()
    
end

## ------------------------------------------------------------------
function _run_server_loop() 

    # reset
    _reset_server()

    # jlfiles
    run_oba_startup()

    upstate!(SERVER_LOOP_ITER_SERVER_KEY, 1)
    while true

        # trigger
        _wait_for_trigger()
        
        # notefiles
        _run_notefiles()

        getstate(SERVER_LOOP_ITER_SERVER_KEY) >= getstate(SERVER_LOOP_NITERS_SERVER_KEY, typemax(Int)) && break
        upstate!(SERVER_LOOP_ITER_SERVER_KEY, 
            getstate(SERVER_LOOP_ITER_SERVER_KEY) + 1
        )
    end

    return nothing

end