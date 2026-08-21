local _, SLI = ...

local ADDON_NAME = "Simple Loot Info"

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

local LOCALES = {
    enUS = {
        suitable = "Suitable",
        wrongArmorType = "Wrong Armor Type",
        wrongPrimaryStat = "Wrong Primary Stat",
        notCurrentSpec = "Not for Current Spec",
        cannotEquip = "Cannot Equip",
        itemLevelUnknown = "Item Level Unknown",
        sameItemLevel = "Same iLvl",
        emptySlot = "Empty Slot",
        differentWeaponSetup = "Different Weapon Setup",
        itemLevelDelta = "iLvl %+d",
    },
}

SLI.DEBUG = false
SLI.L = LOCALES[(GetLocale and GetLocale()) or "enUS"] or LOCALES.enUS

function SLI.PrintMessage(message)
    print("|cff00ff00" .. ADDON_NAME .. ":|r " .. message)
end

function SLI.DebugPrint(...)
    if SLI.DEBUG then
        print("|cff00ff00" .. ADDON_NAME .. " Debug:|r", ...)
    end
end

function SLI.InitializeSettings(reset)
    if reset or type(SimpleLootInfoDB) ~= "table" then
        SimpleLootInfoDB = {}
    end

    for key, value in pairs(DEFAULTS) do
        if SimpleLootInfoDB[key] == nil then
            SimpleLootInfoDB[key] = value
        end
    end

    SLI.settings = SimpleLootInfoDB
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        SLI.InitializeSettings()

        -- Register slightly later to avoid being overwritten by other chat/item-link addons.
        C_Timer.After(2, SLI.RegisterChatFilters)

        return
    end

    -- Cached item levels are keyed by item link, which cannot see a level-scaling or
    -- Timewalking change, so drop them when either becomes possible.
    if SLI.ResetItemLevelCaches then
        SLI.ResetItemLevelCaches()
    end
end)
