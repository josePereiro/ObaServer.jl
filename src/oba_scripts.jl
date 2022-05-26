# this both must be coherents

_generate_rand_id(prefix = "", n = 8) = string(prefix, randstring(n))

## ------------------------------------------------------------------
# HEAD
function _handle_script_id_refactoring!(script_ast::ObaScriptBlockAST, mdfile)
    
    script_id = get_param(script_ast, "id", nothing)
    
    isnothing(script_id) || return false

    embtag = _generate_rand_id(script_ast.line)
    
    set_param!(script_ast, "id", embtag)

    # info
    _info("Refactoring source", "-"; 
        embtag, 
        mdfile = string(mdfile, ":", script_ast.line),
        newsrc = string("\n", script_ast.src),
    )

    write!(parent_ast(script_ast))

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
    script_id = get_param(script_ast, "id")

    # check if processed
    hash_ = hash(script_id)
    (hash_ in processed) && return false
    push!(processed, hash_)

    # set globals
    set_global!(:__VAULT__, vault)
    set_global!(:__FILE__, mdfile)
    set_global!(:__DIR__, dirname(mdfile))
    set_global!(:__LINE__, script_ast.line)
    set_global!(:__FILE_AST__, parent_ast(script_ast))
    set_global!(:__LINE_AST__, script_ast)
    set_global!(:__SCRIPT_ID__, script_id)
    
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