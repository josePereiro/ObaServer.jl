function _reset_globals!()
    @eval Main begin
        __VAULT__ = nothing # The path to the vault
        __DIR__ = nothing # The current file dirname
        __FILE__ = nothing # The current file path
        __LINE__ = nothing # The current script block line number
        __LINE_AST__ = nothing # The current script block ast
        __FILE_AST__ = nothing # The current file ast
        __SCRIPT_ID__ = nothing  # The id of the current script
        __EXTRAS__ = nothing  # To communicate between scripts and backend runs
    end
    return nothing
end

function _set_global!(sym::Symbol, val)
    @eval Main begin
        $(sym) = $(val)
    end
    return val
end

function _get_global(sym::Symbol)
    return @eval Main begin
        $(sym)
    end
end

