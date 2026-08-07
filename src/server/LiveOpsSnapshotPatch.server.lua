local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GamePassConfig = require(Shared:WaitForChild("GamePassConfig"))

local Services = script.Parent:WaitForChild("Services")
local WeatherService = require(Services:WaitForChild("WeatherService"))
local EventService = require(Services:WaitForChild("EventService"))
local GamePassService = require(Services:WaitForChild("GamePassService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getSnapshot = remotes:WaitForChild("GetSnapshot")

local deadline = os.clock() + 15
while type(getSnapshot.OnServerInvoke) ~= "function" and os.clock() < deadline do
    task.wait(0.05)
end

local original = getSnapshot.OnServerInvoke
if type(original) ~= "function" then
    warn("[TintaFinal] No se pudo ampliar GetSnapshot: callback principal no disponible.")
    return
end

getSnapshot.OnServerInvoke = function(player)
    local payload = original(player) or {}
    payload.Config = payload.Config or {}
    payload.Config.GamePasses = {
        PassOrder = GamePassConfig.PassOrder,
        Passes = GamePassService.PublicCatalog(),
    }
    payload.Config.BattlePass = payload.Config.BattlePass or {}
    payload.Config.BattlePass.MaxTier = GameConfig.BattlePass.MaxTier
    payload.Config.BattlePass.XPPerTier = GameConfig.BattlePass.XPPerTier
    payload.Config.BattlePass.FreeRewards = GameConfig.BattlePass.FreeRewards
    payload.Config.BattlePass.PremiumRewards = GameConfig.BattlePass.PremiumRewards
    payload.LiveOps = {
        Weather = WeatherService.GetState(),
        Event = EventService.GetState(),
    }
    return payload
end
