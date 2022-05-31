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
Base.empty!(e::ObaServerState) = empty!(e.state)

## ------------------------------------------------------------------
mutable struct SleepTimer
    tmin::Float64
    tmax::Float64
    dt::Float64
    t::Float64
end

function SleepTimer(tmin, tmax, dt) 
    st = SleepTimer(tmin, tmax, dt, 0)
    reset!(st)
    return st
end

Base.sleep(st::SleepTimer) = sleep(st.t)

set_t!(st::SleepTimer, t::Float64) = (st.t = clamp(t, st.tmin, st.tmax))
update!(st::SleepTimer) = set_t!(st, st.t + st.dt)
sleep!(st::SleepTimer) = (sleep(st); update!(st))
reset!(st::SleepTimer) = set_t!(st, st.dt > 0 ? st.tmin : st.tmax)