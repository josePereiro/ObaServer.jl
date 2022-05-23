# this both must be coherents

_generate_rand_id(prefix = "", n = 8) = string(prefix, randstring(n))

## ------------------------------------------------------------------
# HEAD

function _get_longflag(ast::ObaScriptBlockAST, key::String, dflt = nothing)
    head_ast = get(ast, :head)
    longflags = get(() -> Dict(), head_ast, :longflags)
    return get(longflags, key, dflt)
end

function _get_shortflags(ast::ObaScriptBlockAST)
    head_ast = get(ast, :head)
    return get(head_ast, :shortflags, "")
end

hasflag(ast::ObaScriptBlockAST, flag::String) = contains(_get_shortflags(ast), flag)

function _handle_script_id_refactoring!(ast::ObaScriptBlockAST, mdfile)


    head_ast = get(ast, :head)
    longflags = get(() -> Dict(), head_ast, :longflags)
    script_id = get(longflags, "id", nothing)

    isnothing(script_id) || return false

    # new head
    embtag = _generate_rand_id(ast.line)
    new_head_src = string(strip(head_ast.src), " --id=", embtag)
    script_body = get(ast, :body, "")
    newsrc = string("%% ", new_head_src, "\n", 
        strip(script_body), "\n",
        "%%"
    )
    
    # info
    _info("Refactoring source", "-"; 
        embtag, 
        mdfile = string(mdfile, ":", ast.line),
        newsrc = string("\n", newsrc),
    )
    
    # write
    ast.src = newsrc
    reparse!(parent_ast(ast))
    write(mdfile, parent_ast(ast))
        
    return true

end

## ------------------------------------------------------------------
# RUN SCRIPT

# This replace some util Base macros by its Oba equivalent globals.
# Because the scripts are loaded from strings and not files.
function _replace_base_macros(src)
    for (_macro, _global) in [
        ("__LINE__", "__LINE__"), 
        ("__FILE__", "__FILE__"), 
        ("__DIR__", "__DIR__"),
    ]
        src = replace(src, string("Base.@", _macro) => _global)
        src = replace(src, string("@Base.", _macro) => _global)
        src = replace(src, string("@", _macro) => _global)
    end
    return src
end

function _run_script!(script_ast, processed, vault, mdfile)

    # script_id
    script_id = _get_longflag(script_ast, "id")

    # check if processed
    hash_ = hash(script_id)
    (hash_ in processed) && return false
    push!(processed, hash_)

    # set globals
    _set_global!(:__VAULT__, vault)
    _set_global!(:__FILE__, mdfile)
    _set_global!(:__DIR__, dirname(mdfile))
    _set_global!(:__LINE__, script_ast.line)
    _set_global!(:__FILE_AST__, parent_ast(script_ast))
    _set_global!(:__LINE_AST__, script_ast)
    _set_global!(:__SCRIPT_ID__, script_id)
    
    # emb_script
    script_source = get(script_ast, :script, "")
    
    # reformat source
    script_source = _replace_base_macros(script_source)
    
    # handle scope
    if !hasflag(script_ast, "g") || hasflag(script_ast, "l")
        script_source = string("let;\n", strip(script_source), "\nend")
    end

    # info
    _info("Running script", "-"; 
        script_id, 
        mdfile = string(mdfile, ":", script_ast.line),
        source = string("\n\n", script_source, "\n"), 
    )
    
    # eval
    include_string(Main, script_source)

    return true
end