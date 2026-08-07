local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Visual = require(ReplicatedStorage.Shared:WaitForChild("VisualConfig"))

local GetSnapshot = remotes:WaitForChild("GetSnapshot")
local CastVote = remotes:WaitForChild("CastVote")
local ShopPurchase = remotes:WaitForChild("ShopPurchase")
local Spin = remotes:WaitForChild("Spin")
local ToggleAFK = remotes:WaitForChild("ToggleAFK")
local SelectWeapon = remotes:WaitForChild("SelectWeapon")
local SelectSkin = remotes:WaitForChild("SelectSkin")
local GetLeaderboards = remotes:WaitForChild("GetLeaderboards")
local GameState = remotes:WaitForChild("GameState")
local ProfileState = remotes:WaitForChild("ProfileState")
local Victory = remotes:WaitForChild("Victory")

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)
local DARK = Color3.fromRGB(7, 9, 16)
local PANEL = Color3.fromRGB(13, 16, 27)
local WHITE = Color3.fromRGB(248, 250, 255)
local MUTED = Color3.fromRGB(172, 188, 218)

local profile
local config
local currentState
local currentPanel

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalCompetitiveUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function asset(id)
    id = tonumber(id) or 0
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

local scale = Instance.new("UIScale")
scale.Parent = gui
local function updateScale()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.64, 1.08)
end
updateScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
end

local function stroke(object, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CYAN
    s.Transparency = transparency or 0.3
    s.Thickness = thickness or 1.5
    s.Parent = object
end

local function frame(parent, size, position, color, transparency)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = position or UDim2.new()
    f.BackgroundColor3 = color or PANEL
    f.BackgroundTransparency = transparency or 0.08
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 12)
    return f
end

local function label(parent, text, size, position, textSize, color, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position or UDim2.new()
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextColor3 = color or WHITE
    l.TextSize = textSize or 16
    l.TextWrapped = true
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function button(parent, text, size, color)
    local b = Instance.new("TextButton")
    b.Size = size
    b.BackgroundColor3 = color or CYAN
    b.BackgroundTransparency = 0.08
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBlack
    b.Text = text
    b.TextColor3 = WHITE
    b.TextScaled = true
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 9)
    return b
end

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = DARK
backdrop.BackgroundTransparency = 0.22
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local backgroundImage = Instance.new("ImageLabel")
backgroundImage.Size = UDim2.fromScale(1, 1)
backgroundImage.BackgroundTransparency = 1
backgroundImage.Image = asset(Visual.Assets.Lobby)
backgroundImage.ImageTransparency = backgroundImage.Image == "" and 1 or 0.35
backgroundImage.ScaleType = Enum.ScaleType.Crop
backgroundImage.Parent = backdrop

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0,0,0)
shade.BackgroundTransparency = 0.48
shade.BorderSizePixel = 0
shade.Parent = backdrop

local top = frame(gui, UDim2.new(1, -28, 0, 72), UDim2.new(0, 14, 0, 12), Color3.fromRGB(5,7,13), 0.08)
stroke(top, MAGENTA, 0.18, 2)
local title = label(top, "TINTA FINAL", UDim2.new(0, 260, 1, 0), UDim2.new(0, 18, 0, 0), 27, WHITE)
local subtitle = label(top, "COMPETITIVE ARENA", UDim2.new(0, 240, 0, 22), UDim2.new(0, 185, 0, 40), 11, CYAN)
local moneyLabel = label(top, "TM 0", UDim2.new(0, 190, 1, 0), UDim2.new(0.47, 0, 0, 0), 17, ORANGE, Enum.TextXAlignment.Center)
local ratingLabel = label(top, "RATING 1000", UDim2.new(0, 175, 1, 0), UDim2.new(0.64, 0, 0, 0), 16, CYAN, Enum.TextXAlignment.Center)
local rankLabel = label(top, "BRONZE", UDim2.new(0, 165, 1, 0), UDim2.new(0.80, 0, 0, 0), 16, MAGENTA, Enum.TextXAlignment.Center)

local left = frame(gui, UDim2.new(0, 205, 0, 445), UDim2.new(0, 16, 0.5, -205), Color3.fromRGB(7,9,16), 0.05)
stroke(left, CYAN, 0.28, 2)
local profileCard = frame(left, UDim2.new(1, -18, 0, 82), UDim2.new(0, 9, 0, 9), Color3.fromRGB(17,21,34), 0.02)
local playerName = label(profileCard, player.DisplayName, UDim2.new(1,-16,0,31), UDim2.new(0,8,0,8), 17, WHITE)
local playerMeta = label(profileCard, "NIVEL 1 · 0 VICTORIAS", UDim2.new(1,-16,0,26), UDim2.new(0,8,0,43), 11, MUTED)

local menuHolder = Instance.new("Frame")
menuHolder.Size = UDim2.new(1,-18,1,-106)
menuHolder.Position = UDim2.new(0,9,0,98)
menuHolder.BackgroundTransparency = 1
menuHolder.Parent = left
local menuLayout = Instance.new("UIListLayout")
menuLayout.Padding = UDim.new(0,7)
menuLayout.Parent = menuHolder

local playButton = button(menuHolder, "JUGAR", UDim2.new(1,0,0,52), MAGENTA)
local arsenalButton = button(menuHolder, "ARSENAL", UDim2.new(1,0,0,46), CYAN)
local shopButton = button(menuHolder, "TIENDA", UDim2.new(1,0,0,46), ORANGE)
local rankingButton = button(menuHolder, "RANKING", UDim2.new(1,0,0,46), Color3.fromRGB(84,75,205))
local donationButton = button(menuHolder, "DONACIONES", UDim2.new(1,0,0,46), Color3.fromRGB(210,36,120))
local personalizeButton = button(menuHolder, "PERSONALIZAR", UDim2.new(1,0,0,46), Color3.fromRGB(25,155,125))
local rewardsButton = button(menuHolder, "RECOMPENSAS", UDim2.new(1,0,0,46), Color3.fromRGB(95,105,125))

local quick = frame(gui, UDim2.new(0, 340, 0, 225), UDim2.new(1, -360, 0.5, -78), Color3.fromRGB(7,9,16), 0.06)
stroke(quick, MAGENTA, 0.14, 2)
local quickTitle = label(quick, "LISTO PARA JUGAR", UDim2.new(1,-24,0,42), UDim2.new(0,12,0,14), 23, WHITE, Enum.TextXAlignment.Center)
local modeLabel = label(quick, "10 VS 10 · CIAN VS MAGENTA", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,62), 12, CYAN, Enum.TextXAlignment.Center)
local statusLabel = label(quick, "EN COLA COMPETITIVA", UDim2.new(1,-24,0,28), UDim2.new(0,12,0,93), 12, MUTED, Enum.TextXAlignment.Center)
local bigPlay = button(quick, "JUGAR AHORA", UDim2.new(1,-40,0,74), MAGENTA)
bigPlay.Position = UDim2.new(0,20,0,132)

local prize = frame(gui, UDim2.new(0, 720, 0, 86), UDim2.new(0.5, -360, 1, -105), Color3.fromRGB(8,10,18), 0.04)
stroke(prize, ORANGE, 0.20, 2)
label(prize, "PREMIOS DE TEMPORADA · TINTA MONEY", UDim2.new(1,0,0,28), UDim2.new(0,0,0,7), 15, WHITE, Enum.TextXAlignment.Center)
label(prize, "🥇 300.000.000 TM     🥈 150.000.000 TM     🥉 100.000.000 TM", UDim2.new(1,0,0,40), UDim2.new(0,0,0,35), 18, ORANGE, Enum.TextXAlignment.Center)

local panel = frame(gui, UDim2.new(0, 780, 0, 530), UDim2.new(0.5, -390, 0.5, -240), Color3.fromRGB(8,10,18), 0.02)
panel.Visible = false
stroke(panel, MAGENTA, 0.18, 2)
local panelTitle = label(panel, "PANEL", UDim2.new(1,-80,0,58), UDim2.new(0,22,0,8), 25, WHITE)
local closePanel = button(panel, "✕", UDim2.new(0,48,0,44), Color3.fromRGB(95,40,65))
closePanel.Position = UDim2.new(1,-62,0,12)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1,-36,1,-82)
content.Position = UDim2.new(0,18,0,68)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = MAGENTA
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0,10)
contentLayout.Parent = content

local votePanel = frame(gui, UDim2.new(0, 690, 0, 190), UDim2.new(0.5,-345,1,-215), Color3.fromRGB(8,10,18), 0.02)
votePanel.Visible = false
stroke(votePanel, CYAN, 0.15, 2)
local voteTitle = label(votePanel, "VOTÁ EL PRÓXIMO MAPA", UDim2.new(1,-20,0,40), UDim2.new(0,10,0,5), 20, WHITE, Enum.TextXAlignment.Center)
local voteHolder = Instance.new("Frame")
voteHolder.Size = UDim2.new(1,-20,0,125)
voteHolder.Position = UDim2.new(0,10,0,50)
voteHolder.BackgroundTransparency = 1
voteHolder.Parent = votePanel
local voteLayout = Instance.new("UIListLayout")
voteLayout.FillDirection = Enum.FillDirection.Horizontal
voteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
voteLayout.Padding = UDim.new(0,10)
voteLayout.Parent = voteHolder
local voteButtons = {}
for i = 1, 3 do
    local b = button(voteHolder, "MAPA", UDim2.new(0,215,1,0), i == 1 and CYAN or (i == 2 and MAGENTA or ORANGE))
    voteButtons[i] = b
    b.Activated:Connect(function()
        local mapId = currentState and currentState.OfferedGames and currentState.OfferedGames[i]
        if mapId then CastVote:InvokeServer(mapId) end
    end)
end

local toast = label(gui, "", UDim2.new(0,500,0,52), UDim2.new(0.5,-250,1,-68), 15, WHITE, Enum.TextXAlignment.Center)
toast.BackgroundColor3 = Color3.fromRGB(8,10,18)
toast.BackgroundTransparency = 0.03
toast.Visible = false
corner(toast,10)
stroke(toast,CYAN,0.35,1)
local toastToken = 0
local function showToast(text)
    toastToken += 1
    local token = toastToken
    toast.Text = tostring(text or "")
    toast.TextTransparency = 0
    toast.Visible = true
    task.delay(2.6, function()
        if token ~= toastToken then return end
        TweenService:Create(toast, TweenInfo.new(0.25), {TextTransparency=1}):Play()
        task.wait(0.3)
        if token == toastToken then toast.Visible = false end
    end)
end

local mapNames = { NeonDistrict="DISTRITO NEÓN", InkDepot="DEPÓSITO DE TINTA", RooftopRush="AZOTEAS NEÓN" }

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function row(titleText, description, actionText, color, callback, height)
    local r = frame(content, UDim2.new(1,-8,0,height or 94), UDim2.new(), Color3.fromRGB(16,19,31), 0.02)
    stroke(r, color or CYAN, 0.62, 1)
    label(r, titleText, UDim2.new(0.62,-10,0,34), UDim2.new(0,14,0,9), 17, WHITE)
    local d = label(r, description or "", UDim2.new(0.62,-10,0,42), UDim2.new(0,14,0,44), 12, MUTED)
    if actionText then
        local a = button(r, actionText, UDim2.new(0.32,0,0,62), color or CYAN)
        a.Position = UDim2.new(0.66,0,0,16)
        if callback then a.Activated:Connect(callback) end
    end
    return r
end

local function section(text, color)
    local l = label(content, text, UDim2.new(1,-8,0,38), UDim2.new(), 19, color or WHITE)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function refreshTop()
    if not profile then return end
    moneyLabel.Text = "TM " .. tostring(profile.TintaMoney or profile.Won or 0)
    ratingLabel.Text = "RATING " .. tostring(profile.CompetitiveRating or 1000)
    rankLabel.Text = tostring(profile.CompetitiveRank or "BRONZE")
    playerMeta.Text = string.format("NIVEL %d · %d VICTORIAS", profile.Level or 1, profile.Wins or 0)
end

local function openPanel(name)
    currentPanel = name
    panel.Visible = true
    panelTitle.Text = name
    clearContent()
end

local function openArsenal()
    openPanel("ARSENAL COMPETITIVO")
    for _, weaponId in ipairs(config.Shooter.WeaponOrder) do
        local def = config.Weapons[weaponId]
        local unlocked = profile.Inventory and profile.Inventory[weaponId]
        local selected = profile.SelectedWeapon == weaponId
        local description = string.format("%s · DAÑO %d · CARGADOR %d · %s", def.Class or "ARMA", def.Damage, def.Magazine, def.Automatic and "AUTOMÁTICA" or "SEMIAUTO")
        row(def.DisplayName, description, selected and "EQUIPADA" or (unlocked and "EQUIPAR" or "BLOQUEADA"), def.Accent, function()
            if not unlocked then showToast("Desbloqueala desde la tienda.") return end
            local _, message, newProfile = SelectWeapon:InvokeServer(weaponId)
            if newProfile then profile = newProfile refreshTop() openArsenal() end
            showToast(message)
        end)
    end
end

local function priceText(item)
    if item.Currency == "Gems" then return "💎 " .. tostring(item.Price) end
    return "TM " .. tostring(item.Price)
end

local function openShop()
    openPanel("TIENDA / SHOP")
    section("COMPRAR CON TINTA MONEY", ORANGE)
    for _, itemId in ipairs(config.ShopOrder) do
        local item = config.Shop[itemId]
        local inventoryId = item.WeaponId or item.ItemId or itemId
        local owned = (item.Type == "Weapon" or item.Type == "Cosmetic") and profile.Inventory and profile.Inventory[inventoryId]
        row(item.DisplayName, item.Description, owned and "COMPRADO" or priceText(item), item.Type == "Weapon" and MAGENTA or CYAN, function()
            if owned then showToast("Ya tenés este objeto.") return end
            local _, message, newProfile = ShopPurchase:InvokeServer(itemId)
            if newProfile then profile = newProfile refreshTop() openShop() end
            showToast(message)
        end)
    end

    section("COMPRAR TINTA MONEY CON ROBUX", MAGENTA)
    for _, product in ipairs(config.Monetization.Products or {}) do
        if product.GrantType == "TintaMoney" then
            local ready = (tonumber(product.ProductId) or 0) > 0
            row(product.DisplayName, product.Description, ready and ("R$ " .. tostring(product.PriceRobux)) or "CONFIGURANDO", MAGENTA, function()
                if not ready then showToast("Producto Robux todavía en configuración.") return end
                MarketplaceService:PromptProductPurchase(player, product.ProductId)
            end)
        end
    end
end

local function leaderboardRows(boardName, valueSuffix)
    local board, message = GetLeaderboards:InvokeServer(boardName, 15)
    if type(board) ~= "table" then
        row("RANKING NO DISPONIBLE", tostring(message or "Intentá nuevamente."), nil, CYAN)
        return
    end
    for _, entry in ipairs(board) do
        row(string.format("#%d  %s", entry.Position, entry.Name), tostring(entry.Value) .. (valueSuffix or ""), nil, entry.Position == 1 and ORANGE or CYAN, nil, 68)
    end
end

local function openRanking()
    openPanel("RANKING DE COMPETENCIA")
    section("TEMPORADA " .. tostring(config.Competitive.SeasonId), MAGENTA)
    row("PREMIOS DEL PODIO", "1.º 300.000.000 TM · 2.º 150.000.000 TM · 3.º 100.000.000 TM", nil, ORANGE, nil, 76)
    section("PUNTOS DE TEMPORADA", CYAN)
    leaderboardRows("Season", " PTS")
    section("RATING COMPETITIVO", MAGENTA)
    leaderboardRows("Rating", " RATING")
end

local function openDonations()
    openPanel("DONACIONES / APOYO")
    section("APOYAR CON ROBUX", MAGENTA)
    row("RANKING DE APOYO", "Las compras de apoyo suman al ranking global de donaciones y entregan un bonus de Tinta Money.", nil, MAGENTA, nil, 80)
    for _, product in ipairs(config.Monetization.Products or {}) do
        if product.GrantType == "Donation" then
            local ready = (tonumber(product.ProductId) or 0) > 0
            local desc = string.format("%s · Bonus: TM %s", product.Description or "Apoyo", tostring(product.BonusTintaMoney or 0))
            row(product.DisplayName, desc, ready and ("R$ " .. tostring(product.PriceRobux)) or "CONFIGURANDO", MAGENTA, function()
                if not ready then showToast("Producto Robux todavía en configuración.") return end
                MarketplaceService:PromptProductPurchase(player, product.ProductId)
            end)
        end
    end
    section("TOP DONACIONES", ORANGE)
    leaderboardRows("Donations", " ROBUX")
end

local function openPersonalize()
    openPanel("PERSONALIZAR OPERADOR")
    local skins = {
        {Id="Default", Name="OPERADOR BASE", Color=CYAN},
        {Id="NeonRebelSkin", Name="NEÓN REBELDE", Color=MAGENTA},
        {Id="CyanOperatorSkin", Name="OPERADOR CIAN", Color=CYAN},
        {Id="MagentaOperatorSkin", Name="OPERADOR MAGENTA", Color=MAGENTA},
    }
    for _, skin in ipairs(skins) do
        local unlocked = profile.Inventory and profile.Inventory[skin.Id]
        local selected = profile.SelectedSkin == skin.Id
        row(skin.Name, unlocked and "Disponible en tu inventario." or "Se desbloquea desde la tienda.", selected and "EQUIPADO" or (unlocked and "EQUIPAR" or "BLOQUEADO"), skin.Color, function()
            if not unlocked then showToast("Comprá este aspecto en la tienda.") return end
            local _, message, newProfile = SelectSkin:InvokeServer(skin.Id)
            if newProfile then profile = newProfile refreshTop() openPersonalize() end
            showToast(message)
        end)
    end
end

local function openRewards()
    openPanel("RECOMPENSAS")
    row("GIRO DE RECOMPENSA", "Usa un ticket o Tinta Money para conseguir cosméticos y premios.", "GIRAR", ORANGE, function()
        local _, message, result, newProfile = Spin:InvokeServer()
        if newProfile then profile = newProfile refreshTop() end
        showToast(result and (message .. " · " .. tostring(result.RewardId)) or message)
    end)
    row("VICTORIA COMPETITIVA", "Ganar aumenta rating, puntos de temporada, XP y Tinta Money.", nil, CYAN)
    row("HEADSHOTS", "Los impactos a la cabeza causan daño adicional según el arma.", nil, MAGENTA)
end

local function joinQueue()
    if player:GetAttribute("AFKMode") == true then
        local _, message = ToggleAFK:InvokeServer()
        showToast(message)
    else
        showToast("Ya estás en la cola. La próxima partida te incluirá automáticamente.")
    end
end

playButton.Activated:Connect(joinQueue)
bigPlay.Activated:Connect(joinQueue)
arsenalButton.Activated:Connect(openArsenal)
shopButton.Activated:Connect(openShop)
rankingButton.Activated:Connect(openRanking)
donationButton.Activated:Connect(openDonations)
personalizeButton.Activated:Connect(openPersonalize)
rewardsButton.Activated:Connect(openRewards)
closePanel.Activated:Connect(function() panel.Visible = false currentPanel = nil end)

local function updateState(data)
    currentState = data
    local phase = tostring(data.Phase or "Lobby")
    local combat = phase == "Playing" or phase == "Loading"
    backdrop.Visible = not combat
    left.Visible = not combat
    quick.Visible = not combat
    prize.Visible = not combat and phase ~= "Voting"
    panel.Visible = panel.Visible and not combat
    votePanel.Visible = phase == "Voting"

    local modeNames = {
        TeamSplash = "10 VS 10 · CIAN VS MAGENTA",
        FreeSplash = "TODOS CONTRA TODOS",
        Survival = "ENTRENAMIENTO DE TINTA",
    }
    modeLabel.Text = modeNames[data.Mode] or "COMPETITIVE ARENA · 20 JUGADORES"
    statusLabel.Text = tostring(data.Announcement or "EN COLA COMPETITIVA")

    if phase == "Voting" then
        for i, b in ipairs(voteButtons) do
            local mapId = data.OfferedGames and data.OfferedGames[i]
            b.Text = mapId and ((mapNames[mapId] or mapId) .. "\n" .. tostring((data.Votes and data.Votes[mapId]) or 0) .. " VOTOS") or "-"
        end
    end
end

local function refreshSnapshot()
    local success, snapshot = pcall(function() return GetSnapshot:InvokeServer() end)
    if success and type(snapshot) == "table" then
        profile = snapshot.Profile
        config = snapshot.Config
        currentState = snapshot.Game
        refreshTop()
        updateState(currentState or {})
        if currentPanel == "TIENDA / SHOP" then openShop() end
        if currentPanel == "DONACIONES / APOYO" then openDonations() end
    end
end

ProfileState.OnClientEvent:Connect(function(newProfile)
    profile = newProfile
    refreshTop()
end)
GameState.OnClientEvent:Connect(updateState)
Victory.OnClientEvent:Connect(function(message) showToast(message or "¡Victoria!") end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _, purchased)
    if userId ~= player.UserId or not purchased then return end
    showToast("Compra recibida. Acreditando...")
    task.delay(2, refreshSnapshot)
end)

refreshSnapshot()
if not config then showToast("Conectando con el servidor...") end

print("[TintaFinal] Competitive Lobby UI cargada.")
