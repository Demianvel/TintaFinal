local ArenaVisualService = {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)

local function puddle(parent, position, radius, color, rotation)
    local p = Instance.new("Part")
    p.Name = "InkSplash"
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Shape = Enum.PartType.Cylinder
    p.Size = Vector3.new(0.16, radius * 2, radius * 2)
    p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(rotation or 0), 0)
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = 0.13
    p.Parent = parent
end

local function lane(parent, center, length, width, color, angle)
    local p = Instance.new("Part")
    p.Name = "InkLane"
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Size = Vector3.new(width, 0.14, length)
    p.CFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(angle or 0), 0)
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = 0.22
    p.Parent = parent
end

local function banner(parent, position, text, color)
    local board = Instance.new("Part")
    board.Name = "CompetitiveBanner"
    board.Anchored = true
    board.CanCollide = false
    board.Size = Vector3.new(34, 9, 0.8)
    board.CFrame = CFrame.new(position)
    board.Material = Enum.Material.Metal
    board.Color = Color3.fromRGB(8, 10, 18)
    board.Parent = parent
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = gui
end

function ArenaVisualService.Decorate(arenaData, mode)
    local root = workspace:FindFirstChild("TintaFinalWorld")
    local arenaFolder = root and root:FindFirstChild("Arena")
    if not arenaFolder or not arenaData then return end
    local decoration = Instance.new("Folder")
    decoration.Name = "CompetitiveInkDecoration"
    decoration.Parent = arenaFolder
    local origin = arenaData.Origin

    for index = 1, 18 do
        local angle = (index * 137) % 360
        local distance = 28 + ((index * 29) % 112)
        local offset = Vector3.new(math.cos(math.rad(angle)) * distance, 0.05, math.sin(math.rad(angle)) * distance)
        local color = index % 3 == 0 and ORANGE or (index % 2 == 0 and MAGENTA or CYAN)
        puddle(decoration, origin + offset, 3 + (index % 5) * 1.35, color, angle)
    end

    lane(decoration, origin + Vector3.new(-72, 0.08, 0), 150, 5, CYAN, 14)
    lane(decoration, origin + Vector3.new(72, 0.09, 0), 150, 5, MAGENTA, -14)
    lane(decoration, origin + Vector3.new(0, 0.10, 72), 95, 3.5, ORANGE, 90)

    banner(decoration, origin + Vector3.new(-72, 17, -135), "EQUIPO CIAN", CYAN)
    banner(decoration, origin + Vector3.new(72, 17, -135), "EQUIPO MAGENTA", MAGENTA)
    if mode == "FreeSplash" then
        banner(decoration, origin + Vector3.new(0, 29, 125), "TODOS CONTRA TODOS", ORANGE)
    else
        banner(decoration, origin + Vector3.new(0, 29, 125), "TINTA FINAL · COMPETITIVE", Color3.new(1,1,1))
    end
end

return ArenaVisualService
