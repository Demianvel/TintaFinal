local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Games = require(ReplicatedStorage.Shared.MinigameDefinitions)
local ProfileService = require(script.Parent.ProfileService)
local MapService = require(script.Parent.MapService)
local AudioService = require(script.Parent.AudioService)

local GameService = {}

local remotes
local state = {
    Phase = "Booting",
    TimeLeft = 0,
    MatchStage = 0,
    CurrentGame = nil,
    OfferedGames = {},
    Votes = {},
    AliveCount = 0,
    GuardCount = 0,
    Announcement = "Preparando Tinta Final...",
}

local votesByPlayer = {}
local alive = {}
local participants = {}
local guards = {}
local afkPlayers = {}
local afkEarned = {}
local currentArena
local currentGameId
local matchRunning = false
local eliminationLocked = false

local function countMap(map)
    local total = 0
    for player, enabled in pairs(map) do
        if enabled and player.Parent then
            total += 1
        end
    end
    return total
end

local function activePlayers()
    local result = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if not afkPlayers[player] and ProfileService.Get(player) then
            table.insert(result, player)
        end
    end
    return result
end

local function publicState()
    local votes = {}
    for gameId, amount in pairs(state.Votes) do
        votes[gameId] = amount
    end
    return {
        Phase = state.Phase,
        TimeLeft = state.TimeLeft,
        MatchStage = state.MatchStage,
        CurrentGame = state.CurrentGame,
        OfferedGames = table.clone(state.OfferedGames),
        Votes = votes,
        AliveCount = countMap(alive),
        GuardCount = countMap(guards),
        Announcement = state.Announcement,
    }
end

local function broadcast()
    state.AliveCount = countMap(alive)
    state.GuardCount = countMap(guards)
    remotes.GameState:FireAllClients(publicState())
end

local function setPhase(phase, announcement)
    state.Phase = phase
    state.Announcement = announcement or phase
    broadcast()
end

local function countdown(seconds, phase, announcement)
    state.Phase = phase
    state.Announcement = announcement or phase
    for remaining = seconds, 0, -1 do
        state.TimeLeft = remaining
        broadcast()
        task.wait(1)
    end
end

local function eliminate(player, reason, byGuard)
    if eliminationLocked or not alive[player] then
        return false
    end

    alive[player] = false
    player:SetAttribute("AliveInMatch", false)
    player:SetAttribute("EliminationReason", reason or "Eliminado")
    MapService.Teleport(player, MapService.GetPoint("Spectator"))
    AudioService.PlayEffect("EliminationSound")
    remotes.Eliminated:FireClient(player, reason or "Quedaste eliminado de esta etapa.")

    if byGuard and guards[byGuard] then
        local profile = ProfileService.Get(byGuard)
        if profile then
            profile.Stats.EliminationsAsGuard += 1
            ProfileService.AddWon(byGuard, 250)
        end
    end

    broadcast()
    return true
end

local function survivorList()
    local result = {}
    for player, enabled in pairs(alive) do
        if enabled and player.Parent then
            table.insert(result, player)
        end
    end
    return result
end

local function teleportList(playersList, positions)
    for index, player in ipairs(playersList) do
        local position = positions[((index - 1) % #positions) + 1]
        MapService.Teleport(player, position)
    end
end

local function pointInsidePart(position, target)
    local localPoint = target.CFrame:PointToObjectSpace(position)
    local half = target.Size / 2
    return math.abs(localPoint.X) <= half.X
        and math.abs(localPoint.Y) <= half.Y + 8
        and math.abs(localPoint.Z) <= half.Z
end

local function selectGuards(playersList)
    table.clear(guards)
    local queued = {}
    for _, player in ipairs(playersList) do
        local profile = ProfileService.Get(player)
        if profile and profile.GuardQueued then
            table.insert(queued, player)
        end
    end

    local maxForServer = math.min(
        Config.Roles.MaxGuards,
        math.max(1, math.ceil(#playersList / Config.Roles.PlayersPerGuard))
    )

    for index = 1, math.min(maxForServer, #queued) do
        local player = queued[index]
        guards[player] = true
        local profile = ProfileService.Get(player)
        if profile then
            profile.GuardQueued = false
        end
        player:SetAttribute("MatchRole", "Guard")
    end
end

local function createGuardTool(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end

    local old = backpack:FindFirstChild("Marcador de Guardia")
    if old then
        old:Destroy()
    end

    local tool = Instance.new("Tool")
    tool.Name = "Marcador de Guardia"
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.ToolTip = "Marcá corredores dentro del alcance"
    tool.Parent = backpack

    local lastUse = 0
    tool.Activated:Connect(function()
        if currentGameId ~= "GuardHunt" or not guards[player] then
            return
        end
        if os.clock() - lastUse < Config.Roles.GuardAttackCooldown then
            return
        end
        lastUse = os.clock()

        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character }
        local result = workspace:Raycast(root.Position, root.CFrame.LookVector * Config.Roles.GuardAttackRange, params)
        local targetCharacter = result and result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
        local target = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
        if target and alive[target] and not guards[target] then
            eliminate(target, "Un guardia te marcó.", player)
        end
    end)
end

local function clearGuardTools()
    for player in pairs(guards) do
        local backpack = player:FindFirstChildOfClass("Backpack")
        local character = player.Character
        local inBackpack = backpack and backpack:FindFirstChild("Marcador de Guardia")
        local equipped = character and character:FindFirstChild("Marcador de Guardia")
        if inBackpack then
            inBackpack:Destroy()
        end
        if equipped then
            equipped:Destroy()
        end
    end
end

local function eligibleGameIds(playerCount)
    local ids = {}
    for gameId, definition in pairs(Games) do
        if playerCount >= definition.MinimumPlayers then
            table.insert(ids, gameId)
        end
    end
    table.sort(ids)
    return ids
end

local function directorOffers(playerCount, stage)
    local eligible = eligibleGameIds(playerCount)
    local offers = {}

    -- El director procedural evita repetir y favorece finales más tensos.
    if stage >= Config.Match.StagesPerMatch and table.find(eligible, "LastPlatform") then
        table.insert(offers, "LastPlatform")
    end

    while #offers < math.min(3, #eligible) do
        local candidate = eligible[math.random(1, #eligible)]
        if candidate ~= currentGameId and not table.find(offers, candidate) then
            table.insert(offers, candidate)
        end
    end

    return offers
end

local function beginVoting()
    votesByPlayer = {}
    state.Votes = {}
    state.OfferedGames = directorOffers(countMap(alive), state.MatchStage)
    for _, gameId in ipairs(state.OfferedGames) do
        state.Votes[gameId] = 0
    end

    AudioService.PlayOnly("VotingMusic")
    countdown(Config.Match.VotingSeconds, "Voting", "Votá la próxima prueba")

    local bestGame = state.OfferedGames[1]
    local bestVotes = -1
    local tied = {}
    for _, gameId in ipairs(state.OfferedGames) do
        local amount = state.Votes[gameId] or 0
        if amount > bestVotes then
            bestVotes = amount
            tied = { gameId }
        elseif amount == bestVotes then
            table.insert(tied, gameId)
        end
    end

    if #tied > 0 then
        bestGame = tied[math.random(1, #tied)]
    end
    state.OfferedGames = {}
    state.Votes = {}
    currentGameId = bestGame
    state.CurrentGame = bestGame
    return bestGame
end

local function watchFalling(duration, originY)
    local deadline = os.clock() + duration
    while os.clock() < deadline and countMap(alive) > 0 do
        for player, enabled in pairs(alive) do
            if enabled then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if not root or not humanoid or humanoid.Health <= 0 or root.Position.Y < originY - 15 then
                    eliminate(player, "Caíste fuera de la arena.")
                end
            end
        end
        task.wait(0.25)
    end
end

local function runPulseRun(definition, difficulty)
    local runners = survivorList()
    currentArena = MapService.BuildGame("PulseRun")
    teleportList(runners, currentArena.SpawnPositions)
    task.wait(3)

    local duration = math.floor(definition.BaseDuration * difficulty.TimeMultiplier)
    local deadline = os.clock() + duration
    local finished = {}

    while os.clock() < deadline and countMap(alive) > 0 do
        state.Announcement = "PULSO AZUL: avanzá"
        currentArena.Signal.Color = Color3.fromRGB(70, 190, 255)
        broadcast()
        task.wait(math.random(22, 38) / 10)

        for player, enabled in pairs(alive) do
            if enabled then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and root.Position.Z >= currentArena.Finish.Position.Z - 12 then
                    finished[player] = true
                end
            end
        end

        local snapshots = {}
        for player, enabled in pairs(alive) do
            local root = enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and not finished[player] then
                snapshots[player] = root.Position
            end
        end

        state.Announcement = "PULSO ROJO: no te muevas"
        currentArena.Signal.Color = Color3.fromRGB(235, 65, 90)
        broadcast()
        task.wait(math.random(12, 22) / 10)

        for player, oldPosition in pairs(snapshots) do
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if alive[player] and root and (root.Position - oldPosition).Magnitude > (2.8 / difficulty.HazardMultiplier) then
                eliminate(player, "Te moviste durante el pulso rojo.")
            end
        end
    end

    for player, enabled in pairs(alive) do
        if enabled then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not root or root.Position.Z < currentArena.Finish.Position.Z - 12 then
                eliminate(player, "No llegaste a la meta a tiempo.")
            end
        end
    end
end

local function runInkMemory(definition, difficulty)
    local runners = survivorList()
    currentArena = MapService.BuildGame("InkMemory")
    teleportList(runners, currentArena.SpawnPositions)
    task.wait(3)

    local rounds = math.clamp(math.floor(3 * difficulty.HazardMultiplier), 3, 5)
    for roundIndex = 1, rounds do
        if countMap(alive) == 0 then
            break
        end

        local correct = math.random(1, #currentArena.Zones)
        currentArena.Display.Color = currentArena.Zones[correct].Color
        state.Announcement = "Memorizá el color seguro"
        broadcast()
        task.wait(math.max(1.1, 2.4 / difficulty.HazardMultiplier))

        currentArena.Display.Color = Color3.fromRGB(25, 25, 30)
        state.Announcement = "Elegí una plataforma"
        broadcast()
        task.wait(math.max(3.2, 6 / difficulty.HazardMultiplier))

        for player, enabled in pairs(alive) do
            if enabled then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local correctZone = currentArena.Zones[correct]
                if not root or not pointInsidePart(root.Position, correctZone) then
                    eliminate(player, "Elegiste una plataforma incorrecta.")
                end
            end
        end
        task.wait(1.5)
    end
end

local function runFallingGrid(definition, difficulty)
    local runners = survivorList()
    currentArena = MapService.BuildGame("FallingGrid")
    teleportList(runners, currentArena.SpawnPositions)
    task.wait(3)

    local tiles = table.clone(currentArena.Tiles)
    local duration = math.floor(definition.BaseDuration * difficulty.TimeMultiplier)
    local deadline = os.clock() + duration

    while os.clock() < deadline and #tiles > 12 and countMap(alive) > 0 do
        state.Announcement = "La cuadrícula está cambiando"
        broadcast()
        task.wait(math.max(2.8, 6 / difficulty.HazardMultiplier))

        local removeCount = math.max(1, math.floor(#tiles * 0.16 * difficulty.HazardMultiplier))
        for _ = 1, math.min(removeCount, #tiles - 10) do
            local index = math.random(1, #tiles)
            local tile = table.remove(tiles, index)
            tile.Color = Color3.fromRGB(235, 70, 95)
            task.delay(0.8, function()
                if tile.Parent then
                    tile.CanCollide = false
                    tile.Transparency = 1
                end
            end)
        end

        watchFalling(1.5, currentArena.Origin.Y)
    end

    watchFalling(math.max(0, deadline - os.clock()), currentArena.Origin.Y)
end

local function runGuardHunt(definition, difficulty)
    currentArena = MapService.BuildGame("GuardHunt")
    local runners = survivorList()
    local guardList = {}
    for player, enabled in pairs(guards) do
        if enabled and player.Parent then
            table.insert(guardList, player)
            createGuardTool(player)
        end
    end

    teleportList(runners, currentArena.RunnerSpawns)
    if #guardList > 0 then
        teleportList(guardList, currentArena.GuardSpawns)
    end
    task.wait(3)

    local duration = math.floor(definition.BaseDuration * difficulty.TimeMultiplier)
    state.Announcement = #guardList > 0 and "Sobreviví a los guardias" or "Encontrá refugio y resistí"
    broadcast()
    watchFalling(duration, currentArena.Origin.Y)
    clearGuardTools()
end

local function runLastPlatform(definition, difficulty)
    local runners = survivorList()
    currentArena = MapService.BuildGame("LastPlatform")
    teleportList(runners, currentArena.SpawnPositions)
    task.wait(3)

    for ringIndex = 1, #currentArena.Rings do
        if countMap(alive) <= 1 then
            break
        end
        state.Announcement = "La arena se está reduciendo"
        broadcast()
        task.wait(math.max(3, 8 / difficulty.HazardMultiplier))

        local ring = currentArena.Rings[ringIndex]
        for _, platform in ipairs(ring) do
            platform.Color = Color3.fromRGB(235, 70, 95)
        end
        task.wait(1.2)
        for _, platform in ipairs(ring) do
            platform.CanCollide = false
            platform.Transparency = 1
        end
        watchFalling(2.5, currentArena.Origin.Y)
    end

    watchFalling(10, currentArena.Origin.Y)
end

local runnersByGame = {
    PulseRun = runPulseRun,
    InkMemory = runInkMemory,
    FallingGrid = runFallingGrid,
    GuardHunt = runGuardHunt,
    LastPlatform = runLastPlatform,
}

local function rewardStage(gameId)
    local definition = Games[gameId]
    for player, enabled in pairs(alive) do
        if enabled then
            local profile = ProfileService.Get(player)
            local difficulty = profile and Config.Difficulties[profile.SelectedDifficulty] or Config.Difficulties.Easy
            local boost = profile and (1 + (profile.Upgrades.RewardBoost or 0) * 0.10) or 1
            local amount = math.floor((definition.RewardWon + Config.Economy.StageRewardWon) * difficulty.RewardMultiplier * boost)
            ProfileService.AddWon(player, amount)
            ProfileService.AddXP(player, 80)
            ProfileService.AddBattlePassXP(player, 55)
            if profile then
                profile.Stats.StagesSurvived += 1
            end
            remotes.StageReward:FireClient(player, amount, gameId)
        end
    end
end

local function finishMatch()
    eliminationLocked = true
    local winners = survivorList()
    if #winners > 0 then
        for _, player in ipairs(winners) do
            local profile = ProfileService.Get(player)
            ProfileService.AddWon(player, Config.Match.FinalRewardWon)
            ProfileService.AddXP(player, 500)
            ProfileService.AddBattlePassXP(player, 250)
            if profile then
                profile.Wins += 1
                profile.SpinTickets += 1
            end
            remotes.Victory:FireClient(player, {
                Won = Config.Match.FinalRewardWon,
                Winners = #winners,
                Stages = state.MatchStage,
            })
        end
        AudioService.PlayOnly("VictoryMusic")
        countdown(Config.Match.ResultsSeconds, "Victory", "Los sobrevivientes ganaron la partida")
    else
        countdown(Config.Match.ResultsSeconds, "Results", "La partida terminó sin sobrevivientes")
    end

    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("AliveInMatch", false)
        player:SetAttribute("MatchRole", "Lobby")
        MapService.Teleport(player, afkPlayers[player] and MapService.GetPoint("AFK") or MapService.GetPoint("Lobby"))
    end

    clearGuardTools()
    table.clear(alive)
    table.clear(participants)
    table.clear(guards)
    state.MatchStage = 0
    state.CurrentGame = nil
    currentGameId = nil
    MapService.ClearArena()
    eliminationLocked = false
end

local function runMatch()
    matchRunning = true
    local available = activePlayers()
    selectGuards(available)
    table.clear(alive)
    table.clear(participants)

    for _, player in ipairs(available) do
        if not guards[player] then
            alive[player] = true
            participants[player] = true
            player:SetAttribute("AliveInMatch", true)
            player:SetAttribute("MatchRole", "Runner")
            local profile = ProfileService.Get(player)
            if profile then
                profile.Stats.StagesPlayed += 1
            end
        else
            MapService.Teleport(player, MapService.GetPoint("GuardLounge"))
        end
    end

    if countMap(alive) == 0 then
        matchRunning = false
        return
    end

    for stage = 1, Config.Match.StagesPerMatch do
        if countMap(alive) == 0 then
            break
        end
        state.MatchStage = stage
        local gameId = beginVoting()
        local definition = Games[gameId]

        setPhase("Preparing", "Preparando " .. definition.DisplayName)
        AudioService.PlayOnly("RoundMusic")
        task.wait(3)

        local samplePlayer = survivorList()[1]
        local profile = samplePlayer and ProfileService.Get(samplePlayer)
        local difficulty = profile and Config.Difficulties[profile.SelectedDifficulty] or Config.Difficulties.Easy
        local runner = runnersByGame[gameId]
        if runner then
            setPhase("Playing", definition.DisplayName)
            local success, message = pcall(runner, definition, difficulty)
            if not success then
                warn("Minigame failed", gameId, message)
                state.Announcement = "La prueba se reinició por seguridad"
                broadcast()
            end
        end

        rewardStage(gameId)
        countdown(Config.Match.ResultsSeconds, "StageResults", "Etapa superada")

        if countMap(alive) <= 1 and stage >= 2 then
            break
        end
    end

    finishMatch()
    matchRunning = false
end

function GameService.CastVote(player, gameId)
    if state.Phase ~= "Voting" or not alive[player] or not table.find(state.OfferedGames, gameId) then
        return false, "Voto inválido."
    end

    local previous = votesByPlayer[player]
    if previous then
        state.Votes[previous] = math.max(0, (state.Votes[previous] or 0) - 1)
    end
    votesByPlayer[player] = gameId
    state.Votes[gameId] = (state.Votes[gameId] or 0) + 1
    AudioService.PlayEffect("VoteSound")
    broadcast()
    return true, "Voto registrado."
end

function GameService.ToggleAFK(player)
    if matchRunning and alive[player] then
        return false, "No podés entrar a AFK durante una partida."
    end

    afkPlayers[player] = not afkPlayers[player]
    player:SetAttribute("AFKMode", afkPlayers[player] == true)
    if afkPlayers[player] then
        afkEarned[player] = afkEarned[player] or 0
        MapService.Teleport(player, MapService.GetPoint("AFK"))
        return true, "Entraste a la sala AFK."
    end

    MapService.Teleport(player, MapService.GetPoint("Lobby"))
    return true, "Saliste de la sala AFK."
end

function GameService.GetState()
    return publicState()
end

function GameService.OnCharacterAdded(player, character)
    ProfileService.ApplyUpgrades(player, character)
    task.wait(0.4)

    if afkPlayers[player] then
        MapService.Teleport(player, MapService.GetPoint("AFK"))
    elseif guards[player] then
        MapService.Teleport(player, MapService.GetPoint("GuardLounge"))
    elseif alive[player] and currentArena then
        -- El jugador reaparece como eliminado para impedir reingreso injusto.
        eliminate(player, "Fuiste eliminado al reaparecer.")
    else
        MapService.Teleport(player, MapService.GetPoint("Lobby"))
    end
end

function GameService.PlayerRemoving(player)
    alive[player] = nil
    participants[player] = nil
    guards[player] = nil
    afkPlayers[player] = nil
    afkEarned[player] = nil
    votesByPlayer[player] = nil
end

function GameService.Initialize(remoteFolder)
    remotes = remoteFolder
    MapService.BuildLobby()
    AudioService.Initialize()
    AudioService.PlayOnly("LobbyMusic")

    task.spawn(function()
        while true do
            task.wait(Config.Economy.AFKRewardIntervalSeconds)
            for player, enabled in pairs(afkPlayers) do
                if enabled and player.Parent then
                    local earned = afkEarned[player] or 0
                    if earned < Config.Economy.AFKSessionCapWon then
                        local reward = math.min(Config.Economy.AFKRewardWon, Config.Economy.AFKSessionCapWon - earned)
                        afkEarned[player] = earned + reward
                        local profile = ProfileService.Get(player)
                        if profile then
                            profile.Stats.AFKWonEarned += reward
                        end
                        ProfileService.AddWon(player, reward)
                        remotes.AFKReward:FireClient(player, reward, afkEarned[player])
                    end
                end
            end
        end
    end)
end

function GameService.StartLoop()
    task.spawn(function()
        while true do
            AudioService.PlayOnly("LobbyMusic")
            while #activePlayers() < Config.Match.MinimumPlayers do
                setPhase("Waiting", "Esperando jugadores")
                state.TimeLeft = 0
                task.wait(2)
            end

            countdown(Config.Match.IntermissionSeconds, "Intermission", "La próxima partida está por comenzar")
            if #activePlayers() >= Config.Match.MinimumPlayers then
                runMatch()
            end
            task.wait(2)
        end
    end)
end

return GameService
