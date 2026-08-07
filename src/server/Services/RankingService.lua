local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)

local RankingService = {}
local season = tostring(Config.Competitive.SeasonId or "S1")
local stores = {
    Rating = DataStoreService:GetOrderedDataStore("TintaFinal_Rating_" .. season),
    Season = DataStoreService:GetOrderedDataStore("TintaFinal_SeasonPoints_" .. season),
    Donations = DataStoreService:GetOrderedDataStore("TintaFinal_Donations_AllTime"),
    Wins = DataStoreService:GetOrderedDataStore("TintaFinal_Wins_AllTime"),
}
local nameCache = {}

local function keyFor(userId) return "u" .. tostring(userId) end
local function userIdFromKey(key) return tonumber(string.match(tostring(key), "^u(%d+)$")) end

local function resolveName(userId)
    if nameCache[userId] then return nameCache[userId] end
    local player = Players:GetPlayerByUserId(userId)
    if player then
        nameCache[userId] = player.DisplayName
        return player.DisplayName
    end
    local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
    nameCache[userId] = ok and name or ("Jugador " .. tostring(userId))
    return nameCache[userId]
end

function RankingService.RecordPlayer(player)
    local profile = ProfileService.Get(player)
    if not profile then return false end
    local values = {
        Rating = profile.CompetitiveRating or 0,
        Season = profile.SeasonPoints or 0,
        Donations = profile.DonatedRobux or 0,
        Wins = profile.Wins or 0,
    }
    local allGood = true
    for board, value in pairs(values) do
        local ok = pcall(function()
            stores[board]:SetAsync(keyFor(player.UserId), math.max(0, math.floor(value)))
        end)
        allGood = allGood and ok
    end
    return allGood
end

function RankingService.GetLeaderboard(board, limit)
    board = tostring(board or "Season")
    local ordered = stores[board]
    if not ordered then return {} end
    limit = math.clamp(math.floor(tonumber(limit) or 10), 1, 25)
    local success, pages = pcall(function()
        return ordered:GetSortedAsync(false, limit)
    end)
    if not success or not pages then return {} end
    local page = pages:GetCurrentPage()
    local output = {}
    for index, entry in ipairs(page) do
        local userId = userIdFromKey(entry.key)
        if userId then
            table.insert(output, {
                Position = index,
                UserId = userId,
                Name = resolveName(userId),
                Value = math.floor(tonumber(entry.value) or 0),
            })
        end
    end
    return output
end

function RankingService.GetBundle(limit)
    return {
        SeasonId = season,
        Season = RankingService.GetLeaderboard("Season", limit),
        Rating = RankingService.GetLeaderboard("Rating", limit),
        Donations = RankingService.GetLeaderboard("Donations", limit),
        Wins = RankingService.GetLeaderboard("Wins", limit),
        PodiumRewards = Config.Competitive.PodiumRewards,
    }
end

return RankingService
