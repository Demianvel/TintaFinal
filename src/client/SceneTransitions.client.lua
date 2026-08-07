local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = remotes:WaitForChild("GameState")
local getSnapshot = remotes:WaitForChild("GetSnapshot")
local Visual = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalSceneTransition"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 900
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(3, 4, 9)
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Visible = false
root.Parent = gui

local image = Instance.new("ImageLabel")
image.Size = UDim2.fromScale(1, 1)
image.BackgroundTransparency = 1
image.ImageTransparency = 1
image.ScaleType = Enum.ScaleType.Crop
image.Parent = root

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 1
shade.BorderSizePixel = 0
shade.Parent = root

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.fromScale(0.5, 0.925)
status.Size = UDim2.fromScale(0.70, 0.065)
status.BackgroundColor3 = Color3.fromRGB(5, 7, 14)
status.BackgroundTransparency = 0.16
status.BorderSizePixel = 0
status.Font = Enum.Font.GothamBlack
status.TextColor3 = Color3.fromRGB(248, 250, 255)
status.TextScaled = true
status.TextTransparency = 1
status.Parent = root
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 14)
statusCorner.Parent = status
local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(255, 22, 142)
statusStroke.Transparency = 0.30
statusStroke.Thickness = 1.5
statusStroke.Parent = status

local progressBack = Instance.new("Frame")
progressBack.AnchorPoint = Vector2.new(0.5, 1)
progressBack.Position = UDim2.fromScale(0.5, 0.982)
progressBack.Size = UDim2.fromScale(0.48, 0.017)
progressBack.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
progressBack.BorderSizePixel = 0
progressBack.Parent = root
local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(1, 0)
backCorner.Parent = progressBack

local progress = Instance.new("Frame")
progress.Size = UDim2.fromScale(0, 1)
progress.BackgroundColor3 = Color3.fromRGB(0, 226, 239)
progress.BorderSizePixel = 0
progress.Parent = progressBack
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progress
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 22, 142)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 132, 21)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 226, 239)),
})
gradient.Parent = progress

local transitionToken = 0
local lastPhase
local lastMap
local roundVisualIndex = 0
local bootShown = false

local mapNames = {
    NeonDistrict = "DISTRITO NEÓN",
    InkDepot = "DEPÓSITO DE TINTA",
    RooftopRush = "AZOTEAS NEÓN",
}

local function assetUrl(id)
    id = tonumber(id) or 0
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

local function show(assetId, text, duration, withProgress)
    transitionToken += 1
    local token = transitionToken
    local imageUrl = assetUrl(assetId)

    root.Visible = true
    root.BackgroundTransparency = 1
    image.Image = imageUrl
    image.ImageTransparency = 1
    shade.BackgroundTransparency = 1
    status.Text = text or "TINTA FINAL"
    status.TextTransparency = 1
    progress.Size = UDim2.fromScale(0, 1)
    progressBack.Visible = withProgress == true

    TweenService:Create(root, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()
    TweenService:Create(image, TweenInfo.new(0.28), {ImageTransparency = imageUrl == "" and 1 or 0.01}):Play()
    TweenService:Create(shade, TweenInfo.new(0.28), {BackgroundTransparency = imageUrl == "" and 0.2 or 0.72}):Play()
    TweenService:Create(status, TweenInfo.new(0.22), {TextTransparency = 0}):Play()

    if withProgress then
        TweenService:Create(
            progress,
            TweenInfo.new(math.max(0.8, duration - 0.25), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.fromScale(1, 1)}
        ):Play()
    end

    task.wait(duration)
    if token ~= transitionToken then return end

    local fade = 0.26
    TweenService:Create(root, TweenInfo.new(fade), {BackgroundTransparency = 1}):Play()
    TweenService:Create(image, TweenInfo.new(fade), {ImageTransparency = 1}):Play()
    TweenService:Create(shade, TweenInfo.new(fade), {BackgroundTransparency = 1}):Play()
    TweenService:Create(status, TweenInfo.new(fade), {TextTransparency = 1}):Play()
    task.wait(fade)
    if token == transitionToken then root.Visible = false end
end

local function showBoot()
    if bootShown then return end
    bootShown = true
    task.spawn(show, Visual.Assets.MainMenu, "TINTA FINAL · ENTRANDO A LA ARENA", 1.25, true)
end

local function roundAsset()
    roundVisualIndex += 1
    if roundVisualIndex % 2 == 1 then
        return Visual.Assets.Round1, "RONDA 1 · ¡CUBRE MÁS QUE TU RIVAL!"
    end
    return Visual.Assets.Round2, "RONDA 2 · ¡EL TERRITORIO CAMBIA!"
end

local function handleState(state, force)
    if type(state) ~= "table" then return end
    local phase = tostring(state.Phase or "Waiting")
    local mapId = state.CurrentMap
    local changed = force == true or phase ~= lastPhase or (mapId and mapId ~= lastMap)
    lastPhase = phase
    if mapId then lastMap = mapId end
    if not changed then return end

    if phase == "Loading" then
        task.spawn(show, Visual.Assets.Loading, "PREPARANDO LA BATALLA · " .. (mapNames[mapId] or "ARENA PVP"), 2.05, true)
    elseif phase == "Combat" then
        local artId, roundText = roundAsset()
        task.spawn(show, artId, roundText, 1.20, false)
    elseif phase == "Warmup" then
        task.spawn(show, Visual.Assets.Lobby, "CALENTAMIENTO · MOVETE, APUNTÁ, DISPARÁ Y RECARGÁ", 1.05, false)
    elseif phase == "Results" then
        task.spawn(show, Visual.Assets.Shop, "RONDA TERMINADA · RECOMPENSAS Y RANKING", 1.25, false)
    elseif phase == "Intermission" then
        task.spawn(show, Visual.Assets.MainMenu, "PRÓXIMA PARTIDA · MAPA AUTOMÁTICO", 0.95, false)
    elseif phase == "Waiting" and force == true then
        task.spawn(show, Visual.Assets.Lobby, "LOBBY PVP · ESPERANDO JUGADORES", 0.95, false)
    end
end

gameState.OnClientEvent:Connect(function(state)
    handleState(state, false)
end)

showBoot()
task.spawn(function()
    task.wait(0.30)
    local ok, snapshot = pcall(function()
        return getSnapshot:InvokeServer()
    end)
    if ok and type(snapshot) == "table" and type(snapshot.Game) == "table" then
        task.wait(1.10)
        handleState(snapshot.Game, true)
    end
end)

print("[TintaFinal] Pantallas y transiciones visuales PvP sincronizadas.")
