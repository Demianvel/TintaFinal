local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapService = {}
local root
local lobby
local arena
local points = {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)
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

local function sign(parent, text, position, size, color)
    local board = part(parent, "Sign", size or Vector3.new(28, 10, 1), CFrame.new(position), Color3.fromRGB(8, 9, 16), Enum.Material.Metal)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBlack
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = gui
    return board
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

    part(lobby, "CenterStage", Vector3.new(100, 2, 55), CFrame.new(0, 0, -20), Color3.fromRGB(31, 34, 49), Enum.Material.Metal)
    sign(lobby, "TINTA FINAL\nARENA SHOOTER", Vector3.new(0, 20, -105), Vector3.new(54, 17, 1), CYAN)
    sign(lobby, "ARMERÍA", Vector3.new(-112, 12, -70), Vector3.new(28, 10, 1), ORANGE)
    sign(lobby, "TIENDA", Vector3.new(112, 12, -70), Vector3.new(28, 10, 1), MAGENTA)
    sign(lobby, "PORTAL DE COMBATE", Vector3.new(0, 11, 5), Vector3.new(34, 10, 1), Color3.new(1,1,1))

    for i = 1, 4 do
        local x = -115 + (i - 1) * 77
        neon(lobby, "LobbyPillar", Vector3.new(3, 24, 3), CFrame.new(x, 10, -95), i % 2 == 0 and MAGENTA or CYAN)
    end

    points.VotePads = {}
    for index = 1, 3 do
        local x = (index - 2) * 42
        local pad = neon(lobby, "VotePad" .. index, Vector3.new(30, 1, 22), CFrame.new(x, 0, -55), index == 1 and CYAN or (index == 2 and MAGENTA or ORANGE))
        pad:SetAttribute("VoteIndex", index)
        points.VotePads[index] = pad.Position
    end

    return points
end

function MapService.ClearArena()
    if arena then arena:ClearAllChildren() end
end

function MapService.GetPoint(name) return points[name] end
function MapService.GetPoints() return points end
function MapService.MakeGridPositions(center, count, columns, spacing) return makeGrid(center, count, columns, spacing) end

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
