local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LiveOpsConfig = require(ReplicatedStorage.Shared.LiveOpsConfig)

local EventService = {}
local remotes
local WeatherService
local current
local eventToken = 0
local autoIndex = 0

local function resetMultipliers()
    workspace:SetAttribute("TintaXPMultiplier", 1)
    workspace:SetAttribute("TintaMoneyMultiplier", 1)
    workspace:SetAttribute("TintaSpinLuckMultiplier", 1)
    workspace:SetAttribute("TintaEventId", "")
end

local function publicState()
    if not current then
        return {
            Id = nil,
            DisplayName = "SIN EVENTO",
            Announcement = "",
            EndsAt = 0,
            XPMultiplier = 1,
            TintaMultiplier = 1,
            SpinLuckMultiplier = 1,
        }
    end
    return {
        Id = current.Id,
        DisplayName = current.DisplayName,
        Announcement = current.Announcement,
        EndsAt = current.EndsAt,
        XPMultiplier = current.XPMultiplier,
        TintaMultiplier = current.TintaMultiplier,
        SpinLuckMultiplier = current.SpinLuckMultiplier,
        Weather = current.Weather,
    }
end

local function broadcast()
    if remotes and remotes:FindFirstChild("UniverseEventState") then
        remotes.UniverseEventState:FireAllClients(publicState())
    end
end

function EventService.Initialize(remoteFolder, weatherService)
    remotes = remoteFolder
    WeatherService = weatherService
    resetMultipliers()
end

function EventService.GetState()
    return publicState()
end

function EventService.StartEvent(id, seconds)
    id = tostring(id or "")
    local definition = LiveOpsConfig.Events.Definitions[id]
    if not definition then return false, "Evento inválido." end

    eventToken += 1
    local token = eventToken
    seconds = math.max(30, math.floor(tonumber(seconds) or LiveOpsConfig.Events.DefaultDurationSeconds))
    local endsAt = workspace:GetServerTimeNow() + seconds

    current = {
        Id = id,
        DisplayName = definition.DisplayName,
        Announcement = definition.Announcement,
        EndsAt = endsAt,
        XPMultiplier = definition.XPMultiplier or 1,
        TintaMultiplier = definition.TintaMultiplier or 1,
        SpinLuckMultiplier = definition.SpinLuckMultiplier or 1,
        Weather = definition.Weather,
    }

    workspace:SetAttribute("TintaXPMultiplier", current.XPMultiplier)
    workspace:SetAttribute("TintaMoneyMultiplier", current.TintaMultiplier)
    workspace:SetAttribute("TintaSpinLuckMultiplier", current.SpinLuckMultiplier)
    workspace:SetAttribute("TintaEventId", id)

    if current.Weather and WeatherService then
        WeatherService.SetOverride(current.Weather, seconds)
    end

    broadcast()
    if remotes and remotes:FindFirstChild("GlobalAnnouncement") then
        remotes.GlobalAnnouncement:FireAllClients(current.Announcement, "Event")
    end

    task.delay(seconds, function()
        if token ~= eventToken then return end
        EventService.StopEvent()
    end)

    return true, current.DisplayName, publicState()
end

function EventService.StopEvent()
    local previous = current
    eventToken += 1
    current = nil
    resetMultipliers()
    if previous and previous.Weather and WeatherService then
        WeatherService.ClearOverride()
    end
    broadcast()
    return true, "Evento finalizado."
end

function EventService.ApplyRemote(payload)
    if type(payload) ~= "table" then return false end
    local action = tostring(payload.Action or "Start")
    if action == "Stop" then
        EventService.StopEvent()
        return true
    end
    local id = tostring(payload.Id or "")
    local remaining = tonumber(payload.Seconds)
    if payload.EndsAt then
        remaining = math.max(30, tonumber(payload.EndsAt) - workspace:GetServerTimeNow())
    end
    return EventService.StartEvent(id, remaining)
end

function EventService.StartAutoRotation()
    if not LiveOpsConfig.Events.AutoRotate then return end
    task.spawn(function()
        while true do
            task.wait(LiveOpsConfig.Events.IntervalSeconds)
            if not current then
                autoIndex = (autoIndex % #LiveOpsConfig.Events.Order) + 1
                EventService.StartEvent(LiveOpsConfig.Events.Order[autoIndex], LiveOpsConfig.Events.DefaultDurationSeconds)
            end
        end
    end)
end

return EventService
