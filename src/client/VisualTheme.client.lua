local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Visual = require(shared:WaitForChild("VisualConfig"))
local palette = Visual.Palette

local function corner(parent, radius)
    local object = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 12)
    object.Parent = parent
    return object
end

local function stroke(parent, color, thickness, transparency)
    local object = parent:FindFirstChild("TintaStroke") or Instance.new("UIStroke")
    object.Name = "TintaStroke"
    object.Color = color or palette.Cyan
    object.Thickness = thickness or 2
    object.Transparency = transparency or 0.15
    object.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    object.Parent = parent
    return object
end

local function gradient(parent, first, second, rotation)
    local object = parent:FindFirstChild("TintaGradient") or Instance.new("UIGradient")
    object.Name = "TintaGradient"
    object.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, first),
        ColorSequenceKeypoint.new(1, second),
    })
    object.Rotation = rotation or 0
    object.Parent = parent
    return object
end

local function assetUrl(id)
    id = tonumber(id) or 0
    if id <= 0 then
        return ""
    end
    return "rbxassetid://" .. tostring(id)
end

local function addInkDrop(parent, position, size, color, delayTime)
    local drop = Instance.new("Frame")
    drop.AnchorPoint = Vector2.new(0.5, 0.5)
    drop.Position = position
    drop.Size = size
    drop.BackgroundColor3 = color
    drop.BorderSizePixel = 0
    drop.Rotation = math.random(-18, 18)
    drop.Parent = parent
    corner(drop, 999)

    drop.BackgroundTransparency = 0.16
    task.delay(delayTime or 0, function()
        while drop.Parent do
            local tween = TweenService:Create(
                drop,
                TweenInfo.new(1.4 + math.random() * 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {
                    Size = UDim2.new(
                        drop.Size.X.Scale * 1.1,
                        drop.Size.X.Offset,
                        drop.Size.Y.Scale * 1.1,
                        drop.Size.Y.Offset
                    ),
                    Rotation = drop.Rotation + 8,
                }
            )
            tween:Play()
            tween.Completed:Wait()
        end
    end)
end

local function createLoadingScreen()
    local gui = Instance.new("ScreenGui")
    gui.Name = "TintaFinalLoading"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = palette.Background
    background.BorderSizePixel = 0
    background.Parent = gui
    gradient(background, Color3.fromRGB(5, 12, 30), Color3.fromRGB(29, 5, 36), 20)

    local imageId = assetUrl(Visual.Assets.Loading)
    if imageId ~= "" then
        local artwork = Instance.new("ImageLabel")
        artwork.Name = "Artwork"
        artwork.Size = UDim2.fromScale(1, 1)
        artwork.BackgroundTransparency = 1
        artwork.Image = imageId
        artwork.ScaleType = Enum.ScaleType.Crop
        artwork.Parent = background

        local shade = Instance.new("Frame")
        shade.Size = UDim2.fromScale(1, 1)
        shade.BackgroundColor3 = Color3.new(0, 0, 0)
        shade.BackgroundTransparency = 0.36
        shade.BorderSizePixel = 0
        shade.Parent = artwork
    else
        addInkDrop(background, UDim2.fromScale(0.08, 0.22), UDim2.fromScale(0.22, 0.22), palette.Cyan, 0)
        addInkDrop(background, UDim2.fromScale(0.91, 0.30), UDim2.fromScale(0.26, 0.26), palette.Magenta, 0.15)
        addInkDrop(background, UDim2.fromScale(0.82, 0.83), UDim2.fromScale(0.23, 0.23), palette.Orange, 0.3)
        addInkDrop(background, UDim2.fromScale(0.17, 0.82), UDim2.fromScale(0.18, 0.18), palette.Blue, 0.45)
    end

    local logo = Instance.new("TextLabel")
    logo.Name = "Logo"
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.fromScale(0.5, 0.40)
    logo.Size = UDim2.fromScale(0.78, 0.24)
    logo.BackgroundTransparency = 1
    logo.Font = Enum.Font.GothamBlack
    logo.Text = "TINTA\nFINAL"
    logo.TextColor3 = palette.White
    logo.TextScaled = true
    logo.TextWrapped = true
    logo.TextStrokeColor3 = Color3.new(0, 0, 0)
    logo.TextStrokeTransparency = 0.18
    logo.Parent = background
    gradient(logo, palette.Cyan, palette.Orange, 8)

    local subtitle = Instance.new("TextLabel")
    subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
    subtitle.Position = UDim2.fromScale(0.5, 0.61)
    subtitle.Size = UDim2.fromScale(0.75, 0.06)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = "PREPARANDO LA PRÓXIMA RONDA..."
    subtitle.TextColor3 = palette.White
    subtitle.TextScaled = true
    subtitle.Parent = background

    local barBack = Instance.new("Frame")
    barBack.AnchorPoint = Vector2.new(0.5, 0.5)
    barBack.Position = UDim2.fromScale(0.5, 0.72)
    barBack.Size = UDim2.new(0.66, 0, 0, 26)
    barBack.BackgroundColor3 = Color3.fromRGB(15, 17, 28)
    barBack.BorderSizePixel = 0
    barBack.ClipsDescendants = true
    barBack.Parent = background
    corner(barBack, 999)
    stroke(barBack, palette.White, 2, 0.25)

    local fill = Instance.new("Frame")
    fill.Name = "Progress"
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = palette.Cyan
    fill.BorderSizePixel = 0
    fill.Parent = barBack
    corner(fill, 999)
    gradient(fill, palette.Cyan, palette.Magenta, 0)

    local percent = Instance.new("TextLabel")
    percent.AnchorPoint = Vector2.new(0.5, 0)
    percent.Position = UDim2.fromScale(0.5, 0.765)
    percent.Size = UDim2.new(0.5, 0, 0, 26)
    percent.BackgroundTransparency = 1
    percent.Font = Enum.Font.GothamBold
    percent.Text = "0%"
    percent.TextColor3 = palette.White
    percent.TextSize = 18
    percent.Parent = background

    local duration = math.max(2, tonumber(Visual.LoadingDuration) or 4.5)
    local progressTween = TweenService:Create(
        fill,
        TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.fromScale(1, 1) }
    )
    progressTween:Play()

    local started = os.clock()
    while os.clock() - started < duration and gui.Parent do
        local progress = math.clamp((os.clock() - started) / duration, 0, 1)
        percent.Text = tostring(math.floor(progress * 100)) .. "%"
        task.wait(0.05)
    end
    percent.Text = "100%"

    for _, descendant in ipairs(gui:GetDescendants()) do
        if descendant:IsA("GuiObject") then
            TweenService:Create(descendant, TweenInfo.new(0.35), {
                BackgroundTransparency = 1,
            }):Play()
        end
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            TweenService:Create(descendant, TweenInfo.new(0.35), {
                TextTransparency = 1,
                TextStrokeTransparency = 1,
            }):Play()
        elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            TweenService:Create(descendant, TweenInfo.new(0.35), {
                ImageTransparency = 1,
            }):Play()
        end
    end

    task.wait(0.4)
    gui:Destroy()
end

local function styleButton(button, first, second)
    button.BackgroundColor3 = first
    button.AutoButtonColor = true
    button.TextColor3 = palette.White
    corner(button, 10)
    stroke(button, second, 1.5, 0.30)
    gradient(button, first, second, 0)
end

local function styleMainInterface()
    local gui = player:WaitForChild("PlayerGui"):WaitForChild("TintaFinalUI", 20)
    if not gui then
        warn("TintaFinalUI no apareció; se omite el tema visual.")
        return
    end

    local topBar = gui:FindFirstChild("TopBar")
    if topBar then
        topBar.BackgroundColor3 = palette.Panel
        gradient(topBar, Color3.fromRGB(10, 25, 45), Color3.fromRGB(45, 8, 45), 0)
        stroke(topBar, palette.Cyan, 2, 0.20)

        local title = topBar:FindFirstChild("GameTitle")
        if title and title:IsA("TextLabel") then
            title.Text = "TINTA FINAL"
            title.TextColor3 = palette.White
            gradient(title, palette.Cyan, palette.Magenta, 0)
        end
    end

    local sideMenu = gui:FindFirstChild("SideMenu")
    if sideMenu then
        sideMenu.BackgroundColor3 = palette.Panel
        gradient(sideMenu, Color3.fromRGB(12, 18, 35), Color3.fromRGB(30, 7, 31), 90)
        stroke(sideMenu, palette.Magenta, 2, 0.24)
    end

    local panels = gui:FindFirstChild("Panels")
    if panels then
        panels.BackgroundColor3 = palette.Panel
        gradient(panels, Color3.fromRGB(12, 22, 38), Color3.fromRGB(37, 9, 31), 25)
        stroke(panels, palette.Orange, 2, 0.20)
    end

    local status = gui:FindFirstChild("Status")
    if status then
        gradient(status, Color3.fromRGB(10, 36, 48), Color3.fromRGB(45, 13, 46), 0)
        stroke(status, palette.Cyan, 2, 0.22)
    end

    local votePanel = gui:FindFirstChild("VotePanel")
    if votePanel then
        gradient(votePanel, Color3.fromRGB(10, 29, 43), Color3.fromRGB(50, 12, 34), 0)
        stroke(votePanel, palette.Magenta, 2, 0.22)
    end

    for _, object in ipairs(gui:GetDescendants()) do
        if object:IsA("TextButton") then
            local name = string.lower(object.Name)
            if string.find(name, "shop") or string.find(name, "pass") then
                styleButton(object, Color3.fromRGB(190, 36, 120), palette.Magenta)
            elseif string.find(name, "guard") then
                styleButton(object, Color3.fromRGB(214, 78, 30), palette.Orange)
            elseif string.find(name, "afk") or string.find(name, "difficulty") then
                styleButton(object, Color3.fromRGB(0, 139, 161), palette.Cyan)
            else
                styleButton(object, Color3.fromRGB(45, 89, 190), palette.Magenta)
            end
        elseif object:IsA("TextLabel") then
            if object.TextColor3 ~= Color3.new(0, 0, 0) then
                object.TextColor3 = palette.White
            end
        end
    end

    local accent = Instance.new("Frame")
    accent.Name = "TintaAccentLine"
    accent.AnchorPoint = Vector2.new(0.5, 0)
    accent.Position = UDim2.fromScale(0.5, 0)
    accent.Size = UDim2.new(0.58, 0, 0, 4)
    accent.BackgroundColor3 = palette.Cyan
    accent.BorderSizePixel = 0
    accent.Parent = gui
    gradient(accent, palette.Cyan, palette.Magenta, 0)
end

task.spawn(createLoadingScreen)
task.spawn(styleMainInterface)
