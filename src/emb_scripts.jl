# this both must be coherents
const EMBEDDED_SCRIPT_TAG = "#!julia"
const EMBEDDED_SCRIPT_TAG_REGEX = r"(?<tag>(?<bang>\#\!julia)\-?(?:(?<id>[a-z0-9A-Z]+))?)"

_gen_ambtag(prefix = "", n = 8) = string(EMBEDDED_SCRIPT_TAG, "-", prefix, randstring(n))

## ------------------------------------------------------------------
# This replace some util Base macros by its Oba equivalent globals.
# Because the scripts are loaded from strings and not files
function _replace_base_macros(src)
    for (_macro, _global) in [
        ("__LINE__", "__LINE__"), 
        ("__FILE__", "__FILE__"), 
        ("__DIR__", "__DIR__"), 
    ]
        src = replace(src, string("Base.@", _macro) => _global)
        src = replace(src, string("@Base.", _macro) => _global)
        src = replace(src, string("@", _macro) => _global)
    end
    return src
end

function _format_source(src)
    # remove tag
    src = replace(src, EMBEDDED_SCRIPT_TAG_REGEX => ""; count = 1)
    src = strip(src)
    src = replace(src, r"\A```julia\h*\n" => ""; count = 1)
    src = replace(src, r"```\h*\Z" => ""; count = 1)
    src = _replace_base_macros(src)
    return string(src)
end

## ------------------------------------------------------------------