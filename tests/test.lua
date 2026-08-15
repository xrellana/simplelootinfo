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

print = function() end
SlashCmdList = {}
SimpleLootInfoDB = nil
INVTYPE_WEAPON = "One-Hand"
ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike"
ITEM_MOD_HASTE_RATING_SHORT = "Haste"
ITEM_MOD_MASTERY_RATING_SHORT = "Mastery"
ITEM_MOD_VERSATILITY = "Versatility"
ITEM_MOD_CR_LIFESTEAL_SHORT = "Leech"
ITEM_MOD_CR_AVOIDANCE_SHORT = "Avoidance"
ITEM_MOD_CR_SPEED_SHORT = "Speed"
ITEM_MOD_CR_STURDINESS_SHORT = "Indestructible"

C_Item = {
    GetItemInfoInstant = function(itemLink)
        if itemLink:find("Hitem:999", 1, true) then
            return 999, "Consumable", "Potion", "", 134829, 0, 1
        end

        return 19019, "Weapon", "Sword", "INVTYPE_WEAPON", 135771, 2, 7
    end,
    GetDetailedItemLevelInfo = function()
        return 639
    end,
    GetItemStats = function(itemLink)
        if itemLink:find("Hitem:999", 1, true) then
            return nil
        end

        local stats = {
            ITEM_MOD_CRIT_RATING_SHORT = 95,
            ITEM_MOD_HASTE_RATING_SHORT = 120,
            ITEM_MOD_MASTERY_RATING_SHORT = 80,
        }

        if not itemLink:find("Hitem:888", 1, true) then
            stats.ITEM_MOD_CR_LIFESTEAL_SHORT = 48
            stats.ITEM_MOD_CR_AVOIDANCE_SHORT = 36
            stats.ITEM_MOD_CR_SPEED_SHORT = 24
            stats.ITEM_MOD_CR_STURDINESS_SHORT = 1
        end

        return stats
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

dofile("SimpleLootInfo.lua")
addonFrame.callback()

local gearLink = "|cffa335ee|Hitem:19019:::::::::::::::|h[Thunderfury]|h|r"
local plainGearLink = "|cffa335ee|Hitem:888:::::::::::::::|h[Plain Gear]|h|r"
local consumableLink = "|cffffffff|Hitem:999:::::::::::::::|h[Test Potion]|h|r"

local function Filter(eventName, message)
    local blocked, enhancedMessage = filters[eventName](nil, eventName, message)
    AssertEqual(false, blocked, "The filter must never block a chat message.")
    return enhancedMessage
end

AssertEqual(
    "Loot: Sword/One-Hand/639: " .. gearLink
        .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r",
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
        .. " (Haste 120/Critical Strike 95/Mastery 80)",
    Filter("CHAT_MSG_LOOT", "Loot: " .. plainGearLink),
    "Gear without tertiary stats should not receive an empty highlighted group."
)

local twoLinks = Filter("CHAT_MSG_LOOT", gearLink .. " and " .. gearLink)
AssertEqual(
    "Sword/One-Hand/639: " .. gearLink .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r"
        .. " and Sword/One-Hand/639: " .. gearLink
        .. " (Haste 120/Critical Strike 95/Mastery 80)"
        .. " |cffffd100(Leech 48/Avoidance 36/Speed 24/Indestructible)|r",
    twoLinks,
    "Every gear link in a message should be enhanced."
)

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
    "Loot: |T135771:14:14:0:0|t Sword/One-Hand/639: " .. gearLink,
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
AssertEqual(true, SimpleLootInfoDB.enhanceLoot, "Reset should restore loot enhancements.")
AssertEqual(true, SimpleLootInfoDB.enhanceChat, "Reset should restore chat enhancements.")

print = realPrint
realPrint("All Simple Loot Info tests passed.")
