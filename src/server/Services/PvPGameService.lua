local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)
local RankingService = require(script.Parent.RankingService)
local CharacterStyleService = require(script.Parent.CharacterStyleService)
local MapService = require(script.Parent.MapService)
local WeaponService = require(script.Parent.WeaponService)
local BotService = require(script.Parent.BotService)

local PvPGameService = {}
local remotes
local matchRunning = false
local currentArena
local currentMode = "TeamSplash"
local participants = {}
local afkPlayers = {}
local scores = {}
local teamScores = {Cyan = 0, Magenta = 0}

local DUEL_SIZES = {1, 2, 6, 10}
local DUEL_COUNTDOWN = 10
local duelQueues = {}
local playerQueue = {}
local teleportPlayers = {}
local duelServerTeamSize
local duelServerExpectedPlayers = 0
local duelServerToken

local state = {
    Phase = "Booting",
    TimeLeft = 0,
    CurrentGame = "PvP",
    CurrentMap = nil,
    Mode = "TeamSplash",
    DuelTeamSize = nil,
    Announcement = "Preparando Tinta Final PvP...",
    TeamScores = {Cyan = 0, Magenta = 0},
    TeamCounts = {Cyan = 0, Magenta = 0},
    Podium = {},
    SeasonId = Config.Competitive.SeasonId,
    RotationMode = "DUEL_PARCELS",
    BotsEnabled = false,
    VotingEnabled = false,
}

local function validDuelSize(value)
    value = tonumber(value)
    for _, size in ipairs(DUEL_SIZES) do
        if value == size then return size end
    end
    return nil
end

local function participantList()
    local list = {}
    for player, enabled in pairs(participants) do
        if enabled and player.Parent then table.insert(list, player) end
    end
    table.sort(list, function(a, b) return a.UserId < b.UserId end)
    return list
end

local function teamCounts()
    local cyan, magenta = 0, 0
    for _, player in ipairs(participantList()) do
        if player:GetAttribute("ShooterTeam") == "Cyan" then cyan += 1 end
        if player:GetAttribute("ShooterTeam") == "Magenta" then magenta += 1 end
    end
    if state.BotsEnabled then
        local botCyan, botMagenta = BotService.GetCounts()
        cyan += botCyan
        magenta += botMagenta
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
        DuelTeamSize = state.DuelTeamSize,
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
        RotationMode = "DUEL_PARCELS",
        BotsEnabled = state.BotsEnabled,
        VotingEnabled = false,
        Warmup = false,
    }
end

local function broadcast()
    if remotes and remotes:FindFirstChild("GameState") then remotes.GameState:FireAllClients(publicState()) end
end

local function fireQueueState(player, payload)
    if remotes and remotes:FindFirstChild("DuelQueueState") and player and player.Parent then
        remotes.DuelQueueState:FireClient(player, payload)
    end
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

local function ratingOf(player)
    local profile = ProfileService.Get(player)
    return profile and profile.CompetitiveRating or Config.Competitive.StartingRating
end

local function assignTeams(list, teamSize)
    if #list == 1 then
        list[1]:SetAttribute("ShooterTeam", "Cyan")
        return
    end
    local sorted = table.clone(list)
    table.sort(sorted, function(a, b) return ratingOf(a) > ratingOf(b) end)
    local totals = {Cyan = 0, Magenta = 0}
    local counts = {Cyan = 0, Magenta = 0}
    local maxTeam = math.max(1, tonumber(teamSize) or math.ceil(#sorted / 2))
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
    local points = player:GetAttribute("ShooterTeam") == "Magenta" and currentArena.MagentaSpawns or currentArena.CyanSpawns
    return points[((math.abs(player.UserId) % #points) + 1)]
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
        if matchRunning and participants[player] then
            MapService.Teleport(player, spawnFor(player))
        else
            MapService.Teleport(player, MapService.GetPoint("Lobby"))
        end
    end)

    humanoid.Died:Connect(function()
        local profile = ProfileService.Get(player)
        if profile and matchRunning and participants[player] then profile.Stats.Deaths += 1 end
        if matchRunning and participants[player] then
            task.delay(Config.Match.RespawnSeconds, function()
                if player.Parent and matchRunning and participants[player] then player:LoadCharacter() end
            end)
        end
    end)
end

local function addHumanKill(shooter, victim, headshot)
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
    local team = shooter:GetAttribute("ShooterTeam")
    if teamScores[team] then teamScores[team] += 1 end
    if remotes and remotes:FindFirstChild("KillFeed") then
        remotes.KillFeed:FireAllClients(shooter.DisplayName, victim and victim.DisplayName or "Jugador", headshot == true)
    end
    broadcast()
end

local function addBotKill(shooter, botModel, headshot)
    if not matchRunning or not participants[shooter] then return end
    local profile = ProfileService.Get(shooter)
    if profile and profile.Stats then
        profile.Stats.BotKills = (profile.Stats.BotKills or 0) + 1
        if headshot then profile.Stats.Headshots += 1 end
    end
    scores[shooter.UserId] = (scores[shooter.UserId] or 0) + 1
    local team = shooter:GetAttribute("ShooterTeam")
    if teamScores[team] then teamScores[team] += 1 end
    if remotes and remotes:FindFirstChild("KillFeed") then
        remotes.KillFeed:FireAllClients(shooter.DisplayName, botModel and botModel.Name or "BOT", headshot == true)
    end
    broadcast()
end

local function addBotTeamScore(team, victimName)
    if not matchRunning or not teamScores[team] then return end
    teamScores[team] += 1
    if remotes and remotes:FindFirstChild("KillFeed") then
        remotes.KillFeed:FireAllClients("BOT " .. tostring(team), tostring(victimName or "Rival"), false)
    end
    broadcast()
end

local function duelScoreLimit()
    local size = tonumber(state.DuelTeamSize) or 10
    if size <= 1 then return 10 end
    if size <= 2 then return 20 end
    if size <= 6 then return 40 end
    return Config.Match.TeamScoreLimit
end

local function combatFinished()
    local limit = duelScoreLimit()
    return teamScores.Cyan >= limit or teamScores.Magenta >= limit
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
    local winningTeam
    if teamScores.Cyan > teamScores.Magenta then winningTeam = "Cyan"
    elseif teamScores.Magenta > teamScores.Cyan then winningTeam = "Magenta" end
    if winningTeam then
        for _, player in ipairs(participantList()) do
            if player:GetAttribute("ShooterTeam") == winningTeam then winners[player] = true end
        end
    end
    return winners
end

local function resetQueuePlayer(player)
    if player and player.Parent then
        player:SetAttribute("DuelQueueTeamSize", nil)
        player:SetAttribute("DuelQueueHost", nil)
    end
    playerQueue[player] = nil
end

local function updateQueuePad(teamSize, remaining)
    local queue = duelQueues[teamSize]
    if not queue then return end
    local count = 0
    for _, player in ipairs(queue.Players) do
        if player.Parent then count += 1 end
    end
    if count <= 0 then
        MapService.UpdateDuelPad(teamSize, "PISÁ PARA ENTRAR")
    elseif remaining ~= nil then
        MapService.UpdateDuelPad(teamSize, string.format("%d/%d · %ds", count, queue.Capacity, remaining))
    else
        MapService.UpdateDuelPad(teamSize, string.format("%d/%d · ESPERANDO", count, queue.Capacity))
    end
end

local function removeFromQueue(player)
    local teamSize = playerQueue[player]
    if not teamSize then return end
    local queue = duelQueues[teamSize]
    if queue then
        for index = #queue.Players, 1, -1 do
            if queue.Players[index] == player or not queue.Players[index].Parent then table.remove(queue.Players, index) end
        end
        if queue.Host == player then
            queue.Host = queue.Players[1]
            if queue.Host then queue.Host:SetAttribute("DuelQueueHost", true) end
        end
        if #queue.Players == 0 then
            queue.CountdownToken += 1
            queue.Running = false
            queue.Host = nil
        end
        updateQueuePad(teamSize, queue.Running and queue.Remaining or nil)
    end
    resetQueuePlayer(player)
end

local function launchQueue(teamSize, token)
    local queue = duelQueues[teamSize]
    if not queue or queue.CountdownToken ~= token then return end
    queue.Running = false

    local list = {}
    for _, player in ipairs(queue.Players) do
        if player.Parent and ProfileService.Get(player) then table.insert(list, player) end
    end
    queue.Players = {}
    queue.Host = nil
    updateQueuePad(teamSize)
    if #list == 0 then return end

    for _, player in ipairs(list) do resetQueuePlayer(player) end

    local tokenValue = HttpService:GenerateGUID(false)
    local options = Instance.new("TeleportOptions")
    options.ShouldReserveServer = true
    options:SetTeleportData({
        TintaDuel = true,
        TeamSize = teamSize,
        QueueToken = tokenValue,
        ExpectedPlayers = #list,
    })

    local ok, err = pcall(function()
        TeleportService:TeleportAsync(game.PlaceId, list, options)
    end)
    if not ok then
        warn("[TintaFinal] No se pudo crear servidor de duelo: " .. tostring(err))
        for _, player in ipairs(list) do
            fireQueueState(player, {Joined = false, Message = "No se pudo abrir el duelo. Pisá la parcela nuevamente."})
        end
    end
end

local function startQueueCountdown(teamSize)
    local queue = duelQueues[teamSize]
    if not queue or queue.Running then return end
    queue.Running = true
    queue.CountdownToken += 1
    local token = queue.CountdownToken
    task.spawn(function()
        for remaining = DUEL_COUNTDOWN, 0, -1 do
            if queue.CountdownToken ~= token or #queue.Players == 0 then return end
            queue.Remaining = remaining
            updateQueuePad(teamSize, remaining)
            for _, player in ipairs(queue.Players) do
                if player.Parent then
                    fireQueueState(player, {
                        Joined = true,
                        TeamSize = teamSize,
                        Remaining = remaining,
                        Count = #queue.Players,
                        Capacity = queue.Capacity,
                        Host = queue.Host == player,
                    })
                end
            end
            if remaining == 0 then
                launchQueue(teamSize, token)
                return
            end
            task.wait(1)
        end
    end)
end

local function joinDuelQueue(player, teamSize)
    teamSize = validDuelSize(teamSize)
    if not teamSize or not player.Parent or not ProfileService.Get(player) then return end
    if player:GetAttribute("InShooterMatch") or afkPlayers[player] then return end

    if playerQueue[player] == teamSize then return end
    if playerQueue[player] then removeFromQueue(player) end

    local queue = duelQueues[teamSize]
    if not queue then return end
    if #queue.Players >= queue.Capacity then
        fireQueueState(player, {Joined = false, Message = string.format("La parcela %dv%d está llena.", teamSize, teamSize)})
        return
    end

    table.insert(queue.Players, player)
    playerQueue[player] = teamSize
    player:SetAttribute("DuelQueueTeamSize", teamSize)
    if not queue.Host then
        queue.Host = player
        player:SetAttribute("DuelQueueHost", true)
    else
        player:SetAttribute("DuelQueueHost", false)
    end
    updateQueuePad(teamSize, queue.Running and queue.Remaining or DUEL_COUNTDOWN)
    if not queue.Running then startQueueCountdown(teamSize) end
end

local function bindDuelPads()
    for teamSize, entry in pairs(MapService.GetDuelPads()) do
        local pad = entry.Pad
        pad.Touched:Connect(function(hit)
            local character = hit and hit:FindFirstAncestorOfClass("Model")
            local player = character and Players:GetPlayerFromCharacter(character)
            if player then joinDuelQueue(player, teamSize) end
        end)
    end
end

local function finishMatch()
    matchRunning = false
    WeaponService.SetActive(false)
    BotService.Stop()
    local winners = winnerSet()
    state.Podium = sortedPodium()
    local realPlayers = participantList()
    for _, player in ipairs(realPlayers) do
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
    end

    local announcement
    if teamScores.Cyan > teamScores.Magenta then announcement = "VICTORIA CIAN"
    elseif teamScores.Magenta > teamScores.Cyan then announcement = "VICTORIA MAGENTA"
    else announcement = "EMPATE" end
    countdown(Config.Match.ResultsSeconds, "Results", announcement)

    participants = {}
    scores = {}
    teamScores = {Cyan = 0, Magenta = 0}
    state.Podium = {}
    state.BotsEnabled = false
    workspace:SetAttribute("TintaFinalShooterMode", "Lobby")

    if workspace:GetAttribute("TintaDuelServer") == true and #realPlayers > 0 then
        local ok = pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, realPlayers)
        end)
        if not ok then
            MapService.BuildLobby()
            bindDuelPads()
            for _, player in ipairs(realPlayers) do
                if player.Character then MapService.Teleport(player, MapService.GetPoint("Lobby")) end
            end
        end
    else
        for _, player in ipairs(realPlayers) do
            if player.Character then MapService.Teleport(player, MapService.GetPoint("Lobby")) end
        end
    end
    currentArena = nil
    state.CurrentMap = nil
    state.DuelTeamSize = nil
    state.Phase = "Waiting"
    state.TimeLeft = 0
    state.Announcement = "ELEGÍ UNA PARCELA DE DUELO"
    broadcast()
end

local function beginDuel(teamSize, list)
    if matchRunning or #list == 0 then return end
    teamSize = validDuelSize(teamSize) or 1
    participants = {}
    scores = {}
    teamScores = {Cyan = 0, Magenta = 0}
    for _, player in ipairs(list) do
        participants[player] = true
        scores[player.UserId] = 0
    end

    currentMode = "TeamSplash"
    assignTeams(list, teamSize)
    state.DuelTeamSize = teamSize
    state.CurrentMap = "Duel" .. teamSize .. "v" .. teamSize
    state.Mode = "TeamSplash"
    state.BotsEnabled = #list == 1
    currentArena = MapService.BuildDuelGame(teamSize)
    workspace:SetAttribute("TintaFinalDuelSize", teamSize)
    workspace:SetAttribute("TintaFinalShooterMode", "Duel")

    countdown(3, "Loading", string.format("PREPARANDO DUELO %d VS %d", teamSize, teamSize))
    matchRunning = true
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

    if #list == 1 then
        BotService.Start(currentArena, teamSize, list[1], remotes, {
            OnBotKilledPlayer = function(team, victim)
                addBotTeamScore(team, victim and victim.DisplayName or "Jugador")
            end,
            OnBotKilledBot = function(team, victimBot)
                addBotTeamScore(team, victimBot and victimBot.Name or "BOT")
            end,
        })
    end

    state.Phase = "Combat"
    state.Announcement = string.format("DUELO %d VS %d · PRIMERO A %d", teamSize, teamSize, duelScoreLimit())
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
    for _, teamSize in ipairs(DUEL_SIZES) do
        duelQueues[teamSize] = {
            TeamSize = teamSize,
            Capacity = teamSize * 2,
            Players = {},
            Host = nil,
            Running = false,
            Remaining = DUEL_COUNTDOWN,
            CountdownToken = 0,
        }
    end
    MapService.BuildLobby()
    bindDuelPads()
    WeaponService.Initialize(remoteFolder, {
        OnPlayerKilled = addHumanKill,
        OnBotKilled = addBotKill,
    })
    state.Phase = "Waiting"
    state.Announcement = "ELEGÍ 1V1 · 2V2 · 6V6 · 10V10"
    workspace:SetAttribute("TintaFinalShooterMode", "Lobby")
    workspace:SetAttribute("TintaDuelServer", false)
    broadcast()
end

function PvPGameService.RegisterPlayer(player)
    local ok, joinData = pcall(function() return player:GetJoinData() end)
    local data = ok and joinData and joinData.TeleportData
    local teamSize = type(data) == "table" and data.TintaDuel == true and validDuelSize(data.TeamSize) or nil
    if teamSize then
        duelServerTeamSize = duelServerTeamSize or teamSize
        duelServerExpectedPlayers = math.max(1, math.floor(tonumber(data.ExpectedPlayers) or 1))
        duelServerToken = duelServerToken or tostring(data.QueueToken or "")
        teleportPlayers[player] = true
        player:SetAttribute("DuelTeamSize", teamSize)
        workspace:SetAttribute("TintaDuelServer", true)
    end
end

function PvPGameService.GetState()
    return publicState()
end

function PvPGameService.CastVote()
    return false, "La votación fue reemplazada por las parcelas 1v1, 2v2, 6v6 y 10v10."
end

function PvPGameService.ToggleAFK(player)
    afkPlayers[player] = not afkPlayers[player]
    player:SetAttribute("AFKMode", afkPlayers[player] == true)
    if afkPlayers[player] then removeFromQueue(player) end
    return true, afkPlayers[player] and "Modo AFK activado." or "Modo AFK desactivado."
end

function PvPGameService.OnCharacterAdded(player, character)
    setupCharacter(player, character)
end

function PvPGameService.PlayerRemoving(player)
    participants[player] = nil
    teleportPlayers[player] = nil
    afkPlayers[player] = nil
    removeFromQueue(player)
    WeaponService.PlayerRemoving(player)
end

function PvPGameService.StartLoop()
    task.spawn(function()
        task.wait(2)
        if duelServerTeamSize then
            local deadline = os.clock() + 8
            while os.clock() < deadline do
                local count = 0
                for player in pairs(teleportPlayers) do if player.Parent then count += 1 end end
                if count >= duelServerExpectedPlayers then break end
                task.wait(0.25)
            end
            local list = {}
            for player in pairs(teleportPlayers) do
                if player.Parent and ProfileService.Get(player) then table.insert(list, player) end
            end
            table.sort(list, function(a, b) return a.UserId < b.UserId end)
            if #list > 0 then
                beginDuel(duelServerTeamSize, list)
            end
            return
        end

        while true do
            state.Phase = "Waiting"
            state.TimeLeft = 0
            state.CurrentMap = nil
            state.DuelTeamSize = nil
            state.BotsEnabled = false
            state.Announcement = "ELEGÍ UNA PARCELA DE DUELO"
            broadcast()
            task.wait(2)
        end
    end)
end

return PvPGameService
