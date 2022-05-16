const OBA_PLUGIN_TRIGGER_FILE_CONTENT_EVENT = FileContentEvent()
const RUNNER_FILE_CONTENT_EVENT = FileContentEvent()

_trigger_file(vault) = joinpath(vault, ".obsidian", "plugins", "oba-plugin", "trigger-signal.json")

_has_trigger(vault) = has_event!(OBA_PLUGIN_TRIGGER_FILE_CONTENT_EVENT, _trigger_file(vault))
_up_trigger_event(vault) = update!(OBA_PLUGIN_TRIGGER_FILE_CONTENT_EVENT, _trigger_file(vault))