# NOTE: the callback are responsable of leaving a valid ast and commiting (write) any changes (reparse!/write! should help)

const NOTE_FUN_REG = "general_notefuns"
callback_registry() = getstate!(NOTE_FUN_REG) do
    Dict{Symbol, Set{Symbol}}()
end
callback_registry(key) = get!(callback_registry(), key, Set{Symbol}())
export callback_registry

"""
    register_callback!(f::Symbol, key = :before_exec)

Register a function `f(ast)` to be called every `key` event happends.
The functions are responsable for calling reparse!/write! to validate the ast.
The user must handle duplication avoidance.
For see all events explore `callback_registry()` keys
"""
function register_callback!(f::Symbol, key = :before_exec)
    callbacks_reg = callback_registry(key)
    push!(callbacks_reg, f)
    return nothing
end
export register_callback!

function _run_callbacks!(ast::ObaAST, key)
    try
        callbacks_reg = callback_registry(key)
        isempty(callbacks_reg) && return true
        for fname in callbacks_reg
            fun = getfield(Main, fname)
            Base.invokelatest(fun, ast)
        end
    catch err
        _error("ERROR ON CALLBACK", err, "!"; 
            key,
            notefile = ast.file, 
            obsidian = _obsidian_url(vaultdir(), ast.file)
        )
        return false
    end
    return true
end

# TODO: per tags note functions
# TODO: [DONE] add callbacks in different places of the run_server loop (eg: onparse)
# TODO: add callbacks on note events (eg. modified)
# 