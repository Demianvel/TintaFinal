local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain

local LiveOpsConfig = require(ReplicatedStorage.Shared.LiveOpsConfig)

local WeatherService = {}
local remotes
local currentId = LiveOpsConfig.Weather.Default
local overrideToken = 0
local overrideActive = false
local rotationIndex = 1

local function ensureAtmosphere()
    local atmosphere = Lighting:FindFirstChild("TintaFinalAtmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "TintaFinalAtmosphere"
        atmosphere.Parent = Lighting
    end
    return atmosphere
end

local function ensureClouds()
    local clouds = Terrain:FindFirstChild("TintaFinalClouds")
    if not clouds then
        clouds = Instance.new("Clouds")
        clouds.Name = "TintaFinalClouds"
        clouds.Parent = Terrain
    end
    return clouds
end

local function ensureColorCorrection()
    local effect = Lighting:FindFirstChild("TintaFinalWeatherColor")
    if not effect then
        effect = Instance.new("ColorCorrectionEffect")
        effect.Name = "TintaFinalWeatherColor"
        effect.Parent = Lighting
    end
    return effect
end

local function publicState()
    local profile = LiveOpsConfig.Weather.Profiles[currentId] or LiveOpsConfig.Weather.Profiles[LiveOpsConfig.Weather.Default]
    return {
        Id = currentId,
        DisplayName = profile.DisplayName,
        ClockTime = profile.ClockTime,
        RainIntensity = profile.RainIntensity or 0,
        Wind = profile.Wind or Vector3.zero,
        Override = overrideActive,
    }
end

local function broadcast()
    if remotes and remotes:FindFirstChild("WeatherState") then
        remotes.WeatherState:FireAllClients(publicState())
    end
end

local function applyProfile(id)
    local profile = LiveOpsConfig.Weather.Profiles[id]
    if not profile then return false, "Clima inválido." end

    currentId = id
    Lighting.ClockTime = profile.ClockTime or 14
    Lighting.Brightness = profile.Brightness or 2
    Lighting.Ambient = profile.Ambient or Color3.fromRGB(90, 90, 100)
    Lighting.OutdoorAmbient = profile.OutdoorAmbient or profile.Ambient or Color3.fromRGB(90, 90, 100)
    Lighting.EnvironmentDiffuseScale = 0.55
    Lighting.EnvironmentSpecularScale = 0.65
    Lighting.GlobalShadows = true

    local atmosphere = ensureAtmosphere()
    atmosphere.Density = math.clamp(profile.AtmosphereDensity or 0.25, 0, 1)
    atmosphere.Haze = math.max(0, profile.AtmosphereHaze or 1)
    atmosphere.Glare = id == "Sunset" and 0.35 or 0.08
    atmosphere.Color = id == "Storm" and Color3.fromRGB(160, 175, 205) or Color3.fromRGB(205, 215, 235)
    atmosphere.Decay = id == "Sunset" and Color3.fromRGB(245, 145, 110) or Color3.fromRGB(105, 125, 160)

    local clouds = ensureClouds()
    clouds.Cover = math.clamp(profile.CloudsCover or 0.1, 0, 1)
    clouds.Density = math.clamp(profile.CloudsDensity or 0.15, 0, 1)
    clouds.Color = id == "Storm" and Color3.fromRGB(95, 105, 125) or Color3.fromRGB(220, 225, 235)

    local color = ensureColorCorrection()
    color.Contrast = id == "Night" and 0.08 or (id == "Storm" and 0.16 or 0.04)
    color.Saturation = (id == "Rain" or id == "Storm" or id == "Cloudy") and -0.16 or 0.02
    color.Brightness = id == "Storm" and -0.08 or 0
    color.TintColor = id == "Sunset" and Color3.fromRGB(255, 214, 196) or Color3.fromRGB(245, 248, 255)

    pcall(function()
        workspace.GlobalWind = profile.Wind or Vector3.zero
    end)

    workspace:SetAttribute("TintaWeatherId", id)
    workspace:SetAttribute("TintaRainIntensity", profile.RainIntensity or 0)
    broadcast()
    return true, profile.DisplayName
end

function WeatherService.Initialize(remoteFolder)
    remotes = remoteFolder
    applyProfile(currentId)
end

function WeatherService.GetState()
    return publicState()
end

function WeatherService.SetWeather(id)
    id = tostring(id or "")
    return applyProfile(id)
end

function WeatherService.SetOverride(id, seconds)
    local profile = LiveOpsConfig.Weather.Profiles[id]
    if not profile then return false, "Clima inválido." end
    overrideToken += 1
    local token = overrideToken
    overrideActive = true
    applyProfile(id)

    seconds = math.max(0, tonumber(seconds) or 0)
    if seconds > 0 then
        task.delay(seconds, function()
            if token ~= overrideToken then return end
            overrideActive = false
            applyProfile(LiveOpsConfig.Weather.Default)
        end)
    end
    return true, profile.DisplayName
end

function WeatherService.ClearOverride()
    overrideToken += 1
    overrideActive = false
    return applyProfile(LiveOpsConfig.Weather.Default)
end

function WeatherService.ApplyRemote(payload)
    if type(payload) ~= "table" then return end
    local id = tostring(payload.Id or "")
    if LiveOpsConfig.Weather.Profiles[id] then
        overrideActive = payload.Override == true
        applyProfile(id)
    end
end

function WeatherService.StartAutoRotation()
    if not LiveOpsConfig.Weather.AutoRotate then return end
    task.spawn(function()
        while true do
            task.wait(LiveOpsConfig.Weather.RotationSeconds)
            if not overrideActive then
                rotationIndex = (rotationIndex % #LiveOpsConfig.Weather.Order) + 1
                applyProfile(LiveOpsConfig.Weather.Order[rotationIndex])
            end
        end
    end)
end

return WeatherService
