local Config = {}

Config.GameName = "Tinta Final: Competitive Arena"
Config.UniverseId = 8973271699
Config.PlaceId = 73618099851560
Config.ExpectedMaxPlayers = 20
Config.DataStoreName = "TintaFinal_PlayerData_v4"
Config.BuildRevision = "2026.08.07.pvp-liveops.2"

Config.Match = {
    MinimumPlayers = 2,
    MaxParticipants = 20,
    TeamSize = 10,
    IntermissionSeconds = 12,
    VotingSeconds = 0,
    LoadingSeconds = 4,
    ResultsSeconds = 9,
    RoundSeconds = 360,
    TeamScoreLimit = 75,
    FFAScoreLimit = 30,
    SurvivalWaves = 0,
    RespawnSeconds = 4,
    ParticipationTintaMoney = 350,
    WinTintaMoney = 8_000,
    KillTintaMoney = 140,
    BotKillTintaMoney = 0,
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
        "AuroraAR",
        "ShadowSMG",
        "ThunderShotgun",
        "RailCarbine",
        "NovaPistol",
        "EclipseSniper",
    },
    MapOrder = { "NeonDistrict", "InkDepot", "RooftopRush" },
    MapRotation = "Automatic",
    VotingEnabled = false,
    BotsEnabled = false,
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
    MaxTier = 100,
    XPPerTier = 120,
    PremiumGamePassId = 0,
    FreeRewards = {
        [1] = { Type = "TintaMoney", Amount = 1_000 },
        [5] = { Type = "SpinTicket", Amount = 1 },
        [10] = { Type = "TintaMoney", Amount = 5_000 },
        [15] = { Type = "TintaMoney", Amount = 6_000 },
        [20] = { Type = "SpinTicket", Amount = 2 },
        [25] = { Type = "TintaMoney", Amount = 8_000 },
        [30] = { Type = "TintaMoney", Amount = 15_000 },
        [35] = { Type = "TintaMoney", Amount = 12_000 },
        [40] = { Type = "SpinTicket", Amount = 3 },
        [45] = { Type = "TintaMoney", Amount = 15_000 },
        [50] = { Type = "Cosmetic", Id = "InkChampionAura" },
        [55] = { Type = "TintaMoney", Amount = 18_000 },
        [60] = { Type = "SpinTicket", Amount = 4 },
        [65] = { Type = "TintaMoney", Amount = 22_000 },
        [70] = { Type = "TintaMoney", Amount = 25_000 },
        [75] = { Type = "Cosmetic", Id = "S1CyanStormTrail" },
        [80] = { Type = "SpinTicket", Amount = 5 },
        [85] = { Type = "TintaMoney", Amount = 35_000 },
        [90] = { Type = "TintaMoney", Amount = 40_000 },
        [95] = { Type = "SpinTicket", Amount = 6 },
        [100] = { Type = "Cosmetic", Id = "S1ChampionBanner" },
    },
    PremiumRewards = {
        [1] = { Type = "SpinTicket", Amount = 2 },
        [5] = { Type = "TintaMoney", Amount = 8_000 },
        [10] = { Type = "Cosmetic", Id = "NeonTrail" },
        [15] = { Type = "SpinTicket", Amount = 3 },
        [20] = { Type = "Emote", Id = "VictoryPose" },
        [25] = { Type = "Cosmetic", Id = "S1PremiumTier25" },
        [30] = { Type = "Cosmetic", Id = "GoldenMask" },
        [35] = { Type = "TintaMoney", Amount = 28_000 },
        [40] = { Type = "SpinTicket", Amount = 8 },
        [45] = { Type = "TintaMoney", Amount = 36_000 },
        [50] = { Type = "Cosmetic", Id = "MythicInkCrown" },
        [55] = { Type = "SpinTicket", Amount = 8 },
        [60] = { Type = "Cosmetic", Id = "S1NeonOperator" },
        [65] = { Type = "TintaMoney", Amount = 48_000 },
        [70] = { Type = "SpinTicket", Amount = 10 },
        [75] = { Type = "Cosmetic", Id = "S1PrismWeaponWrap" },
        [80] = { Type = "TintaMoney", Amount = 65_000 },
        [85] = { Type = "SpinTicket", Amount = 12 },
        [90] = { Type = "Cosmetic", Id = "S1StormCrown" },
        [95] = { Type = "TintaMoney", Amount = 90_000 },
        [100] = { Type = "Cosmetic", Id = "S1LegendArmor" },
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
        Common = { "EmoteWave", "InkTrailBlue", "TintaMoney1000", "UtilityMedkit" },
        Rare = { "EmoteDance", "InkTrailGreen", "TintaMoney3000", "UtilitySmoke", "UtilityStim" },
        Epic = { "VictoryPose", "InkTrailPurple", "TintaMoney8000", "NovaPistol", "ShadowSMG", "UtilityInkGrenade" },
        Legendary = { "GoldenMask", "TintaMoney20000", "AuroraAR", "ThunderShotgun" },
        Mythic = { "MythicInkCrown", "VoidAura", "TintaMoney50000", "RailCarbine", "EclipseSniper" },
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
    "AuroraAR",
    "ShadowSMG",
    "ThunderShotgun",
    "RailCarbine",
    "NovaPistol",
    "EclipseSniper",
    "UtilityMedkit",
    "UtilityInkGrenade",
    "UtilitySmoke",
    "UtilityStim",
    "SpeedBoost",
    "HealthBoost",
    "RewardBoost",
    "SpinTicket",
    "NeonRebelSkin",
    "CyanOperatorSkin",
    "MagentaOperatorSkin",
}

Config.Shop = {
    SpeedBoost = { Type = "Upgrade", DisplayName = "MOVILIDAD +2", Description = "Mejora permanente de velocidad para las arenas.", Currency = "TintaMoney", Price = 12_000, MaxPurchases = 3 },
    HealthBoost = { Type = "Upgrade", DisplayName = "RESISTENCIA +10", Description = "Aumenta permanentemente tu vida máxima.", Currency = "TintaMoney", Price = 18_000, MaxPurchases = 5 },
    NeonSMG = { Type = "Weapon", WeaponId = "NeonSMG", DisplayName = "SMG NEÓN", Description = "Alta cadencia para combate cercano.", Currency = "TintaMoney", Price = 20_000, MaxPurchases = 1 },
    SplashShotgun = { Type = "Weapon", WeaponId = "SplashShotgun", DisplayName = "ESCOPETA SPLASH", Description = "Gran impacto a corta distancia.", Currency = "TintaMoney", Price = 30_000, MaxPurchases = 1 },
    PulseCarbine = { Type = "Weapon", WeaponId = "PulseCarbine", DisplayName = "CARABINA PULSE", Description = "Rifle estable y preciso para media distancia.", Currency = "TintaMoney", Price = 42_000, MaxPurchases = 1 },
    ViperPistol = { Type = "Weapon", WeaponId = "ViperPistol", DisplayName = "PISTOLA VIPER", Description = "Secundaria rápida con buen daño por impacto.", Currency = "TintaMoney", Price = 16_000, MaxPurchases = 1 },
    PrismSniper = { Type = "Weapon", WeaponId = "PrismSniper", DisplayName = "PRISM SNIPER", Description = "Francotirador de alta precisión y baja cadencia.", Currency = "TintaMoney", Price = 85_000, MaxPurchases = 1 },
    VoltLMG = { Type = "Weapon", WeaponId = "VoltLMG", DisplayName = "VOLT LMG", Description = "Cargador grande para control de zonas.", Currency = "TintaMoney", Price = 70_000, MaxPurchases = 1 },
    BurstRifle = { Type = "Weapon", WeaponId = "BurstRifle", DisplayName = "BURST RIFLE", Description = "Rifle táctico semiautomático de alto control.", Currency = "TintaMoney", Price = 55_000, MaxPurchases = 1 },
    AuroraAR = { Type = "Weapon", WeaponId = "AuroraAR", DisplayName = "AURORA AR", Description = "Rifle premium equilibrado para PvP.", Currency = "TintaMoney", Price = 68_000, MaxPurchases = 1 },
    ShadowSMG = { Type = "Weapon", WeaponId = "ShadowSMG", DisplayName = "SHADOW SMG", Description = "SMG veloz para flanqueo agresivo.", Currency = "TintaMoney", Price = 48_000, MaxPurchases = 1 },
    ThunderShotgun = { Type = "Weapon", WeaponId = "ThunderShotgun", DisplayName = "THUNDER SHOTGUN", Description = "Escopeta de alta presión a corta distancia.", Currency = "TintaMoney", Price = 64_000, MaxPurchases = 1 },
    RailCarbine = { Type = "Weapon", WeaponId = "RailCarbine", DisplayName = "RAIL CARBINE", Description = "Carabina precisa de alto impacto.", Currency = "TintaMoney", Price = 88_000, MaxPurchases = 1 },
    NovaPistol = { Type = "Weapon", WeaponId = "NovaPistol", DisplayName = "NOVA PISTOL", Description = "Pistola competitiva ligera y rápida.", Currency = "TintaMoney", Price = 34_000, MaxPurchases = 1 },
    EclipseSniper = { Type = "Weapon", WeaponId = "EclipseSniper", DisplayName = "ECLIPSE SNIPER", Description = "Francotirador mítico de precisión extrema.", Currency = "TintaMoney", Price = 145_000, MaxPurchases = 1 },
    UtilityMedkit = { Type = "Utility", ItemId = "UtilityMedkit", DisplayName = "BOTIQUÍN DE CAMPO", Description = "Recupera 45 de vida durante PvP.", Currency = "TintaMoney", Price = 4_500, MaxPurchases = 999 },
    UtilityInkGrenade = { Type = "Utility", ItemId = "UtilityInkGrenade", DisplayName = "GRANADA DE TINTA", Description = "Pulso de tinta de área para combate competitivo.", Currency = "TintaMoney", Price = 7_500, MaxPurchases = 999 },
    UtilitySmoke = { Type = "Utility", ItemId = "UtilitySmoke", DisplayName = "HUMO TÁCTICO", Description = "Crea una nube temporal para cortar visión.", Currency = "TintaMoney", Price = 5_500, MaxPurchases = 999 },
    UtilityStim = { Type = "Utility", ItemId = "UtilityStim", DisplayName = "STIM DE MOVILIDAD", Description = "Aumenta temporalmente la velocidad.", Currency = "TintaMoney", Price = 6_500, MaxPurchases = 999 },
    RewardBoost = { Type = "Upgrade", DisplayName = "PREMIO +10%", Description = "Aumenta las recompensas de Tinta Money obtenidas jugando.", Currency = "Gems", Price = 35, MaxPurchases = 3 },
    SpinTicket = { Type = "Consumable", DisplayName = "TICKET DE RECOMPENSA", Description = "Permite realizar un giro de recompensa.", Currency = "TintaMoney", Price = 3_000, MaxPurchases = 999 },
    NeonRebelSkin = { Type = "Cosmetic", ItemId = "NeonRebelSkin", DisplayName = "ASPECTO NEÓN REBELDE", Description = "Aspecto negro, cian y magenta para el operador.", Currency = "TintaMoney", Price = 120_000, MaxPurchases = 1 },
    CyanOperatorSkin = { Type = "Cosmetic", ItemId = "CyanOperatorSkin", DisplayName = "OPERADOR CIAN", Description = "Armadura competitiva con acentos cian.", Currency = "TintaMoney", Price = 75_000, MaxPurchases = 1 },
    MagentaOperatorSkin = { Type = "Cosmetic", ItemId = "MagentaOperatorSkin", DisplayName = "OPERADOR MAGENTA", Description = "Armadura competitiva con acentos magenta.", Currency = "TintaMoney", Price = 75_000, MaxPurchases = 1 },
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
    SoloSurvivalFallback = false,
    NonGraphicCombat = true,
    CompetitiveRankings = true,
    DonationLeaderboard = true,
    RobuxShop = true,
    PvPOnly = true,
    MapVoting = false,
    Bots = false,
}

return Config
