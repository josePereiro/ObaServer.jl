## ------------------------------------------------------------------
mutable struct SleepTimer
    tmin::Float64
    tmax::Float64
    dt::Float64
    t::Float64
end

function SleepTimer(tmin, tmax, dt) 
    st = SleepTimer(tmin, tmax, dt, 0)
    reset!(st)
    return st
end

Base.sleep(st::SleepTimer) = sleep(st.t)

set_t!(st::SleepTimer, t::Float64) = (st.t = clamp(t, st.tmin, st.tmax))
update!(st::SleepTimer) = set_t!(st, st.t + st.dt)
sleep!(st::SleepTimer) = (sleep(st); update!(st))
reset!(st::SleepTimer) = set_t!(st, st.dt > 0 ? st.tmin : st.tmax)

## ------------------------------------------------------------------
const OBA_PLUGIN_TRIGGER_FILE_EVENT = FileContentEvent()

_has_trigger(trigger_file) = has_event!(OBA_PLUGIN_TRIGGER_FILE_EVENT, trigger_file)
_up_trigger_event(trigger_file) = update!(OBA_PLUGIN_TRIGGER_FILE_EVENT, trigger_file)

const WAIT_FOR_TRIGGER_SLEEP_TIMER = SleepTimer(0.5, 15.0, 0.01)
function _wait_for_trigger(server::ObaServerState)
    #check trigger
    _info("Waiting for trigger", ".")

    while !server[FORCE_TRIGGER_ENV_KEY]
        if !_has_trigger(server[TRIGGER_FILE_ENV_KEY])
            sleep!(WAIT_FOR_TRIGGER_SLEEP_TIMER)
            continue
        end
        break
    end
    reset!(WAIT_FOR_TRIGGER_SLEEP_TIMER)

    _info("Boom!!! triggered", "")
end