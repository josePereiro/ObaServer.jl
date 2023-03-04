# this both must be coherents

_generate_rand_id() = randstring(8)
_generate_rand_id(n::Int) = randstring(n)
_generate_rand_id(prefix, n::Int = 8) = string(prefix, randstring(n))

## ------------------------------------------------------------------
# HEAD
function _handle_script_id_refactoring!(script_ast::ObaScriptBlockAST, mdfile)
    
    script_id = get_param(script_ast, "id", nothing)
    
    isnothing(script_id) || return false

    embtag = _generate_rand_id(string("L", script_ast.line))
    
    set_param!(script_ast, "id", embtag)

    # info
    _info("Refactoring source", "-"; 
        embtag, 
        mdfile = string(mdfile, ":", script_ast.line),
        newsrc = string("\n\n", script_ast.src),
    )

    write!!(script_ast)

    return true
end

## ------------------------------------------------------------------
# RUN SCRIPT

# This replace some util Base macros by its Oba equivalent globals.
# Because the scripts are loaded from strings and not files.
function _replace_base_macros(src)
    for (_macro, _global) in [
        ("__LINE__", "currline()"), 
        ("__FILE__", "currfile()"), 
        ("__DIR__", "currfiledir()"),
    ]
        src = replace(src, Regex(string("Base.@", _macro, "(?:\\(\\h*\\))?")) => _global)
        src = replace(src, Regex(string("@Base.", _macro, "(?:\\(\\h*\\))?")) => _global)
        src = replace(src, Regex(string("@", _macro, "(?:\\(\\h*\\))?")) => _global)
    end
    return src
end

function find_byid(new_ast::ObaAST, script_ast::ObaScriptBlockAST)
    id0 = get_param(script_ast, "id")
    isnothing(id0) && return nothing
    for (idx, ch) in enumerate(new_ast)
        isscriptblock(ch) || continue
        id1 = get_param(script_ast, "id")
        id1 == id0 && return idx
    end
    return nothing
end
find_byid(::ObaAST, ::AbstractObaASTChild) = nothing

export up_currscript!
"""
When a reparse! is made, new childs are created and the globals must be recomputed.
It assumes the id is unchanged.
"""
function up_currscript!()
    ast = currast()
    script = getstate(CURRSCRIPT_GLOBAL_KEY)
    curr_idx = find_byid(ast, script)
    if !isnothing(curr_idx)
        script = ast[curr_idx]
        _currscript!(script)
    end
    return script
end

function _run_obascript!(script_ast::ObaScriptBlockAST; 
        processed = UInt64[]
    )

    # script_id
    script_id = get_param(script_ast, "id")

    # check if processed
    hash_ = hash(script_id)
    (hash_ in processed) && return false
    push!(processed, hash_)
    
    # emb_script
    script_source = get(script_ast, :script, "")
    
    # reformat source
    script_source = _replace_base_macros(script_source)
    
    # handle scope
    if hasflag(script_ast, "l") || !(hasflag(script_ast, "s") || hasflag(script_ast, "g"))
        script_source = string("let;\n", strip(script_source), "\nend")
    end

    # info
    _info("Running ObaScriptBlockAST", "-"; 
        head = source(script_ast[:head]),
        notefile = string(currfile(), ":", currline()),
        obsidian = _obsidian_url(vaultdir(), currfile()),
        source = string("\n\n", script_source, "\n"), 
    )
    
    # eval
    include_string(Main, script_source)

    return true
end