local Config = {}

Config.GameName = "Tinta Final: Último Pulso"
Config.UniverseId = 8973271699
Config.PlaceId = 73618099851560
Config.ExpectedMaxPlayers = 100
Config.DataStoreName = "TintaFinal_PlayerData_v2"

Config.Match = {
    MinimumPlayers = 1,
    IntermissionSeconds = 20,
    VotingSeconds = 15,
    ResultsSeconds = 8,
    StagesPerMatch = 5,
    FinalRewardWon = 50_000,
    ParticipationWon = 150,
}

Config.DifficultyOrder = { "Easy", "Normal", "Hard", "Nightmare" }
Config.Difficulties = {
    Easy = {
        DisplayName = "Fácil",
        RequiredWins = 0,
        TimeMultiplier = 1.20,
        HazardMultiplier = 0.75,
        RewardMultiplier = 0.80,
    },
    Normal = {
        DisplayName = "Normal",
        RequiredWins = 2,
        TimeMultiplier = 1.00,
        HazardMultiplier = 1.00,
        RewardMultiplier = 1.00,
    },
    Hard = {
        DisplayName = "Difícil",
        RequiredWins = 8,
        TimeMultiplier = 0.85,
        HazardMultiplier = 1.20,
        RewardMultiplier = 1.50,
    },
    Nightmare = {
        DisplayName = "Pesadilla",
        RequiredWins = 25,
        TimeMultiplier = 0.70,
        HazardMultiplier = 1.45,
        RewardMultiplier = 2.25,
    },
}

Config.Economy = {
    CurrencyName = "Won",
    CurrencySymbol = "₩",
    StartingWon = 1_000,
    StartingGems = 10,
    GuardRoleCost = 300_000,
    BattlePassWonPrice = 200_000,
    AFKRewardWon = 25,
    AFKRewardIntervalSeconds = 60,
    AFKSessionCapWon = 1_500,
    StageRewardWon = 750,
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
    -- Los giros se pagan solo con Won obtenido jugando o tickets ganados.
    -- No se vende Won por Robux para evitar convertirlos en artículos aleatorios pagados.
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
        Legendary = { "GoldenMask", "GuardSalute", "Won20000" },
        Mythic = { "MythicInkCrown", "VoidAura", "Won50000" },
    },
}

Config.ShopOrder = { "SpeedBoost", "HealthBoost", "RewardBoost", "SpinTicket" }
Config.Shop = {
    SpeedBoost = {
        DisplayName = "Velocidad +2",
        Description = "Aumenta permanentemente tu velocidad.",
        Currency = "Won",
        Price = 8_000,
        MaxPurchases = 3,
    },
    HealthBoost = {
        DisplayName = "Resistencia +10",
        Description = "Aumenta permanentemente tu resistencia.",
        Currency = "Won",
        Price = 12_000,
        MaxPurchases = 5,
    },
    RewardBoost = {
        DisplayName = "Premio +10%",
        Description = "Aumenta los Won obtenidos al superar etapas.",
        Currency = "Gems",
        Price = 35,
        MaxPurchases = 3,
    },
    SpinTicket = {
        DisplayName = "Ticket de giro",
        Description = "Permite realizar un giro de recompensa.",
        Currency = "Won",
        Price = 3_000,
        MaxPurchases = 999,
    },
}

Config.Roles = {
    MaxGuards = 5,
    PlayersPerGuard = 20,
    GuardAttackRange = 18,
    GuardAttackCooldown = 1.5,
}

Config.Audio = {
    LobbyMusic = 0,
    VotingMusic = 0,
    RoundMusic = 0,
    VictoryMusic = 0,
    EliminationSound = 0,
    VoteSound = 0,
    SpinSound = 0,
}

Config.FeatureFlags = {
    ProceduralDirector = true,
    ExternalGenerativeAI = false,
    NonGraphicEliminations = true,
}

return Config
