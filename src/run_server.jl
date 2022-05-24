## ------------------------------------------------------------------
function _reset_server()
    # Events
    reset!(OBA_PLUGIN_TRIGGER_FILE_EVENT)

    return nothing
end

## ------------------------------------------------------------------
function _run_startup_jl(vault)

    # pre-warm
    _up_trigger_event(vault)

    # find startup.oba.jl
    jlfile = find_startup(vault)
    isempty(jlfile) && return

    # prepare globals
    _set_global!([:__LINE__,  :__LINE_AST__, :__FILE_AST__, :__SCRIPT_ID__,])
    _set_global!(:__VAULT__, vault)
    _set_global!(:__FILE__, jlfile)
    _set_global!(:__DIR__, dirname(jlfile))
    
    _info("Running startup.oba.jl", "="; jlfile)
    
    # eval
    Main.include(jlfile)

    return nothing
end
_run_startup_jl(server::ObaServerState) = _run_startup_jl(server[VAULT_ENV_KEY])

## ------------------------------------------------------------------

function _run_notefiles(server::ObaServerState)

    for notes_ext in server[NOTE_EXTS_ENV_KEY]

        _info("Running note ($notes_ext) files", "=")

        notefiles = findall_files(server[VAULT_ENV_KEY], notes_ext)
        for notefile in notefiles

            try

                # prepare globals
                _set_global!([:__LINE__,  :__LINE_AST__, :__FILE_AST__, :__SCRIPT_ID__])
                _set_global!(:__VAULT__, server[VAULT_ENV_KEY])
                _set_global!(:__FILE__, notefile)
                _set_global!(:__DIR__, dirname(notefile))

                processed = UInt64[]
                server[PER_FILE_LOOP_ITER_ENV_KEY] = 1
                while true
                    
                    get!(server, RUN_FILE_AGAIN_SIGNAL, false)

                    AST = parse_file(notefile)
                    
                    for child in AST

                        # check type
                        isscriptblock(child) || continue

                        # handle ignore flag
                        hasflag(child, "i") && continue
                        
                        # refactor if script_id is missing
                        refactored = _handle_script_id_refactoring!(child, notefile)
                        if refactored
                            server[RUN_FILE_AGAIN_SIGNAL] = true # signal
                            break # for child in AST 
                        end

                        # run script
                        didrun = _run_script!(child, processed, server[VAULT_ENV_KEY], notefile)

                        # signal out
                        server[RUN_FILE_AGAIN_SIGNAL] = didrun
                        
                        println()
                        
                        # because an script can modified its own file
                        # I rerun the file 
                        break # for child in AST
                    
                    end # for child in AST

                    get!(server, RUN_FILE_AGAIN_SIGNAL, false) || break
                
                    server[PER_FILE_LOOP_ITER_ENV_KEY] >= get(server, PER_FILE_LOOP_NITERS_ENV_KEY, 1000) && break
                    server[PER_FILE_LOOP_ITER_ENV_KEY] += 1

                end # The run deep
            
            catch err
                _error("ERROR", err, "!"; notefile)
                return
            end

        end # for notefile
    end # for notes_ext
end

## ------------------------------------------------------------------
function run_server(vault=pwd(); 
        niters = typemax(Int), 
        note_exts = [".md"],
        force_trigger = false, 
        trigger_file = _oba_plugin_trigger_file(vault)
    )

    # save envs
    server = ObaServerState()
    setenv!(server; 
        vault = abspath(vault), 
        niters, 
        force_trigger, 
        trigger_file = abspath(trigger_file),
        note_exts
    )

    # run
    run_server(server) 
    
end

## ------------------------------------------------------------------
function run_server(server::ObaServerState) 

    # reset
    _reset_server()

    # set global
    _set_global!(:__SERVER_ENV__, server)

    # jlfiles
    _run_startup_jl(server)

    server[SERVER_LOOP_ITER_ENV_KEY] = 1
    while true

        # trigger
        _wait_for_trigger(server)
        
        # notefiles
        _run_notefiles(server)

        server[SERVER_LOOP_ITER_ENV_KEY] >= get(server, SERVER_LOOP_NITERS_ENV_KEY, typemax(Int)) && break
        server[SERVER_LOOP_ITER_ENV_KEY] += 1
    end

    return nothing

end