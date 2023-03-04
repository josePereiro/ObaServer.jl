## ------------------------------------------------------------------
# will trigger if the trigger_file changed
_has_trigger() = has_event!(
    getstate(OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY), 
    getstate(TRIGGER_FILE_SERVER_KEY)
)
_up_trigger_event() = update!(
    getstate(OBA_PLUGIN_TRIGGER_FILE_EVENT_KEY),
    getstate(TRIGGER_FILE_SERVER_KEY),
)

export up_trigger_file
function up_trigger_file()
    trfile = getstate(TRIGGER_FILE_SERVER_KEY, "")
    isempty(trfile) && return false
    write(trfile, _generate_rand_id(8))
    return true
end

function _wait_for_trigger()

    _info("Waiting for trigger", ".")
    
    timer::SleepTimer = getstate(WAIT_FOR_TRIGGER_SLEEP_TIMER_KEY)

    while true
        
        force = getstate(FORCE_TRIGGER_SERVER_KEY, true)
        force && break

        if !_has_trigger()
            sleep!(timer)
            continue
        end

        # fallback
        break
    end
    reset!(timer)

    _info("Boom!!! triggered", "")
end