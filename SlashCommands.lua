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

local function RegisterSlashCommands()
    SLASH_SHIMMER1 = "/shimmer"
    SLASH_SHIMMER2 = "/ds"

    SlashCmdList["SHIMMER"] = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$")

        if msg == "" then
            PlaySoundFile(DS.SHIMMER_SOUND, "Master")
        elseif msg == "options" or msg == "config" then
            DS.OpenOptions()
        elseif msg == "reset" or msg == "resetminimap" then
            ShimmerTimeDB.minimapAngle = 225
            if DS.UpdateMinimapButtonPosition then
                DS.UpdateMinimapButtonPosition()
            end
            print("|cffffd100ShimmerTime:|r minimap button position reset.")
        elseif msg == "menu" or msg == "emotes" then
            if DS.minimapButton then
                DS.ToggleEmoteMenu(DS.minimapButton)
            end
        elseif msg == "list" then
            print("|cffffd100ShimmerTime emotes:|r")
            for _, category in ipairs(DS.CATEGORIES) do
                local status = DS.IsCategoryEnabled(category) and "enabled" or "disabled"
                print("|cffffd100" .. category.name .. "|r (" .. status .. ")")
                for _, emote in ipairs(category.emotes) do
                    print(" - " .. emote.key)
                end
            end
        else
            print("|cffffd100ShimmerTime commands:|r /shimmer, /shimmerquote, /shimmer options, /shimmer menu, /shimmer reset, /shimmer list")
        end
    end

    SLASH_SHIMMERQUOTE1 = "/shimmerquote"
    SlashCmdList["SHIMMERQUOTE"] = function()
        SendRandomShimmerQuote()
    end
end

DS.RegisterSlashCommands = RegisterSlashCommands
