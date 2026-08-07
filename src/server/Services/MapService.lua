local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapService = {}
local root
local lobby
local arena
local points = {}
local duelPads = {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)
local PURPLE = Color3.fromRGB(115, 82, 230)
local DARK = Color3.fromRGB(18, 21, 34)

local function part(parent, name, size, cframe, color, material, collide)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.Size = size
    object.CFrame = cframe
    object.Color = color or DARK
    object.Material = material or Enum.Material.SmoothPlastic
    object.CanCollide = collide ~= false
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    return object
end

local function neon(parent, name, size, cframe, color)
    return part(parent, name, size, cframe, color, Enum.Material.Neon, true)
end

local function sign(parent, textValue, position, size, color)
    local board = part(parent, "Sign", size or Vector3.new(28, 10, 1), CFrame.new(position), Color3.fromRGB(8, 9, 16), Enum.Material.Metal)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = textValue
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBlack
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = gui
    return board
end

local function floatingStatus(parent, adornee, title, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "DuelStatus"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(220, 92)
    gui.StudsOffset = Vector3.new(0, 7, 0)
    gui.AlwaysOnTop = true
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(7, 9, 16)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Transparency = 0.15
    stroke.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -12, 0, 40)
    titleLabel.Position = UDim2.new(0, 6, 0, 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextScaled = true
    titleLabel.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -12, 0, 36)
    statusLabel.Position = UDim2.new(0, 6, 0, 48)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "PISÁ PARA ENTRAR"
    statusLabel.TextColor3 = color
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextScaled = true
    statusLabel.Parent = frame
    return statusLabel
end

local function makeGrid(center, count, columns, spacing)
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

local function wallBox(parent, center, width, depth, height, color)
    local thickness = 4
    part(parent, "Wall", Vector3.new(width, height, thickness), CFrame.new(center + Vector3.new(0, height / 2, -depth / 2)), color, Enum.Material.Metal)
    part(parent, "Wall", Vector3.new(width, height, thickness), CFrame.new(center + Vector3.new(0, height / 2, depth / 2)), color, Enum.Material.Metal)
    part(parent, "Wall", Vector3.new(thickness, height, depth), CFrame.new(center + Vector3.new(-width / 2, height / 2, 0)), color, Enum.Material.Metal)
    part(parent, "Wall", Vector3.new(thickness, height, depth), CFrame.new(center + Vector3.new(width / 2, height / 2, 0)), color, Enum.Material.Metal)
end

local function cover(parent, position, size, color)
    local object = part(parent, "Cover", size or Vector3.new(14, 9, 5), CFrame.new(position), color or Color3.fromRGB(48, 53, 72), Enum.Material.Metal)
    object:SetAttribute("ShooterCover", true)
    return object
end

local function crate(parent, position, color)
    local box = part(parent, "Crate", Vector3.new(10, 10, 10), CFrame.new(position), color or Color3.fromRGB(52, 58, 78), Enum.Material.Metal)
    local stripe = neon(parent, "CrateStripe", Vector3.new(10.2, 1.2, 10.2), CFrame.new(position + Vector3.new(0, 2.3, 0)), ORANGE)
    stripe.CanCollide = false
    return box
end

local function pickup(parent, name, position, pickupType, amount, color)
    local pad = neon(parent, name, Vector3.new(7, 0.6, 7), CFrame.new(position), color)
    pad.CanCollide = false
    pad:SetAttribute("PickupType", pickupType)
    pad:SetAttribute("Amount", amount)
    return pad
end

function MapService.BuildLobby()
    local existing = Workspace:FindFirstChild("TintaFinalWorld")
    if existing then existing:Destroy() end

    points = {}
    duelPads = {}
    root = Instance.new("Folder")
    root.Name = "TintaFinalWorld"
    root.Parent = Workspace
    lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = root
    arena = Instance.new("Folder")
    arena.Name = "Arena"
    arena.Parent = root

    Lighting.ClockTime = 21
    Lighting.Brightness = 2.4
    Lighting.Ambient = Color3.fromRGB(35, 38, 57)
    Lighting.OutdoorAmbient = Color3.fromRGB(52, 57, 78)

    part(lobby, "LobbyFloor", Vector3.new(300, 4, 230), CFrame.new(0, -3, 0), Color3.fromRGB(20, 23, 36), Enum.Material.Slate)
    wallBox(lobby, Vector3.new(0, -1, 0), 300, 230, 32, Color3.fromRGB(32, 35, 50))
    neon(lobby, "CyanLane", Vector3.new(125, 0.35, 5), CFrame.new(-68, -0.7, 0), CYAN).CanCollide = false
    neon(lobby, "MagentaLane", Vector3.new(125, 0.35, 5), CFrame.new(68, -0.7, 0), MAGENTA).CanCollide = false

    points.Lobby = Vector3.new(0, 2, 72)
    points.Spectator = Vector3.new(0, 10, 95)
    points.AFK = Vector3.new(-112, 2, 72)
    points.Shop = Vector3.new(112, 2, 72)
    points.ArenaOrigin = Vector3.new(0, 0, 850)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LobbySpawn"
    spawn.Size = Vector3.new(18, 1, 18)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Position = points.Lobby
    spawn.Color = CYAN
    spawn.Material = Enum.Material.Neon
    spawn.Parent = lobby

    part(lobby, "CenterStage", Vector3.new(245, 2, 65), CFrame.new(0, 0, -28), Color3.fromRGB(31, 34, 49), Enum.Material.Metal)
    sign(lobby, "TINTA FINAL\nELEGÍ TU DUELO", Vector3.new(0, 20, -105), Vector3.new(58, 17, 1), CYAN)
    sign(lobby, "ARMERÍA", Vector3.new(-112, 12, -70), Vector3.new(28, 10, 1), ORANGE)
    sign(lobby, "TIENDA", Vector3.new(112, 12, -70), Vector3.new(28, 10, 1), MAGENTA)
    sign(lobby, "PISÁ UNA PARCELA · 10 SEGUNDOS", Vector3.new(0, 11, 12), Vector3.new(52, 9, 1), Color3.new(1, 1, 1))

    for i = 1, 4 do
        local x = -115 + (i - 1) * 77
        neon(lobby, "LobbyPillar", Vector3.new(3, 24, 3), CFrame.new(x, 10, -95), i % 2 == 0 and MAGENTA or CYAN)
    end

    local definitions = {
        {TeamSize = 1, Label = "1 VS 1", X = -102, Color = CYAN},
        {TeamSize = 2, Label = "2 VS 2", X = -34, Color = ORANGE},
        {TeamSize = 6, Label = "6 VS 6", X = 34, Color = PURPLE},
        {TeamSize = 10, Label = "10 VS 10", X = 102, Color = MAGENTA},
    }
    for _, definition in ipairs(definitions) do
        local pad = neon(lobby, "DuelPad" .. definition.TeamSize, Vector3.new(54, 1, 34), CFrame.new(definition.X, 0.6, -35), definition.Color)
        pad:SetAttribute("DuelTeamSize", definition.TeamSize)
        pad:SetAttribute("DuelCapacity", definition.TeamSize * 2)
        local statusLabel = floatingStatus(lobby, pad, definition.Label, definition.Color)
        duelPads[definition.TeamSize] = {
            Pad = pad,
            StatusLabel = statusLabel,
            TeamSize = definition.TeamSize,
            Capacity = definition.TeamSize * 2,
            WaitingPosition = pad.Position + Vector3.new(0, 3, 0),
        }
    end
    points.DuelPads = duelPads

    return points
end

function MapService.ClearArena()
    if arena then arena:ClearAllChildren() end
end

function MapService.GetPoint(name) return points[name] end
function MapService.GetPoints() return points end
function MapService.GetDuelPads() return duelPads end
function MapService.MakeGridPositions(center, count, columns, spacing) return makeGrid(center, count, columns, spacing) end

function MapService.UpdateDuelPad(teamSize, statusText)
    local entry = duelPads[tonumber(teamSize)]
    if entry and entry.StatusLabel and entry.StatusLabel.Parent then
        entry.StatusLabel.Text = tostring(statusText or "PISÁ PARA ENTRAR")
    end
end

function MapService.Teleport(player, position)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if rootPart and position then
        rootPart.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
end

local function baseArena(name, width, depth)
    MapService.ClearArena()
    local model = Instance.new("Folder")
    model.Name = name
    model.Parent = arena
    local origin = points.ArenaOrigin
    part(model, "Floor", Vector3.new(width, 3, depth), CFrame.new(origin + Vector3.new(0, -3, 0)), Color3.fromRGB(24, 28, 39), Enum.Material.Concrete)
    wallBox(model, origin + Vector3.new(0, -1, 0), width, depth, 28, Color3.fromRGB(39, 43, 58))
    return model, origin
end

local function duelArena(teamSize)
    teamSize = math.clamp(math.floor(tonumber(teamSize) or 1), 1, 10)
    local dimensions = {
        [1] = {150, 120},
        [2] = {185, 145},
        [6] = {260, 215},
        [10] = {320, 260},
    }
    local chosen = dimensions[teamSize] or dimensions[1]
    local width, depth = chosen[1], chosen[2]
    local model, origin = baseArena("Duel" .. teamSize .. "v" .. teamSize, width, depth)
    sign(model, string.format("DUELO %d VS %d", teamSize, teamSize), origin + Vector3.new(0, 20, -depth / 2 + 3), Vector3.new(48, 13, 1), ORANGE)

    local coverRows = teamSize <= 2 and 2 or (teamSize <= 6 and 3 or 4)
    for row = -coverRows, coverRows do
        local z = row * math.max(22, depth / (coverRows * 2 + 2))
        if math.abs(z) < depth / 2 - 20 then
            cover(model, origin + Vector3.new(-width * 0.18, 4, z), Vector3.new(16, 8, 6), Color3.fromRGB(34, 77, 88))
            cover(model, origin + Vector3.new(width * 0.18, 4, -z), Vector3.new(16, 8, 6), Color3.fromRGB(85, 34, 69))
        end
    end
    crate(model, origin + Vector3.new(0, 4, 0), ORANGE)
    neon(model, "CyanGoalLine", Vector3.new(5, 0.25, depth - 18), CFrame.new(origin + Vector3.new(-width / 2 + 15, -1.2, 0)), CYAN).CanCollide = false
    neon(model, "MagentaGoalLine", Vector3.new(5, 0.25, depth - 18), CFrame.new(origin + Vector3.new(width / 2 - 15, -1.2, 0)), MAGENTA).CanCollide = false

    local spawnCount = math.max(10, teamSize * 2)
    local columns = math.max(1, math.min(teamSize, 5))
    local cyanCenter = origin + Vector3.new(-width * 0.34, 1, 0)
    local magentaCenter = origin + Vector3.new(width * 0.34, 1, 0)
    return {
        Id = "Duel" .. teamSize .. "v" .. teamSize,
        DisplayName = string.format("Duelo %d vs %d", teamSize, teamSize),
        Origin = origin,
        DuelTeamSize = teamSize,
        CyanSpawns = makeGrid(cyanCenter, spawnCount, columns, 10),
        MagentaSpawns = makeGrid(magentaCenter, spawnCount, columns, 10),
        FFASpawns = makeGrid(origin, math.max(20, teamSize * 2), math.max(2, columns * 2), 16),
        BotSpawns = makeGrid(origin, math.max(20, teamSize * 2), math.max(2, columns * 2), 16),
    }
end

local function neonDistrict()
    local model, origin = baseArena("NeonDistrict", 310, 300)
    sign(model, "NEON DISTRICT", origin + Vector3.new(0, 20, -145), Vector3.new(44, 14, 1), CYAN)

    for row = -2, 2 do
        for col = -2, 2 do
            if not (math.abs(row) <= 1 and math.abs(col) <= 1) then
                local pos = origin + Vector3.new(col * 48, 8, row * 48)
                part(model, "Building", Vector3.new(28, 18 + ((row + col) % 3) * 6, 28), CFrame.new(pos), Color3.fromRGB(40, 45, 63), Enum.Material.Concrete)
                neon(model, "BuildingTrim", Vector3.new(29, 1, 29), CFrame.new(pos + Vector3.new(0, 7, 0)), (row + col) % 2 == 0 and CYAN or MAGENTA).CanCollide = false
            end
        end
    end
    for i = -2, 2 do
        cover(model, origin + Vector3.new(i * 44, 5, 0), Vector3.new(20, 10, 6))
        cover(model, origin + Vector3.new(0, 5, i * 44), Vector3.new(6, 10, 20))
    end
    pickup(model, "HealthPickup", origin + Vector3.new(0, 0, 0), "Health", 35, CYAN)
    pickup(model, "AmmoPickup", origin + Vector3.new(80, 0, 0), "Ammo", 18, ORANGE)
    pickup(model, "AmmoPickup", origin + Vector3.new(-80, 0, 0), "Ammo", 18, ORANGE)

    return {
        Id = "NeonDistrict",
        DisplayName = "Distrito Neón",
        Origin = origin,
        CyanSpawns = makeGrid(origin + Vector3.new(-105, 1, 105), 50, 5, 9),
        MagentaSpawns = makeGrid(origin + Vector3.new(105, 1, -105), 50, 5, 9),
        FFASpawns = makeGrid(origin, 100, 10, 24),
        BotSpawns = makeGrid(origin, 24, 6, 38),
    }
end

local function inkDepot()
    local model, origin = baseArena("InkDepot", 340, 260)
    sign(model, "INK DEPOT", origin + Vector3.new(0, 20, -125), Vector3.new(42, 14, 1), ORANGE)

    for row = -2, 2 do
        for col = -3, 3 do
            if (row + col) % 2 == 0 then
                crate(model, origin + Vector3.new(col * 38, 4, row * 38), (row + col) % 4 == 0 and Color3.fromRGB(48, 57, 80) or Color3.fromRGB(62, 48, 67))
            end
        end
    end
    for side = -1, 1, 2 do
        part(model, "Container", Vector3.new(58, 16, 18), CFrame.new(origin + Vector3.new(side * 92, 6, 0)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(42, 52, 70), Enum.Material.Metal)
        neon(model, "ContainerTrim", Vector3.new(60, 1, 20), CFrame.new(origin + Vector3.new(side * 92, 12, 0)) * CFrame.Angles(0, math.rad(90), 0), side < 0 and CYAN or MAGENTA).CanCollide = false
    end
    pickup(model, "HealthPickup", origin + Vector3.new(0, 0, 70), "Health", 35, CYAN)
    pickup(model, "HealthPickup", origin + Vector3.new(0, 0, -70), "Health", 35, MAGENTA)
    pickup(model, "AmmoPickup", origin, "Ammo", 22, ORANGE)

    return {
        Id = "InkDepot",
        DisplayName = "Depósito de Tinta",
        Origin = origin,
        CyanSpawns = makeGrid(origin + Vector3.new(-130, 1, 0), 50, 5, 9),
        MagentaSpawns = makeGrid(origin + Vector3.new(130, 1, 0), 50, 5, 9),
        FFASpawns = makeGrid(origin, 100, 10, 22),
        BotSpawns = makeGrid(origin, 30, 6, 35),
    }
end

local function rooftopRush()
    local model, origin = baseArena("RooftopRush", 300, 300)
    sign(model, "ROOFTOP RUSH", origin + Vector3.new(0, 20, -145), Vector3.new(46, 14, 1), MAGENTA)

    for row = -2, 2 do
        for col = -2, 2 do
            local pos = origin + Vector3.new(col * 52, 4 + ((row + col) % 2) * 3, row * 52)
            part(model, "RoofBlock", Vector3.new(38, 8, 38), CFrame.new(pos), Color3.fromRGB(37, 41, 57), Enum.Material.Metal)
            cover(model, pos + Vector3.new(0, 8, 0), Vector3.new(18, 8, 5), (row + col) % 2 == 0 and Color3.fromRGB(30, 74, 84) or Color3.fromRGB(77, 31, 62))
        end
    end
    for i = -2, 2 do
        local ramp = part(model, "Ramp", Vector3.new(28, 2, 16), CFrame.new(origin + Vector3.new(i * 48, 4, -80)) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(55, 61, 79), Enum.Material.Metal)
        ramp:SetAttribute("Ramp", true)
    end
    pickup(model, "HealthPickup", origin, "Health", 40, CYAN)
    pickup(model, "AmmoPickup", origin + Vector3.new(0, 0, 100), "Ammo", 20, ORANGE)
    pickup(model, "AmmoPickup", origin + Vector3.new(0, 0, -100), "Ammo", 20, ORANGE)

    return {
        Id = "RooftopRush",
        DisplayName = "Azoteas Neón",
        Origin = origin,
        CyanSpawns = makeGrid(origin + Vector3.new(-105, 10, -105), 50, 5, 9),
        MagentaSpawns = makeGrid(origin + Vector3.new(105, 10, 105), 50, 5, 9),
        FFASpawns = makeGrid(origin + Vector3.new(0, 10, 0), 100, 10, 23),
        BotSpawns = makeGrid(origin + Vector3.new(0, 10, 0), 24, 6, 38),
    }
end

function MapService.BuildDuelGame(teamSize)
    return duelArena(teamSize)
end

function MapService.BuildGame(mapId)
    if mapId == "NeonDistrict" then return neonDistrict() end
    if mapId == "InkDepot" then return inkDepot() end
    if mapId == "RooftopRush" then return rooftopRush() end
    return neonDistrict()
end

function MapService.ActivatePickups(onPickup)
    if not arena then return end
    for _, object in ipairs(arena:GetDescendants()) do
        if object:IsA("BasePart") and object:GetAttribute("PickupType") then
            local active = true
            object.Touched:Connect(function(hit)
                if not active then return end
                local character = hit:FindFirstAncestorOfClass("Model")
                local player = character and game:GetService("Players"):GetPlayerFromCharacter(character)
                if not player then return end
                active = false
                object.Transparency = 1
                onPickup(player, object:GetAttribute("PickupType"), object:GetAttribute("Amount") or 0)
                task.delay(12, function()
                    if object.Parent then
                        active = true
                        object.Transparency = 0
                    end
                end)
            end)
        end
    end
end

return MapService
