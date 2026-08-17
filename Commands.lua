local _, SLI = ...

local function StateText(value)
    if value then
        return "|cff00ff00on|r"
    end

    return "|cffff4040off|r"
end

local function PrintStatus()
    local settings = SLI.settings

    SLI.PrintMessage("status")
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
    print("  Debug: " .. StateText(SLI.DEBUG))
end

local function SetOrToggle(optionName, argument)
    local settings = SLI.settings

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
        SLI.DEBUG = not SLI.DEBUG
        return true
    end

    if argument == "on" then
        SLI.DEBUG = true
        return true
    end

    if argument == "off" then
        SLI.DEBUG = false
        return true
    end

    return false
end

local function PrintHelp()
    SLI.PrintMessage("commands")
    print("/sli on|off - Enable or disable all enhancements.")
    print("/sli type [on|off] - Toggle item type.")
    print("/sli slot [on|off] - Toggle equipment slot.")
    print("/sli ilvl [on|off] - Toggle item level.")
    print("/sli secondary [on|off] - Toggle secondary stats.")
    print("/sli tertiary [on|off] - Toggle highlighted tertiary stats.")
    print("/sli icon [on|off] - Toggle the inline item icon.")
    print("/sli suitable [on|off] - Toggle loot suitability labels.")
    print("/sli upgrade [on|off] - Toggle equipped item-level comparisons on loot.")
    print("/sli loot [on|off] - Toggle enhancements in loot messages.")
    print("/sli chat [on|off] - Toggle enhancements in chat messages.")
    print("/sli status - Show the current settings.")
    print("/sli reset - Restore the defaults.")
    print("/sli debug [on|off] - Toggle debug output for this session.")
end

SLASH_SIMPLELOOTINFO1 = "/sli"
SlashCmdList["SIMPLELOOTINFO"] = function(msg)
    if not SLI.settings then
        SLI.InitializeSettings()
    end

    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    local command, argument = msg:match("^(%S+)%s*(.-)$")
    command = command or ""
    argument = argument or ""

    if command == "on" or command == "enable" then
        SLI.settings.enabled = true
        SLI.PrintMessage("enabled.")
        return
    end

    if command == "off" or command == "disable" then
        SLI.settings.enabled = false
        SLI.PrintMessage("disabled.")
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
            SLI.PrintMessage(command .. " is now " .. StateText(SLI.settings[optionName]) .. ".")
        else
            SLI.PrintMessage("use 'on' or 'off' after /sli " .. command .. ".")
        end
        return
    end

    if command == "debug" then
        if SetOrToggleDebug(argument) then
            SLI.PrintMessage("debug is now " .. StateText(SLI.DEBUG) .. ".")
        else
            SLI.PrintMessage("use 'on' or 'off' after /sli debug.")
        end
        return
    end

    if command == "status" then
        PrintStatus()
        return
    end

    if command == "reset" then
        SLI.InitializeSettings(true)
        SLI.PrintMessage("settings reset to defaults.")
        PrintStatus()
        return
    end

    PrintHelp()
end
