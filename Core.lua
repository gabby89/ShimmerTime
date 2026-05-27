
local ADDON_NAME = ...
ShimmerTime = ShimmerTime or {}
local DS = ShimmerTime

DS.VERSION = "1.0.1"
DS.DEFAULT_EMOTE_SIZE = 32
DS.SHIMMER_ICON_TEXTURE = "Interface\\AddOns\\ShimmerTime\\Emotes\\icon.tga"
DS.SHIMMER_BANNER_TEXTURE = "Interface\\AddOns\\ShimmerTime\\Images\\shimmertime_banner.tga"
DS.DIMMER_BANNER_TEXTURE = "Interface\\AddOns\\ShimmerTime\\Images\\dimmertime_banner.tga"
DS.SHIMMER_SOUND = "Interface\\AddOns\\ShimmerTime\\Sounds\\shimmer_theme.wav"
DS.COTTAGE_CHEESE_SOUND = "Interface\\AddOns\\ShimmerTime\\Sounds\\cottagecheese.wav"

DS.THEME = {
    bg = { 0.055, 0.045, 0.070, 0.94 },
    border = { 0.83, 0.64, 0.76, 1.00 },
    text = { 1.00, 0.91, 0.96, 1.00 },
    subText = { 0.92, 0.74, 0.84, 1.00 },
    highlight = { 0.73, 0.36, 0.58, 0.28 },
    highlightEdge = { 1.00, 0.80, 0.90, 0.40 },
}

-- Emote data has been moved to Emotes.lua for easier maintenance.

local function GetCategoryKey(category)
    return category.key or category.name
end

local function IsCategoryEnabled(category)
    local key = GetCategoryKey(category)
    if not ShimmerTimeDB or not ShimmerTimeDB.enabledSections or ShimmerTimeDB.enabledSections[key] == nil then
        return category.enabledByDefault == true
    end

    return ShimmerTimeDB.enabledSections[key] == true
end
DS.IsCategoryEnabled = IsCategoryEnabled

local function GetEnabledCategories()
    local enabled = {}
    for _, category in ipairs(DS.CATEGORIES) do
        if IsCategoryEnabled(category) then
            table.insert(enabled, category)
        end
    end
    return enabled
end

local function SaveCategoryEnabled(category, enabled)
    ShimmerTimeDB.enabledSections = ShimmerTimeDB.enabledSections or {}
    ShimmerTimeDB.enabledSections[GetCategoryKey(category)] = enabled == true
end

local IsChatChannelEnabled
local SaveChatChannelEnabled

-- Shimmer quotes are now maintained in Quotes.lua.

local function GetEmoteTexture(emote)
    return emote.texture or (emote.frames and emote.frames[1])
end

local function TextureTag(texture, size)
    size = size or (ShimmerTimeDB and ShimmerTimeDB.emoteSize) or DS.DEFAULT_EMOTE_SIZE
    return ("|T%s:%d:%d|t"):format(texture, size, size)
end

local function CreateAnimatedEmoteFrame()
    if DS.animatedEmoteFrame then
        return
    end

    local frame = CreateFrame("Frame", "ShimmerTimeAnimatedEmoteFrame", UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetAllPoints(frame)
    frame:Hide()
    DS.animatedEmoteFrame = frame
end

local function PreloadAnimatedEmoteTextures()
    if DS.preloadTextures then
        return
    end

    CreateAnimatedEmoteFrame()

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 1000)
    frame:SetSize(1, 1)
    frame:Show()

    DS.preloadTextures = {}

    for _, category in ipairs(DS.CATEGORIES) do
        if category.emotes then
            for _, emote in ipairs(category.emotes) do
                if emote.frames then
                    for _, path in ipairs(emote.frames) do
                        local texture = frame:CreateTexture(nil, "BACKGROUND")
                        texture:SetTexture(path)
                        texture:SetAllPoints(frame)
                        texture:Show()
                        table.insert(DS.preloadTextures, texture)
                    end
                end
            end
        end
    end

    -- Force a real texture load for the first animated emote frame.
    for _, category in ipairs(DS.CATEGORIES) do
        if category.emotes then
            for _, emote in ipairs(category.emotes) do
                if emote.frames and #emote.frames > 0 then
                    DS.animatedEmoteFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 1000)
                    DS.animatedEmoteFrame:SetSize(1, 1)
                    DS.animatedEmoteFrame.texture:SetTexture(emote.frames[1])
                    DS.animatedEmoteFrame:Show()
                    DS.animatedEmoteFrame:Hide()
                    return
                end
            end
        end
    end
end

local currentEmoteSoundHandle
local function ResetEmoteSoundHandle(handle)
    if currentEmoteSoundHandle == handle then
        currentEmoteSoundHandle = nil
    end
end

local function PlayEmoteSound(emote)
    if not ShimmerTimeDB or ShimmerTimeDB.playEmoteSounds ~= true then
        return
    end

    if currentEmoteSoundHandle then
        return
    end

    if emote and emote.sound then
        local handle = PlaySoundFile(emote.sound, "Master")
        if handle then
            currentEmoteSoundHandle = handle
            C_Timer.After(6, function()
                ResetEmoteSoundHandle(handle)
            end)
        end
    end
end

local function GetAnimatedEmoteAnchor()
    local editBox = ChatEdit_GetActiveWindow()
    if editBox and editBox:IsShown() then
        return editBox
    end

    local chatFrame = _G["ChatFrame1"]
    if chatFrame and chatFrame:IsShown() then
        return chatFrame
    end

    return UIParent
end

local lastAnimatedEmote = {}
function DS.PlayAnimatedEmote(emote)
    if not emote or not emote.frames or #emote.frames == 0 then
        return
    end

    local now = GetTime()
    if lastAnimatedEmote[emote.key] and (now - lastAnimatedEmote[emote.key]) < 1.0 then
        return
    end
    lastAnimatedEmote[emote.key] = now

    CreateAnimatedEmoteFrame()

    local frame = DS.animatedEmoteFrame
    if frame:GetScript("OnUpdate") then
        frame:SetScript("OnUpdate", nil)
    end
    frame:Hide()

    local size = math.max(96, ((ShimmerTimeDB and ShimmerTimeDB.emoteSize) or DS.DEFAULT_EMOTE_SIZE) * 3)
    frame:SetSize(size, size)

    local anchor = GetAnimatedEmoteAnchor()
    frame:ClearAllPoints()
    if anchor == UIParent then
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    else
        frame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 10)
    end

    frame.frames = emote.frames
    frame.frameDuration = emote.frameDuration or 0.08
    frame.elapsed = 0
    frame.index = 1
    frame.loops = 0
    frame.maxLoops = emote.loops or 2
    frame.texture:SetTexture(frame.frames[1])
    frame:Show()

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < self.frameDuration then
            return
        end

        self.elapsed = 0
        self.index = self.index + 1
        if self.index > #self.frames then
            self.index = 1
            self.loops = self.loops + 1
            if self.loops >= self.maxLoops then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end
        end

        self.texture:SetTexture(self.frames[self.index])
    end)
end



local function IsBubbleEmotesEnabled()
    if not ShimmerTimeDB or ShimmerTimeDB.showEmotesInBubbles == nil then
        return false
    end
    return ShimmerTimeDB.showEmotesInBubbles == true
end
DS.IsBubbleEmotesEnabled = IsBubbleEmotesEnabled

local function IsGifBubbleEmotesEnabled()
    if not ShimmerTimeDB or ShimmerTimeDB.showGifsInBubbles == nil then
        return false
    end
    return ShimmerTimeDB.showGifsInBubbles == true
end
DS.IsGifBubbleEmotesEnabled = IsGifBubbleEmotesEnabled

local function FindBubbleFontString(frame)
    if not frame then
        return nil
    end

    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            return region
        end
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        local found = FindBubbleFontString(child)
        if found then
            return found
        end
    end

    return nil
end

local function GetChatBubbles()
    if C_ChatBubbles and C_ChatBubbles.GetAllChatBubbles then
        return C_ChatBubbles.GetAllChatBubbles(false)
    end
    return {}
end

local function EnsureBubbleEmoteFrame(bubble)
    if bubble.ShimmerTimeEmoteFrame then
        return bubble.ShimmerTimeEmoteFrame
    end

    local frame = CreateFrame("Frame", nil, bubble)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetPoint("BOTTOM", bubble, "TOP", 0, 4)
    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetAllPoints(frame)
    bubble.ShimmerTimeEmoteFrame = frame
    return frame
end

function DS.ShowEmoteOnChatBubbles(emote, triggerText)
    if not emote or not triggerText or (not IsBubbleEmotesEnabled() and not IsGifBubbleEmotesEnabled()) then
        return
    end

    local size = math.max(48, ((ShimmerTimeDB and ShimmerTimeDB.emoteSize) or DS.DEFAULT_EMOTE_SIZE) * 2)
    local trigger = triggerText:lower()

    local function TryShow()
        for _, bubble in ipairs(GetChatBubbles()) do
            if bubble and bubble:IsShown() then
                local fontString = FindBubbleFontString(bubble)
                local text = fontString and fontString:GetText()
                if text and text:lower():find(trigger, 1, true) then
                    local frame = EnsureBubbleEmoteFrame(bubble)
                    frame:SetSize(size, size)
                    frame:Show()

                    if emote.frames and #emote.frames > 0 and IsGifBubbleEmotesEnabled() then
                        frame.frames = emote.frames
                        frame.frameDuration = emote.frameDuration or 0.08
                        frame.elapsed = 0
                        frame.index = 1
                        frame.loops = 0
                        frame.maxLoops = emote.loops or 2
                        frame.texture:SetTexture(frame.frames[1])
                        frame:SetScript("OnUpdate", function(self, elapsed)
                            self.elapsed = self.elapsed + elapsed
                            if self.elapsed < self.frameDuration then
                                return
                            end

                            self.elapsed = 0
                            self.index = self.index + 1
                            if self.index > #self.frames then
                                self.index = 1
                                self.loops = self.loops + 1
                                if self.loops >= self.maxLoops then
                                    self:SetScript("OnUpdate", nil)
                                    self:Hide()
                                    return
                                end
                            end

                            self.texture:SetTexture(self.frames[self.index])
                        end)
                    elseif IsBubbleEmotesEnabled() then
                        frame.texture:SetTexture(GetEmoteTexture(emote))
                        frame:SetScript("OnUpdate", nil)
                        C_Timer.After(4, function()
                            if frame then
                                frame:Hide()
                            end
                        end)
                    else
                        frame:Hide()
                    end
                end
            end
        end
    end

    -- Chat bubbles are created shortly after the chat event fires, so check a few times.
    C_Timer.After(0.05, TryShow)
    C_Timer.After(0.20, TryShow)
    C_Timer.After(0.45, TryShow)
end

local function EscapePattern(text)
    return (text:gsub("([^%w])", "%%%1"))
end

local function GetEnabledEmotesByPriority()
    local byKey = {}
    local ordered = {}

    for categoryIndex, category in ipairs(DS.CATEGORIES) do
        if IsCategoryEnabled(category) and category.emotes then
            local categoryPriority = category.priority or 0
            for emoteIndex, emote in ipairs(category.emotes) do
                local key = emote.key and emote.key:lower()
                if key then
                    local existing = byKey[key]
                    local shouldUse = false
                    if not existing then
                        shouldUse = true
                    elseif categoryPriority > existing.priority then
                        shouldUse = true
                    elseif categoryPriority == existing.priority and categoryIndex < existing.categoryIndex then
                        shouldUse = true
                    end

                    if shouldUse then
                        if not existing then
                            table.insert(ordered, key)
                        end
                        byKey[key] = { emote = emote, priority = categoryPriority, categoryIndex = categoryIndex }
                    end
                end
            end
        end
    end

    table.sort(ordered, function(a, b)
        if #a == #b then return a < b end
        return #a > #b
    end)

    return byKey, ordered
end

local function ReplaceEmoteWords(message)
    if not message then
        return message
    end

    -- Match only against the original message so an emote name never gets replaced
    -- inside an already-created |T...|t texture tag.
    local byKey, orderedKeys = GetEnabledEmotesByPriority()
    local lowerMessage = message:lower()
    local replacements = {}

    for _, lowerKey in ipairs(orderedKeys) do
        local item = byKey[lowerKey]
        local emote = item and item.emote
        if emote then
            local escapedKey = EscapePattern(lowerKey)
            local searchStart = 1
            while true do
                local startPos, endPos = lowerMessage:find("%f[%w]" .. escapedKey .. "%f[%W]", searchStart)
                if not startPos then break end

                local overlaps = false
                for _, existing in ipairs(replacements) do
                    if startPos <= existing.finishPos and endPos >= existing.startPos then
                        overlaps = true
                        break
                    end
                end

                if not overlaps then
                    table.insert(replacements, { startPos = startPos, finishPos = endPos, emote = emote })
                end

                searchStart = endPos + 1
            end
        end
    end

    if #replacements == 0 then
        return message
    end

    table.sort(replacements, function(a, b) return a.startPos < b.startPos end)

    local parts = {}
    local cursor = 1
    for _, replacement in ipairs(replacements) do
        local emote = replacement.emote
        table.insert(parts, message:sub(cursor, replacement.startPos - 1))
        table.insert(parts, TextureTag(GetEmoteTexture(emote)))

        if emote.frames then
            if IsBubbleEmotesEnabled() then
                DS.ShowEmoteOnChatBubbles(emote, emote.key)
            end
        else
            DS.ShowEmoteOnChatBubbles(emote, emote.key)
        end
        PlayEmoteSound(emote)

        cursor = replacement.finishPos + 1
    end
    table.insert(parts, message:sub(cursor))

    return table.concat(parts)
end

local function ChatFilter(self, event, message, ...)
    if not IsChatChannelEnabled(event) then
        return false, message, ...
    end

    return false, ReplaceEmoteWords(message), ...
end

local CHAT_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
}

local CHAT_CHANNEL_OPTIONS = {
    { key = "SAY", name = "Say", events = { "CHAT_MSG_SAY" } },
    { key = "YELL", name = "Yell", events = { "CHAT_MSG_YELL" } },
    { key = "GUILD", name = "Guild", events = { "CHAT_MSG_GUILD" } },
    { key = "OFFICER", name = "Officer", events = { "CHAT_MSG_OFFICER" } },
    { key = "PARTY", name = "Party", events = { "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" } },
    { key = "RAID", name = "Raid", events = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" } },
    { key = "INSTANCE", name = "Instance", events = { "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" } },
    { key = "WHISPER", name = "Whisper", events = { "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM" } },
    { key = "CHANNEL", name = "Custom Channels", events = { "CHAT_MSG_CHANNEL" } },
    { key = "BN_WHISPER", name = "Battle.net Whisper", events = { "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM" } },
}
DS.CHAT_CHANNEL_OPTIONS = CHAT_CHANNEL_OPTIONS

local EVENT_TO_CHANNEL_OPTION = {}
for _, option in ipairs(CHAT_CHANNEL_OPTIONS) do
    for _, eventName in ipairs(option.events) do
        EVENT_TO_CHANNEL_OPTION[eventName] = option.key
    end
end

function IsChatChannelEnabled(eventName)
    local key = EVENT_TO_CHANNEL_OPTION[eventName]
    if not key then
        return true
    end

    if not ShimmerTimeDB or not ShimmerTimeDB.enabledChatChannels or ShimmerTimeDB.enabledChatChannels[key] == nil then
        return true
    end

    return ShimmerTimeDB.enabledChatChannels[key] == true
end
DS.IsChatChannelEnabled = IsChatChannelEnabled

function SaveChatChannelEnabled(option, enabled)
    ShimmerTimeDB.enabledChatChannels = ShimmerTimeDB.enabledChatChannels or {}
    ShimmerTimeDB.enabledChatChannels[option.key] = enabled == true
end

local function InsertTextIntoChat(text)
    local editBox = ChatEdit_GetActiveWindow()
    if not editBox then
        editBox = ChatEdit_ChooseBoxForSend()
        ChatEdit_ActivateChat(editBox)
    end
    editBox:Insert(text)
end

local measureString
local function GetStringWidth(text, fontObject)
    if not measureString then
        measureString = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    end
    measureString:SetFontObject(fontObject or "GameFontNormalLarge")
    measureString:SetText(text or "")
    return measureString:GetStringWidth()
end

local function StyleMenuFrame(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    frame:SetBackdropColor(unpack(DS.THEME.bg))
    frame:SetBackdropBorderColor(unpack(DS.THEME.border))
end

local function CreateShimmerHighlight(parent)
    local highlight = parent:CreateTexture(nil, "BACKGROUND")
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(unpack(DS.THEME.highlight))
    highlight:SetAllPoints()
    highlight:Hide()

    return highlight
end


local function GetEnabledMenuCategories()
    local menuCategories = {}
    local parentMap = {}

    for _, category in ipairs(GetEnabledCategories()) do
        if category.menuParent then
            local parent = parentMap[category.menuParent]
            if not parent then
                parent = { name = category.menuParent, children = {} }
                parentMap[category.menuParent] = parent
                table.insert(menuCategories, parent)
            end
            table.insert(parent.children, category)
        else
            table.insert(menuCategories, category)
        end
    end

    return menuCategories
end

local function GetMenuEmotes(category)
    if not category.children then
        return category.emotes or {}
    end

    local emotes = {}
    for _, child in ipairs(category.children) do
        for _, emote in ipairs(child.emotes or {}) do
            table.insert(emotes, {
                key = emote.key,
                displayKey = (child.menuName or child.name) .. " - " .. emote.key,
                texture = emote.texture,
                sound = emote.sound,
                frames = emote.frames,
                frameDuration = emote.frameDuration,
                loops = emote.loops,
            })
        end
    end
    return emotes
end

local function CreateEmoteMenu()
    local clickCatcher = CreateFrame("Button", "ShimmerTimeMenuClickCatcher", UIParent)
    DS.menuClickCatcher = clickCatcher
    clickCatcher:SetAllPoints(UIParent)
    clickCatcher:SetFrameStrata("DIALOG")
    clickCatcher:SetFrameLevel(1)
    clickCatcher:EnableMouse(true)
    clickCatcher:RegisterForClicks("AnyUp")
    clickCatcher:Hide()

    local main = CreateFrame("Frame", "ShimmerTimeCategoryMenu", UIParent, "BackdropTemplate")
    DS.categoryMenu = main
    main:SetFrameStrata("DIALOG")
    main:SetFrameLevel(20)
    main:SetClampedToScreen(true)
    main:EnableMouse(true)
    StyleMenuFrame(main)
    main:Hide()

    local submenu = CreateFrame("Frame", "ShimmerTimeEmoteMenu", UIParent, "BackdropTemplate")
    DS.emoteMenu = submenu
    submenu:SetFrameStrata("DIALOG")
    submenu:SetFrameLevel(21)
    submenu:SetClampedToScreen(true)
    submenu:EnableMouse(true)
    StyleMenuFrame(submenu)
    submenu:Hide()

    local nestedSubmenu = CreateFrame("Frame", "ShimmerTimeNestedEmoteMenu", UIParent, "BackdropTemplate")
    DS.nestedEmoteMenu = nestedSubmenu
    nestedSubmenu:SetFrameStrata("DIALOG")
    nestedSubmenu:SetFrameLevel(22)
    nestedSubmenu:SetClampedToScreen(true)
    nestedSubmenu:EnableMouse(true)
    StyleMenuFrame(nestedSubmenu)
    nestedSubmenu:Hide()

    local function CloseMenus()
        main:Hide()
        submenu:Hide()
        nestedSubmenu:Hide()
        clickCatcher:Hide()
    end

    clickCatcher:SetScript("OnClick", CloseMenus)
    DS.CloseMenus = CloseMenus

    local closeTimer
    local function CancelClose()
        if closeTimer then
            closeTimer:Cancel()
            closeTimer = nil
        end
    end

    local function DelayedSubmenuClose()
        CancelClose()
        closeTimer = C_Timer.NewTimer(0.25, function()
            if not main:IsMouseOver() and not submenu:IsMouseOver() and not nestedSubmenu:IsMouseOver() then
                submenu:Hide()
                nestedSubmenu:Hide()
            end
        end)
    end

    main:SetScript("OnEnter", CancelClose)
    submenu:SetScript("OnEnter", CancelClose)
    nestedSubmenu:SetScript("OnEnter", CancelClose)
    main:SetScript("OnLeave", DelayedSubmenuClose)
    submenu:SetScript("OnLeave", DelayedSubmenuClose)
    nestedSubmenu:SetScript("OnLeave", DelayedSubmenuClose)

    local categoryButtons = {}
    local childCategoryButtons = {}
    local emoteButtons = {}
    local nestedEmoteButtons = {}

    local function PositionMenuFrame(frame, anchorButton)
        frame:ClearAllPoints()
        local screenWidth = UIParent:GetWidth()
        local rightEdge = (anchorButton:GetRight() or 0) + frame:GetWidth() + 8
        if rightEdge > screenWidth then
            frame:SetPoint("TOPRIGHT", anchorButton, "TOPLEFT", -2, 0)
        else
            frame:SetPoint("TOPLEFT", anchorButton, "TOPRIGHT", 2, 0)
        end
    end

    local function ShowEmoteList(category, categoryButton, menuFrame, buttonPool)
        CancelClose()

        -- The middle submenu frame is reused for either a child-category list
        -- or a direct emote list. Hide the other row pool first so old
        -- child rows do not show behind the current emote list.
        if menuFrame == submenu then
            for _, button in ipairs(childCategoryButtons) do
                button:Hide()
            end
        end

        for _, button in ipairs(buttonPool) do
            button:Hide()
        end

        local menuEmotes = category.emotes or {}
        local longest = 0
        for _, emote in ipairs(menuEmotes) do
            longest = math.max(longest, GetStringWidth(emote.displayKey or emote.key, "GameFontNormalLarge"))
        end

        local rowHeight = 28
        local iconSize = 24
        local menuWidth = math.max(116, math.ceil(longest + iconSize + 38))
        local menuHeight = (#menuEmotes * rowHeight) + 10
        menuFrame:SetSize(menuWidth, menuHeight)

        for index, emote in ipairs(menuEmotes) do
            local row = buttonPool[index]
            if not row then
                row = CreateFrame("Button", nil, menuFrame)
                row:SetHeight(rowHeight)
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(iconSize, iconSize)
                row.icon:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetTextColor(unpack(DS.THEME.text))
                row.highlight = CreateShimmerHighlight(row)
                row:SetScript("OnEnter", function(self)
                    CancelClose()
                    self.highlight:Show()
                end)
                row:SetScript("OnLeave", function(self)
                    self.highlight:Hide()
                    DelayedSubmenuClose()
                end)
                buttonPool[index] = row
            end

            row:SetParent(menuFrame)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 5, -5 - ((index - 1) * rowHeight))
            row:SetPoint("RIGHT", menuFrame, "RIGHT", -5, 0)
            row.icon:SetTexture(GetEmoteTexture(emote))
            row.text:SetText(emote.displayKey or emote.key)
            row.text:SetTextColor(unpack(DS.THEME.text))
            row:SetScript("OnClick", function()
                InsertTextIntoChat(emote.key)
                CloseMenus()
            end)
            row:Show()
        end

        PositionMenuFrame(menuFrame, categoryButton)
        menuFrame:Show()
    end

    local function ShowChildCategoryMenu(parentCategory, categoryButton)
        CancelClose()
        nestedSubmenu:Hide()

        -- The middle submenu frame is reused for direct emote rows too.
        -- Hide those rows before showing child sections.
        for _, button in ipairs(emoteButtons) do
            button:Hide()
        end

        for _, button in ipairs(childCategoryButtons) do
            button:Hide()
        end

        local children = parentCategory.children or {}
        local longest = 0
        for _, child in ipairs(children) do
            longest = math.max(longest, GetStringWidth(child.menuName or child.name, "GameFontNormalLarge"))
        end

        local rowHeight = 31
        local menuWidth = math.max(132, math.ceil(longest + 48))
        local menuHeight = (#children * rowHeight) + 10
        submenu:SetSize(menuWidth, menuHeight)

        for index, child in ipairs(children) do
            local row = childCategoryButtons[index]
            if not row then
                row = CreateFrame("Button", nil, submenu)
                row:SetHeight(rowHeight)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                row.text:SetPoint("LEFT", row, "LEFT", 12, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetTextColor(unpack(DS.THEME.text))
                row.arrow = row:CreateTexture(nil, "OVERLAY")
                row.arrow:SetSize(16, 16)
                row.arrow:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row.arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
                row.arrow:SetVertexColor(unpack(DS.THEME.subText))
                row.highlight = CreateShimmerHighlight(row)
                row:SetScript("OnLeave", function(self)
                    self.highlight:Hide()
                    DelayedSubmenuClose()
                end)
                childCategoryButtons[index] = row
            end

            row:SetParent(submenu)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", submenu, "TOPLEFT", 5, -5 - ((index - 1) * rowHeight))
            row:SetPoint("RIGHT", submenu, "RIGHT", -5, 0)
            row.text:SetText(child.menuName or child.name)
            row.text:SetTextColor(unpack(DS.THEME.text))
            row:SetScript("OnEnter", function(self)
                CancelClose()
                self.highlight:Show()
                ShowEmoteList(child, self, nestedSubmenu, nestedEmoteButtons)
            end)
            row:SetScript("OnClick", function(self)
                ShowEmoteList(child, self, nestedSubmenu, nestedEmoteButtons)
            end)
            row:Show()
        end

        PositionMenuFrame(submenu, categoryButton)
        submenu:Show()
    end

    function DS.ToggleEmoteMenu(anchor)
        if main:IsShown() then
            CloseMenus()
            return
        end

        for _, button in ipairs(categoryButtons) do
            button:Hide()
        end
        submenu:Hide()
        nestedSubmenu:Hide()

        local enabledCategories = GetEnabledMenuCategories()
        if #enabledCategories == 0 then
            print("|cffffd100ShimmerTime:|r No minimap sections are enabled. Right-click the minimap button to turn sections on.")
            return
        end

        local longest = 0
        for _, category in ipairs(enabledCategories) do
            longest = math.max(longest, GetStringWidth(category.name, "GameFontNormalLarge"))
        end

        local rowHeight = 31
        local mainWidth = math.max(132, math.ceil(longest + 48))
        local mainHeight = (#enabledCategories * rowHeight) + 10
        main:SetSize(mainWidth, mainHeight)

        for index, category in ipairs(enabledCategories) do
            local row = categoryButtons[index]
            if not row then
                row = CreateFrame("Button", nil, main)
                row:SetHeight(rowHeight)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                row.text:SetPoint("LEFT", row, "LEFT", 12, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetTextColor(unpack(DS.THEME.text))
                row.arrow = row:CreateTexture(nil, "OVERLAY")
                row.arrow:SetSize(16, 16)
                row.arrow:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row.arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
                row.arrow:SetVertexColor(unpack(DS.THEME.subText))
                row.highlight = CreateShimmerHighlight(row)
                row:SetScript("OnLeave", function(self)
                    self.highlight:Hide()
                    DelayedSubmenuClose()
                end)
                categoryButtons[index] = row
            end

            row:SetParent(main)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", main, "TOPLEFT", 5, -5 - ((index - 1) * rowHeight))
            row:SetPoint("RIGHT", main, "RIGHT", -5, 0)
            row.text:SetText(category.name)
            row.text:SetTextColor(unpack(DS.THEME.text))
            row:SetScript("OnEnter", function(self)
                CancelClose()
                self.highlight:Show()
                if category.children then
                    ShowChildCategoryMenu(category, self)
                else
                    nestedSubmenu:Hide()
                    ShowEmoteList(category, self, submenu, emoteButtons)
                end
            end)
            row:SetScript("OnClick", function(self)
                if category.children then
                    ShowChildCategoryMenu(category, self)
                else
                    nestedSubmenu:Hide()
                    ShowEmoteList(category, self, submenu, emoteButtons)
                end
            end)
            row:Show()
        end

        clickCatcher:Show()
        main:ClearAllPoints()
        local screenWidth = UIParent:GetWidth()
        local buttonRight = anchor:GetRight() or 0
        if buttonRight + mainWidth > screenWidth then
            main:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
        else
            main:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        end

        main:Show()
    end
end

local function RefreshMinimapButtonVisibility()
    if not DS.minimapButton then
        return
    end

    if ShimmerTimeDB and ShimmerTimeDB.showMinimapButton == false then
        DS.minimapButton:Hide()
    else
        DS.minimapButton:Show()
        if DS.UpdateMinimapButtonPosition then
            DS.UpdateMinimapButtonPosition()
        end
    end
end
DS.RefreshMinimapButtonVisibility = RefreshMinimapButtonVisibility

local function CreateMinimapButton()
    local button = CreateFrame("Button", "ShimmerTimeMinimapButton", Minimap)
    DS.minimapButton = button

    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(9)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:EnableMouse(true)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\ShimmerTime\\Emotes\\icon.tga")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 1, 0)
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(icon)

    local minimapShapes = {
        ["ROUND"] = {true, true, true, true},
        ["SQUARE"] = {false, false, false, false},
        ["CORNER-TOPLEFT"] = {false, false, false, true},
        ["CORNER-TOPRIGHT"] = {false, false, true, false},
        ["CORNER-BOTTOMLEFT"] = {false, true, false, false},
        ["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
        ["SIDE-LEFT"] = {false, true, false, true},
        ["SIDE-RIGHT"] = {true, false, true, false},
        ["SIDE-TOP"] = {false, false, true, true},
        ["SIDE-BOTTOM"] = {true, true, false, false},
        ["TRICORNER-TOPLEFT"] = {false, true, true, true},
        ["TRICORNER-TOPRIGHT"] = {true, false, true, true},
        ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
        ["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
    }

    local function UpdatePosition()
        local angle = math.rad(ShimmerTimeDB.minimapAngle or 225)
        local x = math.cos(angle)
        local y = math.sin(angle)
        local q = 1
        if x < 0 then q = q + 1 end
        if y > 0 then q = q + 2 end

        local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
        local quadTable = minimapShapes[minimapShape] or minimapShapes["ROUND"]
        local radiusOffset = 5
        local w = ((Minimap:GetWidth() or 140) / 2) + radiusOffset
        local h = ((Minimap:GetHeight() or Minimap:GetWidth() or 140) / 2) + radiusOffset

        if quadTable[q] then
            x = x * w
            y = y * h
        else
            local diagRadiusW = math.sqrt(2 * (w ^ 2)) - 10
            local diagRadiusH = math.sqrt(2 * (h ^ 2)) - 10
            x = math.max(-w, math.min(x * diagRadiusW, w))
            y = math.max(-h, math.min(y * diagRadiusH, h))
        end

        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    local function UpdateFromCursor()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()

        px = px / scale
        py = py / scale

        ShimmerTimeDB.minimapAngle = math.deg(math.atan2(py - my, px - mx)) % 360
        UpdatePosition()
    end

    DS.UpdateMinimapButtonPosition = UpdatePosition
    UpdatePosition()

    Minimap:HookScript("OnSizeChanged", function()
        UpdatePosition()
    end)

    button:SetScript("OnDragStart", function(self)
        if DS.CloseMenus then
            DS.CloseMenus()
        end

        UpdateFromCursor()
        self:SetScript("OnUpdate", UpdateFromCursor)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateFromCursor()
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            if DS.OpenOptions then
                DS.OpenOptions()
            end
        else
            if DS.ToggleEmoteMenu then
                DS.ToggleEmoteMenu(self)
            end
        end
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("ShimmerTime", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open emote menu", 1, 1, 1)
        GameTooltip:AddLine("Right-click: options", 1, 1, 1)
        GameTooltip:Show()
    end)

    RefreshMinimapButtonVisibility()
end

local function CreateSmallButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 88, height or 22)
    button:SetText(text)
    return button
end

local function CreateOptions()
    local panel = CreateFrame("Frame", "ShimmerTimeOptionsPanel")
    DS.optionsPanel = panel

    local scrollFrame = CreateFrame("ScrollFrame", "ShimmerTimeOptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 4)

    local content = CreateFrame("Frame", "ShimmerTimeOptionsScrollContent", scrollFrame)
    content:SetSize(960, 1650)
    scrollFrame:SetScrollChild(content)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local scrollbar = _G[self:GetName() .. "ScrollBar"]
        if not scrollbar then
            return
        end

        local minValue, maxValue = scrollbar:GetMinMaxValues()
        local currentValue = scrollbar:GetValue()
        local pageStep = math.max(40, self:GetHeight() / 5)
        local nextValue = currentValue - (delta * pageStep)

        if nextValue < minValue then
            nextValue = minValue
        elseif nextValue > maxValue then
            nextValue = maxValue
        end

        scrollbar:SetValue(nextValue)
        self:SetVerticalScroll(nextValue)
    end)

    local bannerLeftOffsetX = 16

    local shimmerBanner = content:CreateTexture(nil, "ARTWORK")
    shimmerBanner:SetTexture(DS.SHIMMER_BANNER_TEXTURE)
    shimmerBanner:SetSize(512, 128)
    shimmerBanner:SetPoint("TOPLEFT", content, "TOPLEFT", bannerLeftOffsetX, -8)
    shimmerBanner:SetTexCoord(0, 1, 0, 1)

    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOP", shimmerBanner, "BOTTOM", 0, -6)
    desc:SetText("Shimmer inspired emotes")

    local useEverythingButton = CreateSmallButton(content, "Use Everything", 112, 22)
    useEverythingButton:SetPoint("TOPLEFT", content, "TOPLEFT", bannerLeftOffsetX, -166)

    local resetDefaultsButton = CreateSmallButton(content, "Reset to Default", 112, 22)
    resetDefaultsButton:SetPoint("LEFT", useEverythingButton, "RIGHT", 12, 0)

    local minimapButtonCheckbox = CreateFrame("CheckButton", "ShimmerTimeMinimapButtonCheckbox", content, "InterfaceOptionsCheckButtonTemplate")
    minimapButtonCheckbox:SetPoint("TOPLEFT", useEverythingButton, "BOTTOMLEFT", 0, -18)
    minimapButtonCheckbox.Text:SetText("Show minimap button")
    minimapButtonCheckbox.Text:SetTextColor(1, 0.82, 0)
    minimapButtonCheckbox.tooltipText = "Show the ShimmerTime button on the minimap."
    minimapButtonCheckbox:SetChecked(ShimmerTimeDB.showMinimapButton ~= false)
    minimapButtonCheckbox:SetScript("OnClick", function(self)
        ShimmerTimeDB.showMinimapButton = self:GetChecked() == true
        if DS.RefreshMinimapButtonVisibility then
            DS.RefreshMinimapButtonVisibility()
        end
    end)

    local slider = CreateFrame("Slider", "ShimmerTimeSizeSlider", content, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", minimapButtonCheckbox, "RIGHT", 150, 0)
    slider:SetMinMaxValues(16, 64)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(ShimmerTimeDB.emoteSize or DS.DEFAULT_EMOTE_SIZE)

    _G[slider:GetName() .. "Low"]:SetText("16")
    _G[slider:GetName() .. "High"]:SetText("64")
    _G[slider:GetName() .. "Text"]:SetText("Chat Emote Size: " .. (ShimmerTimeDB.emoteSize or DS.DEFAULT_EMOTE_SIZE))

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        ShimmerTimeDB.emoteSize = value
        _G[self:GetName() .. "Text"]:SetText("Chat Emote Size: " .. value)
    end)

    local optionColumns = 3
    local sectionColumnWidth = 190
    local optionRowHeight = 30
    local sectionCheckBoxes = {}

    local channelsTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    channelsTitle:SetPoint("TOPLEFT", minimapButtonCheckbox, "BOTTOMLEFT", 0, -34)
    channelsTitle:SetText("Chat Channels")

    local channelDescription = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    channelDescription:SetPoint("TOPLEFT", channelsTitle, "BOTTOMLEFT", 0, -4)
    channelDescription:SetText("Choose where typed emote words should turn into images.")
    channelDescription:SetJustifyH("LEFT")

    local channelCheckBoxes = {}

    local toggleChannelSelection = CreateSmallButton(content, "Toggle All", 84, 22)
    toggleChannelSelection:SetPoint("LEFT", channelsTitle, "RIGHT", 14, 0)

    local channelColumnWidth = 190
    for index, option in ipairs(CHAT_CHANNEL_OPTIONS) do
        local checkbox = CreateFrame("CheckButton", "ShimmerTimeChannelCheckbox" .. index, content, "InterfaceOptionsCheckButtonTemplate")
        local column = (index - 1) % optionColumns
        local row = math.floor((index - 1) / optionColumns)
        checkbox:SetPoint("TOPLEFT", channelDescription, "BOTTOMLEFT", column * channelColumnWidth, -10 - (row * optionRowHeight))
        checkbox.Text:SetText(option.name)
        checkbox.Text:SetTextColor(1, 0.82, 0)
        checkbox.tooltipText = "Enable ShimmerTime emotes in " .. option.name .. " chat."
        checkbox:SetChecked(IsChatChannelEnabled(option.events[1]))
        checkbox:SetScript("OnClick", function(self)
            SaveChatChannelEnabled(option, self:GetChecked())
        end)
        channelCheckBoxes[index] = { checkbox = checkbox, option = option }
    end

    toggleChannelSelection:SetScript("OnClick", function()
        local allSelected = true
        for _, item in ipairs(channelCheckBoxes) do
            if not item.checkbox:GetChecked() then
                allSelected = false
                break
            end
        end

        for _, item in ipairs(channelCheckBoxes) do
            local selected = not allSelected
            item.checkbox:SetChecked(selected)
            SaveChatChannelEnabled(item.option, selected)
        end
    end)

    local channelRows = math.max(1, math.ceil(#CHAT_CHANNEL_OPTIONS / optionColumns))

    local miscTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    miscTitle:SetPoint("TOPLEFT", channelDescription, "BOTTOMLEFT", 0, -10 - (channelRows * optionRowHeight) - 18)
    miscTitle:SetText("Misc")

    local miscColumnWidth = 220
    local miscOptions = {
        {
            name = "Emotes above chat bubbles",
            getChecked = IsBubbleEmotesEnabled,
            onClick = function(self)
                ShimmerTimeDB.showEmotesInBubbles = self:GetChecked() == true
            end,
            frameName = "ShimmerTimeBubbleCheckbox",
        },
        {
            name = "GIFs above chat bubbles",
            getChecked = function()
                return ShimmerTimeDB.showGifsInBubbles == true
            end,
            onClick = function(self)
                ShimmerTimeDB.showGifsInBubbles = self:GetChecked() == true
            end,
            frameName = "ShimmerTimeGifBubbleCheckbox",
        },
        {
            name = "Play emote sounds",
            getChecked = function()
                return ShimmerTimeDB.playEmoteSounds == true
            end,
            onClick = function(self)
                ShimmerTimeDB.playEmoteSounds = self:GetChecked() == true
            end,
            frameName = "ShimmerTimeSoundCheckbox",
        },
        {
            name = "Slash Commands",
            getChecked = function()
                return ShimmerTimeDB.enableSlashCommands == true
            end,
            onClick = function(self)
                ShimmerTimeDB.enableSlashCommands = self:GetChecked() == true
            end,
            frameName = "ShimmerTimeSlashCommandsCheckbox",
        },
    }

    local miscCheckBoxes = {}
    local miscToggleSelection = CreateSmallButton(content, "Toggle All", 84, 22)
    miscToggleSelection:SetPoint("LEFT", miscTitle, "RIGHT", 14, 0)

    for index, option in ipairs(miscOptions) do
        local checkbox = CreateFrame("CheckButton", option.frameName, content, "InterfaceOptionsCheckButtonTemplate")
        local column = (index - 1) % optionColumns
        local row = math.floor((index - 1) / optionColumns)
        checkbox:SetPoint("TOPLEFT", miscTitle, "BOTTOMLEFT", column * miscColumnWidth, -8 - (row * optionRowHeight))
        checkbox.Text:SetText(option.name)
        checkbox.Text:SetTextColor(1, 0.82, 0)
        checkbox:SetChecked(option.getChecked())
        checkbox:SetScript("OnClick", option.onClick)
        table.insert(miscCheckBoxes, checkbox)
    end

    local miscRows = math.max(1, math.ceil(#miscOptions / optionColumns))


    local function BuildSectionGroup(titleText, anchor, offsetY, groupName)
        local groupTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        groupTitle:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offsetY)
        groupTitle:SetText(titleText)

        local toggleButton = CreateSmallButton(content, "Toggle All", 84, 22)
        toggleButton:SetPoint("LEFT", groupTitle, "RIGHT", 14, 0)

        local groupItems = {}
        for _, category in ipairs(DS.CATEGORIES) do
            if (category.sectionGroup or "Shimmer Sections") == groupName then
                table.insert(groupItems, category)
            end
        end

        for index, category in ipairs(groupItems) do
            local checkbox = CreateFrame("CheckButton", "ShimmerTimeSectionCheckbox" .. groupName:gsub("%W", "") .. index, content, "InterfaceOptionsCheckButtonTemplate")
            local column = (index - 1) % optionColumns
            local row = math.floor((index - 1) / optionColumns)
            checkbox:SetPoint("TOPLEFT", groupTitle, "BOTTOMLEFT", column * sectionColumnWidth, -8 - (row * optionRowHeight))
            checkbox.Text:SetText(category.optionName or category.name)
            checkbox.Text:SetTextColor(1, 0.82, 0)
            checkbox.tooltipText = "Show " .. (category.optionName or category.name) .. " in the minimap dropdown and enable its chat image triggers."
            checkbox:SetChecked(IsCategoryEnabled(category))
            checkbox:SetScript("OnClick", function(self)
                SaveCategoryEnabled(category, self:GetChecked())
                if DS.CloseMenus then DS.CloseMenus() end
            end)
            table.insert(sectionCheckBoxes, { checkbox = checkbox, category = category })
        end

        toggleButton:SetScript("OnClick", function()
            local allSelected = true
            for _, item in ipairs(sectionCheckBoxes) do
                if (item.category.sectionGroup or "Shimmer Sections") == groupName and not item.checkbox:GetChecked() then
                    allSelected = false
                    break
                end
            end
            for _, item in ipairs(sectionCheckBoxes) do
                if (item.category.sectionGroup or "Shimmer Sections") == groupName then
                    local selected = not allSelected
                    item.checkbox:SetChecked(selected)
                    SaveCategoryEnabled(item.category, selected)
                end
            end
            if DS.CloseMenus then DS.CloseMenus() end
        end)

        local rows = math.max(1, math.ceil(#groupItems / optionColumns))
        return groupTitle, rows
    end

    local shimmerTitle, shimmerRows = BuildSectionGroup("Shimmer Sections", miscTitle, -8 - (miscRows * optionRowHeight) - 28, "Shimmer Sections")

    local dimmerBanner = content:CreateTexture(nil, "ARTWORK")
    dimmerBanner:SetTexture(DS.DIMMER_BANNER_TEXTURE)
    dimmerBanner:SetSize(512, 128)
    dimmerBanner:SetPoint("TOPLEFT", shimmerTitle, "BOTTOMLEFT", 0, -8 - (shimmerRows * optionRowHeight) - 18)
    dimmerBanner:SetTexCoord(0, 1, 0, 1)

    local dimmerDesc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    dimmerDesc:SetPoint("TOP", dimmerBanner, "BOTTOM", 0, 0)
    dimmerDesc:SetText("Dimmer inspired emotes")

    local dimmerTitle, dimmerRows = BuildSectionGroup("Dimmer Sections", dimmerBanner, -18, "Dimmer Sections")
    local nsfwTitle, nsfwRows = BuildSectionGroup("Dimmer NSFW Sections", dimmerTitle, -8 - (dimmerRows * optionRowHeight) - 18, "Dimmer NSFW Sections")

    local function ApplyOptionDefaults()
        minimapButtonCheckbox:SetChecked(ShimmerTimeDB.showMinimapButton ~= false)
        slider:SetValue(ShimmerTimeDB.emoteSize or DS.DEFAULT_EMOTE_SIZE)
        _G[slider:GetName() .. "Text"]:SetText("Chat Emote Size: " .. (ShimmerTimeDB.emoteSize or DS.DEFAULT_EMOTE_SIZE))

        for _, item in ipairs(sectionCheckBoxes) do
            item.checkbox:SetChecked(IsCategoryEnabled(item.category))
        end

        for _, item in ipairs(channelCheckBoxes) do
            item.checkbox:SetChecked(IsChatChannelEnabled(item.option.events[1]))
        end

        for index, checkbox in ipairs(miscCheckBoxes) do
            checkbox:SetChecked(miscOptions[index].getChecked())
        end
    end

    local function RefreshAfterBulkOptionChange()
        ApplyOptionDefaults()
        if DS.UpdateMinimapButtonPosition then
            DS.UpdateMinimapButtonPosition()
        end
        if DS.RefreshMinimapButtonVisibility then
            DS.RefreshMinimapButtonVisibility()
        end
        if DS.CloseMenus then
            DS.CloseMenus()
        end
    end

    useEverythingButton:SetScript("OnClick", function()
        ShimmerTimeDB.showMinimapButton = true
        ShimmerTimeDB.showEmotesInBubbles = true
        ShimmerTimeDB.showGifsInBubbles = true
        ShimmerTimeDB.playEmoteSounds = true
        ShimmerTimeDB.enableSlashCommands = true
        ShimmerTimeDB.enabledSections = ShimmerTimeDB.enabledSections or {}
        for _, category in ipairs(DS.CATEGORIES) do
            ShimmerTimeDB.enabledSections[GetCategoryKey(category)] = true
        end
        ShimmerTimeDB.enabledChatChannels = ShimmerTimeDB.enabledChatChannels or {}
        for _, option in ipairs(CHAT_CHANNEL_OPTIONS) do
            ShimmerTimeDB.enabledChatChannels[option.key] = true
        end

        RefreshAfterBulkOptionChange()
    end)

    resetDefaultsButton:SetScript("OnClick", function()
        ShimmerTimeDB.emoteSize = DS.DEFAULT_EMOTE_SIZE
        ShimmerTimeDB.minimapAngle = 225
        ShimmerTimeDB.showMinimapButton = true
        ShimmerTimeDB.showEmotesInBubbles = false
        ShimmerTimeDB.showGifsInBubbles = false
        ShimmerTimeDB.playEmoteSounds = false
        ShimmerTimeDB.enableSlashCommands = false
        ShimmerTimeDB.enabledSections = {}
        for _, category in ipairs(DS.CATEGORIES) do
            ShimmerTimeDB.enabledSections[GetCategoryKey(category)] = category.enabledByDefault == true
        end
        ShimmerTimeDB.enabledChatChannels = {}
        for _, option in ipairs(CHAT_CHANNEL_OPTIONS) do
            ShimmerTimeDB.enabledChatChannels[option.key] = true
        end

        RefreshAfterBulkOptionChange()
    end)

    miscToggleSelection:SetScript("OnClick", function()
        local allSelected = true
        for _, checkbox in ipairs(miscCheckBoxes) do
            if not checkbox:GetChecked() then
                allSelected = false
                break
            end
        end

        for _, checkbox in ipairs(miscCheckBoxes) do
            local selected = not allSelected
            checkbox:SetChecked(selected)
            checkbox:GetScript("OnClick")(checkbox)
        end
    end)


    content:SetHeight(980)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ShimmerTime")
        Settings.RegisterAddOnCategory(category)
        DS.optionsCategoryId = category:GetID()
    else
        panel.name = "ShimmerTime"
        InterfaceOptions_AddCategory(panel)
    end
end

function DS.OpenOptions()
    if Settings and DS.optionsCategoryId then
        Settings.OpenToCategory(DS.optionsCategoryId)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(DS.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(DS.optionsPanel)
    end
end


-- Slash command handling is now implemented in SlashCommands.lua.

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    ShimmerTimeDB = ShimmerTimeDB or ShimmerDB or {}

    if not ShimmerTimeDB.emoteSize then
        ShimmerTimeDB.emoteSize = DS.DEFAULT_EMOTE_SIZE
    end

    if not ShimmerTimeDB.minimapAngle then
        ShimmerTimeDB.minimapAngle = 225
    end

    ShimmerTimeDB.enabledSections = ShimmerTimeDB.enabledSections or {}
    for _, category in ipairs(DS.CATEGORIES) do
        local key = GetCategoryKey(category)
        if ShimmerTimeDB.enabledSections[key] == nil then
            ShimmerTimeDB.enabledSections[key] = category.enabledByDefault == true
        end
    end

    ShimmerTimeDB.enabledChatChannels = ShimmerTimeDB.enabledChatChannels or {}
    for _, option in ipairs(CHAT_CHANNEL_OPTIONS) do
        if ShimmerTimeDB.enabledChatChannels[option.key] == nil then
            ShimmerTimeDB.enabledChatChannels[option.key] = true
        end
    end

    if ShimmerTimeDB.showMinimapButton == nil then
        ShimmerTimeDB.showMinimapButton = true
    end

    if ShimmerTimeDB.showEmotesInBubbles == nil then
        ShimmerTimeDB.showEmotesInBubbles = false
    end

    if ShimmerTimeDB.showGifsInBubbles == nil then
        ShimmerTimeDB.showGifsInBubbles = false
    end

    if ShimmerTimeDB.playEmoteSounds == nil then
        ShimmerTimeDB.playEmoteSounds = false
    end

    if ShimmerTimeDB.enableSlashCommands == nil then
        ShimmerTimeDB.enableSlashCommands = false
    end

    for _, eventName in ipairs(CHAT_EVENTS) do
        ChatFrame_AddMessageEventFilter(eventName, ChatFilter)
    end

    CreateEmoteMenu()
    PreloadAnimatedEmoteTextures()
    CreateOptions()
    CreateMinimapButton()
    if DS.RegisterSlashCommands then
        DS.RegisterSlashCommands()
    end
end)


-- ShimmerTime Pascal static emote registration
-- Pascal is now a normal static emote in the Shimmer section. GIF/world-bubble support has been removed.
local function ShimmerTime_RegisterPascalStaticEmote()
    local pascalPath = "Interface\\AddOns\\ShimmerTime\\Media\\pascal.tga"

    if ShimmerTimeEmotes then
        ShimmerTimeEmotes["Shimmer"] = ShimmerTimeEmotes["Shimmer"] or {}
        ShimmerTimeEmotes["Shimmer"]["pascal"] = pascalPath
    end

    if ShimmerTimeSections then
        ShimmerTimeSections["Shimmer"] = true
    end

    if ShimmerTimeDB and ShimmerTimeDB.enabledSections and ShimmerTimeDB.enabledSections["Shimmer"] == nil then
        ShimmerTimeDB.enabledSections["Shimmer"] = true
    end

    -- Make sure old bubble behavior stays off.
    if ShimmerTimeDB then
        ShimmerTimeDB.showEmotesInChatBubbles = false
    end
end

local shimmerPascalStaticFrame = CreateFrame("Frame")
shimmerPascalStaticFrame:RegisterEvent("ADDON_LOADED")
shimmerPascalStaticFrame:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon == "ShimmerTime" then
        ShimmerTime_RegisterPascalStaticEmote()
    end
end)
