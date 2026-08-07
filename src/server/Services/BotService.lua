local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BotService = {}

local active = false
local arenaData
local remotes
local callbacks = {}
local botFolder
local bots = {}
local serial = 0
local heartbeatConnection
local random = Random.new()

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 22, 142)

local function makePart(model, name, size, color, position)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.CanCollide = name == "Torso"
    p.Massless = name ~= "Torso"
    p.Anchored = false
    p.CFrame = CFrame.new(position)
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function motor(name, part0, part1, c0, c1)
    local m = Instance.new("Motor6D")
    m.Name = name
    m.Part0 = part0
    m.Part1 = part1
    m.C0 = c0 or CFrame.new()
    m.C1 = c1 or CFrame.new()
    m.Parent = part0
    return m
end

local function buildRig(team, spawnPosition, label)
    local model = Instance.new("Model")
    model.Name = label
    model:SetAttribute("TintaBot", true)
    model:SetAttribute("ShooterTeam", team)
    model:SetAttribute("TintaKillRegistered", false)

    local accent = team == "Magenta" and MAGENTA or CYAN
    local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Color3.fromRGB(30, 32, 42), spawnPosition + Vector3.new(0, 3, 0))
    root.Transparency = 1
    local torso = makePart(model, "Torso", Vector3.new(2, 2, 1), Color3.fromRGB(28, 31, 43), spawnPosition + Vector3.new(0, 3, 0))
    local head = makePart(model, "Head", Vector3.new(2, 1, 1), accent, spawnPosition + Vector3.new(0, 4.5, 0))
    local leftArm = makePart(model, "Left Arm", Vector3.new(1, 2, 1), accent, spawnPosition + Vector3.new(-1.5, 3, 0))
    local rightArm = makePart(model, "Right Arm", Vector3.new(1, 2, 1), accent, spawnPosition + Vector3.new(1.5, 3, 0))
    local leftLeg = makePart(model, "Left Leg", Vector3.new(1, 2, 1), Color3.fromRGB(35, 38, 52), spawnPosition + Vector3.new(-0.5, 1, 0))
    local rightLeg = makePart(model, "Right Leg", Vector3.new(1, 2, 1), Color3.fromRGB(35, 38, 52), spawnPosition + Vector3.new(0.5, 1, 0))

    motor("RootJoint", root, torso)
    motor("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    motor("Left Shoulder", torso, leftArm, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    motor("Right Shoulder", torso, rightArm, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    motor("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    motor("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = 15
    humanoid.AutoRotate = true
    humanoid.DisplayName = label
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = botFolder
    model:PivotTo(CFrame.new(spawnPosition + Vector3.new(0, 4, 0)))
    pcall(function() root:SetNetworkOwner(nil) end)
    return model, humanoid, root, head
end

local function enemyCandidates(team)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("InShooterMatch") == true and player:GetAttribute("ShooterTeam") ~= team then
            local character = player.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                table.insert(list, {Model = character, Humanoid = hum, Root = root, Player = player})
            end
        end
    end
    for model, info in pairs(bots) do
        if model.Parent and info.Team ~= team and info.Humanoid and info.Humanoid.Health > 0 and info.Root then
            table.insert(list, {Model = model, Humanoid = info.Humanoid, Root = info.Root, BotInfo = info})
        end
    end
    return list
end

local function nearestEnemy(info)
    if not info.Root or not info.Root.Parent then return nil end
    local best, bestDistance
    for _, target in ipairs(enemyCandidates(info.Team)) do
        local distance = (target.Root.Position - info.Root.Position).Magnitude
        if not bestDistance or distance < bestDistance then
            best = target
            bestDistance = distance
        end
    end
    return best, bestDistance
end

local function hasLineOfSight(info, target)
    local head = info.Head
    if not head or not target or not target.Root then return false end
    local origin = head.Position
    local targetPart = target.Model:FindFirstChild("Head") or target.Root
    local direction = targetPart.Position - origin
    if direction.Magnitude < 0.1 then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {info.Model}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(target.Model), origin, targetPart.Position
end

local function scoreBotKill(info, target)
    if target.Model:GetAttribute("TintaKillRegistered") then return end
    target.Model:SetAttribute("TintaKillRegistered", true)
    if target.Player and callbacks.OnBotKilledPlayer then
        callbacks.OnBotKilledPlayer(info.Team, target.Player)
    elseif target.BotInfo and callbacks.OnBotKilledBot then
        callbacks.OnBotKilledBot(info.Team, target.Model)
    end
end

local function botShoot(info, target)
    if not active or not info.Model.Parent or not target or target.Humanoid.Health <= 0 then return end
    local visible, origin, destination = hasLineOfSight(info, target)
    if not visible then return end
    local now = os.clock()
    if now - (info.LastShot or 0) < 0.62 then return end
    info.LastShot = now

    if remotes and remotes:FindFirstChild("ShotFX") then
        remotes.ShotFX:FireAllClients(origin, destination, info.Team == "Magenta" and MAGENTA or CYAN)
    end

    local damage = random:NextInteger(10, 16)
    local before = target.Humanoid.Health
    target.Humanoid:TakeDamage(damage)
    if before > 0 and target.Humanoid.Health <= 0 then
        scoreBotKill(info, target)
    end
end

local spawnBot
spawnBot = function(team, spawnIndex)
    if not active or not arenaData then return end
    serial += 1
    local spawnList = team == "Magenta" and arenaData.MagentaSpawns or arenaData.CyanSpawns
    local spawnPosition = spawnList[((spawnIndex - 1) % #spawnList) + 1]
    local label = string.format("BOT %s %02d", team == "Magenta" and "M" or "C", serial)
    local model, humanoid, root, head = buildRig(team, spawnPosition, label)
    local info = {
        Model = model,
        Team = team,
        SpawnIndex = spawnIndex,
        Humanoid = humanoid,
        Root = root,
        Head = head,
        LastShot = 0,
        LastMove = 0,
    }
    bots[model] = info

    humanoid.Died:Connect(function()
        bots[model] = nil
        if active then
            task.delay(3, function()
                if active then spawnBot(team, spawnIndex) end
            end)
        end
        task.delay(1.5, function()
            if model.Parent then model:Destroy() end
        end)
    end)
end

local function updateBot(info)
    if not active or not info.Model.Parent or info.Humanoid.Health <= 0 then return end
    local target, distance = nearestEnemy(info)
    if not target or not distance then return end

    local now = os.clock()
    if distance > 16 and now - (info.LastMove or 0) > 0.28 then
        info.LastMove = now
        local offset = Vector3.new(random:NextNumber(-5, 5), 0, random:NextNumber(-5, 5))
        info.Humanoid:MoveTo(target.Root.Position + offset)
    elseif distance <= 16 then
        info.Humanoid:Move(Vector3.zero, false)
    end

    if distance <= 150 then botShoot(info, target) end
end

function BotService.Start(arena, teamSize, humanPlayer, remoteFolder, handlers)
    BotService.Stop()
    active = true
    arenaData = arena
    remotes = remoteFolder
    callbacks = handlers or {}
    serial = 0
    bots = {}

    botFolder = Instance.new("Folder")
    botFolder.Name = "TintaDuelBots"
    botFolder.Parent = workspace

    teamSize = math.clamp(math.floor(tonumber(teamSize) or 1), 1, 10)
    if humanPlayer then humanPlayer:SetAttribute("ShooterTeam", "Cyan") end

    for index = 1, math.max(0, teamSize - 1) do spawnBot("Cyan", index + 1) end
    for index = 1, teamSize do spawnBot("Magenta", index) end

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        for _, info in pairs(bots) do updateBot(info) end
    end)
end

function BotService.Stop()
    active = false
    if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
    if botFolder then botFolder:Destroy() botFolder = nil end
    bots = {}
    arenaData = nil
end

function BotService.GetCounts()
    local cyan, magenta = 0, 0
    for model, info in pairs(bots) do
        if model.Parent and info.Humanoid and info.Humanoid.Health > 0 then
            if info.Team == "Cyan" then cyan += 1 else magenta += 1 end
        end
    end
    return cyan, magenta
end

function BotService.IsBot(model)
    return model and model:GetAttribute("TintaBot") == true
end

return BotService
