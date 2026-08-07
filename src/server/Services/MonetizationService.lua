local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage.Shared.MonetizationConfig)
local ProfileService = require(script.Parent.ProfileService)
local RankingService = require(script.Parent.RankingService)

local MonetizationService = {}
local remotes

local function productById(productId)
    productId = tonumber(productId) or 0
    if productId <= 0 then return nil end
    for key, product in pairs(Monetization.Products) do
        if tonumber(product.ProductId) == productId then
            local copy = table.clone(product)
            copy.Key = key
            return copy
        end
    end
    return nil
end

function MonetizationService.PublicCatalog()
    local products = {}
    for _, key in ipairs(Monetization.ProductOrder) do
        local product = Monetization.Products[key]
        if product then
            table.insert(products, {
                Key = key,
                ProductId = tonumber(product.ProductId) or 0,
                DisplayName = product.DisplayName,
                Description = product.Description,
                PriceRobux = product.PriceRobux,
                GrantType = product.GrantType,
                Amount = product.Amount,
                DonationRobux = product.DonationRobux,
                BonusTintaMoney = product.BonusTintaMoney,
            })
        end
    end
    return products
end

function MonetizationService.ProcessReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local product = productById(receiptInfo.ProductId)
    if not product then
        warn("[TintaFinal] Producto Robux no reconocido:", receiptInfo.ProductId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local success = ProfileService.ApplyDeveloperProduct(player, receiptInfo.PurchaseId, product)
    if not success then return Enum.ProductPurchaseDecision.NotProcessedYet end

    if remotes and remotes:FindFirstChild("ProfileState") then
        remotes.ProfileState:FireClient(player, ProfileService.Public(player))
    end
    task.spawn(RankingService.RecordPlayer, player)
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Bind(remoteFolder)
    remotes = remoteFolder or ReplicatedStorage:FindFirstChild("Remotes")
    MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt
end

return MonetizationService
