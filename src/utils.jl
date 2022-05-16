# ------------------------------------------------------------------
function _get_match(rmatch::RegexMatch, ksym::Symbol, dflt = nothing) 
    cap = rmatch[ksym]
    return isnothing(cap) ? dflt : string(cap)
end

# ------------------------------------------------------------------
function _match_pos(rm::RegexMatch) 
    i0 = rm.offset
    i1 = i0 + length(rm.match) - 1
    return i0:i1
end

# ------------------------------------------------------------------
function foreach_file(f::Function, vault, ext = ".md"; keepout = [".obsidian", ".git"])
    walkdown(vault; keepout) do path
        !endswith(path, ext) && return
        f(path)
    end
end

# ------------------------------------------------------------------
function findall_files(vault::AbstractString, ext = ".md";
        sortby = mtime, sortrev = false, keepout = [".obsidian", ".git"]
    )

    files = filterdown((path) -> endswith(path, ext), vault; keepout)
    
    sort!(files; by = sortby, rev = sortrev)

    return files
end


# ------------------------------------------------------------------
const START_UP_FILE_NAME = "startup.oba.jl"
function find_startup(vault; keepout = [".obsidian", ".git"])
    path = ""
    walkdown(vault; keepout) do path_
        if basename(path_) == "startup.oba.jl"
            path = path_
            return true
        end
        return false
    end
    return path
end

## ------------------------------------------------------------------
const INFO_COLOR = :yellow
const KEY_COLOR = :blue
const ERROR_COLOR = :red
const SOFT_COLOR = 8

function _info(io::IO, msg::String, sep; kwargs...)

    ioh, iow = displaysize(io)

    println()
    println(sep^max(30, iow - 10))
    printstyled(msg; bold = true, color = INFO_COLOR)
    println()
    for (k, val) in kwargs
        printstyled(k, ": "; bold = false, color = KEY_COLOR)
        printstyled(val; bold = false, color = SOFT_COLOR)
        println()
    end
end
_info(msg::String, sep; kwargs...) = _info(stdout, msg, sep; kwargs...)

function _error(io::IO, msg::String, err, sep; kwargs...)
    ioh, iow = displaysize(io)

    println()
    printstyled(sep^max(30, iow - 10); bold = true, color = ERROR_COLOR)
    println()
    printstyled(msg; bold = true, color = ERROR_COLOR)
    println()
    for (k, val) in kwargs
        printstyled(k, ": "; bold = false, color = KEY_COLOR)
        printstyled(val; bold = false, color = SOFT_COLOR)
        println()
    end
    println()
    errstr = sprint(showerror, err, catch_backtrace())
    printstyled(errstr; bold = false, color = SOFT_COLOR)
    println()
end
_error(msg::String, err, sep; kwargs...) = _error(stdout, msg, err, sep; kwargs...)