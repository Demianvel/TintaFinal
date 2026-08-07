-- Tinta Final visual identity.
-- Asset IDs are populated by .github/workflows/upload-brand-assets.yml.
-- Production sync trigger: assets + Developer Products + serverSize confirmed 2026-08-06.
local VisualConfig = {
    Palette = {
        Background = Color3.fromRGB(7, 7, 15),
        Panel = Color3.fromRGB(18, 20, 32),
        Cyan = Color3.fromRGB(0, 226, 239),
        Blue = Color3.fromRGB(33, 112, 255),
        Magenta = Color3.fromRGB(255, 22, 142),
        Orange = Color3.fromRGB(255, 132, 21),
        Yellow = Color3.fromRGB(255, 214, 41),
        White = Color3.fromRGB(248, 250, 255),
        Muted = Color3.fromRGB(178, 188, 218),
    },

    Assets = {
        MainMenu = 97839776094055,
        Loading = 129720347915606,
        Lobby = 89095985932947,
        Round1 = 125053219308080,
        Round2 = 84361702484652,
        Shop = 138366310874881,
        Icon = 97839776094055,
    },

    LoadingDuration = 4.5,
}

return VisualConfig
