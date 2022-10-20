module ObaServer

import EasyEvents: reset!, update!, has_event!, FileContentEvent, FileMTimeEvent
import Random: randstring
import HTTP: escapeuri

using Dates
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
include("callbacks.jl")

end
