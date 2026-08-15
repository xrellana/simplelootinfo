local ADDON_NAME = "Simple Loot Info"
local DEBUG = false
local registered = false
local settings

local DEFAULTS = {
    enabled = true,
    showType = true,
    showSlot = true,
    showItemLevel = true,
    showSecondary = true,
    showTertiary = true,
    showIcon = false,
    enhanceLoot = true,
    enhanceChat = true,
}

local SECONDARY_STATS = {
    { key = "ITEM_MOD_CRIT_RATING_SHORT", fallbackName = "Critical Strike" },
    { key = "ITEM_MOD_HASTE_RATING_SHORT", fallbackName = "Haste" },
    { key = "ITEM_MOD_MASTERY_RATING_SHORT", fallbackName = "Mastery" },
    { key = "ITEM_MOD_VERSATILITY", fallbackName = "Versatility" },
}

local TERTIARY_STATS = {
    { key = "ITEM_MOD_CR_LIFESTEAL_SHORT", fallbackName = "Leech" },
    { key = "ITEM_MOD_CR_AVOIDANCE_SHORT", fallbackName = "Avoidance" },
    { key = "ITEM_MOD_CR_SPEED_SHORT", fallbackName = "Speed" },
    { key = "ITEM_MOD_CR_STURDINESS_SHORT", fallbackName = "Indestructible", hideValue = true },
}

local TERTIARY_COLOR = "|cffffd100"

local function PrintMessage(message)
    print("|cff00ff00" .. ADDON_NAME .. ":|r " .. message)
end

local function DebugPrint(...)
    if DEBUG then
        print("|cff00ff00" .. ADDON_NAME .. " Debug:|r", ...)
    end
end

local function InitializeSettings(reset)
    if reset or type(SimpleLootInfoDB) ~= "table" then
        SimpleLootInfoDB = {}
    end

    for key, value in pairs(DEFAULTS) do
        if SimpleLootInfoDB[key] == nil then
            SimpleLootInfoDB[key] = value
        end
    end

    settings = SimpleLootInfoDB
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

local function GetItemStats(itemLink, itemID)
    if not C_Item or not C_Item.GetItemStats then
        return nil
    end

    local itemStats = C_Item.GetItemStats(itemLink)

    if not itemStats then
        if C_Item.RequestLoadItemDataByID and itemID then
            C_Item.RequestLoadItemDataByID(itemID)
        end

        return nil
    end

    return itemStats
end

local function GetStatText(itemStats, statDefinitions)
    if not itemStats then
        return nil
    end

    local matchingStats = {}

    for index, statInfo in ipairs(statDefinitions) do
        local value = itemStats[statInfo.key]

        if type(value) == "number" and value > 0 then
            table.insert(matchingStats, {
                hideValue = statInfo.hideValue,
                name = _G[statInfo.key] or statInfo.fallbackName,
                order = index,
                value = value,
            })
        end
    end

    table.sort(matchingStats, function(left, right)
        if left.value == right.value then
            return left.order < right.order
        end

        return left.value > right.value
    end)

    local parts = {}

    for _, statInfo in ipairs(matchingStats) do
        if statInfo.hideValue then
            table.insert(parts, statInfo.name)
        else
            table.insert(parts, statInfo.name .. " " .. tostring(statInfo.value))
        end
    end

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, "/")
end

local function BuildEnhancedItemLink(itemLink)
    if not itemLink or not settings or not settings.enabled then
        return itemLink
    end

    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID =
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
    local itemStats
    local secondaryStatText
    local tertiaryStatText
    local details = {}

    if settings.showSecondary or settings.showTertiary then
        itemStats = GetItemStats(itemLink, itemID)
    end

    if settings.showSecondary then
        secondaryStatText = GetStatText(itemStats, SECONDARY_STATS)
    end

    if settings.showTertiary then
        tertiaryStatText = GetStatText(itemStats, TERTIARY_STATS)
    end

    if settings.showType and typeName then
        table.insert(details, typeName)
    end

    if settings.showSlot and slotName then
        table.insert(details, slotName)
    end

    if settings.showItemLevel and itemLevel then
        table.insert(details, tostring(itemLevel))
    end

    DebugPrint("Enhanced item:", itemID, typeName or "nil", slotName or "nil", itemLevel or "nil")

    local enhancedLink = itemLink

    if #details > 0 then
        enhancedLink = table.concat(details, "/") .. ": " .. enhancedLink
    end

    if settings.showIcon and icon then
        enhancedLink = string.format("|T%s:14:14:0:0|t %s", icon, enhancedLink)
    end

    if secondaryStatText then
        enhancedLink = enhancedLink .. " (" .. secondaryStatText .. ")"
    end

    if tertiaryStatText then
        enhancedLink = enhancedLink .. " " .. TERTIARY_COLOR .. "(" .. tertiaryStatText .. ")|r"
    end

    return enhancedLink
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

local function ShouldEnhanceEvent(event)
    if not settings or not settings.enabled then
        return false
    end

    if event == "CHAT_MSG_LOOT" then
        return settings.enhanceLoot
    end

    return settings.enhanceChat
end

local function ChatMessageFilter(self, event, message, ...)
    DebugPrint("Event:", event)

    if not ShouldEnhanceEvent(event) then
        return false, message, ...
    end

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

    DebugPrint("Chat filters registered.")
end

local function StateText(value)
    if value then
        return "|cff00ff00on|r"
    end

    return "|cffff4040off|r"
end

local function PrintStatus()
    PrintMessage("status")
    print("  Addon: " .. StateText(settings.enabled))
    print(
        "  Display: type " .. StateText(settings.showType)
            .. ", slot " .. StateText(settings.showSlot)
            .. ", item level " .. StateText(settings.showItemLevel)
            .. ", secondary stats " .. StateText(settings.showSecondary)
            .. ", tertiary stats " .. StateText(settings.showTertiary)
            .. ", icon " .. StateText(settings.showIcon)
    )
    print(
        "  Sources: loot " .. StateText(settings.enhanceLoot)
            .. ", chat " .. StateText(settings.enhanceChat)
    )
    print("  Debug: " .. StateText(DEBUG))
end

local function SetOrToggle(optionName, argument)
    if argument == "" then
        settings[optionName] = not settings[optionName]
        return true
    end

    if argument == "on" then
        settings[optionName] = true
        return true
    end

    if argument == "off" then
        settings[optionName] = false
        return true
    end

    return false
end

local function SetOrToggleDebug(argument)
    if argument == "" then
        DEBUG = not DEBUG
        return true
    end

    if argument == "on" then
        DEBUG = true
        return true
    end

    if argument == "off" then
        DEBUG = false
        return true
    end

    return false
end

local function PrintHelp()
    PrintMessage("commands")
    print("/sli on|off - Enable or disable all enhancements.")
    print("/sli type [on|off] - Toggle item type.")
    print("/sli slot [on|off] - Toggle equipment slot.")
    print("/sli ilvl [on|off] - Toggle item level.")
    print("/sli secondary [on|off] - Toggle secondary stats.")
    print("/sli tertiary [on|off] - Toggle highlighted tertiary stats.")
    print("/sli icon [on|off] - Toggle the inline item icon.")
    print("/sli loot [on|off] - Toggle enhancements in loot messages.")
    print("/sli chat [on|off] - Toggle enhancements in chat messages.")
    print("/sli status - Show the current settings.")
    print("/sli reset - Restore the defaults.")
    print("/sli debug [on|off] - Toggle debug output for this session.")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    InitializeSettings()

    -- Register slightly later to avoid being overwritten by other chat/item-link addons.
    C_Timer.After(2, RegisterChatFilters)
end)

SLASH_SIMPLELOOTINFO1 = "/sli"
SlashCmdList["SIMPLELOOTINFO"] = function(msg)
    if not settings then
        InitializeSettings()
    end

    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    local command, argument = msg:match("^(%S+)%s*(.-)$")
    command = command or ""
    argument = argument or ""

    if command == "on" or command == "enable" then
        settings.enabled = true
        PrintMessage("enabled.")
        return
    end

    if command == "off" or command == "disable" then
        settings.enabled = false
        PrintMessage("disabled.")
        return
    end

    local optionNames = {
        type = "showType",
        slot = "showSlot",
        ilvl = "showItemLevel",
        itemlevel = "showItemLevel",
        secondary = "showSecondary",
        stats = "showSecondary",
        tertiary = "showTertiary",
        icon = "showIcon",
        loot = "enhanceLoot",
        chat = "enhanceChat",
    }

    local optionName = optionNames[command]
    if optionName then
        if SetOrToggle(optionName, argument) then
            PrintMessage(command .. " is now " .. StateText(settings[optionName]) .. ".")
        else
            PrintMessage("use 'on' or 'off' after /sli " .. command .. ".")
        end
        return
    end

    if command == "debug" then
        if SetOrToggleDebug(argument) then
            PrintMessage("debug is now " .. StateText(DEBUG) .. ".")
        else
            PrintMessage("use 'on' or 'off' after /sli debug.")
        end
        return
    end

    if command == "status" then
        PrintStatus()
        return
    end

    if command == "reset" then
        InitializeSettings(true)
        PrintMessage("settings reset to defaults.")
        PrintStatus()
        return
    end

    PrintHelp()
end
