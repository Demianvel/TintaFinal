-- Auto-synced by scripts/sync_developer_products.py.
-- ProductId values stay at 0 until the Open Cloud workflow creates or resolves them.
-- Trigger de sincronización: scopes developer-product habilitados 2026-08-06.
return {
    UniverseId = 8973271699,
    Products = {
        TintaPackSmall = {
            ProductId = 0,
            DisplayName = "25.000 Tinta Money",
            Description = "Paquete de moneda virtual para la tienda de Tinta Final.",
            PriceRobux = 25,
            GrantType = "TintaMoney",
            Amount = 25_000,
        },
        TintaPackMedium = {
            ProductId = 0,
            DisplayName = "100.000 Tinta Money",
            Description = "Paquete mediano de Tinta Money.",
            PriceRobux = 75,
            GrantType = "TintaMoney",
            Amount = 100_000,
        },
        TintaPackMega = {
            ProductId = 0,
            DisplayName = "500.000 Tinta Money",
            Description = "Paquete grande de Tinta Money para personalización y arsenal.",
            PriceRobux = 199,
            GrantType = "TintaMoney",
            Amount = 500_000,
        },
        Donation10 = {
            ProductId = 0,
            DisplayName = "Apoyo 10 Robux",
            Description = "Apoya el desarrollo de Tinta Final y suma al ranking de donaciones.",
            PriceRobux = 10,
            GrantType = "Donation",
            DonationRobux = 10,
            BonusTintaMoney = 2_500,
        },
        Donation50 = {
            ProductId = 0,
            DisplayName = "Apoyo 50 Robux",
            Description = "Apoyo especial al desarrollo de Tinta Final.",
            PriceRobux = 50,
            GrantType = "Donation",
            DonationRobux = 50,
            BonusTintaMoney = 15_000,
        },
        Donation100 = {
            ProductId = 0,
            DisplayName = "Apoyo 100 Robux",
            Description = "Apoyo destacado al desarrollo de Tinta Final.",
            PriceRobux = 100,
            GrantType = "Donation",
            DonationRobux = 100,
            BonusTintaMoney = 35_000,
        },
    },
    ProductOrder = {
        "TintaPackSmall",
        "TintaPackMedium",
        "TintaPackMega",
        "Donation10",
        "Donation50",
        "Donation100",
    },
}
