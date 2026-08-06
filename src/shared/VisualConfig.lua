-- Tinta Final visual identity.
-- Asset IDs are populated by .github/workflows/upload-brand-assets.yml.
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
        MainMenu = 0,
        Loading = 0,
        Lobby = 0,
        Round1 = 0,
        Round2 = 0,
        Shop = 0,
        Icon = 0,
    },

    LoadingDuration = 4.5,
}

return VisualConfig
