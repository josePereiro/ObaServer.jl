# TODO: make better global interface
# [DONE] Maybe using functions (e.g currlineast())
# [DONE?] Automatize reparse! detection

const SERVER_STATE = ObaServerState()

serverstate() = SERVER_STATE

upstate!(k, val) = setindex!(SERVER_STATE, val, k)
function upstate!(;kwargs...) 
    for (k, val) in kwargs
        setindex!(SERVER_STATE, val, k)
    end
    return e
end

getstate(k) = getindex(SERVER_STATE, k)
getstate(k, dflt) = get(SERVER_STATE, k, dflt)
getstate!(k, dflt) = get!(SERVER_STATE, k, dflt)
getstate(f::Function, k) = get(f, SERVER_STATE, k)
getstate!(f::Function, k) = get!(f, SERVER_STATE, k)

## ------------------------------------------------------------------
# System keys
# global state
const VAULT_GLOBAL_KEY = "vaultdir"

# Running state
const CURRAST_GLOBAL_KEY = "currast"
const CURRAST_REPARSE_COUNTER_GLOBAL_KEY = "ast_reparse_counter"
const CURRSCRIPT_GLOBAL_KEY = "currscript"
const SERVER_LOOP_NITERS_SERVER_KEY = "niters"
const SERVER_LOOP_ITER_SERVER_KEY = "iter"
const PER_FILE_LOOP_NITERS_SERVER_KEY = "per_files_niters"
const PER_FILE_LOOP_ITER_SERVER_KEY = "per_files_iter"
const FORCE_TRIGGER_SERVER_KEY = "force_trigger"
const TRIGGER_FILE_SERVER_KEY = "trigger_file"
const NOTE_EXT_SERVER_KEY = "note_ext"
const RUN_FILE_AGAIN_SIGNAL = "run_again_signal"
const PROCESSED_SCRIPTS_CACHE = "processed_scripts"
const LAST_UPDATE_REGISTRY = "last_update"
const WAIT_FOR_TRIGGER_SLEEP_TIMER_KEY = "trigger_timer"
const OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY = "trigger_file_event"
const IGNORE_TAGS_SERVER_KEY = "ignore_tags"
const IGNORE_FOLDERS_SERVER_KEY = "ignore_folders"
const IS_STARTUP_SERVER_KEY = "is_startup"

vaultdir() = getindex(SERVER_STATE, VAULT_GLOBAL_KEY)
vaultdir!(dir::String) = setindex!(SERVER_STATE, abspath(dir), VAULT_GLOBAL_KEY)

function currscript() 
    script_ast = getindex(SERVER_STATE, CURRSCRIPT_GLOBAL_KEY)
    ast = parent_ast(script_ast)
    # check reparse counter
    if reparse_counter(ast) != getstate!(CURRAST_REPARSE_COUNTER_GLOBAL_KEY, nothing)
        upstate!(CURRAST_REPARSE_COUNTER_GLOBAL_KEY, reparse_counter(ast))
        script_ast = up_currscript!()
    end
    return script_ast
end
currscript!(ast::ObaScriptBlockAST) = setindex!(SERVER_STATE, ast, CURRSCRIPT_GLOBAL_KEY)
currscript!(ast::CodeBlockAST) = setindex!(SERVER_STATE, ast, CURRSCRIPT_GLOBAL_KEY)

currfile() = parent_file(currscript())
currfiledir() = dirname(currfile())

currline() = currscript().line
scriptid() = get_param(currscript(), "id")

currast() = getindex(SERVER_STATE, CURRAST_GLOBAL_KEY)
currast!(ast::ObaAST) = setindex!(SERVER_STATE, ast, CURRAST_GLOBAL_KEY)

export show_server_state
show_server_state() = _info("Server state", "", SERVER_STATE.state)

ignore_tags() = getstate!(IGNORE_TAGS_SERVER_KEY) do
    String[]
end
ignore_tags!(tags::Vector{String}) = upstate!(IGNORE_TAGS_SERVER_KEY, tags)
export ignore_tags, ignore_tags!

ignore_folders() = getstate!(IGNORE_FOLDERS_SERVER_KEY) do
    String[]
end
ignore_folders!(folders::Vector{String}) = upstate!(IGNORE_FOLDERS_SERVER_KEY, folders)
export ignore_folders, ignore_folders!

function init_server_defaults()
    
    upstate!(WAIT_FOR_TRIGGER_SLEEP_TIMER_KEY, 
        SleepTimer(0.5, 15.0, 0.01)
    )
    upstate!(OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY, 
        FileContentEvent()
    )
    upstate!(LAST_UPDATE_REGISTRY, 
        Dict{String, Float64}()
    )

    ignore_tags!(String["Oba/ignore"])
    ignore_folders!(String[".obsidian", ".git", ".trash"])
    
end