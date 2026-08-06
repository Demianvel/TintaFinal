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
gui.Parent = player:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(4, 5, 11)
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
title.Position = UDim2.fromScale(0.5, 0.45)
title.Size = UDim2.fromScale(0.86, 0.18)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "TINTA FINAL"
title.TextColor3 = Color3.fromRGB(248, 250, 255)
title.TextStrokeColor3 = Color3.new(0,0,0)
title.TextStrokeTransparency = 1
title.TextScaled = true
title.TextTransparency = 1
title.Parent = background

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5,0.5)
subtitle.Position = UDim2.fromScale(0.5,0.61)
subtitle.Size = UDim2.fromScale(0.80,0.07)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "PREPARANDO ARENA..."
subtitle.TextColor3 = Color3.fromRGB(0,226,239)
subtitle.TextScaled = true
subtitle.TextTransparency = 1
subtitle.Parent = background

local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5,0.5)
line.Position = UDim2.fromScale(0.5,0.72)
line.Size = UDim2.new(0,0,0,7)
line.BackgroundColor3 = Color3.fromRGB(255,45,145)
line.BorderSizePixel = 0
line.Parent = background
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,226,239)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,45,145)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,145,25)),
})
gradient.Parent = line

local names = {
    NeonDistrict = "DISTRITO NEÓN",
    InkDepot = "DEPÓSITO DE TINTA",
    RooftopRush = "AZOTEAS NEÓN",
}
local transitionToken = 0
local lastPhase
local lastMap

local function assetUrl(value)
    local id = tonumber(value) or 0
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

local function sceneAsset(phase, mapId)
    if phase == "Loading" then return Visual.Assets.Loading end
    if phase == "Playing" then
        if mapId == "NeonDistrict" then return Visual.Assets.Round1 end
        if mapId == "InkDepot" then return Visual.Assets.Round2 end
        return Visual.Assets.Lobby
    end
    if phase == "Voting" then return Visual.Assets.Lobby end
    if phase == "Results" then return Visual.Assets.Shop end
    return Visual.Assets.MainMenu
end

local function playTransition(mainText, detailText, assetId, duration)
    transitionToken += 1
    local token = transitionToken
    background.Visible = true
    background.BackgroundTransparency = 1
    shade.BackgroundTransparency = 1
    title.TextTransparency = 1
    title.TextStrokeTransparency = 1
    subtitle.TextTransparency = 1
    line.Size = UDim2.new(0,0,0,7)
    title.Text = mainText or "TINTA FINAL"
    subtitle.Text = detailText or "PREPARANDO..."
    image.Image = assetUrl(assetId)
    image.ImageTransparency = 1

    TweenService:Create(background,TweenInfo.new(0.25),{BackgroundTransparency=0}):Play()
    TweenService:Create(shade,TweenInfo.new(0.25),{BackgroundTransparency=0.30}):Play()
    TweenService:Create(image,TweenInfo.new(0.35),{ImageTransparency=image.Image=="" and 1 or 0.05}):Play()
    TweenService:Create(title,TweenInfo.new(0.32),{TextTransparency=0,TextStrokeTransparency=0.2}):Play()
    TweenService:Create(subtitle,TweenInfo.new(0.35),{TextTransparency=0}):Play()
    TweenService:Create(line,TweenInfo.new(0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.new(0.58,0,0,7)}):Play()

    task.wait(duration or 1.6)
    if token ~= transitionToken then return end
    local fade = 0.38
    TweenService:Create(background,TweenInfo.new(fade),{BackgroundTransparency=1}):Play()
    TweenService:Create(shade,TweenInfo.new(fade),{BackgroundTransparency=1}):Play()
    TweenService:Create(image,TweenInfo.new(fade),{ImageTransparency=1}):Play()
    TweenService:Create(title,TweenInfo.new(fade),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    TweenService:Create(subtitle,TweenInfo.new(fade),{TextTransparency=1}):Play()
    TweenService:Create(line,TweenInfo.new(fade),{Size=UDim2.new(0,0,0,7)}):Play()
    task.wait(fade)
    if token == transitionToken then background.Visible = false end
end

gameState.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local phase = state.Phase
    local mapId = state.CurrentMap or state.CurrentGame
    local changed = phase ~= lastPhase or (mapId and mapId ~= lastMap)
    lastPhase = phase
    lastMap = mapId or lastMap
    if not changed then return end

    if phase == "Loading" then
        task.spawn(playTransition,"CARGANDO ARENA",names[mapId] or "TINTA FINAL SHOOTER","" ~= "" and 0 or sceneAsset(phase,mapId),2.3)
    elseif phase == "Playing" then
        local modeNames={Survival="SUPERVIVENCIA DE TINTA",TeamSplash="CIAN VS MAGENTA",FreeSplash="TODOS CONTRA TODOS"}
        task.spawn(playTransition,names[mapId] or "NUEVA ARENA",modeNames[state.Mode] or "COMBATE",sceneAsset(phase,mapId),1.7)
    elseif phase == "Voting" then
        task.spawn(playTransition,"VOTACIÓN DE MAPA","ELEGÍ LA PRÓXIMA ARENA",sceneAsset(phase,mapId),1.4)
    elseif phase == "Results" then
        task.spawn(playTransition,"RONDA TERMINADA","RECOMPENSAS Y RESULTADOS",sceneAsset(phase,mapId),1.5)
    elseif phase == "Intermission" then
        task.spawn(playTransition,"TINTA FINAL","PREPARÁ TU ARMA",Visual.Assets.MainMenu,1.3)
    end
end)

print("[TintaFinal] Transiciones shooter cargadas.")
