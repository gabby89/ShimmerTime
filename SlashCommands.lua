local ADDON_NAME = ...
ShimmerTime = ShimmerTime or Shimmertime or {}
local DS = ShimmerTime

local function GetCurrentChatTarget()
    local editBox = ChatEdit_GetActiveWindow()

    if editBox then
        local chatType = editBox:GetAttribute("chatType")
        local target = editBox:GetAttribute("tellTarget") or editBox:GetAttribute("channelTarget")

        if chatType == "WHISPER" or chatType == "BN_WHISPER" or chatType == "CHANNEL" then
            return chatType, target
        end

        return chatType, nil
    end

    -- Fallbacks when no chat edit box is open.
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    elseif IsInGuild() then
        return "GUILD"
    end

    return "SAY"
end

local function SendRandomShimmerQuote()
    if not DS.SHIMMER_QUOTES or #DS.SHIMMER_QUOTES == 0 then
        print("|cffffd100ShimmerTime:|r No ShimmerTime quotes are configured.")
        return
    end

    local quote = DS.SHIMMER_QUOTES[random(#DS.SHIMMER_QUOTES)]
    local chatType, target = GetCurrentChatTarget()

    if chatType == "WHISPER" or chatType == "BN_WHISPER" or chatType == "CHANNEL" then
        SendChatMessage(quote, chatType, nil, target)
    else
        SendChatMessage(quote, chatType)
    end
end

local function AreFunSlashCommandsEnabled()
    return ShimmerTimeDB and ShimmerTimeDB.enableSlashCommands == true
end

local function PrintSlashCommandsDisabled()
    print("|cffffd100ShimmerTime:|r slash commands are disabled. Turn on Slash Commands in /shimmer options.")
end

local function ResetDefaults()
    ShimmerTimeDB = ShimmerTimeDB or {}
    ShimmerTimeDB.emoteSize = DS.DEFAULT_EMOTE_SIZE
    ShimmerTimeDB.minimapAngle = 225
    ShimmerTimeDB.showMinimapButton = true
    ShimmerTimeDB.showEmotesInBubbles = false
    ShimmerTimeDB.showGifsInBubbles = false
    ShimmerTimeDB.playEmoteSounds = false
    ShimmerTimeDB.enableSlashCommands = false

    ShimmerTimeDB.enabledSections = {}
    if DS.CATEGORIES then
        for _, category in ipairs(DS.CATEGORIES) do
            local key = category.key or category.name
            ShimmerTimeDB.enabledSections[key] = category.enabledByDefault == true
        end
    end

    ShimmerTimeDB.enabledChatChannels = {}
    if DS.CHAT_CHANNEL_OPTIONS then
        for _, option in ipairs(DS.CHAT_CHANNEL_OPTIONS) do
            ShimmerTimeDB.enabledChatChannels[option.key] = true
        end
    end

    if DS.UpdateMinimapButtonPosition then
        DS.UpdateMinimapButtonPosition()
    end
    if DS.RefreshMinimapButtonVisibility then
        DS.RefreshMinimapButtonVisibility()
    end
end

local function RegisterSlashCommands()
    SLASH_SHIMMER1 = "/shimmer"
    SLASH_SHIMMER2 = "/ds"

    SlashCmdList["SHIMMER"] = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$")

        if msg == "" then
            if AreFunSlashCommandsEnabled() then
                PlaySoundFile(DS.SHIMMER_SOUND, "Master")
            else
                PrintSlashCommandsDisabled()
            end
        elseif msg == "options" or msg == "config" then
            DS.OpenOptions()
        elseif msg == "reset" then
            ResetDefaults()
            print("|cffffd100ShimmerTime:|r settings reset to default.")
        elseif msg == "help" then
            print("|cffffd100ShimmerTime commands:|r")
            print("/shimmer - play the shimmer sound")
            print("/shimmer options or /shimmer config - open addon options")
            print("/shimmer reset - reset addon settings to defaults")
            print("/shimmer help - show this help message")
            print("/shimmerquote - send a random Shimmer out-of-context quote")
            print("/cottagecheese - play the cottage cheese sound")
            print("Enable fun slash commands in /shimmer options > Misc > Slash Commands.")
        else
            print("|cffffd100ShimmerTime:|r unknown command. Use /shimmer help")
        end
    end

    SLASH_SHIMMERQUOTE1 = "/shimmerquote"
    SlashCmdList["SHIMMERQUOTE"] = function()
        if AreFunSlashCommandsEnabled() then
            SendRandomShimmerQuote()
        else
            PrintSlashCommandsDisabled()
        end
    end

    SLASH_COTTAGECHEESE1 = "/cottagecheese"
    SlashCmdList["COTTAGECHEESE"] = function()
        if AreFunSlashCommandsEnabled() then
            PlaySoundFile(DS.COTTAGE_CHEESE_SOUND, "Master")
        else
            PrintSlashCommandsDisabled()
        end
    end
end

DS.RegisterSlashCommands = RegisterSlashCommands
