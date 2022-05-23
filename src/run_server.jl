## ------------------------------------------------------------------
function _reset_server()
    # Events
    reset!(OBA_PLUGIN_TRIGGER_FILE_CONTENT_EVENT)
    reset!(RUNNER_FILE_CONTENT_EVENT)

    # running globals
    _reset_globals!()

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
    _reset_globals!()
    _set_global!(:__VAULT__, vault)
    _set_global!(:__FILE__, jlfile)
    _set_global!(:__DIR__, dirname(jlfile))
    
    _info("Running startup.oba.jl", "="; jlfile)
    
    # eval
    Main.include(jlfile)

    return nothing
end


## ------------------------------------------------------------------

function _run_notefiles(vault, ext)

    _info("Running note ($ext) files", "=")

    notefiles = findall_files(vault, ext)
    for notefile in notefiles

        try

            # prepare globals
            _reset_globals!()
            _set_global!(:__VAULT__, vault)
            _set_global!(:__FILE__, notefile)
            _set_global!(:__DIR__, dirname(notefile))

            processed = UInt64[]
            for _ in 1:1000 # The run deep
                
                run_again = false

                AST = parse_file(notefile)
                
                for child in AST

                    # check type
                    isscriptblock(child) || continue

                    # handle ignore flag
                    hasflag(child, "i") && continue
                    
                    # refactor if script_id is missing
                    refactored = _handle_script_id_refactoring!(child, notefile)
                    if refactored
                        run_again = true # signal
                        break # for child in AST 
                    end

                    # run script
                    didrun = _run_script!(child, processed, vault, notefile)

                    # signal out
                    run_again = didrun

                    println()
                    
                    # because an script can modified its own file
                    # I rerun the file 
                    break # for child in AST
                
                end # for child in AST

                run_again || break
            
            end # The run deep
        
        catch err
            _error("ERROR", err, "!"; notefile)
            return
        end

    end # for notefile

end

## ------------------------------------------------------------------
function run_server(vault=pwd(); 
        niters = typemax(Int), force = false, 
        note_exts = [".md"]
    )

    # reset
    _reset_server()

    # jlfiles
    _run_startup_jl(vault)

    for _ in 1:niters

        # trigger
        force || _wait_for_trigger(vault)
        
        # notefiles
        for ext in note_exts
            _run_notefiles(vault, ext)
        end
    
    end
end