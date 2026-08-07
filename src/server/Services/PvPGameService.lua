local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)
local RankingService = require(script.Parent.RankingService)
local CharacterStyleService = require(script.Parent.CharacterStyleService)
local MapService = require(script.Parent.MapService)
local WeaponService = require(script.Parent.WeaponService)

local PvPGameService = {}
local remotes
local matchRunning = false
local warmupRunning = false
local currentArena
local currentMode = "TeamSplash"
local participants = {}
local warmupPlayers = {}
local afkPlayers = {}
local scores = {}
local teamScores = {Cyan = 0, Magenta = 0}
local mapIndex = 0
local matchIndex = 0

local state = {
    Phase = "Booting",
    TimeLeft = 0,
    CurrentGame = "PvP",
    CurrentMap = nil,
    Mode = "TeamSplash",
    Announcement = "Preparando Tinta Final PvP...",
    TeamScores = {Cyan = 0, Magenta = 0},
    TeamCounts = {Cyan = 0, Magenta = 0},
    Podium = {},
    SeasonId = Config.Competitive.SeasonId,
    RotationMode = "AUTO",
    BotsEnabled = false,
    VotingEnabled = false,
}

local function participantList()
    local list = {}
    for player, enabled in pairs(participants) do
        if enabled and player.Parent then table.insert(list, player) end
    end
    table.sort(list, function(a, b) return a.UserId < b.UserId end)
    return list
end

local function queuePlayers()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if not afkPlayers[player] and ProfileService.Get(player) then table.insert(list, player) end
    end
    table.sort(list, function(a, b)
        local aq = a:GetAttribute("TintaQueueTime") or 0
        local bq = b:GetAttribute("TintaQueueTime") or 0
        if aq == bq then return a.UserId < b.UserId end
        return aq < bq
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
    local scoreCopy = {}
    for userId, value in pairs(scores) do scoreCopy[tostring(userId)] = value end
    local cyan, magenta = teamCounts()
    return {
        Phase = state.Phase,
        TimeLeft = state.TimeLeft,
        CurrentGame = "PvP",
        CurrentMap = state.CurrentMap,
        Mode = currentMode,
        OfferedGames = {},
        Votes = {},
        AliveCount = #participantList(),
        Announcement = state.Announcement,
        Scores = scoreCopy,
        TeamScores = {Cyan = teamScores.Cyan, Magenta = teamScores.Magenta},
        TeamCounts = {Cyan = cyan, Magenta = magenta},
        Wave = 0,
        MaxParticipants = Config.Match.MaxParticipants,
        Podium = table.clone(state.Podium),
        SeasonId = Config.Competitive.SeasonId,
        ConnectedPlayers = #Players:GetPlayers(),
        RotationMode = "AUTO",
        BotsEnabled = false,
        VotingEnabled = false,
        Warmup = warmupRunning,
    }
end

local function broadcast()
    if remotes and remotes:FindFirstChild("GameState") then remotes.GameState:FireAllClients(publicState()) end
end

local function countdown(seconds, phase, message)
    state.Phase = phase
    state.Announcement = message or phase
    for remaining = seconds, 0, -1 do
        state.TimeLeft = remaining
        broadcast()
        task.wait(1)
    end
end

local function previewMap()
    return Config.Shooter.MapOrder[(mapIndex % #Config.Shooter.MapOrder) + 1]
end

local function nextMap()
    mapIndex = (mapIndex % #Config.Shooter.MapOrder) + 1
    return Config.Shooter.MapOrder[mapIndex]
end

local function nextMode(playerCount)
    matchIndex += 1
    if playerCount >= 4 and matchIndex % 4 == 0 then return "FreeSplash" end
    return "TeamSplash"
end

local function ratingOf(player)
    local profile = ProfileService.Get(player)
    return profile and profile.CompetitiveRating or Config.Competitive.StartingRating
end

local function assignTeams(list)
    if currentMode ~= "TeamSplash" then
        for _, player in ipairs(list) do player:SetAttribute("ShooterTeam", "Solo") end
        return
    end
    local sorted = table.clone(list)
    table.sort(sorted, function(a, b) return ratingOf(a) > ratingOf(b) end)
    local totals = {Cyan = 0, Magenta = 0}
    local counts = {Cyan = 0, Magenta = 0}
    local maxTeam = math.ceil(#sorted / 2)
    for _, player in ipairs(sorted) do
        local team
        if counts.Cyan >= maxTeam then team = "Magenta"
        elseif counts.Magenta >= maxTeam then team = "Cyan"
        elseif totals.Cyan <= totals.Magenta then team = "Cyan"
        else team = "Magenta" end
        counts[team] += 1
        totals[team] += ratingOf(player)
        player:SetAttribute("ShooterTeam", team)
    end
end

local function spawnFor(player)
    if not currentArena then return MapService.GetPoint("Lobby") end
    if currentMode == "TeamSplash" then
        local points = player:GetAttribute("ShooterTeam") == "Magenta" and currentArena.MagentaSpawns or currentArena.CyanSpawns
        return points[((player.UserId % #points) + 1)]
    end
    local points = currentArena.FFASpawns
    return points[((player.UserId % #points) + 1)]
end

local function setupCharacter(player, character)
    ProfileService.ApplyUpgrades(player, character)
    CharacterStyleService.Apply(player, character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then return end
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.AutoRotate = true
    character:SetAttribute("TintaKillRegistered", false)
    WeaponService.ResetPlayer(player)

    task.delay(0.25, function()
        if not player.Parent or not character.Parent then return end
        if (matchRunning and participants[player]) or warmupPlayers[player] then
            MapService.Teleport(player, spawnFor(player))
        else
            MapService.Teleport(player, MapService.GetPoint("Lobby"))
        end
    end)

    humanoid.Died:Connect(function()
        local profile = ProfileService.Get(player)
        if profile and matchRunning and participants[player] then profile.Stats.Deaths += 1 end
        if (matchRunning and participants[player]) or warmupPlayers[player] then
            task.delay(Config.Match.RespawnSeconds, function()
                if player.Parent and ((matchRunning and participants[player]) or warmupPlayers[player]) then player:LoadCharacter() end
            end)
        end
    end)
end

local function addKill(shooter, victim, headshot)
    if not matchRunning or not participants[shooter] or shooter == victim then return end
    local profile = ProfileService.Get(shooter)
    if profile then
        profile.Stats.Kills += 1
        if headshot then profile.Stats.Headshots += 1 end
    end
    scores[shooter.UserId] = (scores[shooter.UserId] or 0) + 1
    ProfileService.AddTintaMoney(shooter, Config.Match.KillTintaMoney)
    ProfileService.AddXP(shooter, Config.Match.KillXP)
    ProfileService.AddSeasonPoints(shooter, Config.Competitive.KillSeasonPoints)
    if currentMode == "TeamSplash" then
        local team = shooter:GetAttribute("ShooterTeam")
        if teamScores[team] then teamScores[team] += 1 end
    end
    if remotes and remotes:FindFirstChild("KillFeed") then
        remotes.KillFeed:FireAllClients(shooter.DisplayName, victim and victim.DisplayName or "Jugador", headshot == true)
    end
    broadcast()
end

local function combatFinished()
    if currentMode == "TeamSplash" then
        return teamScores.Cyan >= Config.Match.TeamScoreLimit or teamScores.Magenta >= Config.Match.TeamScoreLimit
    end
    for _, value in pairs(scores) do
        if value >= Config.Match.FFAScoreLimit then return true end
    end
    return false
end

local function sortedPodium()
    local list = participantList()
    table.sort(list, function(a, b)
        local sa, sb = scores[a.UserId] or 0, scores[b.UserId] or 0
        if sa == sb then return ratingOf(a) > ratingOf(b) end
        return sa > sb
    end)
    local podium = {}
    for index = 1, math.min(3, #list) do
        local p = list[index]
        podium[index] = {UserId = p.UserId, Name = p.DisplayName, Score = scores[p.UserId] or 0}
    end
    return podium
end

local function winnerSet()
    local winners = {}
    if currentMode == "TeamSplash" then
        local winningTeam
        if teamScores.Cyan > teamScores.Magenta then winningTeam = "Cyan"
        elseif teamScores.Magenta > teamScores.Cyan then winningTeam = "Magenta" end
        if winningTeam then
            for _, player in ipairs(participantList()) do
                if player:GetAttribute("ShooterTeam") == winningTeam then winners[player] = true end
            end
        end
    else
        local best = -1
        for _, player in ipairs(participantList()) do best = math.max(best, scores[player.UserId] or 0) end
        for _, player in ipairs(participantList()) do
            if (scores[player.UserId] or 0) == best then winners[player] = true end
        end
    end
    return winners
end

local function stopWarmup(teleportToLobby)
    if not warmupRunning then return end
    warmupRunning = false
    WeaponService.SetActive(false)
    for player in pairs(warmupPlayers) do
        if player.Parent then
            player:SetAttribute("InShooterMatch", false)
            player:SetAttribute("ShooterActive", false)
            player:SetAttribute("ShooterTeam", "Lobby")
            if teleportToLobby and player.Character then MapService.Teleport(player, MapService.GetPoint("Lobby")) end
        end
    end
    table.clear(warmupPlayers)
    workspace:SetAttribute("TintaFinalShooterMode", "Lobby")
end

local function startWarmup(player)
    if warmupRunning and warmupPlayers[player] then return end
    stopWarmup(false)
    currentMode = "Warmup"
    state.Mode = "Warmup"
    state.CurrentMap = previewMap()
    currentArena = MapService.BuildGame(state.CurrentMap)
    warmupRunning = true
    warmupPlayers[player] = true
    player:SetAttribute("InShooterMatch", true)
    player:SetAttribute("ShooterTeam", "Solo")
    workspace:SetAttribute("TintaFinalShooterMode", "Warmup")
    WeaponService.SetActive(true)
    WeaponService.SetPlayerActive(player, true)
    if player.Character then
        CharacterStyleService.Apply(player, player.Character)
        MapService.Teleport(player, spawnFor(player))
        WeaponService.ResetPlayer(player)
    else
        player:LoadCharacter()
    end
    state.Phase = "Warmup"
    state.TimeLeft = 0
    state.Announcement = "CALENTAMIENTO SIN BOTS · ESPERANDO OTRO JUGADOR"
    broadcast()
end

local function finishMatch()
    matchRunning = false
    WeaponService.SetActive(false)
    local winners = winnerSet()
    state.Podium = sortedPodium()
    for _, player in ipairs(participantList()) do
        local profile = ProfileService.Get(player)
        if profile then
            profile.Stats.MatchesPlayed += 1
            ProfileService.AddTintaMoney(player, Config.Match.ParticipationTintaMoney)
            if winners[player] then
                profile.Wins += 1
                profile.Stats.ShooterWins += 1
                ProfileService.AddTintaMoney(player, Config.Match.WinTintaMoney)
                ProfileService.AddXP(player, Config.Match.WinXP)
                ProfileService.AddSeasonPoints(player, Config.Competitive.WinSeasonPoints)
                ProfileService.AdjustRating(player, 18)
            else
                ProfileService.AddSeasonPoints(player, Config.Competitive.LossSeasonPoints)
                ProfileService.AdjustRating(player, -10)
            end
            task.spawn(RankingService.RecordPlayer, player)
        end
        player:SetAttribute("InShooterMatch", false)
        player:SetAttribute("ShooterActive", false)
        player:SetAttribute("ShooterTeam", "Lobby")
        if player.Character then MapService.Teleport(player, MapService.GetPoint("Lobby")) end
    end
    local announcement
    if currentMode == "TeamSplash" then
        if teamScores.Cyan > teamScores.Magenta then announcement = "VICTORIA CIAN"
        elseif teamScores.Magenta > teamScores.Cyan then announcement = "VICTORIA MAGENTA"
        else announcement = "EMPATE" end
    else
        announcement = state.Podium[1] and ("GANADOR · " .. state.Podium[1].Name) or "FIN DE PARTIDA"
    end
    countdown(Config.Match.ResultsSeconds, "Results", announcement)
    participants = {}
    scores = {}
    teamScores = {Cyan = 0, Magenta = 0}
    state.Podium = {}
    currentArena = nil
    state.CurrentMap = nil
    workspace:SetAttribute("TintaFinalShooterMode", "Lobby")
end

local function beginMatch(list)
    stopWarmup(false)
    participants = {}
    scores = {}
    teamScores = {Cyan = 0, Magenta = 0}
    for _, player in ipairs(list) do participants[player] = true scores[player.UserId] = 0 end
    currentMode = nextMode(#list)
    assignTeams(list)
    state.CurrentMap = nextMap()
    state.Mode = currentMode
    countdown(Config.Match.LoadingSeconds, "Loading", "PREPARANDO " .. tostring(state.CurrentMap))
    currentArena = MapService.BuildGame(state.CurrentMap)
    MapService.ActivatePickups(function(player, pickupType, amount)
        if not matchRunning or not participants[player] then return end
        if pickupType == "Health" then
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount) end
        elseif pickupType == "Ammo" then
            WeaponService.AddAmmo(player, amount)
        end
    end)

    matchRunning = true
    workspace:SetAttribute("TintaFinalShooterMode", currentMode)
    for _, player in ipairs(list) do
        player:SetAttribute("InShooterMatch", true)
        player:SetAttribute("ShooterActive", true)
        if player.Character then
            CharacterStyleService.Apply(player, player.Character)
            MapService.Teleport(player, spawnFor(player))
            WeaponService.ResetPlayer(player)
        else
            player:LoadCharacter()
        end
    end
    WeaponService.SetActive(true)
    state.Phase = "Combat"
    state.Announcement = currentMode == "TeamSplash" and "PVP · CIAN VS MAGENTA" or "PVP · TODOS CONTRA TODOS"
    broadcast()

    local deadline = os.clock() + Config.Match.RoundSeconds
    while matchRunning and os.clock() < deadline and not combatFinished() do
        state.TimeLeft = math.max(0, math.ceil(deadline - os.clock()))
        broadcast()
        task.wait(1)
    end
    finishMatch()
end

function PvPGameService.Initialize(remoteFolder)
    remotes = remoteFolder
    MapService.BuildLobby()
    WeaponService.Initialize(remoteFolder, {OnPlayerKilled = addKill, OnBotKilled = function() end})
    state.Phase = "Waiting"
    state.Announcement = "ESPERANDO JUGADORES PARA PVP"
    workspace:SetAttribute("TintaFinalShooterMode", "Lobby")
    broadcast()
end

function PvPGameService.GetState()
    return publicState()
end

function PvPGameService.CastVote()
    return false, "La votación fue eliminada: los mapas rotan automáticamente."
end

function PvPGameService.ToggleAFK(player)
    afkPlayers[player] = not afkPlayers[player]
    player:SetAttribute("AFKMode", afkPlayers[player] == true)
    player:SetAttribute("TintaQueueTime", workspace:GetServerTimeNow())
    if afkPlayers[player] and warmupPlayers[player] then stopWarmup(true) end
    return true, afkPlayers[player] and "Modo AFK activado." or "Volviste a la cola PvP."
end

function PvPGameService.OnCharacterAdded(player, character)
    setupCharacter(player, character)
end

function PvPGameService.PlayerRemoving(player)
    participants[player] = nil
    warmupPlayers[player] = nil
    afkPlayers[player] = nil
    WeaponService.PlayerRemoving(player)
end

function PvPGameService.StartLoop()
    task.spawn(function()
        task.wait(2)
        while true do
            local queued = queuePlayers()
            if #queued == 0 then
                stopWarmup(true)
                state.Phase = "Waiting"
                state.TimeLeft = 0
                state.CurrentMap = nil
                state.Announcement = "PVP PURO · ESPERANDO JUGADORES"
                broadcast()
                task.wait(1)
            elseif #queued == 1 then
                startWarmup(queued[1])
                task.wait(1)
            else
                stopWarmup(false)
                countdown(Config.Match.IntermissionSeconds, "Intermission", "PRÓXIMA PARTIDA PVP · MAPA AUTOMÁTICO")
                queued = queuePlayers()
                if #queued >= 2 then beginMatch(queued) end
            end
        end
    end)
end

return PvPGameService