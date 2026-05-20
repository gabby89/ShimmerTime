local ADDON_NAME = ...
ShimmerTime = ShimmerTime or {}
local DS = ShimmerTime

DS.CATEGORIES = {
    {
        name = "Dimmer",
        enabledByDefault = false,
        emotes = {
            { key = "alt raid", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\altraid" },
            { key = "bustin", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\bustin" },
            { key = "cream pie", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\cream" },
            { key = "dimmer", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\dimmer" },
            { key = "horse surgeon", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\horsesurgeon" },
            { key = "lexi", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\lexi" },
            { key = "milk it", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\milkit" },
            
        },
    },
    {
        name = "Shimmer",
        enabledByDefault = true,
        emotes = {
            { key = "couchman", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\couchman" },
            { key = "ice cream", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\icecream" },
            { key = "shimmer", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\icon" },
            { key = "pascal", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\pascal" },
        },
    },
    {
        name = "Shimmer Pets",
        enabledByDefault = true,
        emotes = {
            { key = "kyber", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\kyber" },
            { key = "lilly", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\lilly" },
            { key = "rebel", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\rebel" },
            { key = "rudy", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\rudy" },
        },
    },
}

