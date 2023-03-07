module ObaServer

    error("DEPRECATED: new at https://github.com/josePereiro/ObaServers.jl")

    import EasyEvents: has_event!, FileContentEvent, FileMTimeEvent
    import Random: randstring

    using Dates
    using ObaBase
    using ObaASTs

    export run_server
    export serverstate, vaultdir, _vaultdir!, currscript, _currscript!
    export currfile, currfiledir, currline, scriptid, currast, _currast!
    export show_server_state

    #! include .
    include("0_types.jl")
    include("api.jl")
    include("callbacks.jl")
    include("control.jl")
    include("oba_plugin.jl")
    include("oba_scripts.jl")
    include("run_server.jl")
    include("state.jl")
    include("utils.jl")

    function __init__()
        init_server_defaults()
    end

end