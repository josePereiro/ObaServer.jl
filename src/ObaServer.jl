module ObaServer

import EasyEvents: reset!, update!, has_event!, FileContentEvent, FileMTimeEvent
import Random: randstring

using FilesTreeTools
using ObaASTs

export run_server
export serverstate, vaultdir, vaultdir!, currscript, currscript!
export currfile, currfiledir, currline, scriptid, currast, currast!
export show_server_state

include("types.jl")
include("state.jl")
include("control.jl")
include("extras.jl")
include("oba_plugin.jl")
include("oba_scripts.jl")
include("run_server.jl")
include("utils.jl")

    function __init__()
        init_server_defaults()
    end

end
