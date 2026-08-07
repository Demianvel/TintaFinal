-- Auto-synced by scripts/sync_game_passes.py.
-- IDs permanecen en 0 hasta que Open Cloud cree o resuelva cada pase.
return {
    UniverseId = 8973271699,
    Passes = {
        BattlePassPremium = {
            GamePassId = 1940934333,
            DisplayName = "BATTLE PASS PREMIUM",
            Description = "Desbloquea la pista premium de la temporada competitiva.",
            PriceRobux = 199,
            Perk = "PremiumBattlePass",
        },
        VIP = {
            GamePassId = 1943244319,
            DisplayName = "TINTA VIP",
            Description = "Etiqueta VIP, +10% Tinta Money y acceso a cosméticos VIP.",
            PriceRobux = 299,
            Perk = "VIP",
        },
        DoubleXP = {
            GamePassId = 1940370346,
            DisplayName = "2X XP PERMANENTE",
            Description = "Duplica el XP de cuenta y Battle Pass obtenido jugando.",
            PriceRobux = 149,
            Perk = "DoubleXP",
        },
        SpinBooster = {
            GamePassId = 1940538345,
            DisplayName = "LUCKY SPIN BOOSTER",
            Description = "Mejora de forma permanente la suerte de la ruleta.",
            PriceRobux = 99,
            Perk = "SpinBooster",
        },
        Founder = {
            GamePassId = 1940004352,
            DisplayName = "FOUNDER PACK",
            Description = "Título Founder, skin exclusiva y bonus inicial de Tinta Money.",
            PriceRobux = 499,
            Perk = "Founder",
        },
    },
    PassOrder = {
        "BattlePassPremium",
        "VIP",
        "DoubleXP",
        "SpinBooster",
        "Founder",
    },
}
