local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapService = {}

local root
local lobby
local arena
local points = {}

local function part(parent, name, size, cframe, color, material)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.Size = size
    object.CFrame = cframe
    object.Color = color or Color3.fromRGB(70, 75, 90)
    object.Material = material or Enum.Material.SmoothPlastic
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    return object
end

local function sign(parent, text, position, size)
    local board = part(parent, "Sign", size or Vector3.new(18, 8, 1), CFrame.new(position), Color3.fromRGB(20, 22, 30), Enum.Material.SmoothPlastic)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(245, 247, 255)
    label.TextScaled = true
    label.Parent = gui
    return board
end

local function spawnLocation(parent, name, position, color)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = name
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = position
    spawn.Color = color
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.15
    spawn.Parent = parent
    return spawn
end

function MapService.BuildLobby()
    local existing = Workspace:FindFirstChild("TintaFinalWorld")
    if existing then
        existing:Destroy()
    end

    root = Instance.new("Folder")
    root.Name = "TintaFinalWorld"
    root.Parent = Workspace

    lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = root

    arena = Instance.new("Folder")
    arena.Name = "Arena"
    arena.Parent = root

    Lighting.ClockTime = 19.2
    Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(45, 48, 65)
    Lighting.OutdoorAmbient = Color3.fromRGB(65, 70, 95)

    part(lobby, "LobbyFloor", Vector3.new(260, 3, 220), CFrame.new(0, -2, 0), Color3.fromRGB(33, 37, 52), Enum.Material.Slate)
    part(lobby, "CenterStage", Vector3.new(80, 2, 52), CFrame.new(0, 1, -10), Color3.fromRGB(55, 58, 75), Enum.Material.Metal)
    sign(lobby, "TINTA FINAL\nÚLTIMO PULSO", Vector3.new(0, 18, -95), Vector3.new(46, 16, 1))

    points.Lobby = spawnLocation(lobby, "LobbySpawn", Vector3.new(0, 2, 55), Color3.fromRGB(70, 190, 255)).Position
    points.Spectator = Vector3.new(0, 10, -62)
    points.AFK = Vector3.new(-92, 3, 45)
    points.GuardLounge = Vector3.new(92, 3, 45)
    points.ArenaOrigin = Vector3.new(0, 0, 650)

    part(lobby, "SpectatorDeck", Vector3.new(92, 2, 30), CFrame.new(points.Spectator - Vector3.new(0, 2, 0)), Color3.fromRGB(48, 52, 67), Enum.Material.Metal)

    local afkFloor = part(lobby, "AFKFloor", Vector3.new(52, 2, 52), CFrame.new(points.AFK - Vector3.new(0, 2, 0)), Color3.fromRGB(60, 105, 90), Enum.Material.SmoothPlastic)
    afkFloor:SetAttribute("Zone", "AFK")
    sign(lobby, "SALA AFK\nGanás Won con límite", points.AFK + Vector3.new(0, 11, -25), Vector3.new(28, 10, 1))

    local guardFloor = part(lobby, "GuardFloor", Vector3.new(52, 2, 52), CFrame.new(points.GuardLounge - Vector3.new(0, 2, 0)), Color3.fromRGB(105, 55, 70), Enum.Material.SmoothPlastic)
    guardFloor:SetAttribute("Zone", "Guard")
    sign(lobby, "DESCANSO DE GUARDIAS", points.GuardLounge + Vector3.new(0, 11, -25), Vector3.new(28, 10, 1))

    points.VotePads = {}
    for index = 1, 3 do
        local x = (index - 2) * 36
        local pad = part(lobby, "VotePad" .. index, Vector3.new(26, 2, 26), CFrame.new(x, 1, -42), Color3.fromRGB(80 + index * 30, 70, 150 + index * 20), Enum.Material.Neon)
        pad:SetAttribute("VoteIndex", index)
        points.VotePads[index] = pad.Position
    end

    return points
end

function MapService.ClearArena()
    if not arena then
        return
    end
    arena:ClearAllChildren()
end

function MapService.GetPoint(name)
    return points[name]
end

function MapService.GetPoints()
    return points
end

function MapService.Teleport(player, position)
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart and position then
        rootPart.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
end

local function buildPulseRun(origin)
    local model = Instance.new("Folder")
    model.Name = "PulseRun"
    model.Parent = arena

    part(model, "Floor", Vector3.new(170, 2, 420), CFrame.new(origin + Vector3.new(0, -2, 170)), Color3.fromRGB(210, 205, 185), Enum.Material.Sand)
    local start = part(model, "Start", Vector3.new(150, 1, 16), CFrame.new(origin + Vector3.new(0, 0, -20)), Color3.fromRGB(70, 190, 255), Enum.Material.Neon)
    local finish = part(model, "Finish", Vector3.new(150, 1, 16), CFrame.new(origin + Vector3.new(0, 0, 360)), Color3.fromRGB(255, 220, 80), Enum.Material.Neon)
    local signal = part(model, "Signal", Vector3.new(22, 35, 22), CFrame.new(origin + Vector3.new(0, 16, 395)), Color3.fromRGB(80, 190, 255), Enum.Material.Neon)
    sign(model, "PULSO Y SILENCIO", origin + Vector3.new(0, 28, 420), Vector3.new(42, 12, 1))

    return {
        Origin = origin,
        Start = start.Position,
        Finish = finish,
        Signal = signal,
        SpawnPositions = MapService.MakeGridPositions(origin + Vector3.new(0, 1, -35), 100, 10, 12),
    }
end

local function buildInkMemory(origin)
    local model = Instance.new("Folder")
    model.Name = "InkMemory"
    model.Parent = arena

    part(model, "Floor", Vector3.new(210, 2, 210), CFrame.new(origin + Vector3.new(0, -3, 80)), Color3.fromRGB(30, 32, 42), Enum.Material.Slate)
    local colors = {
        Color3.fromRGB(80, 190, 255),
        Color3.fromRGB(240, 90, 120),
        Color3.fromRGB(255, 205, 70),
        Color3.fromRGB(120, 230, 135),
    }
    local zones = {}
    local offsets = {
        Vector3.new(-48, 0, 38),
        Vector3.new(48, 0, 38),
        Vector3.new(-48, 0, 130),
        Vector3.new(48, 0, 130),
    }
    for index, offset in ipairs(offsets) do
        local zone = part(model, "SymbolZone" .. index, Vector3.new(78, 2, 70), CFrame.new(origin + offset), colors[index], Enum.Material.Neon)
        zone:SetAttribute("Symbol", index)
        zones[index] = zone
    end
    local display = part(model, "Display", Vector3.new(28, 28, 2), CFrame.new(origin + Vector3.new(0, 20, -20)), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
    return {
        Origin = origin,
        Zones = zones,
        Display = display,
        SpawnPositions = MapService.MakeGridPositions(origin + Vector3.new(0, 1, -42), 100, 10, 10),
    }
end

local function buildFallingGrid(origin)
    local model = Instance.new("Folder")
    model.Name = "FallingGrid"
    model.Parent = arena

    local tiles = {}
    local gridSize = 10
    local tileSize = 14
    for row = 1, gridSize do
        for column = 1, gridSize do
            local position = origin + Vector3.new((column - 5.5) * tileSize, 0, (row - 5.5) * tileSize + 80)
            local tile = part(model, "Tile", Vector3.new(12, 2, 12), CFrame.new(position), Color3.fromRGB(85, 95, 135), Enum.Material.SmoothPlastic)
            table.insert(tiles, tile)
        end
    end
    part(model, "KillFloor", Vector3.new(210, 4, 210), CFrame.new(origin + Vector3.new(0, -28, 80)), Color3.fromRGB(180, 35, 55), Enum.Material.Neon)
    return {
        Origin = origin,
        Tiles = tiles,
        SpawnPositions = MapService.MakeGridPositions(origin + Vector3.new(0, 3, 80), 100, 10, 12),
    }
end

local function buildGuardHunt(origin)
    local model = Instance.new("Folder")
    model.Name = "GuardHunt"
    model.Parent = arena

    part(model, "Floor", Vector3.new(230, 2, 260), CFrame.new(origin + Vector3.new(0, -2, 100)), Color3.fromRGB(48, 50, 60), Enum.Material.Concrete)
    local shelters = {}
    for row = 1, 3 do
        for column = 1, 4 do
            local x = (column - 2.5) * 44
            local z = 20 + row * 55
            local shelter = part(model, "Shelter", Vector3.new(30, 18, 30), CFrame.new(origin + Vector3.new(x, 8, z)), Color3.fromRGB(60, 75, 100), Enum.Material.Metal)
            shelter:SetAttribute("Shelter", true)
            table.insert(shelters, shelter)
        end
    end
    return {
        Origin = origin,
        Shelters = shelters,
        RunnerSpawns = MapService.MakeGridPositions(origin + Vector3.new(0, 1, -15), 100, 10, 10),
        GuardSpawns = MapService.MakeGridPositions(origin + Vector3.new(0, 1, 220), 5, 5, 12),
    }
end

local function buildLastPlatform(origin)
    local model = Instance.new("Folder")
    model.Name = "LastPlatform"
    model.Parent = arena

    local rings = {}
    for ring = 1, 5 do
        local radius = 100 - (ring - 1) * 18
        local pieces = {}
        local pieceCount = math.max(8, 24 - ring * 2)
        for index = 1, pieceCount do
            local angle = (index / pieceCount) * math.pi * 2
            local position = origin + Vector3.new(math.cos(angle) * radius, 0, 90 + math.sin(angle) * radius)
            local platform = part(model, "Ring" .. ring, Vector3.new(18, 2, 18), CFrame.new(position) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(105 + ring * 20, 80, 160), Enum.Material.Neon)
            table.insert(pieces, platform)
        end
        rings[ring] = pieces
    end
    part(model, "KillFloor", Vector3.new(260, 4, 260), CFrame.new(origin + Vector3.new(0, -30, 90)), Color3.fromRGB(170, 30, 50), Enum.Material.Neon)
    return {
        Origin = origin,
        Rings = rings,
        SpawnPositions = MapService.MakeGridPositions(origin + Vector3.new(0, 4, 90), 100, 10, 10),
    }
end

function MapService.MakeGridPositions(center, count, columns, spacing)
    local positions = {}
    columns = columns or 10
    spacing = spacing or 10
    local rows = math.ceil(count / columns)
    for index = 1, count do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = (column - (columns - 1) / 2) * spacing
        local z = (row - (rows - 1) / 2) * spacing
        positions[index] = center + Vector3.new(x, 0, z)
    end
    return positions
end

function MapService.BuildGame(gameId)
    MapService.ClearArena()
    local origin = points.ArenaOrigin
    if gameId == "PulseRun" then
        return buildPulseRun(origin)
    elseif gameId == "InkMemory" then
        return buildInkMemory(origin)
    elseif gameId == "FallingGrid" then
        return buildFallingGrid(origin)
    elseif gameId == "GuardHunt" then
        return buildGuardHunt(origin)
    elseif gameId == "LastPlatform" then
        return buildLastPlatform(origin)
    end
    error("Unknown game id: " .. tostring(gameId))
end

return MapService
