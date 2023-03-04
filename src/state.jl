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

getstate(k::String) = getindex(SERVER_STATE, k)
getstate(k::String, dflt) = get(SERVER_STATE, k, dflt)
getstate!(k::String, dflt) = get!(SERVER_STATE, k, dflt)
getstate(f::Function, k::String) = get(f, SERVER_STATE, k)
getstate!(f::Function, k::String) = get!(f, SERVER_STATE, k)

## ------------------------------------------------------------------
# System keys
# global state
const VAULT_GLOBAL_KEY = "vaultdir"

# Running state
const LAST_AST_MTIME_KEY = "last_ast_mtime"
const CURR_AST_MTIME_KEY = "curr_ast_mtime"
const CURRAST_GLOBAL_KEY = "currast"
const MSG_FILE_SERVER_KEY = "msg_file"
const NOTE_EXT_SERVER_KEY = "note_ext"
const LAST_UPDATE_REGISTRY = "last_update"
const RUN_FILE_AGAIN_SIGNAL = "run_again_signal"
const IS_STARTUP_SERVER_KEY = "is_startup"
const CURRSCRIPT_GLOBAL_KEY = "currscript"
const IGNORE_TAGS_SERVER_KEY = "ignore_tags"
const TRIGGER_FILE_SERVER_KEY = "trigger_file"
const FORCE_TRIGGER_SERVER_KEY = "force_trigger"
const IGNORE_FOLDERS_SERVER_KEY = "ignore_folders"
const PROCESSED_SCRIPTS_CACHE_KEY = "processed_scripts"
const SERVER_LOOP_ITER_SERVER_KEY = "iter"
const PER_FILE_LOOP_ITER_SERVER_KEY = "per_files_iter"
const SERVER_LOOP_NITERS_SERVER_KEY = "niters"
const PER_FILE_LOOP_NITERS_SERVER_KEY = "per_files_niters"
const WAIT_FOR_TRIGGER_SLEEP_TIMER_KEY = "trigger_timer"
const OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY = "trigger_file_event"
const CURRAST_REPARSE_COUNTER_GLOBAL_KEY = "ast_reparse_counter"

vaultdir() = getstate(VAULT_GLOBAL_KEY)
_vaultdir!(dir::String) = getstate!(VAULT_GLOBAL_KEY, abspath(dir))

function currscript() 
    script_ast = getstate(CURRSCRIPT_GLOBAL_KEY)
    ast = parent_ast(script_ast)
    # check reparse counter
    ast_counter = reparse_counter(ast)
    last_counter = getstate!(CURRAST_REPARSE_COUNTER_GLOBAL_KEY, -1)
    if ast_counter != last_counter
        upstate!(CURRAST_REPARSE_COUNTER_GLOBAL_KEY, ast_counter)
        script_ast = up_currscript!()
    end
    return script_ast
end
_currscript!(ast::ObaScriptBlockAST) = upstate!(CURRSCRIPT_GLOBAL_KEY, ast)
_currscript!(ast::CodeBlockAST) = upstate!(CURRSCRIPT_GLOBAL_KEY, ast)

currfile() = parent_file(currscript())
currfiledir() = dirname(currfile())

currline() = currscript().line
scriptid() = get_param(currscript(), "id")

currast() = getstate(CURRAST_GLOBAL_KEY)
_currast!(ast::ObaAST) = upstate!(CURRAST_GLOBAL_KEY, ast)

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