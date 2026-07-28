local ADDON_NAME = "Simple Loot Info"
local DEBUG = false
local registered = false

local function DebugPrint(...)
    if DEBUG then
        print("|cff00ff00Simple Loot Info Debug:|r", ...)
    end
end

local function IsValidEquipment(classID, itemEquipLoc)
    if not classID or not itemEquipLoc then
        return false
    end

    if itemEquipLoc == "" then
        return false
    end

    if itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" then
        return false
    end

    -- 2 = Weapon, 4 = Armor
    return classID == 2 or classID == 4
end

local function GetItemLevel(itemLink, itemID)
    local itemLevel

    if C_Item and C_Item.GetDetailedItemLevelInfo then
        itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    end

    if not itemLevel then
        local _, _, _, fallbackItemLevel = GetItemInfo(itemLink)
        itemLevel = fallbackItemLevel
    end

    if not itemLevel and C_Item and C_Item.RequestLoadItemDataByID and itemID then
        C_Item.RequestLoadItemDataByID(itemID)
    end

    return itemLevel
end

local function GetEquipmentSlotName(itemEquipLoc)
    if not itemEquipLoc or itemEquipLoc == "" then
        return nil
    end

    return _G[itemEquipLoc] or itemEquipLoc
end

local function BuildEnhancedItemLink(itemLink)
    if not itemLink then
        return itemLink
    end

    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID =
        C_Item.GetItemInfoInstant(itemLink)

    if not itemID then
        DebugPrint("No itemID found for link.")
        return itemLink
    end

    if not IsValidEquipment(classID, itemEquipLoc) then
        DebugPrint("Not equipment:", itemID, classID, itemEquipLoc or "nil")
        return itemLink
    end

    local slotName = GetEquipmentSlotName(itemEquipLoc)
    local typeName = itemSubType or itemType or "Equipment"
    local itemLevel = GetItemLevel(itemLink, itemID)

    DebugPrint("Enhanced item:", itemID, typeName or "nil", slotName or "nil", itemLevel or "nil")

    if itemLevel and slotName then
        return string.format("%s/%s/%s: %s", typeName, slotName, itemLevel, itemLink)
    elseif slotName then
        return string.format("%s/%s: %s", typeName, slotName, itemLink)
    elseif itemLevel then
        return string.format("%s/%s: %s", typeName, itemLevel, itemLink)
    else
        return string.format("%s: %s", typeName, itemLink)
    end
end

local function EnhanceItemLinks(message)
    if not message or not message:find("|Hitem:", 1, true) then
        return message
    end

    DebugPrint("Item link detected in message.")

    -- Normal colored item links
    local enhancedMessage, count = message:gsub("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h%[.-%]|h|r)", function(itemLink)
        return BuildEnhancedItemLink(itemLink)
    end)

    -- Fallback for uncolored item links
    if count == 0 then
        enhancedMessage, count = message:gsub("(|Hitem:.-|h%[.-%]|h)", function(itemLink)
            return BuildEnhancedItemLink(itemLink)
        end)
    end

    DebugPrint("Replacement count:", count)

    return enhancedMessage
end

local function ChatMessageFilter(self, event, message, ...)
    DebugPrint("Event:", event)

    local enhancedMessage = EnhanceItemLinks(message)

    if enhancedMessage ~= message then
        DebugPrint("Message modified.")
    end

    return false, enhancedMessage, ...
end

local chatEvents = {
    "CHAT_MSG_LOOT",

    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",

    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",

    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",

    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",

    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",

    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",

    "CHAT_MSG_CHANNEL",
}

local function RegisterChatFilters()
    if registered then
        return
    end

    registered = true

    for _, eventName in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(eventName, ChatMessageFilter)
    end

    print("|cff00ff00Simple Loot Info filters registered.|r")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    -- Register slightly later to avoid being overwritten by other chat/item-link addons.
    C_Timer.After(2, RegisterChatFilters)
end)

SLASH_SIMPLELOOTINFO1 = "/sli"
SlashCmdList["SIMPLELOOTINFO"] = function(msg)
    msg = msg and msg:lower() or ""

    if msg == "debug" then
        DEBUG = not DEBUG

        if DEBUG then
            print("|cff00ff00Simple Loot Info debug enabled.|r")
        else
            print("|cff00ff00Simple Loot Info debug disabled.|r")
        end

        return
    end

    print("|cff00ff00Simple Loot Info commands:|r")
    print("/sli debug - Toggle debug mode.")
end

print("|cff00ff00Simple Loot Info loaded.|r")