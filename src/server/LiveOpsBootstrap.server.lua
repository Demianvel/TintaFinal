local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GamePassConfig = require(Shared:WaitForChild("GamePassConfig"))
local LiveOpsConfig = require(Shared:WaitForChild("LiveOpsConfig"))

local Services = script.Parent:WaitForChild("Services")
local ProfileService = require(Services:WaitForChild("ProfileService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local WeatherService = require(Services:WaitForChild("WeatherService"))
local EventService = require(Services:WaitForChild("EventService"))
local UniverseMessagingService = require(Services:WaitForChild("UniverseMessagingService"))
local AdminService = require(Services:WaitForChild("AdminService"))
local GamePassService = require(Services:WaitForChild("GamePassService"))
local WeaponService = require(Services:WaitForChild("WeaponService"))

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

local GetLiveOpsSnapshot = ensureRemote("RemoteFunction", "GetLiveOpsSnapshot")
local AdminCommand = ensureRemote("RemoteFunction", "AdminCommand")
local GetAdminState = ensureRemote("RemoteFunction", "GetAdminState")
local SendDirectMessage = ensureRemote("RemoteFunction", "SendDirectMessage")

for _, name in ipairs({
    "WeatherState",
    "UniverseEventState",
    "GlobalAnnouncement",
    "DirectMessage",
    "AdminFeedback",
    "AdminState",
}) do
    ensureRemote("RemoteEvent", name)
end

-- Multiplicadores de LiveOps sin romper los servicios existentes.
if not ProfileService.__LiveOpsWrapped then
    ProfileService.__LiveOpsWrapped = true
    local originalAddTintaMoney = ProfileService.AddTintaMoney
    local originalAddXP = ProfileService.AddXP
    local originalAddBattlePassXP = ProfileService.AddBattlePassXP

    ProfileService.AddTintaMoney = function(player, amount, bypassLiveOps)
        amount = tonumber(amount) or 0
        if not bypassLiveOps then
            local eventMultiplier = tonumber(workspace:GetAttribute("TintaMoneyMultiplier")) or 1
            local vipMultiplier = player:GetAttribute("TintaVIP") == true and 1.10 or 1
            amount *= eventMultiplier * vipMultiplier
        end
        return originalAddTintaMoney(player, amount)
    end

    ProfileService.AddXP = function(player, amount, bypassLiveOps)
        amount = tonumber(amount) or 0
        if not bypassLiveOps then
            local eventMultiplier = tonumber(workspace:GetAttribute("TintaXPMultiplier")) or 1
            local passMultiplier = player:GetAttribute("TintaDoubleXP") == true and 2 or 1
            amount *= eventMultiplier * passMultiplier
        end
        originalAddXP(player, amount)
        -- El XP ganado jugando alimenta también el Battle Pass.
        originalAddBattlePassXP(player, amount)
    end

    ProfileService.AddBattlePassXP = function(player, amount, bypassLiveOps)
        amount = tonumber(amount) or 0
        if not bypassLiveOps then
            local eventMultiplier = tonumber(workspace:GetAttribute("TintaXPMultiplier")) or 1
            local passMultiplier = player:GetAttribute("TintaDoubleXP") == true and 2 or 1
            amount *= eventMultiplier * passMultiplier
        end
        return originalAddBattlePassXP(player, amount)
    end
end

if not EconomyService.__LiveOpsWrapped then
    EconomyService.__LiveOpsWrapped = true
    local originalSpin = EconomyService.Spin
    EconomyService.Spin = function(player)
        local profile = ProfileService.Get(player)
        if profile then
            local eventLuck = tonumber(workspace:GetAttribute("TintaSpinLuckMultiplier")) or 1
            local passLuck = player:GetAttribute("TintaSpinBooster") == true and 1.5 or 1
            local combined = eventLuck * passLuck
            if combined > 1 then
                profile.SpinPity = math.min(GameConfig.Spin.PityAfter - 1, (profile.SpinPity or 0) + math.max(1, math.floor((combined - 1) * 4)))
            end
        end
        return originalSpin(player)
    end
end

WeatherService.Initialize(remotes)
EventService.Initialize(remotes, WeatherService)
UniverseMessagingService.Initialize(remotes, EventService, WeatherService)
GamePassService.Initialize(remotes)
AdminService.Initialize(remotes, {
    ProfileService = ProfileService,
    EventService = EventService,
    WeatherService = WeatherService,
    UniverseMessagingService = UniverseMessagingService,
    WeaponService = WeaponService,
})

local function liveSnapshot(player)
    return {
        Profile = ProfileService.Public(player),
        Weather = WeatherService.GetState(),
        Event = EventService.GetState(),
        Admin = AdminService.GetState(player),
        Config = {
            GamePasses = {
                PassOrder = GamePassConfig.PassOrder,
                Passes = GamePassService.PublicCatalog(),
            },
            BattlePass = {
                MaxTier = GameConfig.BattlePass.MaxTier,
                XPPerTier = GameConfig.BattlePass.XPPerTier,
                FreeRewards = GameConfig.BattlePass.FreeRewards,
                PremiumRewards = GameConfig.BattlePass.PremiumRewards,
            },
            LiveOps = {
                Events = LiveOpsConfig.Events.Definitions,
                Weather = LiveOpsConfig.Weather.Profiles,
                Voice = LiveOpsConfig.Voice,
            },
        },
    }
end

GetLiveOpsSnapshot.OnServerInvoke = function(player)
    return liveSnapshot(player)
end

GetAdminState.OnServerInvoke = function(player)
    return AdminService.GetState(player)
end

AdminCommand.OnServerInvoke = function(player, action, payload)
    return AdminService.ExecuteStructured(player, action, payload)
end

SendDirectMessage.OnServerInvoke = function(player, targetReference, text)
    return UniverseMessagingService.SendDirectMessage(player, targetReference, text)
end

local function setupPlayer(player)
    local banned, banData = AdminService.CheckBan(player)
    if banned then
        player:Kick("Tinta Final Ban: " .. tostring(banData.Reason or "Acceso restringido."))
        return
    end

    local deadline = os.clock() + 20
    while player.Parent and not ProfileService.Get(player) and os.clock() < deadline do
        task.wait(0.15)
    end
    if not player.Parent then return end

    AdminService.SetupPlayer(player)
    UniverseMessagingService.SubscribePlayer(player)
    GamePassService.SyncPlayer(player)

    remotes.WeatherState:FireClient(player, WeatherService.GetState())
    remotes.UniverseEventState:FireClient(player, EventService.GetState())
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(setupPlayer, player)
end)
Players.PlayerRemoving:Connect(function(player)
    AdminService.RemovePlayer(player)
    UniverseMessagingService.UnsubscribePlayer(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    GamePassService.OnPurchaseFinished(player, gamePassId, wasPurchased)
end)

WeatherService.StartAutoRotation()
EventService.StartAutoRotation()

game:BindToClose(function()
    UniverseMessagingService.Destroy()
end)
