local ADDON_NAME = ...
ShimmerTime = ShimmerTime or {}
local DS = ShimmerTime

DS.CATEGORIES = {
    {
        name = "Dimmer",
        enabledByDefault = false,
        emotes = {
            { key = "alt raid", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\altraid" },
            { key = "bustin", texture = "Interface\\AddOns\\ShimmerTime\\Emotes\\bustin", sound = "Interface\\AddOns\\ShimmerTime\\Sounds\\bustin.wav" },
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
        },
    },
    {
        name = "Shimmer Gifs",
        enabledByDefault = false,
        emotes = {
            {
                key = "pascal",
                texture = "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal.tga",
                frames = {
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_01.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_02.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_03.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_04.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_05.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_06.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_07.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_08.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_09.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_10.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_11.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_12.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_13.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_14.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_15.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_16.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_17.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_18.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_19.tga",
                    "Interface\\AddOns\\ShimmerTime\\Gifs\\pascal_20.tga",
                },
                frameDuration = 0.08,
            },
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

