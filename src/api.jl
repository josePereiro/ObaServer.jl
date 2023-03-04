import ObaASTs.hastag
hastag(arg) = hastag(currast(), arg)

export is_modified
function is_modified(elp = 0.0)
    currmtime = getstate(CURR_AST_MTIME_KEY, Inf)
    lastmtime = getstate(LAST_AST_MTIME_KEY, -Inf)
    return currmtime - lastmtime > abs(elp)
end

export is_firstruniter
is_firstruniter() = isone(getstate(PER_FILE_LOOP_ITER_SERVER_KEY, 0))

export findall_notefiles
function findall_notefiles()
    vault = getstate(VAULT_GLOBAL_KEY)
    note_ext = getstate(NOTE_EXT_SERVER_KEY)
    return findall_files(vault, note_ext; 
        keepout = ignore_folders()
    )
end

export foreach_noteast
function foreach_noteast(f::Function)
    vault = getstate(VAULT_GLOBAL_KEY)
    for notefile in findall_notefiles()    
        AST = nothing
        try; AST = parse_file(notefile)
        catch err
            _error("ERROR PARSING", err, "!"; 
                notefile, 
                obsidian = _obsidian_url(vault, notefile)
            )
            return false
        end
        f(AST) === true && return true
    end
    return true
end