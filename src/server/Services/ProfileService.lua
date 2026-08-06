local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)

local ProfileService = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local profiles = {}

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

local function defaults()
    return {
        Version = 2,
        Won = Config.Economy.StartingWon,
        Gems = Config.Economy.StartingGems,
        XP = 0,
        Level = 1,
        Wins = 0,
        BattlePassXP = 0,
        BattlePassTier = 1,
        PremiumPass = false,
        SpinTickets = 1,
        SpinPity = 0,
        SelectedDifficulty = "Easy",
        GuardQueued = false,
        Upgrades = {
            SpeedBoost = 0,
            HealthBoost = 0,
            RewardBoost = 0,
        },
        Inventory = {},
        ClaimedBattlePass = {},
        Stats = {
            StagesPlayed = 0,
            StagesSurvived = 0,
            EliminationsAsGuard = 0,
            AFKWonEarned = 0,
        },
    }
end

local function reconcile(target, template)
    for key, value in pairs(template) do
        if target[key] == nil then
            target[key] = copy(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            reconcile(target[key], value)
        end
    end
    return target
end

local function updateLeaderstats(player)
    local profile = profiles[player]
    local leaderstats = player:FindFirstChild("leaderstats")
    if not profile or not leaderstats then
        return
    end

    for name, value in pairs({
        Won = profile.Won,
        Wins = profile.Wins,
        Level = profile.Level,
    }) do
        local stat = leaderstats:FindFirstChild(name)
        if stat then
            stat.Value = value
        end
    end
end

function ProfileService.Load(player)
    local profile = defaults()
    local success, stored = pcall(function()
        return store:GetAsync("user_" .. player.UserId)
    end)

    if success and type(stored) == "table" then
        profile = reconcile(stored, profile)
    elseif not success then
        warn("Profile load failed for", player.UserId)
    end

    profiles[player] = profile

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    for _, name in ipairs({ "Won", "Wins", "Level" }) do
        local value = Instance.new("IntValue")
        value.Name = name
        value.Parent = leaderstats
    end

    updateLeaderstats(player)
    return profile
end

function ProfileService.Save(player)
    local profile = profiles[player]
    if not profile then
        return true
    end

    local snapshot = copy(profile)
    local success, message = pcall(function()
        store:UpdateAsync("user_" .. player.UserId, function()
            return snapshot
        end)
    end)

    if not success then
        warn("Profile save failed for", player.UserId, message)
    end
    return success
end

function ProfileService.Remove(player)
    profiles[player] = nil
end

function ProfileService.Get(player)
    return profiles[player]
end

function ProfileService.Public(player)
    local profile = profiles[player]
    if not profile then
        return nil
    end

    return {
        Won = profile.Won,
        Gems = profile.Gems,
        XP = profile.XP,
        Level = profile.Level,
        Wins = profile.Wins,
        BattlePassXP = profile.BattlePassXP,
        BattlePassTier = profile.BattlePassTier,
        PremiumPass = profile.PremiumPass,
        SpinTickets = profile.SpinTickets,
        SelectedDifficulty = profile.SelectedDifficulty,
        GuardQueued = profile.GuardQueued,
        Upgrades = copy(profile.Upgrades),
        Inventory = copy(profile.Inventory),
        Stats = copy(profile.Stats),
    }
end

function ProfileService.AddWon(player, amount)
    local profile = profiles[player]
    if not profile then
        return false
    end
    profile.Won = math.max(0, math.floor(profile.Won + amount))
    updateLeaderstats(player)
    return true
end

function ProfileService.SpendWon(player, amount)
    local profile = profiles[player]
    amount = math.max(0, math.floor(amount))
    if not profile or profile.Won < amount then
        return false
    end
    profile.Won -= amount
    updateLeaderstats(player)
    return true
end

function ProfileService.AddGems(player, amount)
    local profile = profiles[player]
    if not profile then
        return false
    end
    profile.Gems = math.max(0, math.floor(profile.Gems + amount))
    return true
end

function ProfileService.SpendGems(player, amount)
    local profile = profiles[player]
    amount = math.max(0, math.floor(amount))
    if not profile or profile.Gems < amount then
        return false
    end
    profile.Gems -= amount
    return true
end

function ProfileService.AddXP(player, amount)
    local profile = profiles[player]
    if not profile then
        return
    end

    profile.XP += math.max(0, math.floor(amount))
    while profile.XP >= profile.Level * 100 do
        profile.XP -= profile.Level * 100
        profile.Level += 1
        if profile.Level % 5 == 0 then
            profile.Gems += 5
        end
    end
    updateLeaderstats(player)
end

function ProfileService.AddBattlePassXP(player, amount)
    local profile = profiles[player]
    if not profile then
        return
    end

    profile.BattlePassXP += math.max(0, math.floor(amount))
    profile.BattlePassTier = math.clamp(
        math.floor(profile.BattlePassXP / Config.BattlePass.XPPerTier) + 1,
        1,
        Config.BattlePass.MaxTier
    )
end

function ProfileService.GrantItem(player, itemId)
    local profile = profiles[player]
    if not profile then
        return false
    end
    profile.Inventory[itemId] = (profile.Inventory[itemId] or 0) + 1
    return true
end

function ProfileService.ApplyUpgrades(player, character)
    local profile = profiles[player]
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not profile or not humanoid then
        return
    end

    humanoid.WalkSpeed = 16 + (profile.Upgrades.SpeedBoost or 0) * 2
    humanoid.MaxHealth = 100 + (profile.Upgrades.HealthBoost or 0) * 10
    humanoid.Health = humanoid.MaxHealth
end

function ProfileService.StartAutosave()
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                ProfileService.Save(player)
            end
        end
    end)
end

return ProfileService
