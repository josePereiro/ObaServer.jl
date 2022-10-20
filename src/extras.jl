const __EXTRAS__ = Dict{Any, Any}()

set_extras!(key, val) = setindex!(__EXTRAS__, val, key)

get_extras() = __EXTRAS__
get_extras(key) = getindex(__EXTRAS__, key)
get_extras(key, dflt) = haskey(__EXTRAS__, key) ? getindex(__EXTRAS__, key) : dflt

get_extras!(key, dflt = nothing) =
    haskey(__EXTRAS__, key) ? getindex(__EXTRAS__, key) : set_extras!(key, dflt)

get_extras!(f::Function, key) = haskey(__EXTRAS__, key) ? getindex(__EXTRAS__, key) : set_extras!(key, f())