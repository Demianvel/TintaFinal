local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local playerStore = DataStoreService:GetDataStore(Config.DataStoreName)

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function remote(className, name)
    local existing = remotes:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local created = Instance.new(className)
    created.Name = name
    created.Parent = remotes
    return created
end

local GetState = remote("RemoteFunction", "GetState")
local Purchase = remote("RemoteFunction", "Purchase")
local SelectDifficulty = remote("RemoteFunction", "SelectDifficulty")
local StateUpdated = remote("RemoteEvent", "StateUpdated")
local RoundUpdated = remote("RemoteEvent", "RoundUpdated")
local Victory = remote("RemoteEvent", "Victory")

local profiles = {}
local activeRuns = {}
local checkpointPositions = {}
local startPositions = {}
local lobbyPosition = Vector3.new(0, 5, 0)
local requestTimes = {}
local currentRound = {
    phase = "Esperando jugadores",
    timeLeft = 0,
    active = false,
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copied = {}
    for key, child in pairs(value) do
        copied[key] = deepCopy(child)
    end
    return copied
end

local function defaultProfile()
    return {
        Version = 1,
        Coins = 0,
        Gems = 25,
        XP = 0,
        Level = 1,
        Wins = 0,
        BattlePassXP = 0,
        BattlePassTier = 1,
        SelectedDifficulty = "Easy",
        Upgrades = {
            SpeedBoost = 0,
            HealthBoost = 0,
            RewardBoost = 0,
        },
    }
end

local function reconcile(target, template)
    for key, value in pairs(template) do
        if target[key] == nil then
            target[key] = deepCopy(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            reconcile(target[key], value)
        end
    end
    return target
end

local function getProfile(player)
    return profiles[player]
end

local function updateLeaderstats(player)
    local profile = getProfile(player)
    local stats = player:FindFirstChild("leaderstats")
    if not profile or not stats then
        return
    end

    local mapping = {
        Coins = profile.Coins,
        Gems = profile.Gems,
        Wins = profile.Wins,
        Level = profile.Level,
    }

    for name, value in pairs(mapping) do
        local stat = stats:FindFirstChild(name)
        if stat then
            stat.Value = value
        end
    end
end

local function publicState(player)
    local profile = getProfile(player)
    if not profile then
        return nil
    end
    return {
        Coins = profile.Coins,
        Gems = profile.Gems,
        XP = profile.XP,
        Level = profile.Level,
        Wins = profile.Wins,
        BattlePassXP = profile.BattlePassXP,
        BattlePassTier = profile.BattlePassTier,
        SelectedDifficulty = profile.SelectedDifficulty,
        Upgrades = deepCopy(profile.Upgrades),
        Round = deepCopy(currentRound),
    }
end

local function pushState(player)
    updateLeaderstats(player)
    local state = publicState(player)
    if state then
        StateUpdated:FireClient(player, state)
    end
end

local function saveProfile(player)
    local profile = getProfile(player)
    if not profile then
        return true
    end

    local key = "user_" .. player.UserId
    local snapshot = deepCopy(profile)
    local success, errorMessage = pcall(function()
        playerStore:UpdateAsync(key, function()
            return snapshot
        end)
    end)

    if not success then
        warn("No se pudo guardar a " .. player.Name .. ": " .. tostring(errorMessage))
    end
    return success
end

local function loadProfile(player)
    local profile = defaultProfile()
    local key = "user_" .. player.UserId
    local success, stored = pcall(function()
        return playerStore:GetAsync(key)
    end)

    if success and type(stored) == "table" then
        profile = reconcile(stored, profile)
    elseif not success then
        warn("No se pudo cargar a " .. player.Name .. ". Se usarán datos temporales.")
    end

    profiles[player] = profile

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    for _, name in ipairs({ "Coins", "Gems", "Wins", "Level" }) do
        local value = Instance.new("IntValue")
        value.Name = name
        value.Parent = leaderstats
    end

    updateLeaderstats(player)
end

local function addXP(profile, amount)
    profile.XP += amount
    while profile.XP >= profile.Level * 100 do
        profile.XP -= profile.Level * 100
        profile.Level += 1
        if profile.Level % 5 == 0 then
            profile.Gems += 10
        end
    end
end

local function addBattlePassXP(profile, amount)
    profile.BattlePassXP += amount
    profile.BattlePassTier = math.clamp(
        math.floor(profile.BattlePassXP / Config.BattlePassXpPerTier) + 1,
        1,
        Config.BattlePassMaxTier
    )
end

local function applyUpgrades(player, character)
    local profile = getProfile(player)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not profile or not humanoid then
        return
    end

    humanoid.WalkSpeed = 16 + (profile.Upgrades.SpeedBoost or 0) * 2
    humanoid.MaxHealth = 100 + (profile.Upgrades.HealthBoost or 0) * 10
    humanoid.Health = humanoid.MaxHealth
end

local function teleportPlayer(player, position)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
    end
end

local function playerFromHit(hit)
    local character = hit and hit.Parent
    if not character then
        return nil
    end
    return Players:GetPlayerFromCharacter(character)
end

local function makePart(parent, name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.Position = position
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function finishPlayer(player, difficultyName)
    local run = activeRuns[player]
    local profile = getProfile(player)
    local difficulty = Config.Difficulties[difficultyName]
    if not run or run.finished or not profile or not difficulty then
        return
    end

    run.finished = true
    local multiplier = 1 + (profile.Upgrades.RewardBoost or 0) * 0.25
    local coinsWon = math.floor(difficulty.RewardCoins * multiplier)

    profile.Coins += coinsWon
    profile.Wins += 1
    addXP(profile, difficulty.RewardXp)
    addBattlePassXP(profile, difficulty.RewardBattlePassXp)

    if difficultyName == "Hard" then
        profile.Gems += 5
    end

    pushState(player)
    Victory:FireClient(player, {
        Difficulty = difficulty.DisplayName,
        Coins = coinsWon,
        XP = difficulty.RewardXp,
        BattlePassXP = difficulty.RewardBattlePassXp,
        Wins = profile.Wins,
    })

    task.delay(6, function()
        if player.Parent then
            teleportPlayer(player, lobbyPosition)
        end
    end)
end

local function generateMap()
    local old = Workspace:FindFirstChild("GeneratedMap")
    if old then
        old:Destroy()
    end

    local map = Instance.new("Folder")
    map.Name = "GeneratedMap"
    map.Parent = Workspace

    makePart(map, "LobbyFloor", Vector3.new(110, 2, 110), Vector3.new(0, -1, 0), Color3.fromRGB(36, 40, 52), Enum.Material.Slate)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LobbySpawn"
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Size = Vector3.new(14, 1, 14)
    spawn.Position = Vector3.new(0, 1, 0)
    spawn.Color = Color3.fromRGB(70, 190, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Parent = map
    lobbyPosition = spawn.Position

    local difficultyColors = {
        Easy = Color3.fromRGB(70, 210, 120),
        Normal = Color3.fromRGB(255, 185, 65),
        Hard = Color3.fromRGB(235, 75, 90),
    }

    local courseSettings = {
        Easy = { platformSize = 18, spacing = 16 },
        Normal = { platformSize = 14, spacing = 18 },
        Hard = { platformSize = 10, spacing = 20 },
    }

    for index, difficultyName in ipairs(Config.DifficultyOrder) do
        local laneX = (index - 2) * 120
        local startZ = 95
        local settings = courseSettings[difficultyName]
        local color = difficultyColors[difficultyName]
        local course = Instance.new("Folder")
        course.Name = difficultyName .. "Course"
        course.Parent = map

        checkpointPositions[difficultyName] = {}

        for checkpoint = 1, Config.CheckpointCount do
            local sideOffset = ((checkpoint % 3) - 1) * 6
            local height = 4 + math.floor((checkpoint - 1) / 3) * 2
            local position = Vector3.new(laneX + sideOffset, height, startZ + checkpoint * settings.spacing)
            checkpointPositions[difficultyName][checkpoint] = position

            local platform = makePart(
                course,
                "Checkpoint_" .. checkpoint,
                Vector3.new(settings.platformSize, 2, settings.platformSize),
                position,
                color,
                checkpoint % 4 == 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
            )
            platform:SetAttribute("Difficulty", difficultyName)
            platform:SetAttribute("Checkpoint", checkpoint)

            platform.Touched:Connect(function(hit)
                local player = playerFromHit(hit)
                local run = player and activeRuns[player]
                if run and not run.finished and run.difficulty == difficultyName and checkpoint > run.checkpoint then
                    run.checkpoint = checkpoint
                end
            end)
        end

        startPositions[difficultyName] = checkpointPositions[difficultyName][1]
        local lastPosition = checkpointPositions[difficultyName][Config.CheckpointCount]
        local goal = makePart(
            course,
            "Goal",
            Vector3.new(settings.platformSize + 4, 3, settings.platformSize + 4),
            lastPosition + Vector3.new(0, 3, settings.spacing),
            Color3.fromRGB(255, 225, 80),
            Enum.Material.Neon
        )

        goal.Touched:Connect(function(hit)
            local player = playerFromHit(hit)
            local run = player and activeRuns[player]
            if run and run.difficulty == difficultyName then
                finishPlayer(player, difficultyName)
            end
        end)
    end

    local killFloor = makePart(
        map,
        "KillFloor",
        Vector3.new(430, 4, 520),
        Vector3.new(0, -22, 260),
        Color3.fromRGB(170, 30, 40),
        Enum.Material.Neon
    )
    killFloor.Transparency = 0.25
    killFloor.Touched:Connect(function(hit)
        local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end)
end

local function rateLimit(player, action)
    requestTimes[player] = requestTimes[player] or {}
    local now = os.clock()
    local previous = requestTimes[player][action] or 0
    if now - previous < 0.3 then
        return false
    end
    requestTimes[player][action] = now
    return true
end

GetState.OnServerInvoke = function(player)
    return publicState(player)
end

Purchase.OnServerInvoke = function(player, itemId)
    if not rateLimit(player, "Purchase") then
        return false, "Esperá un momento."
    end

    local profile = getProfile(player)
    local item = Config.Shop[itemId]
    if not profile or not item then
        return false, "Producto inválido."
    end

    local purchases = profile.Upgrades[itemId] or 0
    if purchases >= item.MaxPurchases then
        return false, "Ya alcanzaste el nivel máximo."
    end

    local balance = profile[item.Currency]
    if type(balance) ~= "number" or balance < item.Price then
        return false, "No tenés saldo suficiente."
    end

    profile[item.Currency] -= item.Price
    profile.Upgrades[itemId] = purchases + 1

    if player.Character then
        applyUpgrades(player, player.Character)
    end
    pushState(player)
    return true, "Compra realizada.", publicState(player)
end

SelectDifficulty.OnServerInvoke = function(player, difficultyName)
    if not rateLimit(player, "Difficulty") then
        return false, "Esperá un momento."
    end

    local profile = getProfile(player)
    local difficulty = Config.Difficulties[difficultyName]
    if not profile or not difficulty then
        return false, "Dificultad inválida."
    end

    if profile.Wins < difficulty.RequiredWins then
        return false, "Necesitás " .. difficulty.RequiredWins .. " victorias."
    end

    profile.SelectedDifficulty = difficultyName
    pushState(player)
    return true, "Dificultad seleccionada.", publicState(player)
end

local function allFinished()
    local found = false
    for player, run in pairs(activeRuns) do
        if player.Parent then
            found = true
            if not run.finished then
                return false
            end
        end
    end
    return found
end

local function startRound()
    activeRuns = {}
    currentRound.active = true
    currentRound.phase = "Ronda en curso"
    currentRound.timeLeft = Config.RoundSeconds

    for _, player in ipairs(Players:GetPlayers()) do
        local profile = getProfile(player)
        if profile then
            local difficultyName = profile.SelectedDifficulty
            local difficulty = Config.Difficulties[difficultyName]
            if not difficulty or profile.Wins < difficulty.RequiredWins then
                difficultyName = "Easy"
                profile.SelectedDifficulty = difficultyName
            end

            activeRuns[player] = {
                difficulty = difficultyName,
                checkpoint = 1,
                finished = false,
            }
            teleportPlayer(player, startPositions[difficultyName])
            pushState(player)
        end
    end

    for timeLeft = Config.RoundSeconds, 0, -1 do
        currentRound.timeLeft = timeLeft
        RoundUpdated:FireAllClients(deepCopy(currentRound))
        if allFinished() then
            break
        end
        task.wait(1)
    end

    currentRound.active = false
    currentRound.phase = "Ronda finalizada"
    currentRound.timeLeft = 0
    RoundUpdated:FireAllClients(deepCopy(currentRound))

    for player in pairs(activeRuns) do
        if player.Parent then
            teleportPlayer(player, lobbyPosition)
        end
    end
    activeRuns = {}
end

Players.PlayerAdded:Connect(function(player)
    loadProfile(player)

    player.CharacterAdded:Connect(function(character)
        applyUpgrades(player, character)
        task.wait(0.5)
        local run = activeRuns[player]
        if run and not run.finished then
            local positions = checkpointPositions[run.difficulty]
            local destination = positions and positions[run.checkpoint]
            if destination then
                teleportPlayer(player, destination)
            end
        end
    end)

    if player.Character then
        task.spawn(applyUpgrades, player, player.Character)
    end

    pushState(player)
end)

Players.PlayerRemoving:Connect(function(player)
    saveProfile(player)
    profiles[player] = nil
    activeRuns[player] = nil
    requestTimes[player] = nil
end)

generateMap()

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        if not profiles[player] then
            loadProfile(player)
        end
    end)
end

task.spawn(function()
    while true do
        if #Players:GetPlayers() == 0 then
            currentRound.phase = "Esperando jugadores"
            currentRound.timeLeft = 0
            task.wait(2)
        else
            currentRound.active = false
            currentRound.phase = "Próxima ronda"
            for timeLeft = Config.IntermissionSeconds, 0, -1 do
                currentRound.timeLeft = timeLeft
                RoundUpdated:FireAllClients(deepCopy(currentRound))
                task.wait(1)
            end
            startRound()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            saveProfile(player)
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveProfile(player)
    end
    task.wait(2)
end)
