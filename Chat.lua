local _, SLI = ...

local registered = false

local function EnhanceItemLinks(message, event)
    if not message or not message:find("|Hitem:", 1, true) then
        return message
    end

    SLI.DebugPrint("Item link detected in message.")

    local settings = SLI.settings
    local includeEvaluation = event == "CHAT_MSG_LOOT"
        and (settings.showSuitability or settings.showUpgrade)

    -- Normal colored item links
    local enhancedMessage, count = message:gsub("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h%[.-%]|h|r)", function(itemLink)
        return SLI.BuildEnhancedItemLink(itemLink, includeEvaluation)
    end)

    -- Fallback for uncolored item links
    if count == 0 then
        enhancedMessage, count = message:gsub("(|Hitem:.-|h%[.-%]|h)", function(itemLink)
            return SLI.BuildEnhancedItemLink(itemLink, includeEvaluation)
        end)
    end

    SLI.DebugPrint("Replacement count:", count)

    return enhancedMessage
end

local function ShouldEnhanceEvent(event)
    local settings = SLI.settings

    if not settings or not settings.enabled then
        return false
    end

    if event == "CHAT_MSG_LOOT" then
        return settings.enhanceLoot
    end

    return settings.enhanceChat
end

local function ChatMessageFilter(self, event, message, ...)
    SLI.DebugPrint("Event:", event)

    if not ShouldEnhanceEvent(event) then
        return false, message, ...
    end

    local enhancedMessage = EnhanceItemLinks(message, event)

    if enhancedMessage ~= message then
        SLI.DebugPrint("Message modified.")
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

function SLI.RegisterChatFilters()
    if registered then
        return
    end

    registered = true

    for _, eventName in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(eventName, ChatMessageFilter)
    end

    SLI.DebugPrint("Chat filters registered.")
end
