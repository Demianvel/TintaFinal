-- Professional runtime configuration and health metadata for Tinta Final.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EXPECTED_MAX_PLAYERS = 100
local BUILD = "2026.08.06-professional.1"
local startedAt = os.time()

local deadline = os.clock() + 20
while not Workspace:GetAttribute("LegacyEternalContentRemoved") and os.clock() < deadline do
    task.wait(0.1)
end

Workspace.StreamingEnabled = true
pcall(function()
    Workspace.StreamingMinRadius = 64
    Workspace.StreamingTargetRadius = 256
end)
Workspace.FallenPartsDestroyHeight = -220
Players.RespawnTime = 3

local function updatePopulation()
    Workspace:SetAttribute("TintaFinalPlayerCount", #Players:GetPlayers())
end

Workspace:SetAttribute("TintaFinalBuild", BUILD)
Workspace:SetAttribute("TintaFinalServerStartedAt", startedAt)
Workspace:SetAttribute("TintaFinalExpectedMaxPlayers", EXPECTED_MAX_PLAYERS)
Workspace:SetAttribute("TintaFinalActualMaxPlayers", Players.MaxPlayers)
Workspace:SetAttribute("TintaFinalUniverseId", game.GameId)
Workspace:SetAttribute("TintaFinalPlaceId", game.PlaceId)
Workspace:SetAttribute("TintaFinalJobId", game.JobId)
Workspace:SetAttribute("TintaFinalServerReady", true)
updatePopulation()

Players.PlayerAdded:Connect(updatePopulation)
Players.PlayerRemoving:Connect(function()
    task.defer(updatePopulation)
end)

if not RunService:IsStudio() and Players.MaxPlayers < EXPECTED_MAX_PLAYERS then
    warn(string.format(
        "[TintaFinal] El código soporta %d jugadores, pero Creator Dashboard tiene MaxPlayers=%d.",
        EXPECTED_MAX_PLAYERS,
        Players.MaxPlayers
    ))
end

local frames = 0
local elapsed = 0
RunService.Heartbeat:Connect(function(deltaTime)
    frames += 1
    elapsed += deltaTime
    if elapsed >= 5 then
        local average = elapsed / math.max(frames, 1)
        local estimatedFps = math.floor((1 / math.max(average, 0.001)) + 0.5)
        Workspace:SetAttribute("TintaFinalServerFPS", estimatedFps)
        Workspace:SetAttribute("TintaFinalUptime", os.time() - startedAt)
        frames = 0
        elapsed = 0
    end
end)

print(string.format(
    "[TintaFinal] Servidor profesional listo. Build=%s | Place=%s | MaxPlayers=%d",
    BUILD,
    tostring(game.PlaceId),
    Players.MaxPlayers
))
