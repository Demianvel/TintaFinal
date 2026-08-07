local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local LiveOpsConfig = require(ReplicatedStorage.Shared.LiveOpsConfig)

local UniverseMessagingService = {}
local remotes
local EventService
local WeatherService
local busConnection
local directConnections = {}
local directCooldowns = {}
local announceCooldowns = {}

local function encode(payload)
    return HttpService:JSONEncode(payload)
end

local function decode(value)
    if type(value) == "table" then return value end
    if type(value) ~= "string" then return nil end
    local ok, result = pcall(function() return HttpService:JSONDecode(value) end)
    return ok and result or nil
end

local function publish(topic, payload)
    local ok, err = pcall(function()
        MessagingService:PublishAsync(topic, encode(payload))
    end)
    if not ok then
        warn("[TintaFinal] MessagingService publish failed:", topic, err)
    end
    return ok, err
end

local function filterForBroadcast(sender, text)
    local ok, filtered = pcall(function()
        local result = TextService:FilterStringAsync(text, sender.UserId)
        return result:GetNonChatStringForBroadcastAsync()
    end)
    if not ok then return nil, "No se pudo filtrar el mensaje." end
    return filtered
end

local function filterForUser(sender, targetUserId, text)
    local ok, filtered = pcall(function()
        local result = TextService:FilterStringAsync(text, sender.UserId)
        return result:GetChatForUserAsync(targetUserId)
    end)
    if not ok then return nil, "No se pudo filtrar el mensaje." end
    return filtered
end

local function findTarget(reference)
    reference = tostring(reference or ""):gsub("^@", "")
    local numeric = tonumber(reference)
    if numeric and numeric > 0 then
        local player = Players:GetPlayerByUserId(math.floor(numeric))
        return math.floor(numeric), player
    end

    local lowered = string.lower(reference)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == lowered or string.lower(player.DisplayName) == lowered then
            return player.UserId, player
        end
    end

    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(reference)
    end)
    if ok and userId and userId > 0 then return userId, nil end
    return nil, nil
end

local function fireAnnouncement(text, category)
    if remotes and remotes:FindFirstChild("GlobalAnnouncement") then
        remotes.GlobalAnnouncement:FireAllClients(text, category or "Global")
    end
end

local function handleBus(payload)
    if type(payload) ~= "table" then return end
    if payload.Origin == game.JobId then return end

    if payload.Type == "Announcement" then
        fireAnnouncement(tostring(payload.Text or ""), tostring(payload.Category or "Global"))
    elseif payload.Type == "Event" and EventService then
        EventService.ApplyRemote(payload.Payload)
    elseif payload.Type == "Weather" and WeatherService then
        WeatherService.ApplyRemote(payload.Payload)
    end
end

function UniverseMessagingService.Initialize(remoteFolder, eventService, weatherService)
    remotes = remoteFolder
    EventService = eventService
    WeatherService = weatherService

    local ok, connection = pcall(function()
        return MessagingService:SubscribeAsync(LiveOpsConfig.Messaging.BusTopic, function(message)
            local payload = decode(message.Data)
            if payload then handleBus(payload) end
        end)
    end)
    if ok then
        busConnection = connection
    else
        warn("[TintaFinal] No se pudo suscribir al bus global:", connection)
    end
end

function UniverseMessagingService.SubscribePlayer(player)
    if directConnections[player] then return end
    local topic = LiveOpsConfig.Messaging.DirectTopicPrefix .. tostring(player.UserId)
    local ok, connection = pcall(function()
        return MessagingService:SubscribeAsync(topic, function(message)
            local payload = decode(message.Data)
            if type(payload) ~= "table" then return end
            if remotes and remotes:FindFirstChild("DirectMessage") and player.Parent then
                remotes.DirectMessage:FireClient(
                    player,
                    tostring(payload.FromName or "Jugador"),
                    tonumber(payload.FromUserId) or 0,
                    tostring(payload.Text or "")
                )
            end
        end)
    end)
    if ok then
        directConnections[player] = connection
    else
        warn("[TintaFinal] No se pudo abrir DM topic para", player.UserId, connection)
    end
end

function UniverseMessagingService.UnsubscribePlayer(player)
    local connection = directConnections[player]
    if connection then pcall(function() connection:Disconnect() end) end
    directConnections[player] = nil
    directCooldowns[player] = nil
    announceCooldowns[player] = nil
end

function UniverseMessagingService.SendDirectMessage(sender, targetReference, text)
    local now = os.clock()
    if now - (directCooldowns[sender] or 0) < LiveOpsConfig.Messaging.DirectMessageCooldown then
        return false, "Esperá antes de enviar otro mensaje."
    end
    directCooldowns[sender] = now

    text = tostring(text or ""):sub(1, LiveOpsConfig.Messaging.DirectMessageMaxLength)
    if text == "" then return false, "Mensaje vacío." end

    local targetUserId, localTarget = findTarget(targetReference)
    if not targetUserId then return false, "No encontré ese usuario." end
    if targetUserId == sender.UserId then return false, "No podés enviarte un mensaje a vos mismo." end

    local filtered, filterError = filterForUser(sender, targetUserId, text)
    if not filtered then return false, filterError end

    local payload = {
        FromUserId = sender.UserId,
        FromName = sender.DisplayName,
        Text = filtered,
        SentAt = os.time(),
    }

    if localTarget and remotes and remotes:FindFirstChild("DirectMessage") then
        remotes.DirectMessage:FireClient(localTarget, sender.DisplayName, sender.UserId, filtered)
        return true, "Mensaje enviado."
    end

    local ok = publish(LiveOpsConfig.Messaging.DirectTopicPrefix .. tostring(targetUserId), payload)
    if not ok then return false, "No se pudo entregar el mensaje ahora." end
    return true, "Mensaje enviado."
end

function UniverseMessagingService.BroadcastAnnouncement(sender, text, category)
    local now = os.clock()
    if sender and now - (announceCooldowns[sender] or 0) < LiveOpsConfig.Messaging.GlobalAnnouncementCooldown then
        return false, "Esperá antes de publicar otro anuncio."
    end
    if sender then announceCooldowns[sender] = now end

    text = tostring(text or ""):sub(1, 220)
    if text == "" then return false, "Anuncio vacío." end

    local filtered = text
    if sender then
        local filteredText, err = filterForBroadcast(sender, text)
        if not filteredText then return false, err end
        filtered = filteredText
    end

    fireAnnouncement(filtered, category or "Admin")
    publish(LiveOpsConfig.Messaging.BusTopic, {
        Type = "Announcement",
        Text = filtered,
        Category = category or "Admin",
        Origin = game.JobId,
    })
    return true, "Anuncio global enviado."
end

function UniverseMessagingService.BroadcastEvent(payload)
    handleBus({ Type = "Event", Payload = payload })
    return publish(LiveOpsConfig.Messaging.BusTopic, {
        Type = "Event",
        Payload = payload,
        Origin = game.JobId,
    })
end

function UniverseMessagingService.BroadcastWeather(payload)
    handleBus({ Type = "Weather", Payload = payload })
    return publish(LiveOpsConfig.Messaging.BusTopic, {
        Type = "Weather",
        Payload = payload,
        Origin = game.JobId,
    })
end

function UniverseMessagingService.Destroy()
    if busConnection then pcall(function() busConnection:Disconnect() end) end
    for player in pairs(directConnections) do UniverseMessagingService.UnsubscribePlayer(player) end
end

return UniverseMessagingService
