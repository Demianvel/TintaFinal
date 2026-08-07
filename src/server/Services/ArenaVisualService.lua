local Lighting = game:GetService("Lighting")

local ArenaVisualService = {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 22, 142)
local ORANGE = Color3.fromRGB(255, 132, 21)
local DARK = Color3.fromRGB(8, 10, 18)
local METAL = Color3.fromRGB(31, 36, 52)

local function part(parent, name, size, cframe, color, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = collide == true
    p.CanTouch = collide == true
    p.CanQuery = collide == true
    p.Size = size
    p.CFrame = cframe
    p.Color = color or DARK
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function puddle(parent, position, radius, color, rotation)
    local p = part(parent, "InkSplash", Vector3.new(0.16, radius * 2, radius * 2), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(rotation or 0), 0), color, Enum.Material.Neon, false)
    p.Shape = Enum.PartType.Cylinder
    p.Transparency = 0.16
end

local function lane(parent, center, length, width, color, angle)
    local p = part(parent, "InkLane", Vector3.new(width, 0.14, length), CFrame.new(center) * CFrame.Angles(0, math.rad(angle or 0), 0), color, Enum.Material.Neon, false)
    p.Transparency = 0.20
end

local function banner(parent, position, textValue, color, width)
    local board = part(parent, "CompetitiveBanner", Vector3.new(width or 34, 9, 0.8), CFrame.new(position), DARK, Enum.Material.Metal, false)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.PixelsPerStud = 40
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = textValue
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.35
    label.Parent = gui

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 1.4
    light.Range = 18
    light.Shadows = false
    light.Parent = board
    return board
end

local function tower(parent, position, height, accent)
    local base = part(parent, "NeonCityTower", Vector3.new(22, height, 22), CFrame.new(position + Vector3.new(0, height / 2, 0)), METAL, Enum.Material.Metal, true)
    local trim = part(parent, "TowerGlow", Vector3.new(22.3, 0.8, 22.3), CFrame.new(position + Vector3.new(0, height - 2, 0)), accent, Enum.Material.Neon, false)
    trim.Transparency = 0.08
    return base
end

local function lightColumn(parent, position, color, height)
    local column = part(parent, "ArenaLight", Vector3.new(1.2, height or 20, 1.2), CFrame.new(position + Vector3.new(0, (height or 20) / 2, 0)), color, Enum.Material.Neon, false)
    column.Transparency = 0.14
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 2
    light.Range = 26
    light.Shadows = false
    light.Parent = column
end

local function removeLegacyVoteObjects(root)
    for _, object in ipairs(root:GetDescendants()) do
        if string.find(string.lower(object.Name), "votepad", 1, true) or object:GetAttribute("VoteIndex") ~= nil then
            object:Destroy()
        end
    end
end

local function ensurePostEffects()
    local bloom = Lighting:FindFirstChild("TintaFinalBloom")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "TintaFinalBloom"
        bloom.Intensity = 0.65
        bloom.Size = 28
        bloom.Threshold = 1.1
        bloom.Parent = Lighting
    end

    local correction = Lighting:FindFirstChild("TintaFinalColor")
    if not correction then
        correction = Instance.new("ColorCorrectionEffect")
        correction.Name = "TintaFinalColor"
        correction.Brightness = 0.02
        correction.Contrast = 0.12
        correction.Saturation = 0.18
        correction.TintColor = Color3.fromRGB(235, 242, 255)
        correction.Parent = Lighting
    end
end

function ArenaVisualService.DecorateLobby()
    local world = workspace:FindFirstChild("TintaFinalWorld")
    local lobby = world and world:FindFirstChild("Lobby")
    if not lobby then return end

    removeLegacyVoteObjects(lobby)
    local old = lobby:FindFirstChild("TintaFinalLobbyStyle")
    if old then old:Destroy() end

    ensurePostEffects()
    local decoration = Instance.new("Folder")
    decoration.Name = "TintaFinalLobbyStyle"
    decoration.Parent = lobby

    lane(decoration, Vector3.new(-48, -0.82, 15), 125, 5.5, CYAN, 0)
    lane(decoration, Vector3.new(48, -0.81, 15), 125, 5.5, MAGENTA, 0)
    lane(decoration, Vector3.new(0, -0.79, -30), 82, 4, ORANGE, 90)

    for index = 1, 12 do
        local angle = index * 137
        local distance = 24 + (index * 19) % 88
        local offset = Vector3.new(math.cos(math.rad(angle)) * distance, -0.73, math.sin(math.rad(angle)) * distance)
        local color = index % 3 == 0 and ORANGE or (index % 2 == 0 and MAGENTA or CYAN)
        puddle(decoration, offset, 3 + (index % 4) * 1.2, color, angle)
    end

    banner(decoration, Vector3.new(0, 17, -93), "TINTA FINAL · DUELOS", Color3.new(1, 1, 1), 58)
    banner(decoration, Vector3.new(-92, 12, -70), "ARSENAL", CYAN, 28)
    banner(decoration, Vector3.new(92, 12, -70), "TIENDA", ORANGE, 28)

    for _, data in ipairs({
        {Vector3.new(-132, 0, -94), 25, CYAN},
        {Vector3.new(-132, 0, 64), 19, MAGENTA},
        {Vector3.new(132, 0, -94), 25, ORANGE},
        {Vector3.new(132, 0, 64), 19, CYAN},
    }) do
        tower(decoration, data[1], data[2], data[3])
    end
end

function ArenaVisualService.Decorate(arenaData, mode)
    local world = workspace:FindFirstChild("TintaFinalWorld")
    local arenaFolder = world and world:FindFirstChild("Arena")
    if not arenaFolder or not arenaData then return end

    local previous = arenaFolder:FindFirstChild("CompetitiveInkDecoration")
    if previous then previous:Destroy() end

    ensurePostEffects()
    local decoration = Instance.new("Folder")
    decoration.Name = "CompetitiveInkDecoration"
    decoration.Parent = arenaFolder
    local origin = arenaData.Origin
    local duelSize = mode == "Duel" and tonumber(workspace:GetAttribute("TintaFinalDuelSize")) or nil

    for index = 1, 24 do
        local angle = (index * 137) % 360
        local distance = 22 + ((index * 29) % 120)
        local offset = Vector3.new(math.cos(math.rad(angle)) * distance, 0.05, math.sin(math.rad(angle)) * distance)
        local color = index % 3 == 0 and ORANGE or (index % 2 == 0 and MAGENTA or CYAN)
        puddle(decoration, origin + offset, 3 + (index % 5) * 1.35, color, angle)
    end

    lane(decoration, origin + Vector3.new(-72, 0.08, 0), 150, 5, CYAN, 14)
    lane(decoration, origin + Vector3.new(72, 0.09, 0), 150, 5, MAGENTA, -14)
    lane(decoration, origin + Vector3.new(0, 0.10, 72), 95, 3.5, ORANGE, 90)

    banner(decoration, origin + Vector3.new(-78, 17, -135), "EQUIPO CIAN", CYAN)
    banner(decoration, origin + Vector3.new(78, 17, -135), (mode == "TeamSplash" or mode == "Duel") and "EQUIPO MAGENTA" or "RIVALES", MAGENTA)
    local centerText
    if duelSize then
        centerText = string.format("TINTA FINAL · %d VS %d", duelSize, duelSize)
    elseif mode == "FreeSplash" then
        centerText = "TODOS CONTRA TODOS"
    else
        centerText = "TINTA FINAL · 10 VS 10"
    end
    banner(decoration, origin + Vector3.new(0, 29, 125), centerText, ORANGE, 54)
    banner(decoration, origin + Vector3.new(-142, 13, 0), "ZONA B", CYAN, 24)
    banner(decoration, origin + Vector3.new(142, 13, 0), "ZONA A", ORANGE, 24)

    local skyline = {
        {Vector3.new(-145, 0, -118), 34, CYAN},
        {Vector3.new(-145, 0, 115), 25, MAGENTA},
        {Vector3.new(145, 0, -118), 34, ORANGE},
        {Vector3.new(145, 0, 115), 25, CYAN},
    }
    for _, data in ipairs(skyline) do
        tower(decoration, origin + data[1], data[2], data[3])
    end

    for _, data in ipairs({
        {Vector3.new(-105, 0, -75), CYAN}, {Vector3.new(-105, 0, 75), MAGENTA},
        {Vector3.new(105, 0, -75), ORANGE}, {Vector3.new(105, 0, 75), CYAN},
    }) do
        lightColumn(decoration, origin + data[1], data[2], 22)
    end
end

return ArenaVisualService
