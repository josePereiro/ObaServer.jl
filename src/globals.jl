function oba_globals_help()
    println("__VAULT__", " -> ", "The path to the vault")
    println("__SERVER__", " -> ", "The running server state container")
    println("__DIR__", " -> ", "The current file dirname")
    println("__FILE__", " -> ", "The current file path")
    println("__LINE__", " -> ", "The current script block line number")
    println("__LINE_AST__", " -> ", "The current script block ast")
    println("__FILE_AST__", " -> ", "The current file ast")
    println("__SCRIPT_ID__", " -> ", "The id of the current script")
end

function _set_global!(sym::Symbol, val = nothing)
    T = typeof(val)
    _valref = Ref{T}(val)
    @eval Main begin
        $(sym) = $(_valref)[]
    end
    return val
end

function _set_global!(syms::Vector, val = nothing)
    for sym in syms
        _set_global!(sym, val)
    end
end

_get_global(sym::Symbol) = isdefined(Main, sym) ? getproperty(Main, sym) : nothing
function _get_global!(sym::Symbol, dflt = nothing) 
    isdefined(Main, sym) && return getproperty(Main, sym)
    _set_global!(sym, dflt)
end
function _get_global!(f::Function, sym::Symbol) 
    isdefined(Main, sym) && return getproperty(Main, sym)
    _set_global!(sym, f())
end

_reset_globals!() = _set_global!(
    [ __VAULT__, __SERVER_ENV__, __DIR__, __FILE__, __LINE__, __LINE_AST__, __FILE_AST__, __SCRIPT_ID__, __EXTRAS__ ]
)