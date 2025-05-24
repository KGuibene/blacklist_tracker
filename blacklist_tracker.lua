-- Default list
local defaultNames = {
}

-- Tracked list: name (lowercase) => reason
local trackedNames = {}

-- Load names from saved variables or default
local function loadNames()
    wipe(trackedNames)
    if not BlacklistTrackerDB then BlacklistTrackerDB = {} end
    local src = next(BlacklistTrackerDB) and BlacklistTrackerDB or defaultNames
    for name, reason in pairs(src) do
        trackedNames[string.lower(name)] = reason
    end
end

-- Save to saved variables
local function saveNames()
    wipe(BlacklistTrackerDB)
    for name, reason in pairs(trackedNames) do
        BlacklistTrackerDB[name] = reason
    end
end

-- Convert to display text
local function namesToString()
    local lines = {}
    for name, reason in pairs(trackedNames) do
        table.insert(lines, name .. " - " .. reason)
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

-- Parse text input and update list
local function updateNameListFromInput(text)
    wipe(trackedNames)
    for line in string.gmatch(text or "", "[^\r\n]+") do
        local namesStr, reason = string.match(line, "^%s*(.-)%s*%-%s*(.+)$")
        if namesStr and reason then
            for name in string.gmatch(namesStr, "[^/]+") do
                local cleaned = string.lower(strtrim(name))
                if cleaned ~= "" then
                    trackedNames[cleaned] = reason
                end
            end
        end
    end
    saveNames()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Blacklist Tracker]|r Name list updated.")
end


-- Event handler
local function onEvent(self, event, msg, sender)
    if event == "CHAT_MSG_WHISPER" then
        local nameOnly = string.match(sender or "", "^[^%-]+") -- strip realm
        if nameOnly then
            local reason = trackedNames[string.lower(nameOnly)]
            if reason then
                local alertMessage = "|cffff0000[Blacklist Tracker]|r |cffffff00" .. nameOnly .. "|r is in your blacklist. Reason: " .. reason
                for i = 1, NUM_CHAT_WINDOWS do
                    local frame = _G["ChatFrame" .. i]
                    if frame then
                        frame:AddMessage(alertMessage)
                    end
                end
            end
        end
    elseif event == "ADDON_LOADED" and msg == "BlacklistTracker" then
        loadNames()
    end
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:SetScript("OnEvent", onEvent)

-- Slash command
SLASH_WHISPERCHECKER1 = "/whisperchecker"
SlashCmdList["WHISPERCHECKER"] = function()
    if BlacklistTrackerUI then
        BlacklistTrackerUI.editBox:SetText(namesToString())
        BlacklistTrackerUI:Show()
    end
end

-- UI
local function createUI()
    local f = CreateFrame("Frame", "BlacklistTrackerUI", UIParent)
    f:SetSize(340, 300)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("BlacklistTracker List")

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 180)
    scrollFrame:SetPoint("TOP", 0, -30)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(280)
    editBox:SetAutoFocus(false)
    editBox:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    scrollFrame:SetScrollChild(editBox)
    f.editBox = editBox

    -- Apply button
    local applyButton = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    applyButton:SetPoint("BOTTOM", 0, 20)
    applyButton:SetSize(140, 30)
    applyButton:SetText("Apply List")
    applyButton:SetScript("OnClick", function()
        local input = f.editBox:GetText()
        updateNameListFromInput(input)
    end)

    -- Close button
    local closeButton = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    closeButton:SetPoint("BOTTOM", applyButton, "TOP", 0, 10)
    closeButton:SetSize(140, 30)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        f:Hide()
    end)
end

createUI()

SLASH_BLT1 = "/blt"
SlashCmdList["BLT"] = function()
    if BlacklistTrackerUI:IsShown() then
        BlacklistTrackerUI:Hide()
    else
        BlacklistTrackerUI.editBox:SetText(namesToString())
        BlacklistTrackerUI:Show()
    end
end
