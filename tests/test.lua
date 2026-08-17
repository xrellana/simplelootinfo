local realPrint = print
local filters = {}
local addonFrame

local function AssertEqual(expected, actual, description)
    if expected ~= actual then
        error(string.format(
            "%s\nexpected: %s\nactual:   %s",
            description,
            tostring(expected),
            tostring(actual)
        ))
    end
end

local function AssertContains(haystack, needle, description)
    if not haystack:find(needle, 1, true) then
        error(string.format("%s\nmissing: %s\nin:      %s", description, needle, haystack))
    end
end

local function AssertNotContains(haystack, needle, description)
    if haystack:find(needle, 1, true) then
        error(string.format("%s\nunexpected: %s\nin:         %s", description, needle, haystack))
    end
end

print = function() end
SlashCmdList = {}
SimpleLootInfoDB = nil
INVTYPE_WEAPON = "One-Hand"
INVTYPE_2HWEAPON = "Two-Hand"
INVTYPE_HEAD = "Head"
INVTYPE_NECK = "Neck"
INVTYPE_FINGER = "Finger"
ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike"
ITEM_MOD_HASTE_RATING_SHORT = "Haste"
ITEM_MOD_MASTERY_RATING_SHORT = "Mastery"
ITEM_MOD_VERSATILITY = "Versatility"
ITEM_MOD_CR_LIFESTEAL_SHORT = "Leech"
ITEM_MOD_CR_AVOIDANCE_SHORT = "Avoidance"
ITEM_MOD_CR_SPEED_SHORT = "Speed"
ITEM_MOD_CR_STURDINESS_SHORT = "Indestructible"
ITEM_MOD_STRENGTH_SHORT = "Strength"
ITEM_MOD_AGILITY_SHORT = "Agility"
ITEM_MOD_INTELLECT_SHORT = "Intellect"

local function GetItemIDFromLink(itemLink)
    return tonumber(itemLink:match("Hitem:(%d+)"))
end

local itemInfo = {
    [888] = { "Weapon", "Sword", "INVTYPE_WEAPON", 135771, 2, 7 },
    [1001] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1002] = { "Armor", "Leather", "INVTYPE_HEAD", 133071, 4, 2 },
    [1003] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1004] = { "Armor", "Miscellaneous", "INVTYPE_FINGER", 133345, 4, 0 },
    [1005] = { "Armor", "Miscellaneous", "INVTYPE_FINGER", 133345, 4, 0 },
    [1006] = { "Armor", "Miscellaneous", "INVTYPE_FINGER", 133345, 4, 0 },
    [1007] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1008] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1009] = { "Armor", "Miscellaneous", "INVTYPE_NECK", 133296, 4, 0 },
    [1010] = { "Weapon", "Two-Handed Sword", "INVTYPE_2HWEAPON", 135349, 2, 8 },
    [1011] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1012] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1013] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [1014] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [5001] = { "Weapon", "Sword", "INVTYPE_WEAPON", 135771, 2, 7 },
    [5101] = { "Armor", "Plate", "INVTYPE_HEAD", 133071, 4, 4 },
    [5201] = { "Armor", "Miscellaneous", "INVTYPE_FINGER", 133345, 4, 0 },
    [5202] = { "Armor", "Miscellaneous", "INVTYPE_FINGER", 133345, 4, 0 },
    [19019] = { "Weapon", "Sword", "INVTYPE_WEAPON", 135771, 2, 7 },
}

local itemLevels = {
    [888] = 639,
    [1001] = 639,
    [1002] = 639,
    [1003] = 639,
    [1004] = 630,
    [1005] = 625,
    [1006] = 620,
    [1008] = 639,
    [1009] = 639,
    [1010] = 650,
    [1011] = 639,
    [1012] = 639,
    [1013] = 639,
    [1014] = 639,
    [5001] = 631,
    [5101] = 630,
    [5201] = 625,
    [5202] = 635,
    [5301] = 630,
    [19019] = 639,
}

local equippedLinks = {
    [1] = "|cffa335ee|Hitem:5101:::::::::::::::|h[Equipped Helm]|h|r",
    [11] = "|cffa335ee|Hitem:5201:::::::::::::::|h[Lower Ring]|h|r",
    [12] = "|cffa335ee|Hitem:5202:::::::::::::::|h[Higher Ring]|h|r",
    [16] = "|cffa335ee|Hitem:5001:::::::::::::::|h[Equipped Sword]|h|r",
}

GetLocale = function()
    return "enUS"
end

UnitClass = function()
    return "Warrior", "WARRIOR", 1
end

C_SpecializationInfo = {
    GetSpecialization = function()
        return 1
    end,
    GetSpecializationInfo = function()
        return 71, "Arms", nil, nil, "DAMAGER", 1
    end,
}

CanDualWield = function()
    return false
end

GetInventoryItemLink = function(_, slotID)
    return equippedLinks[slotID]
end

GetInventoryItemID = function(_, slotID)
    local equippedLink = equippedLinks[slotID]
    return equippedLink and GetItemIDFromLink(equippedLink) or nil
end

C_PlayerInfo = {
    CanUseItem = function(itemID)
        return itemID ~= 1003
    end,
}

C_Item = {
    GetItemInfoInstant = function(itemLink)
        local itemID = GetItemIDFromLink(itemLink)

        if itemID == 999 then
            return 999, "Consumable", "Potion", "", 134829, 0, 1
        end

        local info = itemInfo[itemID] or itemInfo[19019]
        return itemID, info[1], info[2], info[3], info[4], info[5], info[6]
    end,
    GetDetailedItemLevelInfo = function(itemLink)
        return itemLevels[GetItemIDFromLink(itemLink)]
    end,
    GetItemStats = function(itemLink)
        if itemLink:find("Hitem:999", 1, true) then
            return nil
        end

        local stats = {
            ITEM_MOD_STRENGTH_SHORT = 150,
            ITEM_MOD_CRIT_RATING_SHORT = 95,
            ITEM_MOD_HASTE_RATING_SHORT = 120,
            ITEM_MOD_MASTERY_RATING_SHORT = 80,
        }

        if itemLink:find("Hitem:1008", 1, true) then
            stats.ITEM_MOD_STRENGTH_SHORT = nil
            stats.ITEM_MOD_INTELLECT_SHORT = 150
        end

        if itemLink:find("Hitem:1004", 1, true)
            or itemLink:find("Hitem:1005", 1, true)
            or itemLink:find("Hitem:1006", 1, true)
            or itemLink:find("Hitem:1009", 1, true)
        then
            stats.ITEM_MOD_STRENGTH_SHORT = nil
        end

        if not itemLink:find("Hitem:888", 1, true) then
            stats.ITEM_MOD_CR_LIFESTEAL_SHORT = 48
            stats.ITEM_MOD_CR_AVOIDANCE_SHORT = 36
            stats.ITEM_MOD_CR_SPEED_SHORT = 24
            stats.ITEM_MOD_CR_STURDINESS_SHORT = 1
        end

        return stats
    end,
    GetItemSpecInfo = function(itemLink)
        local itemID = GetItemIDFromLink(itemLink)

        if itemID == 1011 then
            return { 72 }
        end

        if itemID == 1012 then
            return { 72, 71 }
        end

        if itemID == 1013 then
            return {}
        end

        if itemID == 1014 then
            return nil
        end

        return { 71 }
    end,
    RequestLoadItemDataByID = function() end,
}

GetItemInfo = function()
    return nil, nil, nil, 639
end

ChatFrame_AddMessageEventFilter = function(eventName, callback)
    filters[eventName] = callback
end

C_Timer = {
    After = function(_, callback)
        callback()
    end,
}

CreateFrame = function()
    local frame = {}

    frame.RegisterEvent = function(self, eventName)
        self.eventName = eventName
    end

    frame.SetScript = function(self, _, callback)
        self.callback = callback
    end

    addonFrame = frame
    return frame
end

local addonNamespace = {}

for fileName in io.lines("SimpleLootInfo.toc") do
    fileName = fileName:match("^%s*(.-)%s*$")

    if fileName ~= "" and not fileName:match("^#") and fileName:match("%.lua$") then
        local chunk, loadError = loadfile(fileName)
        assert(chunk, loadError)
        chunk("SimpleLootInfo", addonNamespace)
    end
end

addonFrame.callback()

local gearLink = "|cffa335ee|Hitem:19019:::::::::::::::|h[Thunderfury]|h|r"
local plainGearLink = "|cffa335ee|Hitem:888:::::::::::::::|h[Plain Gear]|h|r"
local consumableLink = "|cffffffff|Hitem:999:::::::::::::::|h[Test Potion]|h|r"
local plateHeadLink = "|cffa335ee|Hitem:1001:::::::::::::::|h[Plate Helm]|h|r"
local leatherHeadLink = "|cffa335ee|Hitem:1002:::::::::::::::|h[Leather Helm]|h|r"
local unusableHeadLink = "|cffa335ee|Hitem:1003:::::::::::::::|h[Restricted Helm]|h|r"
local upgradeRingLink = "|cffa335ee|Hitem:1004:::::::::::::::|h[Upgrade Ring]|h|r"
local sameRingLink = "|cffa335ee|Hitem:1005:::::::::::::::|h[Same Ring]|h|r"
local lowerRingLink = "|cffa335ee|Hitem:1006:::::::::::::::|h[Lower Ring]|h|r"
local unknownHeadLink = "|cffa335ee|Hitem:1007:::::::::::::::|h[Unknown Helm]|h|r"
local intellectHeadLink = "|cffa335ee|Hitem:1008:::::::::::::::|h[Intellect Helm]|h|r"
local emptyNeckLink = "|cffa335ee|Hitem:1009:::::::::::::::|h[First Necklace]|h|r"
local twoHandLink = "|cffa335ee|Hitem:1010:::::::::::::::|h[Two-Handed Sword]|h|r"
local specMismatchHeadLink = "|cffa335ee|Hitem:1011:::::::::::::::|h[Other Spec Helm]|h|r"
local multiSpecHeadLink = "|cffa335ee|Hitem:1012:::::::::::::::|h[Multi-Spec Helm]|h|r"
local emptySpecHeadLink = "|cffa335ee|Hitem:1013:::::::::::::::|h[Empty Spec Helm]|h|r"
local missingSpecHeadLink = "|cffa335ee|Hitem:1014:::::::::::::::|h[Missing Spec Helm]|h|r"

local function Filter(eventName, message)
    local blocked, enhancedMessage = filters[eventName](nil, eventName, message)
    AssertEqual(false, blocked, "The filter must never block a chat message.")
    return enhancedMessage
end

AssertEqual(
    "Loot: Sword/One-Hand/639: " .. gearLink
        .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r"
        .. " |cff67d8ff[Suitable]|r |cff55ff88[iLvl +8]|r",
    Filter("CHAT_MSG_LOOT", "Loot: " .. gearLink),
    "Default settings should append secondary stats in descending order."
)

AssertEqual(
    "Loot: " .. consumableLink,
    Filter("CHAT_MSG_LOOT", "Loot: " .. consumableLink),
    "Non-equipment links should remain unchanged."
)

AssertEqual(
    "Loot: Sword/One-Hand/639: " .. plainGearLink
        .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cff67d8ff[Suitable]|r |cff55ff88[iLvl +8]|r",
    Filter("CHAT_MSG_LOOT", "Loot: " .. plainGearLink),
    "Gear without tertiary stats should not receive an empty highlighted group."
)

local twoLinks = Filter("CHAT_MSG_LOOT", gearLink .. " and " .. gearLink)
AssertEqual(
    "Sword/One-Hand/639: " .. gearLink .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r"
        .. " |cff67d8ff[Suitable]|r |cff55ff88[iLvl +8]|r"
        .. " and Sword/One-Hand/639: " .. gearLink
        .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r"
        .. " |cff67d8ff[Suitable]|r |cff55ff88[iLvl +8]|r",
    twoLinks,
    "Every gear link in a message should be enhanced."
)

AssertEqual(
    "Sword/One-Hand/639: " .. gearLink
        .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r",
    Filter("CHAT_MSG_SAY", gearLink),
    "Ordinary chat should keep the original enhancement without player-specific evaluation labels."
)

AssertContains(
    Filter("CHAT_MSG_LOOT", plateHeadLink),
    "|cff67d8ff[Suitable]|r |cff55ff88[iLvl +9]|r",
    "Preferred armor with the current specialization's primary stat should be suitable and compared."
)

local wrongArmorMessage = Filter("CHAT_MSG_LOOT", leatherHeadLink)
AssertContains(
    wrongArmorMessage,
    "[Wrong Armor Type]",
    "A non-preferred armor type should receive a specific armor-mismatch label."
)
AssertNotContains(
    wrongArmorMessage,
    "[Not for Current Spec]",
    "An armor mismatch should not be conflated with an item specialization mismatch."
)
AssertNotContains(
    wrongArmorMessage,
    "[Wrong Primary Stat]",
    "An armor mismatch should not be conflated with a primary-stat mismatch."
)
AssertNotContains(wrongArmorMessage, "[iLvl", "Wrong-armor gear should not receive an item-level comparison.")

local wrongPrimaryMessage = Filter("CHAT_MSG_LOOT", intellectHeadLink)
AssertContains(
    wrongPrimaryMessage,
    "[Wrong Primary Stat]",
    "An item with a different primary stat should receive a specific primary-stat label."
)
AssertNotContains(
    wrongPrimaryMessage,
    "[Not for Current Spec]",
    "A primary-stat mismatch should not be conflated with an item specialization mismatch."
)
AssertNotContains(
    wrongPrimaryMessage,
    "[Wrong Armor Type]",
    "A primary-stat mismatch should not be conflated with an armor mismatch."
)
AssertNotContains(wrongPrimaryMessage, "[iLvl", "Wrong-primary-stat gear should not receive a comparison.")

local wrongItemSpecMessage = Filter("CHAT_MSG_LOOT", specMismatchHeadLink)
AssertContains(
    wrongItemSpecMessage,
    "[Not for Current Spec]",
    "An item restricted to another specialization should receive the specialization label."
)
AssertNotContains(
    wrongItemSpecMessage,
    "[Wrong Armor Type]",
    "A specialization mismatch should not be conflated with an armor mismatch."
)
AssertNotContains(
    wrongItemSpecMessage,
    "[Wrong Primary Stat]",
    "A specialization mismatch should not be conflated with a primary-stat mismatch."
)
AssertNotContains(
    wrongItemSpecMessage,
    "[iLvl",
    "Gear restricted to another specialization should not receive an item-level comparison."
)

AssertContains(
    Filter("CHAT_MSG_LOOT", multiSpecHeadLink),
    "[Suitable]",
    "An item listing multiple specializations should be suitable when it includes the current specialization."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", multiSpecHeadLink),
    "[iLvl +9]",
    "A multi-specialization item that includes the current specialization should still be compared."
)

AssertContains(
    Filter("CHAT_MSG_LOOT", emptySpecHeadLink),
    "[Suitable]",
    "An item with an explicitly empty specialization list should remain usable for conservative evaluation."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", emptySpecHeadLink),
    "[iLvl +9]",
    "An item with an empty specialization list should still receive a comparison when other checks pass."
)

AssertContains(
    Filter("CHAT_MSG_LOOT", missingSpecHeadLink),
    "[Suitable]",
    "An item without specialization metadata should remain usable for conservative evaluation."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", missingSpecHeadLink),
    "[iLvl +9]",
    "An item without specialization metadata should still receive a comparison when other checks pass."
)

local cannotEquipMessage = Filter("CHAT_MSG_LOOT", unusableHeadLink)
AssertContains(
    cannotEquipMessage,
    "|cffff5c5c[Cannot Equip]|r",
    "Items rejected by the player usability API should be marked as not equippable."
)
AssertNotContains(cannotEquipMessage, "[iLvl", "Unusable gear should not receive an item-level comparison.")

AssertContains(
    Filter("CHAT_MSG_LOOT", upgradeRingLink),
    "|cff55ff88[iLvl +5]|r",
    "Rings should compare against the lower of the two equipped ring item levels."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", sameRingLink),
    "|cffc7cbd1[Same iLvl]|r",
    "Equal item levels should receive a neutral label."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", lowerRingLink),
    "|cffff8a65[iLvl -5]|r",
    "Lower item levels should receive the downgrade label."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", emptyNeckLink),
    "|cff50e3c2[Empty Slot]|r",
    "An empty compatible slot should be identified directly."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", unknownHeadLink),
    "|cffadb3bd[Item Level Unknown]|r",
    "Missing detailed item-level data must not fall back to an upgrade guess."
)

equippedLinks[17] = "|cffa335ee|Hitem:5301:::::::::::::::|h[Equipped Off-Hand]|h|r"
AssertContains(
    Filter("CHAT_MSG_LOOT", twoHandLink),
    "|cffffc857[Different Weapon Setup]|r",
    "Two-handed weapons should avoid a misleading one-slot comparison when an off-hand is equipped."
)
equippedLinks[17] = nil

SlashCmdList.SIMPLELOOTINFO("suitable off")
AssertEqual(false, SimpleLootInfoDB.showSuitability, "Suitability preference should be persisted.")
local comparisonOnlyMessage = Filter("CHAT_MSG_LOOT", gearLink)
AssertNotContains(comparisonOnlyMessage, "[Suitable]", "Suitability labels should be independently disableable.")
AssertContains(comparisonOnlyMessage, "[iLvl +8]", "Upgrade labels should remain when suitability is disabled.")
SlashCmdList.SIMPLELOOTINFO("suitable on")

SlashCmdList.SIMPLELOOTINFO("upgrade off")
AssertEqual(false, SimpleLootInfoDB.showUpgrade, "Upgrade preference should be persisted.")
local suitabilityOnlyMessage = Filter("CHAT_MSG_LOOT", gearLink)
AssertContains(suitabilityOnlyMessage, "[Suitable]", "Suitability should remain when comparisons are disabled.")
AssertNotContains(suitabilityOnlyMessage, "[iLvl", "Upgrade labels should be independently disableable.")
SlashCmdList.SIMPLELOOTINFO("upgrade on")

SlashCmdList.SIMPLELOOTINFO("icon on")
AssertEqual(true, SimpleLootInfoDB.showIcon, "Icon preference should be persisted.")
AssertContains(
    Filter("CHAT_MSG_LOOT", gearLink),
    "|T135771:14:14:0:0|t Sword/One-Hand/639:",
    "The icon option should prepend the item texture."
)

SlashCmdList.SIMPLELOOTINFO("secondary off")
AssertEqual(false, SimpleLootInfoDB.showSecondary, "Secondary stat preference should be persisted.")
AssertContains(
    Filter("CHAT_MSG_LOOT", gearLink),
    "|cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r",
    "Tertiary stats should remain visible when secondary stats are disabled."
)

SlashCmdList.SIMPLELOOTINFO("tertiary off")
AssertEqual(false, SimpleLootInfoDB.showTertiary, "Tertiary stat preference should be persisted.")
AssertEqual(
    "Loot: |T135771:14:14:0:0|t Sword/One-Hand/639: " .. gearLink
        .. " |cff67d8ff[Suitable]|r |cff55ff88[iLvl +8]|r",
    Filter("CHAT_MSG_LOOT", "Loot: " .. gearLink),
    "Secondary and tertiary stats should be independently disableable."
)
SlashCmdList.SIMPLELOOTINFO("stats on")
SlashCmdList.SIMPLELOOTINFO("tertiary on")

SlashCmdList.SIMPLELOOTINFO("type off")
SlashCmdList.SIMPLELOOTINFO("slot off")
AssertContains(
    Filter("CHAT_MSG_LOOT", gearLink),
    "|T135771:14:14:0:0|t 639:",
    "Display components should be independently configurable."
)

SlashCmdList.SIMPLELOOTINFO("chat off")
AssertEqual(
    gearLink,
    Filter("CHAT_MSG_SAY", gearLink),
    "Chat enhancements should be independently disableable."
)
AssertContains(
    Filter("CHAT_MSG_LOOT", gearLink),
    "639:",
    "Disabling chat should not disable loot enhancements."
)

SlashCmdList.SIMPLELOOTINFO("off")
AssertEqual(
    gearLink,
    Filter("CHAT_MSG_LOOT", gearLink),
    "The global switch should disable every enhancement."
)

SlashCmdList.SIMPLELOOTINFO("reset")
AssertEqual(true, SimpleLootInfoDB.enabled, "Reset should enable the addon.")
AssertEqual(true, SimpleLootInfoDB.showType, "Reset should restore item type.")
AssertEqual(true, SimpleLootInfoDB.showSlot, "Reset should restore equipment slot.")
AssertEqual(true, SimpleLootInfoDB.showItemLevel, "Reset should restore item level.")
AssertEqual(true, SimpleLootInfoDB.showSecondary, "Reset should restore secondary stats.")
AssertEqual(true, SimpleLootInfoDB.showTertiary, "Reset should restore tertiary stats.")
AssertEqual(false, SimpleLootInfoDB.showIcon, "Reset should hide the optional icon.")
AssertEqual(true, SimpleLootInfoDB.showSuitability, "Reset should restore suitability labels.")
AssertEqual(true, SimpleLootInfoDB.showUpgrade, "Reset should restore item-level comparisons.")
AssertEqual(true, SimpleLootInfoDB.enhanceLoot, "Reset should restore loot enhancements.")
AssertEqual(true, SimpleLootInfoDB.enhanceChat, "Reset should restore chat enhancements.")

print = realPrint
realPrint("All Simple Loot Info tests passed.")
