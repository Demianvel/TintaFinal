local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))
local Weapons = require(ReplicatedStorage.Shared:WaitForChild("WeaponDefinitions"))

local function appendUnique(list, value)
    if not table.find(list, value) then table.insert(list, value) end
end

local additions = {
    AuroraAR = {
        DisplayName = "AURORA AR",
        Class = "Rifle",
        Damage = 27,
        HeadshotMultiplier = 1.58,
        FireInterval = 0.12,
        Magazine = 32,
        ReloadSeconds = 1.75,
        Range = 470,
        Pellets = 1,
        SpreadDegrees = 0.68,
        Automatic = true,
        Accent = Color3.fromRGB(80, 255, 220),
        Recoil = 0.72,
    },
    ShadowSMG = {
        DisplayName = "SHADOW SMG",
        Class = "SMG",
        Damage = 18,
        HeadshotMultiplier = 1.42,
        FireInterval = 0.076,
        Magazine = 42,
        ReloadSeconds = 1.62,
        Range = 285,
        Pellets = 1,
        SpreadDegrees = 2.05,
        Automatic = true,
        Accent = Color3.fromRGB(165, 75, 255),
        Recoil = 0.48,
    },
    ThunderShotgun = {
        DisplayName = "THUNDER SHOTGUN",
        Class = "Shotgun",
        Damage = 14,
        HeadshotMultiplier = 1.28,
        FireInterval = 0.82,
        Magazine = 8,
        ReloadSeconds = 2.35,
        Range = 165,
        Pellets = 7,
        SpreadDegrees = 6.7,
        Automatic = false,
        Accent = Color3.fromRGB(255, 205, 45),
        Recoil = 1.25,
    },
    RailCarbine = {
        DisplayName = "RAIL CARBINE",
        Class = "Carbine",
        Damage = 38,
        HeadshotMultiplier = 1.62,
        FireInterval = 0.29,
        Magazine = 20,
        ReloadSeconds = 1.95,
        Range = 620,
        Pellets = 1,
        SpreadDegrees = 0.30,
        Automatic = false,
        Accent = Color3.fromRGB(70, 150, 255),
        Recoil = 0.82,
    },
    NovaPistol = {
        DisplayName = "NOVA PISTOL",
        Class = "Pistol",
        Damage = 29,
        HeadshotMultiplier = 1.72,
        FireInterval = 0.19,
        Magazine = 16,
        ReloadSeconds = 1.28,
        Range = 345,
        Pellets = 1,
        SpreadDegrees = 0.64,
        Automatic = false,
        Accent = Color3.fromRGB(255, 100, 205),
        Recoil = 0.52,
    },
    EclipseSniper = {
        DisplayName = "ECLIPSE SNIPER",
        Class = "Sniper",
        Damage = 88,
        HeadshotMultiplier = 1.82,
        FireInterval = 1.38,
        Magazine = 5,
        ReloadSeconds = 2.8,
        Range = 1_050,
        Pellets = 1,
        SpreadDegrees = 0.08,
        Automatic = false,
        Accent = Color3.fromRGB(235, 115, 255),
        Recoil = 1.35,
    },
}

for id, definition in pairs(additions) do Weapons[id] = definition end

local prices = {
    AuroraAR = 68_000,
    ShadowSMG = 48_000,
    ThunderShotgun = 64_000,
    RailCarbine = 88_000,
    NovaPistol = 34_000,
    EclipseSniper = 145_000,
}

for id, price in pairs(prices) do
    appendUnique(Config.Shooter.WeaponOrder, id)
    appendUnique(Config.ShopOrder, id)
    Config.Shop[id] = {
        Type = "Weapon",
        WeaponId = id,
        DisplayName = Weapons[id].DisplayName,
        Description = "Arma competitiva original de Tinta Final · " .. tostring(Weapons[id].Class),
        Currency = "TintaMoney",
        Price = price,
        MaxPurchases = 1,
    }
end

appendUnique(Config.Spin.Rewards.Epic, "NovaPistol")
appendUnique(Config.Spin.Rewards.Epic, "ShadowSMG")
appendUnique(Config.Spin.Rewards.Legendary, "AuroraAR")
appendUnique(Config.Spin.Rewards.Legendary, "ThunderShotgun")
appendUnique(Config.Spin.Rewards.Mythic, "RailCarbine")
appendUnique(Config.Spin.Rewards.Mythic, "EclipseSniper")
