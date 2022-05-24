## ------------------------------------------------------------------
# System keys
const VAULT_ENV_KEY = "vault"
const SERVER_LOOP_NITERS_ENV_KEY = "niters"
const SERVER_LOOP_ITER_ENV_KEY = "iter"
const PER_FILE_LOOP_NITERS_ENV_KEY = "per_files_niters"
const PER_FILE_LOOP_ITER_ENV_KEY = "per_files_iter"
const FORCE_TRIGGER_ENV_KEY = "force_trigger"
const TRIGGER_FILE_ENV_KEY = "trigger_file"
const NOTE_EXTS_ENV_KEY = "note_exts"
const RUN_FILE_AGAIN_SIGNAL = "run_again_signal"

## ------------------------------------------------------------------
# ServerState api
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

function setenv!(e::ObaServerState; kwargs...) 
    for (k, val) in kwargs
        setindex!(e, val, k)
    end
    return e
end