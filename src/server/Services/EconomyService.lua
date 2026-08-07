local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)

local EconomyService = {}

local function chooseWeighted(entries, minimumRarity)
    local allowed = {}
    local total = 0
    local rarityRank = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
    local minimumRank = rarityRank[minimumRarity or "Common"] or 1
    for _, entry in ipairs(entries) do
        if (rarityRank[entry.Rarity] or 0) >= minimumRank then
            total += entry.Weight
            table.insert(allowed, entry)
        end
    end
    local roll = math.random() * total
    local cursor = 0
    for _, entry in ipairs(allowed) do
        cursor += entry.Weight
        if roll <= cursor then return entry.Rarity end
    end
    return allowed[#allowed].Rarity
end

local function spend(player, item)
    if item.Currency == "TintaMoney" then return ProfileService.SpendTintaMoney(player, item.Price) end
    if item.Currency == "Gems" then return ProfileService.SpendGems(player, item.Price) end
    return false
end

local function awardSpinResult(player, rewardId)
    local amount = string.match(rewardId, "^TintaMoney(%d+)$")
    if amount then
        ProfileService.AddTintaMoney(player, tonumber(amount))
    else
        ProfileService.GrantItem(player, rewardId)
    end
end

function EconomyService.PurchaseShopItem(player, itemId)
    local profile = ProfileService.Get(player)
    local item = Config.Shop[itemId]
    if not profile or not item then return false, "Producto inválido." end

    if item.Type == "Weapon" then
        local weaponId = item.WeaponId or itemId
        if profile.Inventory[weaponId] then return false, "Ya tenés esta arma." end
        if not spend(player, item) then return false, "Tinta Money insuficiente." end
        ProfileService.GrantItem(player, weaponId)
        return true, item.DisplayName .. " desbloqueada."
    end

    if item.Type == "Cosmetic" then
        local inventoryId = item.ItemId or itemId
        if profile.Inventory[inventoryId] then return false, "Ya tenés este aspecto." end
        if not spend(player, item) then return false, "Tinta Money insuficiente." end
        ProfileService.GrantItem(player, inventoryId)
        return true, item.DisplayName .. " desbloqueado."
    end

    if itemId == "SpinTicket" then
        if not spend(player, item) then return false, "No tenés suficiente Tinta Money." end
        profile.SpinTickets += 1
        return true, "Ticket agregado."
    end

    local level = profile.Upgrades[itemId] or 0
    if level >= (item.MaxPurchases or 1) then return false, "Mejora al máximo." end
    if not spend(player, item) then return false, "Saldo insuficiente." end
    profile.Upgrades[itemId] = level + 1
    if player.Character then ProfileService.ApplyUpgrades(player, player.Character) end
    return true, "Compra realizada."
end

function EconomyService.BuyPremiumPassWithTintaMoney(player)
    local profile = ProfileService.Get(player)
    if not profile then return false, "Perfil no disponible." end
    if profile.PremiumPass then return false, "Ya tenés el pase premium." end
    if not ProfileService.SpendTintaMoney(player, Config.Economy.BattlePassTintaMoneyPrice) then
        return false, "Necesitás más Tinta Money."
    end
    profile.PremiumPass = true
    return true, "Pase premium desbloqueado."
end

EconomyService.BuyPremiumPassWithWon = EconomyService.BuyPremiumPassWithTintaMoney

function EconomyService.QueueGuardRole()
    return false, "Los roles antiguos fueron reemplazados por Competitive Arena."
end

function EconomyService.Spin(player)
    local profile = ProfileService.Get(player)
    if not profile then return false, "Perfil no disponible." end
    if profile.SpinTickets > 0 then
        profile.SpinTickets -= 1
    elseif not ProfileService.SpendTintaMoney(player, Config.Economy.SpinTintaMoneyPrice) then
        return false, "Necesitás un ticket o más Tinta Money."
    end
    profile.SpinPity += 1
    local minimumRarity = profile.SpinPity >= Config.Spin.PityAfter and "Legendary" or "Common"
    local rarity = chooseWeighted(Config.Spin.Odds, minimumRarity)
    local pool = Config.Spin.Rewards[rarity]
    local rewardId = pool[math.random(1, #pool)]
    if rarity == "Legendary" or rarity == "Mythic" then profile.SpinPity = 0 end
    awardSpinResult(player, rewardId)
    return true, "Premio obtenido.", { Rarity = rarity, RewardId = rewardId, Pity = profile.SpinPity }
end

function EconomyService.ClaimBattlePassReward(player, tier, premium)
    local profile = ProfileService.Get(player)
    tier = tonumber(tier)
    if not profile or not tier or tier < 1 or tier > Config.BattlePass.MaxTier then return false, "Nivel inválido." end
    if profile.BattlePassTier < tier then return false, "Todavía no alcanzaste ese nivel." end
    if premium and not profile.PremiumPass then return false, "Necesitás el pase premium." end
    local track = premium and Config.BattlePass.PremiumRewards or Config.BattlePass.FreeRewards
    local reward = track[tier]
    if not reward then return false, "Este nivel no tiene recompensa." end
    local claimKey = (premium and "P" or "F") .. tostring(tier)
    if profile.ClaimedBattlePass[claimKey] then return false, "Recompensa ya reclamada." end
    profile.ClaimedBattlePass[claimKey] = true
    if reward.Type == "TintaMoney" then
        ProfileService.AddTintaMoney(player, reward.Amount)
    elseif reward.Type == "SpinTicket" then
        profile.SpinTickets += reward.Amount
    elseif reward.Type == "Cosmetic" or reward.Type == "Emote" then
        ProfileService.GrantItem(player, reward.Id)
    end
    return true, "Recompensa reclamada."
end

return EconomyService
