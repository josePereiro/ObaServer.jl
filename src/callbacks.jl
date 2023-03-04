# CALLBACK INTERFACE
# A registry of functions to be called on a given events
# The default run_server loop events is implemented but the system is extensible
# NOTE: the callback are responsable of leaving a valid ast and commiting (write) any changes (reparse!/write!! should help)


const NOTE_FUN_REG = "general_notefuns"
export callback_registry
callback_registry() = getstate!(NOTE_FUN_REG) do
    Dict{Symbol, Set{Symbol}}()
end
callback_registry(key) = get!(callback_registry(), key, Set{Symbol}())

export register_callback!
"""
    register_callback!(f::Symbol, key = :on_modified)

Register a function `f(ast)` to be called every `key` event happends.
The functions are responsable for calling reparse!/write!! to validate the ast.
The user must handle duplication avoidance.
For see all events explore `callback_registry()` keys
"""
function register_callback!(f::Symbol, key)
    callbacks_reg = callback_registry(key)
    push!(callbacks_reg, f)
    return nothing
end

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

# TODO: per tags/inlink/note callbacks
# DONE: add callbacks in different places of the run_server loop (eg: onparse)
# DONE: add callbacks on note events (eg. modified)
