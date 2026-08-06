local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Parent.ProfileService)

local EconomyService = {}

local function chooseWeighted(entries, minimumRarity)
    local allowed = {}
    local total = 0
    local rarityRank = {
        Common = 1,
        Rare = 2,
        Epic = 3,
        Legendary = 4,
        Mythic = 5,
    }
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
        if roll <= cursor then
            return entry.Rarity
        end
    end
    return allowed[#allowed].Rarity
end

local function awardSpinResult(player, rewardId)
    local profile = ProfileService.Get(player)
    if not profile then
        return
    end

    local wonAmount = string.match(rewardId, "^Won(%d+)$")
    if wonAmount then
        ProfileService.AddWon(player, tonumber(wonAmount))
    else
        ProfileService.GrantItem(player, rewardId)
    end
end

function EconomyService.PurchaseShopItem(player, itemId)
    local profile = ProfileService.Get(player)
    local item = Config.Shop[itemId]
    if not profile or not item then
        return false, "Producto inválido."
    end

    if itemId == "SpinTicket" then
        if not ProfileService.SpendWon(player, item.Price) then
            return false, "No tenés suficientes Won."
        end
        profile.SpinTickets += 1
        return true, "Ticket agregado."
    end

    local level = profile.Upgrades[itemId] or 0
    if level >= item.MaxPurchases then
        return false, "Mejora al máximo."
    end

    local spent
    if item.Currency == "Won" then
        spent = ProfileService.SpendWon(player, item.Price)
    elseif item.Currency == "Gems" then
        spent = ProfileService.SpendGems(player, item.Price)
    end

    if not spent then
        return false, "Saldo insuficiente."
    end

    profile.Upgrades[itemId] = level + 1
    if player.Character then
        ProfileService.ApplyUpgrades(player, player.Character)
    end
    return true, "Compra realizada."
end

function EconomyService.BuyPremiumPassWithWon(player)
    local profile = ProfileService.Get(player)
    if not profile then
        return false, "Perfil no disponible."
    end
    if profile.PremiumPass then
        return false, "Ya tenés el pase premium."
    end
    if not ProfileService.SpendWon(player, Config.Economy.BattlePassWonPrice) then
        return false, "Necesitás más Won."
    end
    profile.PremiumPass = true
    return true, "Pase premium desbloqueado."
end

function EconomyService.QueueGuardRole(player)
    local profile = ProfileService.Get(player)
    if not profile then
        return false, "Perfil no disponible."
    end
    if profile.GuardQueued then
        return false, "Ya estás anotado como guardia."
    end
    if not ProfileService.SpendWon(player, Config.Economy.GuardRoleCost) then
        return false, "Necesitás más Won para ser guardia."
    end
    profile.GuardQueued = true
    return true, "Quedaste anotado como guardia para la próxima partida."
end

function EconomyService.Spin(player)
    local profile = ProfileService.Get(player)
    if not profile then
        return false, "Perfil no disponible."
    end

    if profile.SpinTickets > 0 then
        profile.SpinTickets -= 1
    elseif ProfileService.SpendWon(player, Config.Economy.SpinWonPrice) then
        -- Won solo se obtiene jugando y no se vende por Robux.
    else
        return false, "Necesitás un ticket o más Won."
    end

    profile.SpinPity += 1
    local minimumRarity = profile.SpinPity >= Config.Spin.PityAfter and "Legendary" or "Common"
    local rarity = chooseWeighted(Config.Spin.Odds, minimumRarity)
    local pool = Config.Spin.Rewards[rarity]
    local rewardId = pool[math.random(1, #pool)]

    if rarity == "Legendary" or rarity == "Mythic" then
        profile.SpinPity = 0
    end

    awardSpinResult(player, rewardId)
    return true, "Premio obtenido.", {
        Rarity = rarity,
        RewardId = rewardId,
        Pity = profile.SpinPity,
    }
end

function EconomyService.ClaimBattlePassReward(player, tier, premium)
    local profile = ProfileService.Get(player)
    tier = tonumber(tier)
    if not profile or not tier or tier < 1 or tier > Config.BattlePass.MaxTier then
        return false, "Nivel inválido."
    end
    if profile.BattlePassTier < tier then
        return false, "Todavía no alcanzaste ese nivel."
    end
    if premium and not profile.PremiumPass then
        return false, "Necesitás el pase premium."
    end

    local track = premium and Config.BattlePass.PremiumRewards or Config.BattlePass.FreeRewards
    local reward = track[tier]
    if not reward then
        return false, "Este nivel no tiene recompensa."
    end

    local claimKey = (premium and "P" or "F") .. tostring(tier)
    if profile.ClaimedBattlePass[claimKey] then
        return false, "Recompensa ya reclamada."
    end
    profile.ClaimedBattlePass[claimKey] = true

    if reward.Type == "Won" then
        ProfileService.AddWon(player, reward.Amount)
    elseif reward.Type == "SpinTicket" then
        profile.SpinTickets += reward.Amount
    elseif reward.Type == "Cosmetic" or reward.Type == "Emote" then
        ProfileService.GrantItem(player, reward.Id)
    end

    return true, "Recompensa reclamada."
end

return EconomyService
