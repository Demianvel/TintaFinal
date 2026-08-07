local Config = {}

Config.GameName = "Tinta Final: Competitive Arena"
Config.UniverseId = 8973271699
Config.PlaceId = 73618099851560
Config.ExpectedMaxPlayers = 20
Config.DataStoreName = "TintaFinal_PlayerData_v4"
Config.BuildRevision = "2026.08.06.competitive.2"

Config.Match = {
    MinimumPlayers = 1,
    MaxParticipants = 20,
    TeamSize = 10,
    IntermissionSeconds = 14,
    VotingSeconds = 10,
    LoadingSeconds = 5,
    ResultsSeconds = 10,
    RoundSeconds = 360,
    TeamScoreLimit = 75,
    FFAScoreLimit = 30,
    SurvivalWaves = 5,
    RespawnSeconds = 4,
    ParticipationTintaMoney = 350,
    WinTintaMoney = 8_000,
    KillTintaMoney = 140,
    BotKillTintaMoney = 70,
    WinXP = 400,
    KillXP = 40,
}

Config.Competitive = {
    StartingRating = 1_000,
    RatingK = 32,
    SeasonId = "S1-NEON",
    WinSeasonPoints = 100,
    LossSeasonPoints = 35,
    KillSeasonPoints = 2,
    PodiumRewards = {
        [1] = 300_000_000,
        [2] = 150_000_000,
        [3] = 100_000_000,
    },
    Ranks = {
        { Min = 0, Name = "BRONZE" },
        { Min = 900, Name = "SILVER" },
        { Min = 1_100, Name = "GOLD" },
        { Min = 1_300, Name = "PLATINUM" },
        { Min = 1_500, Name = "DIAMOND" },
        { Min = 1_750, Name = "ELITE" },
        { Min = 2_000, Name = "MASTER" },
        { Min = 2_300, Name = "TINTA LEGEND" },
    },
}

Config.Shooter = {
    DefaultWeapon = "InkRifle",
    WeaponOrder = {
        "InkRifle",
        "NeonSMG",
        "SplashShotgun",
        "PulseCarbine",
        "ViperPistol",
        "PrismSniper",
        "VoltLMG",
        "BurstRifle",
    },
    MapOrder = { "NeonDistrict", "InkDepot", "RooftopRush" },
    Modes = {
        TeamSplash = {
            DisplayName = "10 VS 10 · CIAN VS MAGENTA",
            MinimumPlayers = 2,
            Competitive = true,
        },
        FreeSplash = {
            DisplayName = "TODOS CONTRA TODOS",
            MinimumPlayers = 2,
            Competitive = true,
        },
        Survival = {
            DisplayName = "ENTRENAMIENTO DE TINTA",
            MinimumPlayers = 1,
            Competitive = false,
        },
    },
}

Config.Economy = {
    CurrencyName = "Tinta Money",
    CurrencyKey = "TintaMoney",
    CurrencySymbol = "TM",
    StartingTintaMoney = 5_000,
    StartingGems = 10,
    BattlePassTintaMoneyPrice = 200_000,
    AFKRewardTintaMoney = 25,
    AFKRewardIntervalSeconds = 60,
    AFKSessionCapTintaMoney = 1_500,
    SpinTintaMoneyPrice = 3_000,
}

Config.BattlePass = {
    MaxTier = 50,
    XPPerTier = 100,
    PremiumGamePassId = 0,
    FreeRewards = {
        [1] = { Type = "TintaMoney", Amount = 1_000 },
        [5] = { Type = "SpinTicket", Amount = 1 },
        [10] = { Type = "TintaMoney", Amount = 5_000 },
        [20] = { Type = "SpinTicket", Amount = 2 },
        [30] = { Type = "TintaMoney", Amount = 15_000 },
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
        Common = { "EmoteWave", "InkTrailBlue", "TintaMoney1000" },
        Rare = { "EmoteDance", "InkTrailGreen", "TintaMoney3000" },
        Epic = { "VictoryPose", "InkTrailPurple", "TintaMoney8000" },
        Legendary = { "GoldenMask", "TintaMoney20000" },
        Mythic = { "MythicInkCrown", "VoidAura", "TintaMoney50000" },
    },
}

Config.ShopOrder = {
    "NeonSMG",
    "SplashShotgun",
    "PulseCarbine",
    "ViperPistol",
    "PrismSniper",
    "VoltLMG",
    "BurstRifle",
    "SpeedBoost",
    "HealthBoost",
    "RewardBoost",
    "SpinTicket",
    "NeonRebelSkin",
    "CyanOperatorSkin",
    "MagentaOperatorSkin",
}

Config.Shop = {
    SpeedBoost = {
        Type = "Upgrade",
        DisplayName = "MOVILIDAD +2",
        Description = "Mejora permanente de velocidad para las arenas.",
        Currency = "TintaMoney",
        Price = 12_000,
        MaxPurchases = 3,
    },
    HealthBoost = {
        Type = "Upgrade",
        DisplayName = "RESISTENCIA +10",
        Description = "Aumenta permanentemente tu vida máxima.",
        Currency = "TintaMoney",
        Price = 18_000,
        MaxPurchases = 5,
    },
    NeonSMG = {
        Type = "Weapon", WeaponId = "NeonSMG", DisplayName = "SMG NEÓN",
        Description = "Alta cadencia para combate cercano.", Currency = "TintaMoney", Price = 20_000, MaxPurchases = 1,
    },
    SplashShotgun = {
        Type = "Weapon", WeaponId = "SplashShotgun", DisplayName = "ESCOPETA SPLASH",
        Description = "Gran impacto a corta distancia.", Currency = "TintaMoney", Price = 30_000, MaxPurchases = 1,
    },
    PulseCarbine = {
        Type = "Weapon", WeaponId = "PulseCarbine", DisplayName = "CARABINA PULSE",
        Description = "Rifle estable y preciso para media distancia.", Currency = "TintaMoney", Price = 42_000, MaxPurchases = 1,
    },
    ViperPistol = {
        Type = "Weapon", WeaponId = "ViperPistol", DisplayName = "PISTOLA VIPER",
        Description = "Secundaria rápida con buen daño por impacto.", Currency = "TintaMoney", Price = 16_000, MaxPurchases = 1,
    },
    PrismSniper = {
        Type = "Weapon", WeaponId = "PrismSniper", DisplayName = "PRISM SNIPER",
        Description = "Francotirador de alta precisión y baja cadencia.", Currency = "TintaMoney", Price = 85_000, MaxPurchases = 1,
    },
    VoltLMG = {
        Type = "Weapon", WeaponId = "VoltLMG", DisplayName = "VOLT LMG",
        Description = "Cargador grande para control de zonas.", Currency = "TintaMoney", Price = 70_000, MaxPurchases = 1,
    },
    BurstRifle = {
        Type = "Weapon", WeaponId = "BurstRifle", DisplayName = "BURST RIFLE",
        Description = "Rifle táctico semiautomático de alto control.", Currency = "TintaMoney", Price = 55_000, MaxPurchases = 1,
    },
    RewardBoost = {
        Type = "Upgrade", DisplayName = "PREMIO +10%",
        Description = "Aumenta las recompensas de Tinta Money obtenidas jugando.", Currency = "Gems", Price = 35, MaxPurchases = 3,
    },
    SpinTicket = {
        Type = "Consumable", DisplayName = "TICKET DE RECOMPENSA",
        Description = "Permite realizar un giro de recompensa.", Currency = "TintaMoney", Price = 3_000, MaxPurchases = 999,
    },
    NeonRebelSkin = {
        Type = "Cosmetic", ItemId = "NeonRebelSkin", DisplayName = "ASPECTO NEÓN REBELDE",
        Description = "Aspecto negro, cian y magenta para el operador.", Currency = "TintaMoney", Price = 120_000, MaxPurchases = 1,
    },
    CyanOperatorSkin = {
        Type = "Cosmetic", ItemId = "CyanOperatorSkin", DisplayName = "OPERADOR CIAN",
        Description = "Armadura competitiva con acentos cian.", Currency = "TintaMoney", Price = 75_000, MaxPurchases = 1,
    },
    MagentaOperatorSkin = {
        Type = "Cosmetic", ItemId = "MagentaOperatorSkin", DisplayName = "OPERADOR MAGENTA",
        Description = "Armadura competitiva con acentos magenta.", Currency = "TintaMoney", Price = 75_000, MaxPurchases = 1,
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
    CompetitiveRankings = true,
    DonationLeaderboard = true,
    RobuxShop = true,
}

return Config
