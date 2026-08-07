local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePassConfig = require(ReplicatedStorage.Shared.GamePassConfig)
local ProfileService = require(script.Parent.ProfileService)

local GamePassService = {}
local remotes

local function applyPerk(player, key, definition, owns)
    player:SetAttribute("GamePass_" .. key, owns == true)
    if not owns then return end

    local profile = ProfileService.Get(player)
    if not profile then return end

    if definition.Perk == "PremiumBattlePass" then
        profile.PremiumPass = true
    elseif definition.Perk == "VIP" then
        player:SetAttribute("TintaVIP", true)
        if not profile.Inventory.VIPNeonAura then
            ProfileService.GrantItem(player, "VIPNeonAura")
        end
    elseif definition.Perk == "DoubleXP" then
        player:SetAttribute("TintaDoubleXP", true)
    elseif definition.Perk == "SpinBooster" then
        player:SetAttribute("TintaSpinBooster", true)
    elseif definition.Perk == "Founder" then
        player:SetAttribute("TintaFounder", true)
        if not profile.Inventory.FounderSkin then
            ProfileService.GrantItem(player, "FounderSkin")
            ProfileService.GrantItem(player, "FounderTitle")
            ProfileService.AddTintaMoney(player, 100_000, true)
        end
    end
end

function GamePassService.PublicCatalog()
    local result = {}
    for key, definition in pairs(GamePassConfig.Passes) do
        result[key] = {
            GamePassId = definition.GamePassId,
            DisplayName = definition.DisplayName,
            Description = definition.Description,
            PriceRobux = definition.PriceRobux,
            Perk = definition.Perk,
        }
    end
    return result
end

function GamePassService.SyncPlayer(player)
    for key, definition in pairs(GamePassConfig.Passes) do
        local passId = tonumber(definition.GamePassId) or 0
        local owns = false
        if passId > 0 then
            local ok, value = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            owns = ok and value == true
        end
        applyPerk(player, key, definition, owns)
    end

    if remotes and remotes:FindFirstChild("ProfileState") then
        local public = ProfileService.Public(player)
        if public then remotes.ProfileState:FireClient(player, public) end
    end
end

function GamePassService.OnPurchaseFinished(player, gamePassId, purchased)
    if not purchased then return end
    for key, definition in pairs(GamePassConfig.Passes) do
        if tonumber(definition.GamePassId) == tonumber(gamePassId) then
            applyPerk(player, key, definition, true)
            if remotes and remotes:FindFirstChild("ProfileState") then
                local public = ProfileService.Public(player)
                if public then remotes.ProfileState:FireClient(player, public) end
            end
            return
        end
    end
end

function GamePassService.Initialize(remoteFolder)
    remotes = remoteFolder
end

return GamePassService
