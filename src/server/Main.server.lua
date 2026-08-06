local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Weapons = require(ReplicatedStorage.Shared.WeaponDefinitions)
local Services = script.Parent:WaitForChild("Services")
local ProfileService = require(Services:WaitForChild("ProfileService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local ShooterGameService = require(Services:WaitForChild("ShooterGameService"))
local WeaponService = require(Services:WaitForChild("WeaponService"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function ensureRemote(className, name)
    local existing = remotes:FindFirstChild(name)
    if existing and existing.ClassName == className then return existing end
    if existing then existing:Destroy() end
    local object = Instance.new(className)
    object.Name = name
    object.Parent = remotes
    return object
end

local GetSnapshot = ensureRemote("RemoteFunction", "GetSnapshot")
local CastVote = ensureRemote("RemoteFunction", "CastVote")
local ShopPurchase = ensureRemote("RemoteFunction", "ShopPurchase")
local Spin = ensureRemote("RemoteFunction", "Spin")
local BuyPremiumWithWon = ensureRemote("RemoteFunction", "BuyPremiumWithWon")
local ToggleAFK = ensureRemote("RemoteFunction", "ToggleAFK")
local ClaimBattlePass = ensureRemote("RemoteFunction", "ClaimBattlePass")
local SelectWeapon = ensureRemote("RemoteFunction", "SelectWeapon")
-- Compatibilidad con la interfaz anterior durante la migración.
local QueueGuard = ensureRemote("RemoteFunction", "QueueGuard")
local SelectDifficulty = ensureRemote("RemoteFunction", "SelectDifficulty")

for _, name in ipairs({ "GameState", "ProfileState", "Victory", "Eliminated", "StageReward", "AFKReward", "AmmoState", "HitConfirm", "KillFeed", "ShotFX", "FireWeapon", "ReloadWeapon" }) do
    ensureRemote("RemoteEvent", name)
end

local requestTimes = {}
local function allow(player, action, cooldown)
    requestTimes[player] = requestTimes[player] or {}
    local now = os.clock()
    local previous = requestTimes[player][action] or 0
    if now - previous < (cooldown or 0.25) then return false end
    requestTimes[player][action] = now
    return true
end

local function snapshot(player)
    return {
        Profile = ProfileService.Public(player),
        Game = ShooterGameService.GetState(),
        Config = {
            GameName = Config.GameName,
            ExpectedMaxPlayers = Config.ExpectedMaxPlayers,
            Economy = Config.Economy,
            Shooter = Config.Shooter,
            Match = Config.Match,
            BattlePass = {
                MaxTier = Config.BattlePass.MaxTier,
                XPPerTier = Config.BattlePass.XPPerTier,
                PremiumGamePassId = Config.BattlePass.PremiumGamePassId,
            },
            Spin = Config.Spin,
            Shop = Config.Shop,
            ShopOrder = Config.ShopOrder,
            Weapons = Weapons,
        },
    }
end

local function pushProfile(player)
    local profile = ProfileService.Public(player)
    if profile then remotes.ProfileState:FireClient(player, profile) end
end

local function syncPremiumOwnership(player)
    local passId = Config.BattlePass.PremiumGamePassId
    local profile = ProfileService.Get(player)
    if not profile or not passId or passId <= 0 then return end
    local success, ownsPass = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId) end)
    if success and ownsPass then profile.PremiumPass = true end
end

GetSnapshot.OnServerInvoke = function(player) return snapshot(player) end
CastVote.OnServerInvoke = function(player, mapId)
    if not allow(player, "Vote", 0.15) then return false, "Esperá un momento." end
    return ShooterGameService.CastVote(player, tostring(mapId))
end
ShopPurchase.OnServerInvoke = function(player, itemId)
    if not allow(player, "Shop", 0.4) then return false, "Esperá un momento." end
    local success, message = EconomyService.PurchaseShopItem(player, tostring(itemId))
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end
Spin.OnServerInvoke = function(player)
    if not allow(player, "Spin", 1.3) then return false, "Esperá antes de volver a girar." end
    local success, message, result = EconomyService.Spin(player)
    pushProfile(player)
    return success, message, result, ProfileService.Public(player)
end
BuyPremiumWithWon.OnServerInvoke = function(player)
    local success, message = EconomyService.BuyPremiumPassWithWon(player)
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end
ToggleAFK.OnServerInvoke = function(player)
    if not allow(player, "AFK", 0.8) then return false, "Esperá un momento." end
    return ShooterGameService.ToggleAFK(player)
end
ClaimBattlePass.OnServerInvoke = function(player, tier, premium)
    local success, message = EconomyService.ClaimBattlePassReward(player, tier, premium == true)
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end
SelectWeapon.OnServerInvoke = function(player, weaponId)
    if not allow(player, "Weapon", 0.25) then return false, "Esperá un momento." end
    local success, message, profile = WeaponService.SelectWeapon(player, tostring(weaponId))
    if success then pushProfile(player) end
    return success, message, profile
end
QueueGuard.OnServerInvoke = function() return false, "El modo guardia fue reemplazado por Arena Shooter." end
SelectDifficulty.OnServerInvoke = function() return false, "Las dificultades fueron reemplazadas por modos shooter." end

local function setupPlayer(player)
    if ProfileService.Get(player) then return end
    ProfileService.Load(player)
    syncPremiumOwnership(player)
    player:SetAttribute("InShooterMatch", false)
    player:SetAttribute("ShooterTeam", "Lobby")
    player:SetAttribute("AFKMode", false)
    player:SetAttribute("ShooterActive", false)
    player.CharacterAdded:Connect(function(character) ShooterGameService.OnCharacterAdded(player, character) end)
    if player.Character then task.spawn(ShooterGameService.OnCharacterAdded, player, player.Character) end
    pushProfile(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    if not wasPurchased or gamePassId ~= Config.BattlePass.PremiumGamePassId then return end
    local profile = ProfileService.Get(player)
    if profile then profile.PremiumPass = true pushProfile(player) end
end)

ShooterGameService.Initialize(remotes)
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    ShooterGameService.PlayerRemoving(player)
    ProfileService.Save(player)
    ProfileService.Remove(player)
    requestTimes[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, player) end

ProfileService.StartAutosave()
ShooterGameService.StartLoop()

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do ProfileService.Save(player) end
    task.wait(2)
end)
