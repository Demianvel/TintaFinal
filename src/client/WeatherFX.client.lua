local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeatherState = remotes:WaitForChild("WeatherState")

local holder = Instance.new("Part")
holder.Name = "TintaFinalLocalWeather"
holder.Size = Vector3.new(1, 1, 1)
holder.Transparency = 1
holder.Anchored = true
holder.CanCollide = false
holder.CanQuery = false
holder.CanTouch = false
holder.Parent = workspace

local attachment = Instance.new("Attachment")
attachment.Name = "RainEmitterAttachment"
attachment.Parent = holder

local rain = Instance.new("ParticleEmitter")
rain.Name = "TintaRain"
rain.Enabled = false
rain.Rate = 0
rain.Lifetime = NumberRange.new(0.45, 0.7)
rain.Speed = NumberRange.new(95, 120)
rain.Acceleration = Vector3.new(8, -120, 4)
rain.EmissionDirection = Enum.NormalId.Bottom
rain.SpreadAngle = Vector2.new(7, 7)
rain.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.08),
    NumberSequenceKeypoint.new(1, 0.03),
})
rain.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.28),
    NumberSequenceKeypoint.new(0.8, 0.45),
    NumberSequenceKeypoint.new(1, 1),
})
rain.Color = ColorSequence.new(Color3.fromRGB(190, 220, 255), Color3.fromRGB(105, 155, 220))
rain.LightInfluence = 0.3
rain.Parent = attachment

local current = { Id = "ClearDay", RainIntensity = 0, Wind = Vector3.zero }
local lightningToken = 0

local function apply(state)
    if type(state) ~= "table" then return end
    current = state
    local intensity = math.clamp(tonumber(state.RainIntensity) or 0, 0, 1)
    rain.Enabled = intensity > 0.02
    rain.Rate = 250 + 1_100 * intensity
    rain.Speed = NumberRange.new(85 + 25 * intensity, 110 + 35 * intensity)

    lightningToken += 1
    local token = lightningToken
    if tostring(state.Id) == "Storm" then
        task.spawn(function()
            while token == lightningToken and tostring(current.Id) == "Storm" do
                task.wait(math.random(7, 15))
                if token ~= lightningToken then break end
                local oldBrightness = Lighting.Brightness
                Lighting.Brightness = math.max(oldBrightness, 4.6)
                task.wait(0.055)
                Lighting.Brightness = oldBrightness
                task.wait(0.08)
                Lighting.Brightness = math.max(oldBrightness, 3.5)
                task.wait(0.045)
                Lighting.Brightness = oldBrightness
            end
        end)
    end
end

WeatherState.OnClientEvent:Connect(apply)

RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local wind = current.Wind
    if typeof(wind) ~= "Vector3" then wind = Vector3.zero end
    local position = camera.CFrame.Position + Vector3.new(wind.X * 0.3, 38, wind.Z * 0.3)
    holder.CFrame = CFrame.new(position)
end)

player.AncestryChanged:Connect(function(_, parent)
    if not parent and holder then holder:Destroy() end
end)
