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
    showSuitability = true,
    showUpgrade = true,
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

local LOCALES = {
    enUS = {
        suitable = "Suitable",
        notCurrentSpec = "Not for Current Spec",
        cannotEquip = "Cannot Equip",
        itemLevelUnknown = "Item Level Unknown",
        sameItemLevel = "Same iLvl",
        emptySlot = "Empty Slot",
        weaponSetup = "Weapon Setup",
        itemLevelDelta = "iLvl %+d",
    },
}

local L = LOCALES[(GetLocale and GetLocale()) or "enUS"] or LOCALES.enUS

local EVALUATION_COLORS = {
    suitable = "|cff67d8ff",
    upgrade = "|cff55ff88",
    same = "|cffc7cbd1",
    downgrade = "|cffff8a65",
    empty = "|cff50e3c2",
    notCurrentSpec = "|cffffc857",
    cannotEquip = "|cffff5c5c",
    unknown = "|cffadb3bd",
}

local PRIMARY_STAT_KEYS = {
    [1] = "ITEM_MOD_STRENGTH_SHORT",
    [2] = "ITEM_MOD_AGILITY_SHORT",
    [4] = "ITEM_MOD_INTELLECT_SHORT",
}

local PREFERRED_ARMOR_SUBCLASS = {
    WARRIOR = 4,
    PALADIN = 4,
    DEATHKNIGHT = 4,
    HUNTER = 3,
    SHAMAN = 3,
    EVOKER = 3,
    ROGUE = 2,
    DRUID = 2,
    MONK = 2,
    DEMONHUNTER = 2,
    MAGE = 1,
    PRIEST = 1,
    WARLOCK = 1,
}

local ARMOR_PROFICIENCY_EQUIP_LOCS = {
    INVTYPE_HEAD = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CHEST = true,
    INVTYPE_ROBE = true,
    INVTYPE_WAIST = true,
    INVTYPE_LEGS = true,
    INVTYPE_FEET = true,
    INVTYPE_WRIST = true,
    INVTYPE_HAND = true,
}

local SLOT_IDS = {
    HEAD = INVSLOT_HEAD or 1,
    NECK = INVSLOT_NECK or 2,
    SHOULDER = INVSLOT_SHOULDER or 3,
    CHEST = INVSLOT_CHEST or 5,
    WAIST = INVSLOT_WAIST or 6,
    LEGS = INVSLOT_LEGS or 7,
    FEET = INVSLOT_FEET or 8,
    WRIST = INVSLOT_WRIST or 9,
    HAND = INVSLOT_HAND or 10,
    FINGER1 = INVSLOT_FINGER1 or 11,
    FINGER2 = INVSLOT_FINGER2 or 12,
    TRINKET1 = INVSLOT_TRINKET1 or 13,
    TRINKET2 = INVSLOT_TRINKET2 or 14,
    BACK = INVSLOT_BACK or 15,
    MAINHAND = INVSLOT_MAINHAND or 16,
    OFFHAND = INVSLOT_OFFHAND or 17,
}

local EQUIPMENT_SLOTS = {
    INVTYPE_HEAD = { SLOT_IDS.HEAD },
    INVTYPE_NECK = { SLOT_IDS.NECK },
    INVTYPE_SHOULDER = { SLOT_IDS.SHOULDER },
    INVTYPE_CHEST = { SLOT_IDS.CHEST },
    INVTYPE_ROBE = { SLOT_IDS.CHEST },
    INVTYPE_WAIST = { SLOT_IDS.WAIST },
    INVTYPE_LEGS = { SLOT_IDS.LEGS },
    INVTYPE_FEET = { SLOT_IDS.FEET },
    INVTYPE_WRIST = { SLOT_IDS.WRIST },
    INVTYPE_HAND = { SLOT_IDS.HAND },
    INVTYPE_FINGER = { SLOT_IDS.FINGER1, SLOT_IDS.FINGER2 },
    INVTYPE_TRINKET = { SLOT_IDS.TRINKET1, SLOT_IDS.TRINKET2 },
    INVTYPE_CLOAK = { SLOT_IDS.BACK },
    INVTYPE_WEAPONMAINHAND = { SLOT_IDS.MAINHAND },
    INVTYPE_2HWEAPON = { SLOT_IDS.MAINHAND },
    INVTYPE_WEAPONOFFHAND = { SLOT_IDS.OFFHAND },
    INVTYPE_SHIELD = { SLOT_IDS.OFFHAND },
    INVTYPE_HOLDABLE = { SLOT_IDS.OFFHAND },
    -- Retail ranged weapons occupy the main-hand equipment slot; slot 18 is legacy/Classic.
    INVTYPE_RANGED = { SLOT_IDS.MAINHAND },
    INVTYPE_RANGEDRIGHT = { SLOT_IDS.MAINHAND },
    INVTYPE_THROWN = { SLOT_IDS.MAINHAND },
}

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

local function ColorLabel(text, color)
    return color .. "[" .. text .. "]|r"
end

local function GetDetailedItemLevelForComparison(itemLink)
    if not C_Item or not C_Item.GetDetailedItemLevelInfo then
        return nil
    end

    local itemLevel, isPreview = C_Item.GetDetailedItemLevelInfo(itemLink)

    if isPreview or type(itemLevel) ~= "number" then
        return nil
    end

    return itemLevel
end

local function GetPlayerEquipmentContext()
    local getSpecialization = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
        or GetSpecialization
    local getSpecializationInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
        or GetSpecializationInfo

    if not UnitClass or not getSpecialization or not getSpecializationInfo then
        return nil
    end

    local _, classToken = UnitClass("player")
    local specializationIndex = getSpecialization()

    if not classToken or not specializationIndex then
        return nil
    end

    local specializationID, _, _, _, _, primaryStat = getSpecializationInfo(specializationIndex)

    if not specializationID or specializationID == 0 or not PRIMARY_STAT_KEYS[primaryStat] then
        return nil
    end

    return {
        classToken = classToken,
        specializationID = specializationID,
        primaryStat = primaryStat,
    }
end

local function MatchesPreferredArmorType(classID, subClassID, itemEquipLoc, classToken)
    if classID ~= 4 or not ARMOR_PROFICIENCY_EQUIP_LOCS[itemEquipLoc] then
        return true
    end

    -- Armor subclasses 1-4 are Cloth, Leather, Mail and Plate.
    if type(subClassID) ~= "number" or subClassID < 1 or subClassID > 4 then
        return true
    end

    local preferredSubClassID = PREFERRED_ARMOR_SUBCLASS[classToken]
    return not preferredSubClassID or subClassID == preferredSubClassID
end

local function MatchesPrimaryStat(itemStats, primaryStat)
    if not itemStats then
        return true
    end

    local hasPrimaryStat = false
    local hasMatchingPrimaryStat = false

    for statIndex, statKey in pairs(PRIMARY_STAT_KEYS) do
        local value = itemStats[statKey]

        if type(value) == "number" and value > 0 then
            hasPrimaryStat = true

            if statIndex == primaryStat then
                hasMatchingPrimaryStat = true
            end
        end
    end

    return not hasPrimaryStat or hasMatchingPrimaryStat
end

local function MatchesCurrentSpecialization(itemLink, specializationID)
    if not C_Item or not C_Item.GetItemSpecInfo then
        return true
    end

    local specializationIDs = C_Item.GetItemSpecInfo(itemLink)

    if type(specializationIDs) ~= "table" or not next(specializationIDs) then
        return true
    end

    for _, itemSpecializationID in pairs(specializationIDs) do
        if itemSpecializationID == specializationID then
            return true
        end
    end

    return false
end

local function GetEquippedItemInfo(slotID)
    if not GetInventoryItemLink then
        return nil, "unknown"
    end

    local equippedLink = GetInventoryItemLink("player", slotID)

    if not equippedLink then
        if GetInventoryItemID and GetInventoryItemID("player", slotID) then
            return nil, "unknown"
        end

        return nil, "empty"
    end

    local itemLevel = GetDetailedItemLevelForComparison(equippedLink)

    if not itemLevel then
        return nil, "unknown"
    end

    return itemLevel, "equipped"
end

local function GetEquippedItemEquipLoc(slotID)
    if not GetInventoryItemLink or not C_Item or not C_Item.GetItemInfoInstant then
        return nil
    end

    local equippedLink = GetInventoryItemLink("player", slotID)

    if not equippedLink then
        return nil
    end

    local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(equippedLink)
    return itemEquipLoc
end

local function GetComparisonSlots(itemEquipLoc)
    if itemEquipLoc ~= "INVTYPE_WEAPON" then
        return EQUIPMENT_SLOTS[itemEquipLoc]
    end

    local canDualWield = CanDualWield and CanDualWield()
    local mainHandEquipLoc = GetEquippedItemEquipLoc(SLOT_IDS.MAINHAND)

    if canDualWield and mainHandEquipLoc ~= "INVTYPE_2HWEAPON" then
        return { SLOT_IDS.MAINHAND, SLOT_IDS.OFFHAND }
    end

    return { SLOT_IDS.MAINHAND }
end

local function NeedsManualWeaponComparison(itemEquipLoc)
    if itemEquipLoc ~= "INVTYPE_WEAPON"
        and itemEquipLoc ~= "INVTYPE_WEAPONMAINHAND"
        and itemEquipLoc ~= "INVTYPE_2HWEAPON"
        and itemEquipLoc ~= "INVTYPE_WEAPONOFFHAND"
        and itemEquipLoc ~= "INVTYPE_SHIELD"
        and itemEquipLoc ~= "INVTYPE_HOLDABLE"
    then
        return false
    end

    local mainHandEquipLoc = GetEquippedItemEquipLoc(SLOT_IDS.MAINHAND)
    local offHandLink = GetInventoryItemLink and GetInventoryItemLink("player", SLOT_IDS.OFFHAND)

    if itemEquipLoc == "INVTYPE_2HWEAPON" then
        return offHandLink ~= nil
    end

    if mainHandEquipLoc ~= "INVTYPE_2HWEAPON" then
        return false
    end

    return itemEquipLoc == "INVTYPE_WEAPON"
        or itemEquipLoc == "INVTYPE_WEAPONMAINHAND"
        or itemEquipLoc == "INVTYPE_WEAPONOFFHAND"
        or itemEquipLoc == "INVTYPE_SHIELD"
        or itemEquipLoc == "INVTYPE_HOLDABLE"
end

local function GetLowestEquippedItemLevel(slotIDs)
    local lowestItemLevel

    for _, slotID in ipairs(slotIDs) do
        local itemLevel, state = GetEquippedItemInfo(slotID)

        if state == "empty" then
            return nil, "empty"
        end

        if state == "unknown" then
            return nil, "unknown"
        end

        if not lowestItemLevel or itemLevel < lowestItemLevel then
            lowestItemLevel = itemLevel
        end
    end

    if not lowestItemLevel then
        return nil, "unknown"
    end

    return lowestItemLevel, "equipped"
end

local function BuildItemLevelComparisonText(itemLink, itemEquipLoc)
    if NeedsManualWeaponComparison(itemEquipLoc) then
        return ColorLabel(L.weaponSetup, EVALUATION_COLORS.notCurrentSpec)
    end

    local slotIDs = GetComparisonSlots(itemEquipLoc)

    if not slotIDs then
        return nil
    end

    local candidateItemLevel = GetDetailedItemLevelForComparison(itemLink)

    if not candidateItemLevel then
        return ColorLabel(L.itemLevelUnknown, EVALUATION_COLORS.unknown)
    end

    local equippedItemLevel, state = GetLowestEquippedItemLevel(slotIDs)

    if state == "empty" then
        return ColorLabel(L.emptySlot, EVALUATION_COLORS.empty)
    end

    if state == "unknown" then
        return ColorLabel(L.itemLevelUnknown, EVALUATION_COLORS.unknown)
    end

    local difference = candidateItemLevel - equippedItemLevel

    if difference > 0 then
        return ColorLabel(string.format(L.itemLevelDelta, difference), EVALUATION_COLORS.upgrade)
    end

    if difference < 0 then
        return ColorLabel(string.format(L.itemLevelDelta, difference), EVALUATION_COLORS.downgrade)
    end

    return ColorLabel(L.sameItemLevel, EVALUATION_COLORS.same)
end

local function BuildEquipmentEvaluationText(itemLink, itemID, classID, subClassID, itemEquipLoc, itemStats)
    if not settings.showSuitability and not settings.showUpgrade then
        return nil
    end

    if not EQUIPMENT_SLOTS[itemEquipLoc] and itemEquipLoc ~= "INVTYPE_WEAPON" then
        return nil
    end

    -- Cosmetic armor keeps the original decoration but is not combat gear to compare.
    if classID == 4 and subClassID == 5 then
        return nil
    end

    local playerContext = GetPlayerEquipmentContext()

    if not playerContext or not C_PlayerInfo or not C_PlayerInfo.CanUseItem then
        return nil
    end

    if not C_PlayerInfo.CanUseItem(itemID) then
        if settings.showSuitability then
            return ColorLabel(L.cannotEquip, EVALUATION_COLORS.cannotEquip)
        end

        return nil
    end

    local matchesCurrentSpec = MatchesPreferredArmorType(
        classID,
        subClassID,
        itemEquipLoc,
        playerContext.classToken
    )
        and MatchesPrimaryStat(itemStats, playerContext.primaryStat)
        and MatchesCurrentSpecialization(itemLink, playerContext.specializationID)

    if not matchesCurrentSpec then
        if settings.showSuitability then
            return ColorLabel(L.notCurrentSpec, EVALUATION_COLORS.notCurrentSpec)
        end

        return nil
    end

    local labels = {}

    if settings.showSuitability then
        table.insert(labels, ColorLabel(L.suitable, EVALUATION_COLORS.suitable))
    end

    if settings.showUpgrade then
        local comparisonText = BuildItemLevelComparisonText(itemLink, itemEquipLoc)

        if comparisonText then
            table.insert(labels, comparisonText)
        end
    end

    if #labels == 0 then
        return nil
    end

    return table.concat(labels, " ")
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

local function BuildEnhancedItemLink(itemLink, includeEvaluation)
    if not itemLink or not settings or not settings.enabled then
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
    local itemStats
    local secondaryStatText
    local tertiaryStatText
    local details = {}

    if settings.showSecondary or settings.showTertiary or includeEvaluation then
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

    if includeEvaluation then
        local evaluationText = BuildEquipmentEvaluationText(
            itemLink,
            itemID,
            classID,
            subClassID,
            itemEquipLoc,
            itemStats
        )

        if evaluationText then
            enhancedLink = enhancedLink .. " " .. evaluationText
        end
    end

    return enhancedLink
end

local function EnhanceItemLinks(message, event)
    if not message or not message:find("|Hitem:", 1, true) then
        return message
    end

    DebugPrint("Item link detected in message.")

    local includeEvaluation = event == "CHAT_MSG_LOOT"
        and (settings.showSuitability or settings.showUpgrade)

    -- Normal colored item links
    local enhancedMessage, count = message:gsub("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h%[.-%]|h|r)", function(itemLink)
        return BuildEnhancedItemLink(itemLink, includeEvaluation)
    end)

    -- Fallback for uncolored item links
    if count == 0 then
        enhancedMessage, count = message:gsub("(|Hitem:.-|h%[.-%]|h)", function(itemLink)
            return BuildEnhancedItemLink(itemLink, includeEvaluation)
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

    local enhancedMessage = EnhanceItemLinks(message, event)

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
            .. ", suitability " .. StateText(settings.showSuitability)
            .. ", upgrade comparison " .. StateText(settings.showUpgrade)
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
    print("/sli suitable [on|off] - Toggle current-spec suitability labels on loot.")
    print("/sli upgrade [on|off] - Toggle equipped item-level comparisons on loot.")
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
        suitable = "showSuitability",
        suitability = "showSuitability",
        upgrade = "showUpgrade",
        comparison = "showUpgrade",
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
