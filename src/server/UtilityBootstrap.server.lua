local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local UtilityDefinitions = require(Shared:WaitForChild("UtilityDefinitions"))

local Services = script.Parent:WaitForChild("Services")
local ProfileService = require(Services:WaitForChild("ProfileService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local UtilityService = require(Services:WaitForChild("UtilityService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function ensureRemote(className, name)
    local existing = remotes:FindFirstChild(name)
    if existing and existing.ClassName == className then return existing end
    if existing then existing:Destroy() end
    local object = Instance.new(className)
    object.Name = name
    object.Parent = remotes
    return object
end

local UseUtility = ensureRemote("RemoteFunction", "UseUtility")
local GetUtilityState = ensureRemote("RemoteFunction", "GetUtilityState")
ensureRemote("RemoteEvent", "UtilityState")

local function appendUnique(list, value)
    if not table.find(list, value) then table.insert(list, value) end
end

for utilityId, definition in pairs(UtilityDefinitions) do
    appendUnique(Config.ShopOrder, utilityId)
    Config.Shop[utilityId] = {
        Type = "Utility",
        ItemId = utilityId,
        DisplayName = definition.DisplayName,
        Description = definition.Description,
        Currency = "TintaMoney",
        Price = definition.Price,
        MaxPurchases = 999,
    }
end

appendUnique(Config.Spin.Rewards.Common, "UtilityMedkit")
appendUnique(Config.Spin.Rewards.Rare, "UtilitySmoke")
appendUnique(Config.Spin.Rewards.Rare, "UtilityStim")
appendUnique(Config.Spin.Rewards.Epic, "UtilityInkGrenade")

UtilityService.Initialize(remotes)

if not ProfileService.__UtilityGrantWrapped then
    ProfileService.__UtilityGrantWrapped = true
    local originalGrantItem = ProfileService.GrantItem
    ProfileService.GrantItem = function(player, itemId)
        if UtilityDefinitions[itemId] then return UtilityService.Grant(player, itemId, 1) end
        return originalGrantItem(player, itemId)
    end
end

if not EconomyService.__UtilityShopWrapped then
    EconomyService.__UtilityShopWrapped = true
    local originalPurchase = EconomyService.PurchaseShopItem
    EconomyService.PurchaseShopItem = function(player, itemId)
        local item = Config.Shop[itemId]
        if item and item.Type == "Utility" then
            local spent = false
            if item.Currency == "TintaMoney" then spent = ProfileService.SpendTintaMoney(player, item.Price)
            elseif item.Currency == "Gems" then spent = ProfileService.SpendGems(player, item.Price) end
            if not spent then return false, "Saldo insuficiente." end
            UtilityService.Grant(player, itemId, 1)
            return true, item.DisplayName .. " agregado al inventario."
        end
        return originalPurchase(player, itemId)
    end
end

UseUtility.OnServerInvoke = function(player, utilityId, direction)
    return UtilityService.Use(player, utilityId, direction)
end

GetUtilityState.OnServerInvoke = function(player)
    return UtilityService.GetState(player)
end

local function setupPlayer(player)
    local deadline = os.clock() + 20
    while player.Parent and not ProfileService.Get(player) and os.clock() < deadline do task.wait(0.15) end
    local profile = ProfileService.Get(player)
    if not profile then return end
    if profile.Inventory.UtilityMedkit == nil then UtilityService.Grant(player, "UtilityMedkit", 1) end
    if profile.Inventory.UtilitySmoke == nil then UtilityService.Grant(player, "UtilitySmoke", 1) end
end

Players.PlayerAdded:Connect(function(player) task.spawn(setupPlayer, player) end)
Players.PlayerRemoving:Connect(function(player) UtilityService.RemovePlayer(player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, player) end
