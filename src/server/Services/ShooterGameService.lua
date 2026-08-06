local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)
local MapService = require(script.Parent.MapService)
local WeaponService = require(script.Parent.WeaponService)

local ShooterGameService = {}
local remotes
local matchRunning = false
local currentArena
local currentMode = "Survival"
local participants = {}
local afkPlayers = {}
local votesByPlayer = {}
local bots = {}
local botTouchCooldown = {}
local scores = {}
local teamScores = { Cyan = 0, Magenta = 0 }

local state = {
    Phase = "Booting",
    TimeLeft = 0,
    CurrentGame = nil,
    CurrentMap = nil,
    Mode = nil,
    OfferedGames = {},
    Votes = {},
    AliveCount = 0,
    Announcement = "Preparando Tinta Final Arena Shooter...",
    Scores = {},
    TeamScores = { Cyan = 0, Magenta = 0 },
    Wave = 0,
}

local function participantList()
    local list = {}
    for player, enabled in pairs(participants) do
        if enabled and player.Parent then table.insert(list, player) end
    end
    return list
end

local function activePlayers()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if not afkPlayers[player] and ProfileService.Get(player) then table.insert(list, player) end
    end
    return list
end

local function publicState()
    local publicScores = {}
    for userId, amount in pairs(scores) do publicScores[tostring(userId)] = amount end
    return {
        Phase = state.Phase,
        TimeLeft = state.TimeLeft,
        CurrentGame = state.CurrentGame,
        CurrentMap = state.CurrentMap,
        Mode = state.Mode,
        OfferedGames = table.clone(state.OfferedGames),
        Votes = table.clone(state.Votes),
        AliveCount = #participantList(),
        Announcement = state.Announcement,
        Scores = publicScores,
        TeamScores = { Cyan = teamScores.Cyan, Magenta = teamScores.Magenta },
        Wave = state.Wave,
    }
end

local function broadcast()
    if remotes then remotes.GameState:FireAllClients(publicState()) end
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

local function mapSpawnFor(player)
    if not currentArena then return MapService.GetPoint("Lobby") end
    if currentMode == "TeamSplash" then
        local team = player:GetAttribute("ShooterTeam")
        local list = team == "Magenta" and currentArena.MagentaSpawns or currentArena.CyanSpawns
        return list[((player.UserId % #list) + 1)]
    end
    local list = currentArena.FFASpawns
    return list[((player.UserId % #list) + 1)]
end

local function setupCombatCharacter(player, character)
    ProfileService.ApplyUpgrades(player, character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then return end
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    character:SetAttribute("TintaKillRegistered", false)
    WeaponService.ResetPlayer(player)

    if matchRunning and participants[player] then
        task.delay(0.2, function()
            if player.Parent and character.Parent then MapService.Teleport(player, mapSpawnFor(player)) end
        end)
    else
        task.delay(0.2, function()
            if player.Parent and character.Parent then MapService.Teleport(player, MapService.GetPoint("Lobby")) end
        end)
    end

    humanoid.Died:Connect(function()
        local profile = ProfileService.Get(player)
        if profile and matchRunning and participants[player] then profile.Stats.Deaths += 1 end
    end)
end

local function clearBots()
    for model in pairs(bots) do
        if model.Parent then model:Destroy() end
    end
    table.clear(bots)
    table.clear(botTouchCooldown)
end

local function nearestParticipant(position)
    local bestPlayer
    local bestDistance = math.huge
    for _, player in ipairs(participantList()) do
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if humanoid and root and humanoid.Health > 0 then
            local distance = (root.Position - position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                bestPlayer = player
            end
        end
    end
    return bestPlayer, bestDistance
end

local function spawnBot(position, wave)
    local model = Instance.new("Model")
    model.Name = "InkDrone"
    model:SetAttribute("TintaBot", true)
    model:SetAttribute("TintaKillRegistered", false)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2.4, 2.4, 1.4)
    root.Color = Color3.fromRGB(30, 33, 43)
    root.Material = Enum.Material.Metal
    root.Position = position + Vector3.new(0, 4, 0)
    root.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(3, 3.2, 1.7)
    torso.Color = Color3.fromRGB(255, 52, 138)
    torso.Material = Enum.Material.SmoothPlastic
    torso.Position = root.Position + Vector3.new(0, 1.3, 0)
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2.2, 2.2, 2.2)
    head.Color = Color3.fromRGB(0, 226, 239)
    head.Material = Enum.Material.Neon
    head.Position = root.Position + Vector3.new(0, 3.6, 0)
    head.Parent = model

    local rootJoint = Instance.new("WeldConstraint")
    rootJoint.Part0 = root
    rootJoint.Part1 = torso
    rootJoint.Parent = root
    local headJoint = Instance.new("WeldConstraint")
    headJoint.Part0 = torso
    headJoint.Part1 = head
    headJoint.Parent = torso

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 70 + wave * 18
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = math.min(17, 10 + wave)
    humanoid.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace:FindFirstChild("TintaFinalWorld") or workspace
    pcall(function() root:SetNetworkOwner(nil) end)
    bots[model] = true

    humanoid.Died:Connect(function()
        bots[model] = nil
        task.delay(2, function() if model.Parent then model:Destroy() end end)
    end)

    task.spawn(function()
        while model.Parent and humanoid.Health > 0 and matchRunning and currentMode == "Survival" do
            local target, distance = nearestParticipant(root.Position)
            if target then
                local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                    humanoid:MoveTo(targetRoot.Position)
                    if distance < 6.5 then
                        local now = os.clock()
                        if now - (botTouchCooldown[model] or 0) >= 1.1 then
                            botTouchCooldown[model] = now
                            targetHumanoid:TakeDamage(8 + wave * 2)
                        end
                    end
                end
            end
            task.wait(0.35)
        end
    end)
    return model
end

local function chooseMode(count)
    if count <= 1 then return "Survival" end
    local roll = math.random(1, 10)
    if roll <= 2 then return "Survival" end
    if roll <= 7 then return "TeamSplash" end
    return "FreeSplash"
end

local function assignTeams(playersList)
    for index, player in ipairs(playersList) do
        local team = index % 2 == 0 and "Magenta" or "Cyan"
        player:SetAttribute("ShooterTeam", currentMode == "TeamSplash" and team or "Solo")
    end
end

local function startVoting(playerCount)
    votesByPlayer = {}
    state.Votes = {}
    state.OfferedGames = table.clone(Config.Shooter.MapOrder)
    for _, mapId in ipairs(state.OfferedGames) do state.Votes[mapId] = 0 end
    countdown(Config.Match.VotingSeconds, "Voting", "Votá el próximo mapa shooter")

    local best = state.OfferedGames[1]
    local highest = -1
    local tied = {}
    for _, mapId in ipairs(state.OfferedGames) do
        local amount = state.Votes[mapId] or 0
        if amount > highest then
            highest = amount
            tied = { mapId }
        elseif amount == highest then
            table.insert(tied, mapId)
        end
    end
    if #tied > 0 then best = tied[math.random(1, #tied)] end
    state.OfferedGames = {}
    state.Votes = {}
    return best
end

local function pickup(player, pickupType, amount)
    if not matchRunning or not participants[player] then return end
    if pickupType == "Health" then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount) end
    elseif pickupType == "Ammo" then
        WeaponService.AddAmmo(player, amount)
    end
end

local function addKill(shooter, victim, headshot)
    if not matchRunning or not participants[shooter] or shooter == victim then return end
    local shooterProfile = ProfileService.Get(shooter)
    if shooterProfile then
        shooterProfile.Stats.Kills += 1
        if headshot then shooterProfile.Stats.Headshots += 1 end
    end
    ProfileService.AddWon(shooter, Config.Match.KillRewardWon)
    ProfileService.AddXP(shooter, Config.Match.KillXP)

    if currentMode == "TeamSplash" then
        local team = shooter:GetAttribute("ShooterTeam")
        if teamScores[team] then teamScores[team] += 1 end
    else
        scores[shooter.UserId] = (scores[shooter.UserId] or 0) + 1
    end
    if remotes then
        remotes.KillFeed:FireAllClients(shooter.DisplayName, victim and victim.DisplayName or "Objetivo", headshot == true)
    end
    broadcast()
end

local function addBotKill(shooter, _, headshot)
    if not matchRunning or not participants[shooter] then return end
    local profile = ProfileService.Get(shooter)
    if profile then
        profile.Stats.BotKills += 1
        if headshot then profile.Stats.Headshots += 1 end
    end
    scores[shooter.UserId] = (scores[shooter.UserId] or 0) + 1
    ProfileService.AddWon(shooter, Config.Match.BotKillRewardWon)
    ProfileService.AddXP(shooter, math.floor(Config.Match.KillXP * 0.6))
    broadcast()
end

local function runSurvival()
    local completed = true
    for wave = 1, Config.Match.SurvivalWaves do
        state.Wave = wave
        state.Announcement = "OLEADA " .. wave .. " / " .. Config.Match.SurvivalWaves
        broadcast()
        local spawns = currentArena.BotSpawns
        local count = math.min(8 + wave * 3 + #participantList() * 2, 38)
        for index = 1, count do
            spawnBot(spawns[((index - 1) % #spawns) + 1], wave)
            if index % 5 == 0 then task.wait(0.15) end
        end
        local deadline = os.clock() + math.min(42, 25 + wave * 3)
        while matchRunning and os.clock() < deadline do
            local aliveBots = 0
            for model in pairs(bots) do
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then aliveBots += 1 end
            end
            state.TimeLeft = math.max(0, math.ceil(deadline - os.clock()))
            broadcast()
            if aliveBots == 0 then break end
            task.wait(1)
        end
        local remaining = 0
        for model in pairs(bots) do
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then remaining += 1 end
        end
        if remaining > 0 then completed = false break end
        task.wait(2)
    end
    clearBots()
    return completed
end

local function combatLimitReached()
    if currentMode == "TeamSplash" then
        return teamScores.Cyan >= Config.Match.TeamScoreLimit or teamScores.Magenta >= Config.Match.TeamScoreLimit
    end
    for _, amount in pairs(scores) do
        if amount >= Config.Match.FFAScoreLimit then return true end
    end
    return false
end

local function runPvP()
    local deadline = os.clock() + Config.Match.RoundSeconds
    while matchRunning and os.clock() < deadline and not combatLimitReached() do
        state.TimeLeft = math.max(0, math.ceil(deadline - os.clock()))
        if currentMode == "TeamSplash" then
            state.Announcement = string.format("CIAN %d  -  %d MAGENTA", teamScores.Cyan, teamScores.Magenta)
        else
            state.Announcement = "TODOS CONTRA TODOS"
        end
        broadcast()
        task.wait(1)
    end
end

local function winners(survivalCompleted)
    local result = {}
    local list = participantList()
    if currentMode == "Survival" then
        if survivalCompleted then return list end
        return result
    end
    if currentMode == "TeamSplash" then
        local winningTeam = teamScores.Cyan == teamScores.Magenta and nil or (teamScores.Cyan > teamScores.Magenta and "Cyan" or "Magenta")
        if not winningTeam then return list end
        for _, player in ipairs(list) do if player:GetAttribute("ShooterTeam") == winningTeam then table.insert(result, player) end end
        return result
    end
    local bestScore = -1
    for _, player in ipairs(list) do bestScore = math.max(bestScore, scores[player.UserId] or 0) end
    for _, player in ipairs(list) do if (scores[player.UserId] or 0) == bestScore then table.insert(result, player) end end
    return result
end

local function finishMatch(survivalCompleted)
    WeaponService.SetActive(false)
    clearBots()
    local winList = winners(survivalCompleted)
    local winSet = {}
    for _, player in ipairs(winList) do winSet[player] = true end

    for _, player in ipairs(participantList()) do
        local profile = ProfileService.Get(player)
        if profile then profile.Stats.MatchesPlayed += 1 end
        ProfileService.AddWon(player, Config.Match.ParticipationWon)
        if winSet[player] then
            if profile then
                profile.Wins += 1
                profile.Stats.ShooterWins += 1
            end
            ProfileService.AddWon(player, Config.Match.FinalRewardWon)
            ProfileService.AddXP(player, Config.Match.WinXP)
            if remotes then remotes.Victory:FireClient(player, "¡Victoria en Tinta Final!") end
        end
        player:SetAttribute("InShooterMatch", false)
        player:SetAttribute("ShooterTeam", "Lobby")
        MapService.Teleport(player, MapService.GetPoint("Lobby"))
    end

    state.Announcement = #winList > 0 and "PARTIDA TERMINADA - VICTORIA REGISTRADA" or "PARTIDA TERMINADA"
    countdown(Config.Match.ResultsSeconds, "Results", state.Announcement)
    table.clear(participants)
    table.clear(scores)
    teamScores.Cyan = 0
    teamScores.Magenta = 0
    state.Wave = 0
    state.CurrentGame = nil
    state.CurrentMap = nil
    state.Mode = nil
    matchRunning = false
end

local function startMatch(mapId)
    local playersList = activePlayers()
    if #playersList < 1 then return end
    participants = {}
    scores = {}
    teamScores.Cyan = 0
    teamScores.Magenta = 0
    for _, player in ipairs(playersList) do
        participants[player] = true
        scores[player.UserId] = 0
        player:SetAttribute("InShooterMatch", true)
    end

    currentMode = chooseMode(#playersList)
    assignTeams(playersList)
    state.Mode = currentMode
    state.CurrentGame = mapId
    state.CurrentMap = mapId
    state.Announcement = "Cargando arena shooter..."
    countdown(Config.Match.LoadingSeconds, "Loading", "Cargando " .. mapId)

    currentArena = MapService.BuildGame(mapId)
    MapService.ActivatePickups(pickup)
    for _, player in ipairs(playersList) do
        MapService.Teleport(player, mapSpawnFor(player))
        WeaponService.ResetPlayer(player)
    end

    matchRunning = true
    workspace:SetAttribute("TintaFinalShooterMode", currentMode)
    WeaponService.SetActive(true)
    state.Phase = "Playing"
    state.Announcement = Config.Shooter.Modes[currentMode].DisplayName
    broadcast()

    local survivalCompleted = false
    if currentMode == "Survival" then survivalCompleted = runSurvival() else runPvP() end
    finishMatch(survivalCompleted)
end

function ShooterGameService.Initialize(remoteFolder)
    remotes = remoteFolder
    MapService.BuildLobby()
    WeaponService.Initialize(remotes, { OnPlayerKilled = addKill, OnBotKilled = addBotKill })
    workspace:SetAttribute("TintaFinalShooterMode", "Lobby")
end

function ShooterGameService.GetState() return publicState() end

function ShooterGameService.CastVote(player, mapId)
    if state.Phase ~= "Voting" then return false, "La votación ya terminó." end
    if not table.find(state.OfferedGames, mapId) then return false, "Mapa inválido." end
    local previous = votesByPlayer[player]
    if previous and state.Votes[previous] then state.Votes[previous] = math.max(0, state.Votes[previous] - 1) end
    votesByPlayer[player] = mapId
    state.Votes[mapId] = (state.Votes[mapId] or 0) + 1
    broadcast()
    return true, "Voto registrado."
end

function ShooterGameService.ToggleAFK(player)
    afkPlayers[player] = not afkPlayers[player]
    player:SetAttribute("AFKMode", afkPlayers[player] == true)
    if afkPlayers[player] then MapService.Teleport(player, MapService.GetPoint("AFK")) else MapService.Teleport(player, MapService.GetPoint("Lobby")) end
    return true, afkPlayers[player] and "Modo AFK activado." or "Modo AFK desactivado."
end

function ShooterGameService.OnCharacterAdded(player, character)
    setupCombatCharacter(player, character)
end

function ShooterGameService.PlayerRemoving(player)
    participants[player] = nil
    afkPlayers[player] = nil
    votesByPlayer[player] = nil
    WeaponService.PlayerRemoving(player)
end

function ShooterGameService.StartLoop()
    task.spawn(function()
        task.wait(2)
        while true do
            while #activePlayers() < Config.Match.MinimumPlayers do
                state.Phase = "Lobby"
                state.Announcement = "Esperando jugadores..."
                state.TimeLeft = 0
                broadcast()
                task.wait(2)
            end
            countdown(Config.Match.IntermissionSeconds, "Intermission", "Prepará tu arma en el lobby")
            local mapId = startVoting(#activePlayers())
            if mapId then startMatch(mapId) end
            task.wait(1)
        end
    end)
end

return ShooterGameService
