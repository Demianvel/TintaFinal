local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)

local ProfileService = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local profiles = {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function defaults()
    return {
        Version = 4,
        TintaMoney = Config.Economy.StartingTintaMoney,
        Gems = Config.Economy.StartingGems,
        XP = 0,
        Level = 1,
        Wins = 0,
        CompetitiveRating = Config.Competitive.StartingRating,
        SeasonPoints = 0,
        DonatedRobux = 0,
        BattlePassXP = 0,
        BattlePassTier = 1,
        PremiumPass = false,
        SpinTickets = 1,
        SpinPity = 0,
        SelectedWeapon = Config.Shooter.DefaultWeapon,
        SelectedSkin = "Default",
        Upgrades = {
            SpeedBoost = 0,
            HealthBoost = 0,
            RewardBoost = 0,
        },
        Inventory = {
            [Config.Shooter.DefaultWeapon] = 1,
            Default = 1,
        },
        ClaimedBattlePass = {},
        ProcessedReceipts = {},
        ReceiptOrder = {},
        Stats = {
            MatchesPlayed = 0,
            ShooterWins = 0,
            Kills = 0,
            Deaths = 0,
            Headshots = 0,
            BotKills = 0,
            Damage = 0,
            AFKTintaMoneyEarned = 0,
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

local function migrate(profile)
    if profile.TintaMoney == nil and profile.Won ~= nil then
        profile.TintaMoney = math.max(0, math.floor(tonumber(profile.Won) or 0))
    end
    profile = reconcile(profile, defaults())
    profile.Version = 4
    profile.Won = nil
    profile.Stats.AFKWonEarned = nil
    profile.Inventory[Config.Shooter.DefaultWeapon] = math.max(1, profile.Inventory[Config.Shooter.DefaultWeapon] or 0)
    profile.Inventory.Default = math.max(1, profile.Inventory.Default or 0)
    if not profile.Inventory[profile.SelectedWeapon] then profile.SelectedWeapon = Config.Shooter.DefaultWeapon end
    if not profile.Inventory[profile.SelectedSkin] then profile.SelectedSkin = "Default" end
    return profile
end

local function rankName(rating)
    local selected = Config.Competitive.Ranks[1].Name
    for _, rank in ipairs(Config.Competitive.Ranks) do
        if rating >= rank.Min then selected = rank.Name else break end
    end
    return selected
end

local function updateLeaderstats(player)
    local profile = profiles[player]
    local leaderstats = player:FindFirstChild("leaderstats")
    if not profile or not leaderstats then return end
    local values = {
        TintaMoney = profile.TintaMoney,
        Wins = profile.Wins,
        Rating = profile.CompetitiveRating,
    }
    for name, value in pairs(values) do
        local stat = leaderstats:FindFirstChild(name)
        if stat then stat.Value = math.floor(value or 0) end
    end
    player:SetAttribute("CompetitiveRank", rankName(profile.CompetitiveRating or 0))
    player:SetAttribute("SeasonPoints", profile.SeasonPoints or 0)
end

function ProfileService.Load(player)
    local profile = defaults()
    local success, stored = pcall(function()
        return store:GetAsync("user_" .. player.UserId)
    end)
    if success and type(stored) == "table" then
        profile = migrate(stored)
    elseif not success then
        warn("[TintaFinal] Profile load failed for", player.UserId)
    end
    profiles[player] = profile

    local old = player:FindFirstChild("leaderstats")
    if old then old:Destroy() end
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    for _, name in ipairs({ "TintaMoney", "Wins", "Rating" }) do
        local value = Instance.new("IntValue")
        value.Name = name
        value.Parent = leaderstats
    end
    updateLeaderstats(player)
    return profile
end

function ProfileService.Save(player)
    local profile = profiles[player]
    if not profile then return true end
    local snapshot = copy(profile)
    local success, message = pcall(function()
        store:UpdateAsync("user_" .. player.UserId, function()
            return snapshot
        end)
    end)
    if not success then warn("[TintaFinal] Profile save failed for", player.UserId, message) end
    return success
end

function ProfileService.Remove(player) profiles[player] = nil end
function ProfileService.Get(player) return profiles[player] end
function ProfileService.GetRankName(rating) return rankName(tonumber(rating) or 0) end

function ProfileService.Public(player)
    local profile = profiles[player]
    if not profile then return nil end
    return {
        TintaMoney = profile.TintaMoney,
        Won = profile.TintaMoney, -- alias temporal para clientes antiguos durante la migración
        CurrencyName = Config.Economy.CurrencyName,
        CurrencySymbol = Config.Economy.CurrencySymbol,
        Gems = profile.Gems,
        XP = profile.XP,
        Level = profile.Level,
        Wins = profile.Wins,
        CompetitiveRating = profile.CompetitiveRating,
        CompetitiveRank = rankName(profile.CompetitiveRating),
        SeasonPoints = profile.SeasonPoints,
        DonatedRobux = profile.DonatedRobux,
        BattlePassXP = profile.BattlePassXP,
        BattlePassTier = profile.BattlePassTier,
        PremiumPass = profile.PremiumPass,
        SpinTickets = profile.SpinTickets,
        SelectedWeapon = profile.SelectedWeapon,
        SelectedSkin = profile.SelectedSkin,
        Upgrades = copy(profile.Upgrades),
        Inventory = copy(profile.Inventory),
        Stats = copy(profile.Stats),
    }
end

function ProfileService.AddTintaMoney(player, amount)
    local profile = profiles[player]
    if not profile then return false end
    local multiplier = 1 + (profile.Upgrades.RewardBoost or 0) * 0.10
    profile.TintaMoney = math.max(0, math.floor(profile.TintaMoney + amount * multiplier))
    updateLeaderstats(player)
    return true
end

function ProfileService.SpendTintaMoney(player, amount)
    local profile = profiles[player]
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if not profile or profile.TintaMoney < amount then return false end
    profile.TintaMoney -= amount
    updateLeaderstats(player)
    return true
end

-- Aliases de compatibilidad para servicios que todavía se estén actualizando.
ProfileService.AddWon = ProfileService.AddTintaMoney
ProfileService.SpendWon = ProfileService.SpendTintaMoney

function ProfileService.AddGems(player, amount)
    local profile = profiles[player]
    if not profile then return false end
    profile.Gems = math.max(0, math.floor(profile.Gems + amount))
    return true
end

function ProfileService.SpendGems(player, amount)
    local profile = profiles[player]
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if not profile or profile.Gems < amount then return false end
    profile.Gems -= amount
    return true
end

function ProfileService.AddXP(player, amount)
    local profile = profiles[player]
    if not profile then return end
    profile.XP += math.max(0, math.floor(amount))
    while profile.XP >= profile.Level * 100 do
        profile.XP -= profile.Level * 100
        profile.Level += 1
        if profile.Level % 5 == 0 then profile.Gems += 5 end
    end
end

function ProfileService.AddBattlePassXP(player, amount)
    local profile = profiles[player]
    if not profile then return end
    profile.BattlePassXP += math.max(0, math.floor(amount))
    profile.BattlePassTier = math.clamp(math.floor(profile.BattlePassXP / Config.BattlePass.XPPerTier) + 1, 1, Config.BattlePass.MaxTier)
end

function ProfileService.AddSeasonPoints(player, amount)
    local profile = profiles[player]
    if not profile then return false end
    profile.SeasonPoints = math.max(0, math.floor(profile.SeasonPoints + amount))
    updateLeaderstats(player)
    return true
end

function ProfileService.AdjustRating(player, delta)
    local profile = profiles[player]
    if not profile then return false end
    profile.CompetitiveRating = math.max(0, math.floor(profile.CompetitiveRating + delta))
    updateLeaderstats(player)
    return true
end

function ProfileService.AddDonationRobux(player, amount)
    local profile = profiles[player]
    if not profile then return false end
    profile.DonatedRobux = math.max(0, math.floor(profile.DonatedRobux + amount))
    return true
end

function ProfileService.GrantItem(player, itemId)
    local profile = profiles[player]
    if not profile then return false end
    profile.Inventory[itemId] = math.max(1, profile.Inventory[itemId] or 0)
    return true
end

function ProfileService.SetSelectedWeapon(player, weaponId)
    local profile = profiles[player]
    if not profile or not profile.Inventory[weaponId] then return false end
    profile.SelectedWeapon = weaponId
    return true
end

function ProfileService.SetSelectedSkin(player, skinId)
    local profile = profiles[player]
    skinId = tostring(skinId or "Default")
    if not profile or not profile.Inventory[skinId] then return false end
    profile.SelectedSkin = skinId
    return true
end

function ProfileService.ApplyUpgrades(player, character)
    local profile = profiles[player]
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not profile or not humanoid then return end
    humanoid.WalkSpeed = 16 + (profile.Upgrades.SpeedBoost or 0) * 2
    humanoid.MaxHealth = 100 + (profile.Upgrades.HealthBoost or 0) * 10
    humanoid.Health = humanoid.MaxHealth
end

local function applyProductToProfile(profile, product)
    if product.GrantType == "TintaMoney" then
        profile.TintaMoney += math.max(0, math.floor(product.Amount or 0))
    elseif product.GrantType == "Donation" then
        profile.DonatedRobux += math.max(0, math.floor(product.DonationRobux or product.PriceRobux or 0))
        profile.TintaMoney += math.max(0, math.floor(product.BonusTintaMoney or 0))
    else
        return false
    end
    return true
end

function ProfileService.ApplyDeveloperProduct(player, purchaseId, product)
    local current = profiles[player]
    if not current or not product then return false, "Perfil o producto no disponible." end
    purchaseId = tostring(purchaseId or "")
    if purchaseId == "" then return false, "Receipt inválido." end
    if current.ProcessedReceipts[purchaseId] then return true, "Receipt ya procesado." end

    local working = copy(current)
    if not applyProductToProfile(working, product) then return false, "Tipo de producto inválido." end
    working.ProcessedReceipts[purchaseId] = true
    table.insert(working.ReceiptOrder, purchaseId)
    while #working.ReceiptOrder > 500 do
        local expired = table.remove(working.ReceiptOrder, 1)
        working.ProcessedReceipts[expired] = nil
    end

    local storedProfile
    local success, message = pcall(function()
        storedProfile = store:UpdateAsync("user_" .. player.UserId, function(latest)
            latest = type(latest) == "table" and migrate(latest) or defaults()
            if latest.ProcessedReceipts[purchaseId] then return latest end
            -- Se parte del estado vivo para no perder progreso aún no autoguardado.
            local merged = migrate(copy(working))
            return merged
        end)
    end)
    if not success or type(storedProfile) ~= "table" then
        warn("[TintaFinal] Receipt save failed", purchaseId, message)
        return false, "No se pudo confirmar la compra todavía."
    end

    profiles[player] = migrate(storedProfile)
    updateLeaderstats(player)
    return true, "Compra acreditada."
end

function ProfileService.StartAutosave()
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do ProfileService.Save(player) end
        end
    end)
end

return ProfileService
