local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameState = remotes:WaitForChild("GameState")
local Visual = require(ReplicatedStorage.Shared:WaitForChild("VisualConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalCinematics"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Parent = gui

local image = Instance.new("ImageLabel")
image.Size = UDim2.fromScale(1, 1)
image.BackgroundTransparency = 1
image.ImageTransparency = 1
image.ScaleType = Enum.ScaleType.Crop
image.Parent = overlay

local tint = Instance.new("Frame")
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.new(0, 0, 0)
tint.BackgroundTransparency = 0.42
tint.Parent = overlay

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.45)
title.Size = UDim2.new(0.82, 0, 0, 78)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "TINTA FINAL"
title.TextColor3 = Color3.fromRGB(248, 250, 255)
title.TextStrokeTransparency = 0.45
title.TextScaled = true
title.TextTransparency = 1
title.Parent = overlay

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.56)
subtitle.Size = UDim2.new(0.72, 0, 0, 42)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "COMPETITIVE ARENA"
subtitle.TextColor3 = Color3.fromRGB(0, 226, 239)
subtitle.TextScaled = true
subtitle.TextTransparency = 1
subtitle.Parent = overlay

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.67)
barBack.Size = UDim2.new(0.46, 0, 0, 8)
barBack.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
barBack.BorderSizePixel = 0
barBack.BackgroundTransparency = 1
barBack.Parent = overlay
local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(1, 0)
backCorner.Parent = barBack

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(255, 45, 145)
bar.BorderSizePixel = 0
bar.BackgroundTransparency = 1
bar.Parent = barBack
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = bar

local phaseToken = 0
local roundNumber = 0
local lastPhase = ""

local mapNames = {
    NeonDistrict = "DISTRITO NEÓN",
    InkDepot = "DEPÓSITO DE TINTA",
    RooftopRush = "AZOTEAS NEÓN",
}

local function asset(id)
    id = tonumber(id) or 0
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

local function setArtwork(assetId)
    local value = asset(assetId)
    image.Image = value
    image.ImageTransparency = value == "" and 1 or 0.03
end

local function fadeOut(token)
    local tween = TweenService:Create(overlay, TweenInfo.new(0.34), { BackgroundTransparency = 1 })
    TweenService:Create(image, TweenInfo.new(0.34), { ImageTransparency = 1 }):Play()
    TweenService:Create(title, TweenInfo.new(0.24), { TextTransparency = 1 }):Play()
    TweenService:Create(subtitle, TweenInfo.new(0.24), { TextTransparency = 1 }):Play()
    TweenService:Create(barBack, TweenInfo.new(0.24), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(bar, TweenInfo.new(0.24), { BackgroundTransparency = 1 }):Play()
    tween:Play()
    tween.Completed:Wait()
    if token == phaseToken then overlay.Visible = false end
end

local function showCinematic(assetId, titleText, subtitleText, duration, useProgress)
    phaseToken += 1
    local token = phaseToken
    overlay.Visible = true
    overlay.BackgroundTransparency = 0
    setArtwork(assetId)
    title.Text = titleText
    subtitle.Text = subtitleText
    title.TextTransparency = 0
    subtitle.TextTransparency = 0
    barBack.BackgroundTransparency = useProgress and 0.18 or 1
    bar.BackgroundTransparency = useProgress and 0 or 1
    bar.Size = UDim2.fromScale(0, 1)

    image.Size = UDim2.fromScale(1.04, 1.04)
    image.Position = UDim2.fromScale(-0.02, -0.02)
    TweenService:Create(image, TweenInfo.new(duration + 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
    }):Play()

    if useProgress then
        TweenService:Create(bar, TweenInfo.new(math.max(0.8, duration - 0.2), Enum.EasingStyle.Linear), {
            Size = UDim2.fromScale(1, 1),
        }):Play()
    end

    task.delay(duration, function()
        if token == phaseToken then fadeOut(token) end
    end)
end

local function handleState(state)
    if type(state) ~= "table" then return end
    local phase = tostring(state.Phase or "")
    if phase == lastPhase then return end
    lastPhase = phase

    local map = mapNames[state.CurrentMap] or tostring(state.CurrentMap or "ARENA")
    local mode = tostring(state.Mode or state.CurrentGame or "COMPETITIVE")

    if phase == "Loading" then
        showCinematic(Visual.Assets.Loading, "PREPARANDO LA BATALLA", map .. " · " .. mode, 3.8, true)
    elseif phase == "Combat" then
        roundNumber += 1
        local roundAsset = roundNumber % 2 == 1 and Visual.Assets.Round1 or Visual.Assets.Round2
        showCinematic(roundAsset, "RONDA " .. tostring(roundNumber), map .. " · " .. mode, 2.0, false)
    elseif phase == "Results" then
        showCinematic(Visual.Assets.Lobby, "RESULTADOS", tostring(state.Announcement or "FIN DE PARTIDA"), 2.7, false)
    elseif phase == "Voting" then
        showCinematic(Visual.Assets.Lobby, "ELEGÍ EL PRÓXIMO CAMPO", "VOTACIÓN DE MAPA", 1.5, false)
    elseif phase == "Intermission" then
        roundNumber = 0
    end
end

GameState.OnClientEvent:Connect(handleState)
