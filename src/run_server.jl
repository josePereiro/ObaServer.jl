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

function _run_mdfiles(vault)

    _info("Running md files", "=")

    mdfiles = findall_files(vault, ".md")
    for mdfile in mdfiles

        try

            # prepare globals
            _reset_globals!()
            _set_global!(:__VAULT__, vault)
            _set_global!(:__FILE__, mdfile)
            _set_global!(:__DIR__, dirname(mdfile))

            processed = UInt64[]
            for _ in 1:1000 # The run deep
                
                run_again = false

                AST = parse_file(mdfile)
                
                for child in AST

                    # check type
                    (child isa CommentBlockAST) || continue
                    
                    # values
                    emb_script = child.body
                    
                    # check is script comment
                    rmatch = match(EMBEDDED_SCRIPT_TAG_REGEX, emb_script)
                    isnothing(rmatch) && continue # check is script comment     

                    # script_id
                    script_id = _get_match(rmatch, :id)

                    # refactor is script_id is missing
                    if isnothing(script_id)

                        # new script
                        embtag = _gen_ambtag(child.line)
                        newsrc = replace(child.src, EMBEDDED_SCRIPT_TAG_REGEX => embtag; count = 1)
                        
                        # info
                        _info("Refactoring source", "-"; 
                            embtag, 
                            mdfile = string(mdfile, ":", child.line),
                            newsrc = string("\n", newsrc),
                        )
                        
                        # write
                        # TODO: add write(mdfile, AST) proper method
                        child.src = newsrc
                        reparse!(AST)
                        write(mdfile, AST)
                        
                        # signal
                        run_again = true
                        
                        break # for child in AST
                    end

                    # check if processed
                    hash_ = hash(script_id)
                    (hash_ in processed) && continue
                    push!(processed, hash_)

                    # set globals
                    _set_global!(:__VAULT__, vault)
                    _set_global!(:__FILE__, mdfile)
                    _set_global!(:__DIR__, dirname(mdfile))
                    _set_global!(:__LINE__, child.line)
                    _set_global!(:__FILE_AST__, AST)
                    _set_global!(:__LINE_AST__, child)
                    _set_global!(:__SCRIPT_ID__, script_id)
                    
                    # emb_script
                    emb_script = _format_source(emb_script)

                    # info
                    _info("Running script", "-"; 
                        script_id, 
                        mdfile = string(mdfile, ":", child.line),
                        src = string("\n", emb_script), 
                    )
                    
                    # eval
                    include_string(Main, emb_script)

                    # signal
                    run_again = true

                    println()
                    
                    # because an script can modified its own file
                    # I rerun the file 
                    break # for child in AST
                
                end # for child in AST

                run_again || break
            
            end # The run deep
        
        catch err
            _error("ERROR", err, "!"; mdfile)
            return
        end

    end # for mdfile in mdfiles

end

## ------------------------------------------------------------------
function run_server(vault=pwd(); niters = typemax(Int), force = false)

    # reset
    _reset_server()

    # jlfiles
    _run_startup_jl(vault)

    for _ in 1:niters

        # trigger
        force || _wait_for_trigger(vault)
        
        # mdfiles
        _run_mdfiles(vault)
    
    end
end