-- Mobile-friendly scene transitions between lobby, voting, rounds and results.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = remotes:WaitForChild("GameState")
local Visual = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalSceneTransition"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 900
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(5, 7, 16)
background.BackgroundTransparency = 1
background.BorderSizePixel = 0
background.Visible = false
background.Parent = gui

local image = Instance.new("ImageLabel")
image.Size = UDim2.fromScale(1, 1)
image.BackgroundTransparency = 1
image.ImageTransparency = 1
image.ScaleType = Enum.ScaleType.Crop
image.Parent = background

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 1
shade.BorderSizePixel = 0
shade.Parent = background

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.46)
title.Size = UDim2.fromScale(0.86, 0.19)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "TINTA FINAL"
title.TextColor3 = Color3.fromRGB(245, 250, 255)
title.TextStrokeColor3 = Color3.new(0, 0, 0)
title.TextStrokeTransparency = 1
title.TextScaled = true
title.TextTransparency = 1
title.Parent = background

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.60)
subtitle.Size = UDim2.fromScale(0.78, 0.08)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "PREPARANDO..."
subtitle.TextColor3 = Color3.fromRGB(0, 226, 239)
subtitle.TextScaled = true
subtitle.TextTransparency = 1
subtitle.Parent = background

local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0.5)
line.Position = UDim2.fromScale(0.5, 0.71)
line.Size = UDim2.new(0, 0, 0, 6)
line.BackgroundColor3 = Color3.fromRGB(255, 45, 145)
line.BorderSizePixel = 0
line.Parent = background

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 226, 239)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 45, 145)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 157, 35)),
})
gradient.Parent = line

local names = {
    PulseRun = "PULSO Y SILENCIO",
    InkMemory = "MEMORIA DE TINTA",
    FallingGrid = "CUADRÍCULA INESTABLE",
    GuardHunt = "CACERÍA DE SOMBRAS",
    LastPlatform = "ÚLTIMA PLATAFORMA",
}

local phaseNames = {
    Intermission = "NUEVA PARTIDA",
    Voting = "ELEGÍ LA PRÓXIMA PRUEBA",
    Playing = "COMIENZA LA RONDA",
    Results = "RESULTADOS",
    Lobby = "LOBBY",
}

local transitionToken = 0
local lastPhase
local lastGame

local function assetUrl(value)
    local id = tonumber(value) or 0
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

local function playTransition(mainText, detailText, useLoading)
    transitionToken += 1
    local token = transitionToken

    background.Visible = true
    background.BackgroundTransparency = 1
    shade.BackgroundTransparency = 1
    title.TextTransparency = 1
    title.TextStrokeTransparency = 1
    subtitle.TextTransparency = 1
    line.Size = UDim2.new(0, 0, 0, 6)

    title.Text = mainText or "TINTA FINAL"
    subtitle.Text = detailText or "PREPARANDO..."
    image.Image = assetUrl(useLoading and Visual.Assets.Loading or Visual.Assets.MainMenu)
    image.ImageTransparency = image.Image == "" and 1 or 1

    TweenService:Create(background, TweenInfo.new(0.24), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(shade, TweenInfo.new(0.24), { BackgroundTransparency = 0.34 }):Play()
    TweenService:Create(image, TweenInfo.new(0.3), { ImageTransparency = image.Image == "" and 1 or 0.12 }):Play()
    TweenService:Create(title, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0.2 }):Play()
    TweenService:Create(subtitle, TweenInfo.new(0.34), { TextTransparency = 0 }):Play()
    TweenService:Create(line, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.56, 0, 0, 6),
    }):Play()

    task.wait(1.35)
    if token ~= transitionToken then
        return
    end

    local duration = 0.35
    TweenService:Create(background, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(shade, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(image, TweenInfo.new(duration), { ImageTransparency = 1 }):Play()
    TweenService:Create(title, TweenInfo.new(duration), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    TweenService:Create(subtitle, TweenInfo.new(duration), { TextTransparency = 1 }):Play()
    TweenService:Create(line, TweenInfo.new(duration), { Size = UDim2.new(0, 0, 0, 6) }):Play()
    task.wait(duration)

    if token == transitionToken then
        background.Visible = false
    end
end

gameState.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then
        return
    end

    local phase = state.Phase
    local currentGame = state.CurrentGame
    local changed = phase ~= lastPhase or (currentGame and currentGame ~= lastGame)
    lastPhase = phase
    lastGame = currentGame or lastGame

    if not changed then
        return
    end

    if phase == "Playing" and currentGame then
        task.spawn(playTransition, names[currentGame] or "NUEVA PRUEBA", "SOBREVIVÍ HASTA EL FINAL", true)
    elseif phase == "Voting" then
        task.spawn(playTransition, "VOTACIÓN", phaseNames.Voting, false)
    elseif phase == "Results" then
        task.spawn(playTransition, "RONDA TERMINADA", "REVISANDO RESULTADOS", false)
    elseif phase == "Intermission" then
        task.spawn(playTransition, "TINTA FINAL", "PREPARANDO LA PARTIDA", true)
    end
end)

print("[TintaFinal] Transiciones de escenas cargadas.")
