local Config = {}

Config.GameName = "Tinta Final"
Config.UniverseId = 8973271699
Config.PlaceId = 73618099851560
Config.DataStoreName = "TintaFinal_PlayerData_v1"
Config.IntermissionSeconds = 15
Config.RoundSeconds = 180
Config.CheckpointCount = 12
Config.BattlePassMaxTier = 50
Config.BattlePassXpPerTier = 100

Config.DifficultyOrder = { "Easy", "Normal", "Hard" }
Config.Difficulties = {
    Easy = {
        DisplayName = "Fácil",
        RequiredWins = 0,
        RewardCoins = 250,
        RewardXp = 100,
        RewardBattlePassXp = 60,
    },
    Normal = {
        DisplayName = "Normal",
        RequiredWins = 3,
        RewardCoins = 550,
        RewardXp = 220,
        RewardBattlePassXp = 120,
    },
    Hard = {
        DisplayName = "Difícil",
        RequiredWins = 10,
        RewardCoins = 1100,
        RewardXp = 450,
        RewardBattlePassXp = 220,
    },
}

Config.ShopOrder = { "SpeedBoost", "HealthBoost", "RewardBoost" }
Config.Shop = {
    SpeedBoost = {
        DisplayName = "Velocidad +2",
        Description = "Aumenta permanentemente tu velocidad.",
        Currency = "Coins",
        Price = 500,
        MaxPurchases = 3,
    },
    HealthBoost = {
        DisplayName = "Vida +10",
        Description = "Aumenta permanentemente tu vida máxima.",
        Currency = "Coins",
        Price = 750,
        MaxPurchases = 5,
    },
    RewardBoost = {
        DisplayName = "Premio +25%",
        Description = "Aumenta las monedas obtenidas al ganar.",
        Currency = "Gems",
        Price = 50,
        MaxPurchases = 2,
    },
}

return Config
