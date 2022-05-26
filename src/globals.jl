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

function set_global!(sym::Symbol, val = nothing)
    T = typeof(val)
    _valref = Ref{T}(val)
    @eval Main begin
        $(sym) = $(_valref)[]
    end
    return val
end

function set_global!(syms::Vector, val = nothing)
    for sym in syms
        set_global!(sym, val)
    end
end

function get_global(sym::Symbol) 
    !isdefined(Main, sym) && 
        error(
            "global '", sym, "' not defined!\n", 
            "Maybe you are running the server interface outside without it being running!"
        )
    return getproperty(Main, sym)
end
get_global(sym::Symbol, dflt) = isdefined(Main, sym) ? getproperty(Main, sym) : dflt
function get_global!(sym::Symbol, dflt = nothing) 
    isdefined(Main, sym) && return getproperty(Main, sym)
    set_global!(sym, dflt)
end
function get_global!(f::Function, sym::Symbol) 
    isdefined(Main, sym) && return getproperty(Main, sym)
    set_global!(sym, f())
end

reset_globals!() = set_global!(
    [ __VAULT__, __SERVER_ENV__, __DIR__, __FILE__, __LINE__, __LINE_AST__, __FILE_AST__, __SCRIPT_ID__, __EXTRAS__ ]
)