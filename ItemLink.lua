local _, SLI = ...

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
    local itemLevel = SLI.GetCachedDisplayedItemLevel and SLI.GetCachedDisplayedItemLevel(itemLink)

    if not itemLevel and C_Item and C_Item.GetDetailedItemLevelInfo then
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

local function DecomposeItemLink(itemLink)
    local color, linkOpen, itemName, linkClose =
        itemLink:match("^(|c%x%x%x%x%x%x%x%x)(|Hitem:.-|h)%[(.-)%](|h|r)$")

    if color then
        return color, linkOpen, itemName, linkClose
    end

    linkOpen, itemName, linkClose = itemLink:match("^(|Hitem:.-|h)%[(.-)%](|h)$")

    if linkOpen then
        return "", linkOpen, itemName, linkClose
    end

    return nil
end

function SLI.BuildEnhancedItemLink(itemLink, includeEvaluation)
    local settings = SLI.settings

    if not itemLink or not settings or not settings.enabled then
        return itemLink
    end

    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID =
        C_Item.GetItemInfoInstant(itemLink)

    if not itemID then
        SLI.DebugPrint("No itemID found for link.")
        return itemLink
    end

    if not IsValidEquipment(classID, itemEquipLoc) then
        SLI.DebugPrint("Not equipment:", itemID, classID, itemEquipLoc or "nil")
        return itemLink
    end

    local color, linkOpen, itemName, linkClose = DecomposeItemLink(itemLink)

    if not linkOpen then
        SLI.DebugPrint("Unrecognized item link shape:", itemID)
        return itemLink
    end

    -- No |r may appear inside the hyperlink body: it can reset the outer quality
    -- color instead of restoring it. Re-apply the link color explicitly instead.
    local restoreColor = color ~= "" and color or "|r"

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

    SLI.DebugPrint("Enhanced item:", itemID, typeName or "nil", slotName or "nil", itemLevel or "nil")

    local displayText = itemName

    if #details > 0 then
        displayText = table.concat(details, "/") .. ": " .. displayText
    end

    if secondaryStatText then
        displayText = displayText .. " (" .. secondaryStatText .. ")"
    end

    if tertiaryStatText then
        displayText = displayText .. " " .. TERTIARY_COLOR .. "(" .. tertiaryStatText .. ")" .. restoreColor
    end

    if includeEvaluation then
        local evaluationText = SLI.BuildEquipmentEvaluationText(
            itemLink,
            itemID,
            classID,
            subClassID,
            itemEquipLoc,
            itemStats,
            restoreColor
        )

        if evaluationText then
            displayText = displayText .. " " .. evaluationText
        end
    end

    local enhancedLink = color .. linkOpen .. "[" .. displayText .. "]" .. linkClose

    -- The icon stays outside the hyperlink: a texture inside the body can split the
    -- clickable region.
    if settings.showIcon and icon then
        enhancedLink = string.format("|T%s:14:14:0:0|t %s", icon, enhancedLink)
    end

    return enhancedLink
end
