local _, SLI = ...

local L = SLI.L

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

function SLI.BuildEquipmentEvaluationText(itemLink, itemID, classID, subClassID, itemEquipLoc, itemStats)
    local settings = SLI.settings

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
