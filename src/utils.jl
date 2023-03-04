# -------------------------------------------------------------------
function is_modified(file::AbstractString)
    mtimereg = getstate!(LAST_UPDATE_REGISTRY) do
        Dict{String, Float64}()
    end
    lastmtime = get!(mtimereg, file, -1)
    currmtime = mtime(file)
    return lastmtime != currmtime
end

# -------------------------------------------------------------------
function send_msg(msg::AbstractString)
    msg_file = getstate(MSG_FILE_SERVER_KEY)
    write(msg_file, string(msg))
    return msg_file
end