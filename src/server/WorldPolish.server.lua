-- Adds a polished neon environment after the procedural lobby is created.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("TintaFinalWorld", 30)
if not world then
    warn("[TintaFinal] No se encontró TintaFinalWorld para aplicar decoración.")
    return
end

local lobby = world:WaitForChild("Lobby", 15)
if not lobby then
    warn("[TintaFinal] No se encontró el Lobby para aplicar decoración.")
    return
end

local old = lobby:FindFirstChild("ProfessionalSet")
if old then
    old:Destroy()
end

local set = Instance.new("Folder")
set.Name = "ProfessionalSet"
set.Parent = lobby

local function part(name, size, cframe, color, material, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.CanCollide = true
    object.Size = size
    object.CFrame = cframe
    object.Color = color
    object.Material = material or Enum.Material.SmoothPlastic
    object.Transparency = transparency or 0
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = set
    return object
end

local function addSurfaceText(target, text, accent)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "TintaFinalSign"
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.Parent = target

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(7, 9, 18)
    label.BackgroundTransparency = 0.12
    label.Text = text
    label.TextColor3 = accent
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.25
    label.TextWrapped = true
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = gui
end

local cyan = Color3.fromRGB(0, 226, 239)
local magenta = Color3.fromRGB(255, 35, 145)
local orange = Color3.fromRGB(255, 150, 35)
local dark = Color3.fromRGB(15, 18, 31)

-- Perimeter walls keep players in the lobby without using an old lake map.
part("NorthWall", Vector3.new(270, 32, 4), CFrame.new(0, 14, -108), dark, Enum.Material.Metal)
part("SouthWall", Vector3.new(270, 32, 4), CFrame.new(0, 14, 108), dark, Enum.Material.Metal)
part("WestWall", Vector3.new(4, 32, 220), CFrame.new(-132, 14, 0), dark, Enum.Material.Metal)
part("EastWall", Vector3.new(4, 32, 220), CFrame.new(132, 14, 0), dark, Enum.Material.Metal)

for index = 1, 12 do
    local angle = (index / 12) * math.pi * 2
    local radiusX, radiusZ = 112, 88
    local position = Vector3.new(math.cos(angle) * radiusX, 9, math.sin(angle) * radiusZ)
    local color = index % 3 == 0 and orange or (index % 2 == 0 and magenta or cyan)
    local pillar = part(
        "NeonPillar" .. index,
        Vector3.new(3, 22, 3),
        CFrame.new(position),
        color,
        Enum.Material.Neon,
        0.08
    )
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 1.5
    light.Range = 22
    light.Shadows = false
    light.Parent = pillar
end

-- Central portal / next-round focal point.
local portalBase = part("RoundPortalBase", Vector3.new(46, 2, 18), CFrame.new(0, 1, -70), dark, Enum.Material.Metal)
part("PortalLeft", Vector3.new(4, 34, 4), CFrame.new(-20, 18, -70), cyan, Enum.Material.Neon)
part("PortalRight", Vector3.new(4, 34, 4), CFrame.new(20, 18, -70), magenta, Enum.Material.Neon)
part("PortalTop", Vector3.new(44, 4, 4), CFrame.new(0, 34, -70), orange, Enum.Material.Neon)
local portalSign = part("PortalSign", Vector3.new(38, 12, 1), CFrame.new(0, 25, -67.8), dark, Enum.Material.SmoothPlastic)
addSurfaceText(portalSign, "PRÓXIMA\nRONDA", Color3.fromRGB(245, 250, 255))
portalBase:SetAttribute("TintaFinalPortal", true)

-- Shop and armory kiosks are visual anchors for the existing UI systems.
local shop = part("ShopKiosk", Vector3.new(30, 18, 10), CFrame.new(-88, 8, -30), dark, Enum.Material.Metal)
addSurfaceText(shop, "TIENDA\nMEJORAS", magenta)
shop:SetAttribute("Panel", "Shop")

local armory = part("ArmoryKiosk", Vector3.new(30, 18, 10), CFrame.new(88, 8, -30), dark, Enum.Material.Metal)
addSurfaceText(armory, "ARSENAL\nDE TINTA", cyan)
armory:SetAttribute("Panel", "Armory")

for row = 1, 3 do
    for column = 1, 4 do
        local crate = part(
            "SupplyCrate",
            Vector3.new(8, 6, 8),
            CFrame.new(-52 + column * 22, 2, 65 + row * 10),
            row % 2 == 0 and Color3.fromRGB(36, 45, 65) or Color3.fromRGB(50, 35, 58),
            Enum.Material.Metal
        )
        crate:SetAttribute("TintaFinalObject", "Supply")
    end
end

-- Lighting kept lightweight enough for mobile and large servers.
Lighting.ClockTime = 20.2
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(34, 38, 60)
Lighting.OutdoorAmbient = Color3.fromRGB(48, 53, 80)

local atmosphere = Lighting:FindFirstChild("TintaFinalAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "TintaFinalAtmosphere"
atmosphere.Density = 0.26
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(115, 145, 190)
atmosphere.Decay = Color3.fromRGB(55, 22, 75)
atmosphere.Glare = 0.08
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting

local bloom = Lighting:FindFirstChild("TintaFinalBloom") or Instance.new("BloomEffect")
bloom.Name = "TintaFinalBloom"
bloom.Intensity = 0.65
bloom.Size = 28
bloom.Threshold = 1.1
bloom.Parent = Lighting

local correction = Lighting:FindFirstChild("TintaFinalColor") or Instance.new("ColorCorrectionEffect")
correction.Name = "TintaFinalColor"
correction.Brightness = 0.02
correction.Contrast = 0.08
correction.Saturation = 0.08
correction.TintColor = Color3.fromRGB(235, 241, 255)
correction.Parent = Lighting

Workspace:SetAttribute("TintaFinalProfessionalWorldReady", true)
print("[TintaFinal] Lobby profesional, objetos y ambientación cargados.")
