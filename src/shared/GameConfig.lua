local Config = {}

Config.GameName = "Tinta Final: Arena Shooter"
Config.UniverseId = 8973271699
Config.PlaceId = 73618099851560
Config.ExpectedMaxPlayers = 100
Config.DataStoreName = "TintaFinal_PlayerData_v3"
Config.BuildRevision = "2026.08.06.shooter.1"

Config.Match = {
    MinimumPlayers = 1,
    IntermissionSeconds = 15,
    VotingSeconds = 12,
    LoadingSeconds = 5,
    ResultsSeconds = 10,
    RoundSeconds = 180,
    TeamScoreLimit = 40,
    FFAScoreLimit = 20,
    SurvivalWaves = 5,
    RespawnSeconds = 4,
    FinalRewardWon = 8_000,
    ParticipationWon = 250,
    KillRewardWon = 120,
    BotKillRewardWon = 60,
    WinXP = 350,
    KillXP = 35,
}

Config.Shooter = {
    DefaultWeapon = "InkRifle",
    WeaponOrder = { "InkRifle", "NeonSMG", "SplashShotgun" },
    MapOrder = { "NeonDistrict", "InkDepot", "RooftopRush" },
    Modes = {
        Survival = { DisplayName = "Supervivencia de Tinta", MinimumPlayers = 1 },
        TeamSplash = { DisplayName = "Cian vs Magenta", MinimumPlayers = 2 },
        FreeSplash = { DisplayName = "Todos contra todos", MinimumPlayers = 2 },
    },
}

Config.Economy = {
    CurrencyName = "Won",
    CurrencySymbol = "₩",
    StartingWon = 1_000,
    StartingGems = 10,
    BattlePassWonPrice = 200_000,
    AFKRewardWon = 25,
    AFKRewardIntervalSeconds = 60,
    AFKSessionCapWon = 1_500,
    SpinWonPrice = 3_000,
}

Config.BattlePass = {
    MaxTier = 50,
    XPPerTier = 100,
    PremiumGamePassId = 0,
    FreeRewards = {
        [1] = { Type = "Won", Amount = 500 },
        [5] = { Type = "SpinTicket", Amount = 1 },
        [10] = { Type = "Won", Amount = 2_500 },
        [20] = { Type = "SpinTicket", Amount = 2 },
        [30] = { Type = "Won", Amount = 8_000 },
        [40] = { Type = "SpinTicket", Amount = 3 },
        [50] = { Type = "Cosmetic", Id = "InkChampionAura" },
    },
    PremiumRewards = {
        [1] = { Type = "SpinTicket", Amount = 2 },
        [10] = { Type = "Cosmetic", Id = "NeonTrail" },
        [20] = { Type = "Emote", Id = "VictoryPose" },
        [30] = { Type = "Cosmetic", Id = "GoldenMask" },
        [40] = { Type = "SpinTicket", Amount = 8 },
        [50] = { Type = "Cosmetic", Id = "MythicInkCrown" },
    },
}

Config.Spin = {
    Odds = {
        { Rarity = "Common", DisplayName = "Común", Weight = 55 },
        { Rarity = "Rare", DisplayName = "Raro", Weight = 27 },
        { Rarity = "Epic", DisplayName = "Épico", Weight = 12 },
        { Rarity = "Legendary", DisplayName = "Legendario", Weight = 5 },
        { Rarity = "Mythic", DisplayName = "Mítico", Weight = 1 },
    },
    PityAfter = 40,
    Rewards = {
        Common = { "EmoteWave", "InkTrailBlue", "Won1000" },
        Rare = { "EmoteDance", "InkTrailGreen", "Won3000" },
        Epic = { "VictoryPose", "InkTrailPurple", "Won8000" },
        Legendary = { "GoldenMask", "Won20000" },
        Mythic = { "MythicInkCrown", "VoidAura", "Won50000" },
    },
}

Config.ShopOrder = { "SpeedBoost", "HealthBoost", "NeonSMG", "SplashShotgun", "RewardBoost", "SpinTicket" }
Config.Shop = {
    SpeedBoost = {
        Type = "Upgrade",
        DisplayName = "Velocidad +2",
        Description = "Mejora permanente para moverte por las arenas.",
        Currency = "Won",
        Price = 8_000,
        MaxPurchases = 3,
    },
    HealthBoost = {
        Type = "Upgrade",
        DisplayName = "Resistencia +10",
        Description = "Aumenta permanentemente tu vida máxima.",
        Currency = "Won",
        Price = 12_000,
        MaxPurchases = 5,
    },
    NeonSMG = {
        Type = "Weapon",
        WeaponId = "NeonSMG",
        DisplayName = "SMG Neón",
        Description = "Alta cadencia para combate cercano.",
        Currency = "Won",
        Price = 18_000,
        MaxPurchases = 1,
    },
    SplashShotgun = {
        Type = "Weapon",
        WeaponId = "SplashShotgun",
        DisplayName = "Escopeta Splash",
        Description = "Dispersión de tinta potente a corta distancia.",
        Currency = "Won",
        Price = 28_000,
        MaxPurchases = 1,
    },
    RewardBoost = {
        Type = "Upgrade",
        DisplayName = "Premio +10%",
        Description = "Aumenta las recompensas obtenidas jugando.",
        Currency = "Gems",
        Price = 35,
        MaxPurchases = 3,
    },
    SpinTicket = {
        Type = "Consumable",
        DisplayName = "Ticket de giro",
        Description = "Permite realizar un giro de recompensa.",
        Currency = "Won",
        Price = 3_000,
        MaxPurchases = 999,
    },
}

Config.Audio = {
    LobbyMusic = 0,
    VotingMusic = 0,
    RoundMusic = 0,
    VictoryMusic = 0,
    ShotSound = 0,
    HitSound = 0,
    EliminationSound = 0,
}

Config.FeatureFlags = {
    ServerAuthoritativeWeapons = true,
    SoloSurvivalFallback = true,
    NonGraphicCombat = true,
}

return Config
