local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

local meleeFX = remotes:FindFirstChild("MeleeFX")
if not meleeFX then
    meleeFX = Instance.new("RemoteEvent")
    meleeFX.Name = "MeleeFX"
    meleeFX.Parent = remotes
end

local meleeHit = remotes:WaitForChild("MeleeHit", 30)
if not meleeHit then
    warn("[TintaFinal] CombatFXBootstrap: MeleeHit no disponible.")
    return
end

local lastFX = {}

local function teamColor(player)
    local team = player:GetAttribute("ShooterTeam")
    if team == "Magenta" then return Color3.fromRGB(255, 45, 145) end
    return Color3.fromRGB(0, 226, 239)
end

meleeHit.OnServerEvent:Connect(function(player)
    if player:GetAttribute("InShooterMatch") ~= true or player:GetAttribute("ShooterActive") ~= true then return end

    local now = os.clock()
    if now - (lastFX[player] or 0) < 0.42 then return end
    lastFX[player] = now

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end

    meleeFX:FireAllClients(
        player.UserId,
        root.Position + Vector3.new(0, 1.5, 0),
        root.CFrame.LookVector,
        teamColor(player)
    )
end)

Players.PlayerRemoving:Connect(function(player)
    lastFX[player] = nil
end)

print("[TintaFinal] CombatFXBootstrap activo: golpes replicados como FX visual.")
