local addonName, ns = ...
local Parser = {}

local strlower = string.lower
local strgsub = string.gsub
local strfind = string.find

-- Accent mapping for normalization
local ACCENT_MAP = {
    ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
    ["ñ"] = "n", ["ü"] = "u", ["Á"] = "a", ["É"] = "e", ["Í"] = "i",
    ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n", ["Ü"] = "u"
}

function Parser.Normalize(text)
    if not text then return "" end
    text = strlower(text)
    -- Remove accents
    for accent, sub in pairs(ACCENT_MAP) do
        text = strgsub(text, accent, sub)
    end
    -- Remove punctuation except spacers
    text = strgsub(text, "[%p%c]", " ")
    
    -- Preserve common raid shorthand before splitting others
    -- This ensures "25h", "10n", etc. stay as single tokens
    text = strgsub(text, "(%d+)([hn])", " %1%2 ")
    
    -- Separate other numbers from letters
    text = strgsub(text, "([%a])([%d])", "%1 %2")
    text = strgsub(text, "([%d])([%a])", "%1 %2")
    
    -- Collapse spaces
    text = strgsub(text, "%s+", " ")
    return strtrim(text)
end

function Parser.Tokenize(text)
    local tokens = {}
    for token in string.gmatch(text, "%S+") do
        -- Check synonym map
        local syn = ns.Config.SYNONYM_MAP[token]
        table.insert(tokens, syn or token)
    end
    return tokens
end

-- Production-grade wrapper
function Parser.SafeParse(sender, message)
    local ok, result = pcall(function()
        local clean = Parser.Normalize(message)
        local tokens = Parser.Tokenize(clean)
        return {
            clean = clean,
            tokens = tokens,
            sender = sender,
            original = message
        }
    end)
    
    if ok then
        return result
    else
        if ns.Config.DEFAULTS.debug then
            print("|cffff0000Parser Error:|r", result)
        end
        return nil
    end
end

ns.Parser = Parser
