struct ObaServerState
    state::Dict{String, Any}
    ObaServerState() = new(Dict{String, Any}())
end

function Base.show(io::IO, e::ObaServerState)
    println(io, "ObaServerState")
    for (k, val) in e.state
        println(io, k, " => ", val)
    end
    return nothing
end

Base.get(e::ObaServerState, key, deft = nothing) = get(e.state, string(key), deft)
Base.get!(e::ObaServerState, key, deft = nothing) = get!(e.state, string(key), deft)
Base.get(f::Function, e::ObaServerState, key) = get(f, e.state, string(key))
Base.get!(f::Function, e::ObaServerState, key) = get!(f, e.state, string(key))
Base.getindex(e::ObaServerState, key) = getindex(e.state, string(key))
Base.setindex!(e::ObaServerState, val, key) = setindex!(e.state, val, string(key))
Base.keys(e::ObaServerState) = keys(e.state)
Base.haskey(e::ObaServerState, key) = haskey(e.state, key)
Base.empty!(e::ObaServerState) = (empty!(e.state); e)
