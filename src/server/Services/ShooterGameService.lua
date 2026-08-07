local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)
local RankingService = require(script.Parent.RankingService)
local CharacterStyleService = require(script.Parent.CharacterStyleService)
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
local matchNumber = 0

local state = {
    Phase = "Booting",
    TimeLeft = 0,
    CurrentGame = nil,
    CurrentMap = nil,
    Mode = nil,
    OfferedGames = {},
    Votes = {},
    AliveCount = 0,
    Announcement = "Preparando Tinta Final Competitive Arena...",
    Scores = {},
    TeamScores = { Cyan = 0, Magenta = 0 },
    TeamCounts = { Cyan = 0, Magenta = 0 },
    Wave = 0,
    MaxParticipants = Config.Match.MaxParticipants,
    Podium = {},
    SeasonId = Config.Competitive.SeasonId,
}

local function participantList()
    local list = {}
    for player, enabled in pairs(participants) do
        if enabled and player.Parent then table.insert(list, player) end
    end
    table.sort(list, function(a, b) return a.UserId < b.UserId end)
    return list
end

local function activePlayers()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if not afkPlayers[player] and ProfileService.Get(player) then table.insert(list, player) end
    end
    table.sort(list, function(a, b)
        local aJoin = a:GetAttribute("TintaQueueTime") or 0
        local bJoin = b:GetAttribute("TintaQueueTime") or 0
        if aJoin == bJoin then return a.UserId < b.UserId end
        return aJoin < bJoin
    end)
    while #list > Config.Match.MaxParticipants do table.remove(list) end
    return list
end

local function teamCounts()
    local cyan, magenta = 0, 0
    for _, player in ipairs(participantList()) do
        if player:GetAttribute("ShooterTeam") == "Cyan" then cyan += 1 end
        if player:GetAttribute("ShooterTeam") == "Magenta" then magenta += 1 end
    end
    return cyan, magenta
end

local function publicState()
    local publicScores = {}
    for userId, amount in pairs(scores) do publicScores[tostring(userId)] = amount end
    local cyanCount, magentaCount = teamCounts()
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
        TeamCounts = { Cyan = cyanCount, Magenta = magentaCount },
        Wave = state.Wave,
        MaxParticipants = Config.Match.MaxParticipants,
        Podium = table.clone(state.Podium),
        SeasonId = Config.Competitive.SeasonId,
        ConnectedPlayers = #Players:GetPlayers(),
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
    CharacterStyleService.Apply(player, character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then return end
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    character:SetAttribute("TintaKillRegistered", false)
    WeaponService.ResetPlayer(player)

    if matchRunning and participants[player] then
        task.delay(0.2, function()
            if player.Parent and character.Parent then
                CharacterStyleService.Apply(player, character)
                MapService.Teleport(player, mapSpawnFor(player))
            end
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
    for model in pairs(bots) do if model.Parent then model:Destroy() end end
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
            if distance < bestDistance then bestDistance, bestPlayer = distance, player end
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
    rootJoint.Part0, rootJoint.Part1, rootJoint.Parent = root, torso, root
    local headJoint = Instance.new("WeldConstraint")
    headJoint.Part0, headJoint.Part1, headJoint.Parent = torso, head, torso

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
    matchNumber += 1
    -- Tres partidas por equipos y luego una FFA para mantener ambos modos activos.
    if matchNumber % 4 == 0 then return "FreeSplash" end
    return "TeamSplash"
end

local function ratingOf(player)
    local profile = ProfileService.Get(player)
    return profile and profile.CompetitiveRating or Config.Competitive.StartingRating
end

local function assignTeams(playersList)
    if currentMode ~= "TeamSplash" then
        for _, player in ipairs(playersList) do player:SetAttribute("ShooterTeam", "Solo") end
        return
    end

    local sorted = table.clone(playersList)
    table.sort(sorted, function(a, b) return ratingOf(a) > ratingOf(b) end)
    local totals = { Cyan = 0, Magenta = 0 }
    local counts = { Cyan = 0, Magenta = 0 }
    local maxPerTeam = math.ceil(#sorted / 2)

    for _, player in ipairs(sorted) do
        local team
        if counts.Cyan >= maxPerTeam then
            team = "Magenta"
        elseif counts.Magenta >= maxPerTeam then
            team = "Cyan"
        elseif totals.Cyan < totals.Magenta then
            team = "Cyan"
        elseif totals.Magenta < totals.Cyan then
            team = "Magenta"
        else
            team = counts.Cyan <= counts.Magenta and "Cyan" or "Magenta"
        end
        counts[team] += 1
        totals[team] += ratingOf(player)
        player:SetAttribute("ShooterTeam", team)
    end
end

local function startVoting()
    votesByPlayer = {}
    state.Votes = {}
    state.OfferedGames = table.clone(Config.Shooter.MapOrder)
    for _, mapId in ipairs(state.OfferedGames) do state.Votes[mapId] = 0 end
    countdown(Config.Match.VotingSeconds, "Voting", "VOTÁ EL PRÓXIMO MAPA")

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
    state.OfferedGames, state.Votes = {}, {}
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
    scores[shooter.UserId] = (scores[shooter.UserId] or 0) + 1
    ProfileService.AddTintaMoney(shooter, Config.Match.KillTintaMoney)
    ProfileService.AddXP(shooter, Config.Match.KillXP)
    ProfileService.AddSeasonPoints(shooter, Config.Competitive.KillSeasonPoints)

    if currentMode == "TeamSplash" then
        local team = shooter:GetAttribute("ShooterTeam")
        if teamScores[team] then teamScores[team] += 1 end
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
    ProfileService.AddTintaMoney(shooter, Config.Match.BotKillTintaMoney)
    ProfileService.AddXP(shooter, math.floor(Config.Match.KillXP * 0.6))
    broadcast()
end

local function runSurvival()
    local completed = true
    for wave = 1, Config.Match.SurvivalWaves do
        state.Wave = wave
        state.Announcement = "ENTRENAMIENTO · OLEADA " .. wave .. " / " .. Config.Match.SurvivalWaves
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
            local cyanCount, magentaCount = teamCounts()
            state.Announcement = string.format("CIAN %d [%d]  ·  [%d] %d MAGENTA", teamScores.Cyan, cyanCount, magentaCount, teamScores.Magenta)
        else
            state.Announcement = "TODOS CONTRA TODOS · PRIMEROS " .. Config.Match.FFAScoreLimit
        end
        broadcast()
        task.wait(1)
    end
end

local function orderedPlayers()
    local list = participantList()
    table.sort(list, function(a, b)
        local aScore, bScore = scores[a.UserId] or 0, scores[b.UserId] or 0
        if aScore == bScore then return ratingOf(a) > ratingOf(b) end
        return aScore > bScore
    end)
    return list
end

local function winners(survivalCompleted)
    local result = {}
    local list = participantList()
    if currentMode == "Survival" then return survivalCompleted and list or result end
    if currentMode == "TeamSplash" then
        local winningTeam = teamScores.Cyan == teamScores.Magenta and nil or (teamScores.Cyan > teamScores.Magenta and "Cyan" or "Magenta")
        if not winningTeam then return list end
        for _, player in ipairs(list) do
            if player:GetAttribute("ShooterTeam") == winningTeam then table.insert(result, player) end
        end
        return result
    end
    local ordered = orderedPlayers()
    if ordered[1] then table.insert(result, ordered[1]) end
    return result
end

local function buildPodium()
    state.Podium = {}
    local ordered = orderedPlayers()
    for index = 1, math.min(3, #ordered) do
        local player = ordered[index]
        table.insert(state.Podium, {
            Position = index,
            UserId = player.UserId,
            Name = player.DisplayName,
            Score = scores[player.UserId] or 0,
            Prize = Config.Competitive.PodiumRewards[index],
        })
    end
end

local function applyCompetitiveResult(player, didWin, placement, totalPlayers)
    if currentMode == "Survival" then return end
    local ratingDelta
    if currentMode == "TeamSplash" then
        ratingDelta = didWin and 16 or -12
    else
        local topHalf = placement <= math.max(1, math.ceil(totalPlayers / 2))
        ratingDelta = topHalf and 10 or -8
        if placement == 1 then ratingDelta = 20 end
    end
    ProfileService.AdjustRating(player, ratingDelta)
    ProfileService.AddSeasonPoints(player, didWin and Config.Competitive.WinSeasonPoints or Config.Competitive.LossSeasonPoints)
end

local function finishMatch(survivalCompleted)
    WeaponService.SetActive(false)
    clearBots()
    buildPodium()
    local ordered = orderedPlayers()
    local placement = {}
    for index, player in ipairs(ordered) do placement[player] = index end

    local winList = winners(survivalCompleted)
    local winSet = {}
    for _, player in ipairs(winList) do winSet[player] = true end

    for _, player in ipairs(participantList()) do
        local profile = ProfileService.Get(player)
        if profile then profile.Stats.MatchesPlayed += 1 end
        ProfileService.AddTintaMoney(player, Config.Match.ParticipationTintaMoney)
        if winSet[player] then
            if profile then
                profile.Wins += 1
                profile.Stats.ShooterWins += 1
            end
            ProfileService.AddTintaMoney(player, Config.Match.WinTintaMoney)
            ProfileService.AddXP(player, Config.Match.WinXP)
            if remotes then remotes.Victory:FireClient(player, "¡Victoria competitiva! + Tinta Money") end
        end
        applyCompetitiveResult(player, winSet[player] == true, placement[player] or #ordered, #ordered)
        task.spawn(RankingService.RecordPlayer, player)
        player:SetAttribute("InShooterMatch", false)
        player:SetAttribute("ShooterTeam", "Lobby")
        if player.Character then CharacterStyleService.Apply(player, player.Character) end
        MapService.Teleport(player, MapService.GetPoint("Lobby"))
    end

    state.Announcement = #winList > 0 and "PARTIDA TERMINADA · RANKING ACTUALIZADO" or "PARTIDA TERMINADA"
    countdown(Config.Match.ResultsSeconds, "Results", state.Announcement)
    table.clear(participants)
    table.clear(scores)
    teamScores.Cyan, teamScores.Magenta = 0, 0
    state.Wave = 0
    state.CurrentGame = nil
    state.CurrentMap = nil
    state.Mode = nil
    matchRunning = false
end

local function startMatch(mapId)
    local playersList = activePlayers()
    if #playersList < 1 then return end
    participants, scores = {}, {}
    teamScores.Cyan, teamScores.Magenta = 0, 0
    state.Podium = {}
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
    countdown(Config.Match.LoadingSeconds, "Loading", "PREPARANDO " .. string.upper(mapId))

    currentArena = MapService.BuildGame(mapId)
    MapService.ActivatePickups(pickup)
    for _, player in ipairs(playersList) do
        if player.Character then CharacterStyleService.Apply(player, player.Character) end
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
    Players.RespawnTime = Config.Match.RespawnSeconds
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
    if afkPlayers[player] then
        MapService.Teleport(player, MapService.GetPoint("AFK"))
    else
        player:SetAttribute("TintaQueueTime", workspace:GetServerTimeNow())
        MapService.Teleport(player, MapService.GetPoint("Lobby"))
    end
    return true, afkPlayers[player] and "Modo AFK activado." or "Volviste a la cola competitiva."
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
                state.Announcement = "ESPERANDO JUGADORES · MÁXIMO 20 POR SERVIDOR"
                state.TimeLeft = 0
                broadcast()
                task.wait(2)
            end
            countdown(Config.Match.IntermissionSeconds, "Intermission", "PREPARÁ TU ARSENAL · PRÓXIMA PARTIDA")
            local mapId = startVoting()
            if mapId then startMatch(mapId) end
            task.wait(1)
        end
    end)
end

return ShooterGameService
