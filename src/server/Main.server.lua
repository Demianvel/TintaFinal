local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local ProfileService = require(script.Services.ProfileService)
local EconomyService = require(script.Services.EconomyService)
local GameService = require(script.Services.GameService)

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function ensureRemote(className, name)
    local existing = remotes:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end
    if existing then
        existing:Destroy()
    end
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
local QueueGuard = ensureRemote("RemoteFunction", "QueueGuard")
local ToggleAFK = ensureRemote("RemoteFunction", "ToggleAFK")
local ClaimBattlePass = ensureRemote("RemoteFunction", "ClaimBattlePass")
local SelectDifficulty = ensureRemote("RemoteFunction", "SelectDifficulty")

ensureRemote("RemoteEvent", "GameState")
ensureRemote("RemoteEvent", "ProfileState")
ensureRemote("RemoteEvent", "Eliminated")
ensureRemote("RemoteEvent", "Victory")
ensureRemote("RemoteEvent", "StageReward")
ensureRemote("RemoteEvent", "AFKReward")

local requestTimes = {}

local function allow(player, action, cooldown)
    requestTimes[player] = requestTimes[player] or {}
    local now = os.clock()
    local previous = requestTimes[player][action] or 0
    if now - previous < (cooldown or 0.35) then
        return false
    end
    requestTimes[player][action] = now
    return true
end

local function snapshot(player)
    return {
        Profile = ProfileService.Public(player),
        Game = GameService.GetState(),
        Config = {
            GameName = Config.GameName,
            ExpectedMaxPlayers = Config.ExpectedMaxPlayers,
            Economy = Config.Economy,
            BattlePass = {
                MaxTier = Config.BattlePass.MaxTier,
                XPPerTier = Config.BattlePass.XPPerTier,
                PremiumGamePassId = Config.BattlePass.PremiumGamePassId,
            },
            Spin = Config.Spin,
            Shop = Config.Shop,
            ShopOrder = Config.ShopOrder,
            Difficulties = Config.Difficulties,
            DifficultyOrder = Config.DifficultyOrder,
        },
    }
end

local function pushProfile(player)
    local profile = ProfileService.Public(player)
    if profile then
        remotes.ProfileState:FireClient(player, profile)
    end
end

GetSnapshot.OnServerInvoke = function(player)
    return snapshot(player)
end

CastVote.OnServerInvoke = function(player, gameId)
    if not allow(player, "Vote", 0.2) then
        return false, "Esperá un momento."
    end
    return GameService.CastVote(player, tostring(gameId))
end

ShopPurchase.OnServerInvoke = function(player, itemId)
    if not allow(player, "Shop", 0.5) then
        return false, "Esperá un momento."
    end
    local success, message = EconomyService.PurchaseShopItem(player, tostring(itemId))
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end

Spin.OnServerInvoke = function(player)
    if not allow(player, "Spin", 1.5) then
        return false, "Esperá antes de volver a girar."
    end
    local success, message, result = EconomyService.Spin(player)
    pushProfile(player)
    return success, message, result, ProfileService.Public(player)
end

BuyPremiumWithWon.OnServerInvoke = function(player)
    if not allow(player, "Premium", 1) then
        return false, "Esperá un momento."
    end
    local success, message = EconomyService.BuyPremiumPassWithWon(player)
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end

QueueGuard.OnServerInvoke = function(player)
    if not allow(player, "Guard", 1) then
        return false, "Esperá un momento."
    end
    local success, message = EconomyService.QueueGuardRole(player)
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end

ToggleAFK.OnServerInvoke = function(player)
    if not allow(player, "AFK", 1) then
        return false, "Esperá un momento."
    end
    return GameService.ToggleAFK(player)
end

ClaimBattlePass.OnServerInvoke = function(player, tier, premium)
    if not allow(player, "Claim", 0.5) then
        return false, "Esperá un momento."
    end
    local success, message = EconomyService.ClaimBattlePassReward(player, tier, premium == true)
    pushProfile(player)
    return success, message, ProfileService.Public(player)
end

SelectDifficulty.OnServerInvoke = function(player, difficultyName)
    if not allow(player, "Difficulty", 0.5) then
        return false, "Esperá un momento."
    end

    local profile = ProfileService.Get(player)
    local definition = Config.Difficulties[tostring(difficultyName)]
    if not profile or not definition then
        return false, "Dificultad inválida."
    end
    if profile.Wins < definition.RequiredWins then
        return false, "Necesitás " .. definition.RequiredWins .. " victorias."
    end

    profile.SelectedDifficulty = tostring(difficultyName)
    pushProfile(player)
    return true, "Dificultad seleccionada.", ProfileService.Public(player)
end

local function setupPlayer(player)
    if ProfileService.Get(player) then
        return
    end

    ProfileService.Load(player)
    player:SetAttribute("AliveInMatch", false)
    player:SetAttribute("MatchRole", "Lobby")
    player:SetAttribute("AFKMode", false)

    player.CharacterAdded:Connect(function(character)
        GameService.OnCharacterAdded(player, character)
    end)

    if player.Character then
        task.spawn(GameService.OnCharacterAdded, player, player.Character)
    end
    pushProfile(player)
end

GameService.Initialize(remotes)

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    GameService.PlayerRemoving(player)
    ProfileService.Save(player)
    ProfileService.Remove(player)
    requestTimes[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

ProfileService.StartAutosave()
GameService.StartLoop()

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        ProfileService.Save(player)
    end
    task.wait(2)
end)
