-- Server-authoritative, non-graphic ink blaster for guard rounds.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local TOOL_NAME = "Bláster de Tinta"
local RANGE = 85
local COOLDOWN = 1.15
local cooldowns = {}

local function removeTool(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    local inBackpack = backpack and backpack:FindFirstChild(TOOL_NAME)
    local equipped = character and character:FindFirstChild(TOOL_NAME)
    if inBackpack then
        inBackpack:Destroy()
    end
    if equipped then
        equipped:Destroy()
    end
end

local function tracer(origin, destination, color)
    local distance = (destination - origin).Magnitude
    if distance <= 0 then
        return
    end
    local beam = Instance.new("Part")
    beam.Name = "TintaTracer"
    beam.Anchored = true
    beam.CanCollide = false
    beam.CanQuery = false
    beam.CanTouch = false
    beam.Material = Enum.Material.Neon
    beam.Color = color
    beam.Transparency = 0.1
    beam.Size = Vector3.new(0.22, 0.22, distance)
    beam.CFrame = CFrame.lookAt((origin + destination) / 2, destination)
    beam.Parent = workspace
    Debris:AddItem(beam, 0.14)
end

local function validTarget(shooter, target)
    if not target or target == shooter or not target.Parent then
        return false
    end
    if shooter:GetAttribute("MatchRole") ~= "Guard" then
        return false
    end
    if not target:GetAttribute("AliveInMatch") then
        return false
    end
    if target:GetAttribute("MatchRole") == "Guard" then
        return false
    end
    return true
end

local function fire(player)
    if player:GetAttribute("MatchRole") ~= "Guard" then
        return
    end

    local now = os.clock()
    if now - (cooldowns[player] or 0) < COOLDOWN then
        return
    end
    cooldowns[player] = now

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")
    if not character or not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    local origin = head and head.Position or root.Position
    local direction = root.CFrame.LookVector * RANGE
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)
    local destination = result and result.Position or (origin + direction)
    tracer(origin, destination, Color3.fromRGB(0, 226, 239))

    if not result or not result.Instance then
        return
    end

    local targetCharacter = result.Instance:FindFirstAncestorOfClass("Model")
    local target = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
    if not validTarget(player, target) then
        return
    end

    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if targetHumanoid and targetHumanoid.Health > 0 then
        target:SetAttribute("MarkedByInk", player.UserId)
        target:SetAttribute("InkMarkedAt", os.time())
        targetHumanoid.Health = 0
    end
end

local function createTool(player)
    removeTool(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = TOOL_NAME
    tool.ToolTip = "Marcá rivales durante las rondas de guardias"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.Grip = CFrame.new(0, -0.2, -0.8) * CFrame.Angles(0, math.rad(90), 0)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.7, 0.7, 2.4)
    handle.Color = Color3.fromRGB(18, 22, 35)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    local barrel = Instance.new("Part")
    barrel.Name = "NeonBarrel"
    barrel.Size = Vector3.new(0.28, 0.28, 2.6)
    barrel.Color = Color3.fromRGB(0, 226, 239)
    barrel.Material = Enum.Material.Neon
    barrel.CanCollide = false
    barrel.Massless = true
    barrel.CFrame = handle.CFrame
    barrel.Parent = tool

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = barrel
    weld.Parent = handle

    tool.Activated:Connect(function()
        fire(player)
    end)
    tool.Parent = backpack
end

local function syncPlayer(player)
    task.defer(function()
        if player:GetAttribute("MatchRole") == "Guard" then
            createTool(player)
        else
            removeTool(player)
        end
    end)
end

local function setupPlayer(player)
    player:GetAttributeChangedSignal("MatchRole"):Connect(function()
        syncPlayer(player)
    end)
    player.CharacterAdded:Connect(function()
        task.wait(0.6)
        syncPlayer(player)
    end)
    syncPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

print("[TintaFinal] Arsenal de tinta controlado por servidor habilitado.")
