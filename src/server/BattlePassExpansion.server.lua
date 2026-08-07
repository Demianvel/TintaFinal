local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))

-- Expansión S1: 100 niveles. Se modifica la misma tabla compartida por los
-- servicios del servidor, por lo que EconomyService y ProfileService adoptan
-- los nuevos límites sin duplicar lógica.
Config.BattlePass.MaxTier = 100
Config.BattlePass.XPPerTier = 120

local free = Config.BattlePass.FreeRewards
local premium = Config.BattlePass.PremiumRewards

for tier = 5, 100, 5 do
    if free[tier] == nil then
        if tier % 20 == 0 then
            free[tier] = { Type = "SpinTicket", Amount = math.max(1, math.floor(tier / 20)) }
        else
            free[tier] = { Type = "TintaMoney", Amount = 1_000 + tier * 250 }
        end
    end

    if premium[tier] == nil then
        if tier % 25 == 0 then
            premium[tier] = { Type = "Cosmetic", Id = "S1PremiumTier" .. tostring(tier) }
        elseif tier % 10 == 0 then
            premium[tier] = { Type = "SpinTicket", Amount = math.max(2, math.floor(tier / 10)) }
        else
            premium[tier] = { Type = "TintaMoney", Amount = 3_000 + tier * 500 }
        end
    end
end

free[75] = free[75] or { Type = "Cosmetic", Id = "S1CyanStormTrail" }
free[100] = { Type = "Cosmetic", Id = "S1ChampionBanner" }
premium[60] = premium[60] or { Type = "Cosmetic", Id = "S1NeonOperator" }
premium[75] = { Type = "Cosmetic", Id = "S1PrismWeaponWrap" }
premium[90] = { Type = "Cosmetic", Id = "S1StormCrown" }
premium[100] = { Type = "Cosmetic", Id = "S1LegendArmor" }
