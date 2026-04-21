local addonName, ns = ...
ns.Config = {}

local csep = "[^%w]*"

-- Synonym Map: Regionalisms/Slang to Canonical IDs
ns.Config.SYNONYM_MAP = {
    ["ciudadela"] = "icc", ["corona"] = "icc", ["hielo"] = "icc", ["ciuda"] = "icc",
    ["sagrario"] = "sr", ["rubi"] = "sr", ["halion"] = "sr", ["rs"] = "sr",
    ["prueba"] = "toc", ["cruzado"] = "toc", ["titanes"] = "toc", ["campeones"] = "toc",
    ["archavon"] = "archa", ["conquista"] = "archa", ["torre"] = "archa", ["voa"] = "archa", ["vov"] = "archa", ["archa"] = "archa",
    ["semanal"] = "weekly", ["weekly"] = "weekly",
    ["u5"] = "u5", ["utgara"] = "weekly",
}

-- Raid Map: Configuration and Patterns
ns.Config.RAID_LIST = {
    {
        id = "icc",
        name = "ICC",
        patterns = {"icc", "ciuda", "corona", "hielo", "tuetano", "lk", "icecrown", "citadel"},
        priorities = 10
    },
    {
        id = "sr",
        name = "SR",
        patterns = {"sr", "sagrario", "halion", "rubi", "rs", "ruby", "sanctum"},
        priorities = 9
    },
    {
        id = "toc",
        name = "TOC",
        patterns = {"toc", "prueba", "cruzado", "titanes", "campeones", "trial", "crusader"},
        priorities = 8
    },
    {
        id = "archa",
        name = "ARCHA",
        patterns = {"archa", "archavon", "conquista", "torre", "voa", "fuego", "toran", "koralon", "vault"},
        priorities = 7
    },
    {
        id = "weekly",
        name = "Semanal",
        patterns = {"semanal", "weekly", "u5", "utgara", "naxx", "naxxramas", "maly", "malygos", "sarth", "sartharion", "ony", "onyxia"},
        priorities = 6
    }
}

-- Mapping patterns to IDs for O(1) matching
ns.Config.PATTERN_TO_ID = {}
for _, raid in ipairs(ns.Config.RAID_LIST) do
    for _, p in ipairs(raid.patterns) do
        ns.Config.PATTERN_TO_ID[p] = raid.id
    end
end

-- Role Patterns
ns.Config.ROLE_PATTERNS = {
    tank = {
        -- español
        "tank", "tanke", "tanques", "tanque", "tanqe", "tanks", "tankear",
        -- inglés / spanglish
        "mt", "ot", "offtank",
        -- clases usadas como tank en este servidor
        "oso",   -- druida guardian
        "prot",  -- guerrero/paladin prot
        "dk",    -- death knight tank (cuando aparece solo en contexto tank)
        -- combinaciones donde el token de clase actúa como rol
        "war",   -- warrior tank
    },
    healer = {
        -- genérico
        "heal", "healer", "heals", "heler", "helers", "healers",
        "hyler",  -- typo frecuente observado en logs
        -- specs/clases heal
        "holy",   -- paladin holy / priest holy
        "disci", "disc",  -- priest discipline
        "resto",  -- druida/shaman resto
        "restauracion",
        -- clases heal abreviadas
        "hpala",  -- holy paladin
        "dudu",   -- druida (cuando aparece en contexto heal)
        "rdudu",  -- druida restauracion
        "chamy", "chami", "chaman", "chammy", "sham", "shaman",
        "rshaman", -- shaman resto
        "pri",    -- priest
        "priest",
        "sacer",  -- sacerdote
        -- combinaciones observadas (token individual)
        "druida", -- druida heal/resto
        "pala",   -- paladin heal (cuando aparece solo)
        "nito",   -- "necesito" abreviado, en este servidor se usa como "busco rol"
    },
    dps = {
        -- genérico
        "dps", "dpser", "dd",
        -- tipos de dps
        "melee", "mele", "mdps",
        "ranged", "rdps",
        "caster", "casters",
        -- clases DPS observadas en logs
        "feral",   -- druida feral dps
        "picaro",  -- rogue
        "rogue",
        "mago",
        "brujo", "lock",
        "cazador", "caza",  -- hunter
        "shadow",  -- priest shadow
        "pollo",   -- apodo local para druida balance / chaman mejora
        "ele",     -- chamán elemental
        "mejora",  -- chamán mejora
        "demo", "demon",    -- brujo demonología
        "afli",    -- brujo affliction
        "retri", "retry",   -- paladín retribución
        "profano", -- dk unholy
        "frost",   -- dk frost / mago frost
        "war",     -- warrior dps (cuando aparece en contexto dps)
        "warr",
        "equilibrio", -- druida balance
        -- combinaciones observadas como token individual
        "sacer",   -- sacerdote dps (shadow)
        "prot",    -- en raros casos prot dps (evaluar)
    },
}

-- Settings Defaults
ns.Config.DEFAULTS = {
    ttl = 120,
    mergeByLeader = true,
    showProgress = true,
    enableSmartSearch = true,
    showMinimap = true,
    minimapPos = 45,
    windowLocked = false,
    windowPoint = "CENTER",
    windowRelativePoint = "CENTER",
    windowX = 0,
    windowY = 0,
    reactiveSync = true,
    patterns = {},
    debug = false,
}
