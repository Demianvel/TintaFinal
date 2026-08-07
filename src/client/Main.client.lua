local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Visual = require(ReplicatedStorage.Shared:WaitForChild("VisualConfig"))

local GetSnapshot = remotes:WaitForChild("GetSnapshot")
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
local MAGENTA = Color3.fromRGB(255, 22, 142)
local ORANGE = Color3.fromRGB(255, 132, 21)
local DARK = Color3.fromRGB(5, 7, 14)
local PANEL = Color3.fromRGB(10, 13, 24)
local WHITE = Color3.fromRGB(248, 250, 255)
local MUTED = Color3.fromRGB(170, 185, 215)

local profile = {}
local config = {}
local currentState = {}
local panelMode = nil

local function asset(id)
    id = tonumber(id) or 0
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalCompetitiveUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui
local function refreshScale()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.72, 1.08)
end
refreshScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = object
end

local function stroke(object, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CYAN
    s.Transparency = transparency or 0.25
    s.Thickness = thickness or 1.5
    s.Parent = object
end

local function makeLabel(parent, value, size, position, fontSize, color, align)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position or UDim2.new()
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = color or WHITE
    label.Font = Enum.Font.GothamBold
    label.TextSize = fontSize or 16
    label.TextWrapped = true
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makeButton(parent, value, size, color)
    local b = Instance.new("TextButton")
    b.Size = size
    b.BackgroundColor3 = color or MAGENTA
    b.BackgroundTransparency = 0.08
    b.BorderSizePixel = 0
    b.Text = value
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBlack
    b.TextScaled = true
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 12)
    stroke(b, WHITE, 0.72, 1)
    return b
end

local root = Instance.new("Frame")
root.Name = "LobbyRoot"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = DARK
root.BorderSizePixel = 0
root.Parent = gui

local art = Instance.new("ImageLabel")
art.Name = "LobbyArt"
art.Size = UDim2.fromScale(1, 1)
art.BackgroundTransparency = 1
art.Image = asset(Visual.Assets.Lobby)
art.ScaleType = Enum.ScaleType.Crop
art.Parent = root

local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.new(0, 0, 0)
vignette.BackgroundTransparency = art.Image == "" and 0.12 or 0.47
vignette.BorderSizePixel = 0
vignette.Parent = root

local top = Instance.new("Frame")
top.Size = UDim2.new(1, -36, 0, 74)
top.Position = UDim2.new(0, 18, 0, 14)
top.BackgroundColor3 = DARK
top.BackgroundTransparency = 0.10
top.BorderSizePixel = 0
top.Parent = root
corner(top, 16)
stroke(top, MAGENTA, 0.18, 2)

local playerLabel = makeLabel(top, player.DisplayName, UDim2.new(0.30, 0, 0, 32), UDim2.new(0, 18, 0, 9), 19, WHITE)
local playerMeta = makeLabel(top, "NIVEL 1 · 0 VICTORIAS", UDim2.new(0.30, 0, 0, 24), UDim2.new(0, 18, 0, 41), 11, CYAN)
local moneyLabel = makeLabel(top, "TM 0", UDim2.new(0.20, 0, 1, 0), UDim2.new(0.44, 0, 0, 0), 17, CYAN, Enum.TextXAlignment.Center)
local ratingLabel = makeLabel(top, "RATING 1000", UDim2.new(0.18, 0, 1, 0), UDim2.new(0.62, 0, 0, 0), 16, WHITE, Enum.TextXAlignment.Center)
local rankLabel = makeLabel(top, "SILVER", UDim2.new(0.17, 0, 1, 0), UDim2.new(0.80, 0, 0, 0), 16, MAGENTA, Enum.TextXAlignment.Center)

local menu = Instance.new("Frame")
menu.Size = UDim2.fromOffset(245, 405)
menu.Position = UDim2.new(0, 24, 0.5, -165)
menu.BackgroundTransparency = 1
menu.Parent = root
local menuLayout = Instance.new("UIListLayout")
menuLayout.Padding = UDim.new(0, 10)
menuLayout.Parent = menu

local playButton = makeButton(menu, "▶  JUGAR", UDim2.new(1, 0, 0, 70), MAGENTA)
local arsenalButton = makeButton(menu, "ARSENAL", UDim2.new(1, 0, 0, 58), CYAN)
local shopButton = makeButton(menu, "TIENDA", UDim2.new(1, 0, 0, 58), ORANGE)
local rankingButton = makeButton(menu, "RANKING", UDim2.new(1, 0, 0, 58), Color3.fromRGB(103, 65, 220))
local rewardsButton = makeButton(menu, "RECOMPENSAS", UDim2.new(1, 0, 0, 58), Color3.fromRGB(40, 155, 125))

local playCard = Instance.new("Frame")
playCard.Size = UDim2.fromOffset(355, 238)
playCard.Position = UDim2.new(1, -385, 0.5, -92)
playCard.BackgroundColor3 = PANEL
playCard.BackgroundTransparency = 0.08
playCard.BorderSizePixel = 0
playCard.Parent = root
corner(playCard, 18)
stroke(playCard, MAGENTA, 0.10, 2)

makeLabel(playCard, "LISTO PARA JUGAR", UDim2.new(1, -28, 0, 42), UDim2.new(0, 14, 0, 16), 24, WHITE, Enum.TextXAlignment.Center)
local modeLabel = makeLabel(playCard, "PVP · MAPA AUTOMÁTICO", UDim2.new(1, -28, 0, 28), UDim2.new(0, 14, 0, 63), 13, CYAN, Enum.TextXAlignment.Center)
local statusLabel = makeLabel(playCard, "CONECTANDO...", UDim2.new(1, -28, 0, 42), UDim2.new(0, 14, 0, 94), 12, MUTED, Enum.TextXAlignment.Center)
local playNow = makeButton(playCard, "JUGAR AHORA", UDim2.new(1, -42, 0, 72), MAGENTA)
playNow.Position = UDim2.new(0, 21, 0, 146)

local season = Instance.new("Frame")
season.Size = UDim2.new(0.58, 0, 0, 70)
season.Position = UDim2.new(0.5, -290, 1, -88)
season.BackgroundColor3 = DARK
season.BackgroundTransparency = 0.10
season.BorderSizePixel = 0
season.Parent = root
corner(season, 14)
stroke(season, ORANGE, 0.25, 1.5)
makeLabel(season, "TOP 3 TEMPORADA", UDim2.new(0.22, 0, 1, 0), UDim2.new(0, 12, 0, 0), 12, WHITE, Enum.TextXAlignment.Center)
makeLabel(season, "1.º 300M TM   ·   2.º 150M TM   ·   3.º 100M TM", UDim2.new(0.74, 0, 1, 0), UDim2.new(0.24, 0, 0, 0), 15, ORANGE, Enum.TextXAlignment.Center)

local modal = Instance.new("Frame")
modal.Size = UDim2.new(0.74, 0, 0.76, 0)
modal.Position = UDim2.new(0.13, 0, 0.13, 0)
modal.BackgroundColor3 = PANEL
modal.BackgroundTransparency = 0.02
modal.BorderSizePixel = 0
modal.Visible = false
modal.Parent = root
corner(modal, 18)
stroke(modal, MAGENTA, 0.08, 2)

local modalArt = Instance.new("ImageLabel")
modalArt.Size = UDim2.fromScale(1, 1)
modalArt.BackgroundTransparency = 1
modalArt.ImageTransparency = 0.82
modalArt.ScaleType = Enum.ScaleType.Crop
modalArt.Parent = modal
corner(modalArt, 18)

local modalShade = Instance.new("Frame")
modalShade.Size = UDim2.fromScale(1, 1)
modalShade.BackgroundColor3 = Color3.new(0, 0, 0)
modalShade.BackgroundTransparency = 0.22
modalShade.BorderSizePixel = 0
modalShade.Parent = modal
corner(modalShade, 18)

local modalTitle = makeLabel(modal, "TINTA FINAL", UDim2.new(1, -90, 0, 58), UDim2.new(0, 22, 0, 8), 25, WHITE)
local closeModal = makeButton(modal, "✕", UDim2.fromOffset(50, 46), Color3.fromRGB(75, 28, 55))
closeModal.Position = UDim2.new(1, -64, 0, 12)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -40, 1, -86)
list.Position = UDim2.new(0, 20, 0, 72)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = MAGENTA
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = modal
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 9)
listLayout.Parent = list

local toast = makeLabel(gui, "", UDim2.fromOffset(520, 48), UDim2.new(0.5, -260, 1, -62), 14, WHITE, Enum.TextXAlignment.Center)
toast.BackgroundColor3 = DARK
toast.BackgroundTransparency = 0.05
toast.Visible = false
corner(toast, 10)
stroke(toast, CYAN, 0.28, 1)
local toastToken = 0
local function showToast(message)
    toastToken += 1
    local token = toastToken
    toast.Text = tostring(message or "")
    toast.TextTransparency = 0
    toast.Visible = true
    task.delay(2.4, function()
        if token ~= toastToken then return end
        TweenService:Create(toast, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        task.wait(0.22)
        if token == toastToken then toast.Visible = false end
    end)
end

local function clearList()
    for _, child in ipairs(list:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function row(titleText, description, actionText, color, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -8, 0, 82)
    holder.BackgroundColor3 = Color3.fromRGB(15, 18, 31)
    holder.BackgroundTransparency = 0.08
    holder.BorderSizePixel = 0
    holder.Parent = list
    corner(holder, 12)
    stroke(holder, color or CYAN, 0.55, 1)
    makeLabel(holder, titleText, UDim2.new(0.62, -12, 0, 29), UDim2.new(0, 13, 0, 8), 16, WHITE)
    makeLabel(holder, description or "", UDim2.new(0.62, -12, 0, 34), UDim2.new(0, 13, 0, 39), 11, MUTED)
    if actionText then
        local action = makeButton(holder, actionText, UDim2.new(0.31, 0, 0, 52), color or CYAN)
        action.Position = UDim2.new(0.67, 0, 0, 15)
        if callback then action.Activated:Connect(callback) end
    end
end

local function openModal(titleText, artId)
    panelMode = titleText
    modal.Visible = true
    modalTitle.Text = titleText
    modalArt.Image = asset(artId or Visual.Assets.Shop)
    clearList()
end

local function rankName(rating)
    local name = "BRONZE"
    for _, entry in ipairs((config.Competitive and config.Competitive.Ranks) or {}) do
        if rating >= (entry.Min or 0) then name = entry.Name end
    end
    return name
end

local function refreshTop()
    local rating = tonumber(profile.CompetitiveRating) or 1000
    playerLabel.Text = player.DisplayName
    playerMeta.Text = string.format("NIVEL %d · %d VICTORIAS", tonumber(profile.Level) or 1, tonumber(profile.Wins) or 0)
    moneyLabel.Text = "TM " .. tostring(profile.TintaMoney or 0)
    ratingLabel.Text = "RATING " .. tostring(rating)
    rankLabel.Text = rankName(rating)
end

local function openArsenal()
    openModal("ARSENAL", Visual.Assets.Lobby)
    local inventory = profile.Inventory or {}
    local order = (config.Shooter and config.Shooter.WeaponOrder) or {}
    for _, weaponId in ipairs(order) do
        local definition = config.Weapons and config.Weapons[weaponId]
        if definition then
            local owned = inventory[weaponId] ~= nil
            local selected = profile.SelectedWeapon == weaponId
            row(definition.DisplayName or weaponId, string.format("Daño %s · Cargador %s", tostring(definition.Damage or "-"), tostring(definition.Magazine or "-")), selected and "EQUIPADA" or (owned and "EQUIPAR" or "TIENDA"), CYAN, function()
                if not owned then openModal("TIENDA", Visual.Assets.Shop) return end
                local ok, message, newProfile = SelectWeapon:InvokeServer(weaponId)
                if newProfile then profile = newProfile refreshTop() end
                showToast(message)
                if ok then openArsenal() end
            end)
        end
    end
end

local function openShop()
    openModal("TIENDA / RECOMPENSAS", Visual.Assets.Shop)
    for _, itemId in ipairs(config.ShopOrder or {}) do
        local item = config.Shop and config.Shop[itemId]
        if item then
            local inventoryId = item.WeaponId or item.ItemId or itemId
            local owned = (item.Type == "Weapon" or item.Type == "Cosmetic") and profile.Inventory and profile.Inventory[inventoryId]
            local price = item.Currency == "Gems" and ("GEM " .. tostring(item.Price)) or ("TM " .. tostring(item.Price))
            row(item.DisplayName or itemId, item.Description or "", owned and "COMPRADO" or price, item.Type == "Weapon" and MAGENTA or ORANGE, function()
                if owned then showToast("Ya tenés este objeto.") return end
                local _, message, newProfile = ShopPurchase:InvokeServer(itemId)
                if newProfile then profile = newProfile refreshTop() end
                showToast(message)
                openShop()
            end)
        end
    end
    for _, product in ipairs((config.Monetization and config.Monetization.Products) or {}) do
        if (tonumber(product.ProductId) or 0) > 0 then
            row(product.DisplayName or "PACK ROBUX", product.Description or "Compra premium", "R$ " .. tostring(product.PriceRobux or ""), MAGENTA, function()
                MarketplaceService:PromptProductPurchase(player, product.ProductId)
            end)
        end
    end
end

local function openRanking()
    openModal("RANKING COMPETITIVO", Visual.Assets.Round1)
    row("PREMIOS DE TEMPORADA", "1.º 300M TM · 2.º 150M TM · 3.º 100M TM", nil, ORANGE)
    local board, message = GetLeaderboards:InvokeServer("Season", 15)
    if type(board) ~= "table" then
        row("RANKING NO DISPONIBLE", tostring(message or "Intentá nuevamente."), nil, CYAN)
        return
    end
    for _, entry in ipairs(board) do
        row(string.format("#%d  %s", entry.Position or 0, entry.Name or "Jugador"), tostring(entry.Value or 0) .. " PTS", nil, entry.Position == 1 and ORANGE or CYAN)
    end
end

local function openRewards()
    openModal("RECOMPENSAS / RULETA", Visual.Assets.Shop)
    row("RULETA TINTA FINAL", "Premios, Tinta Money, utilidades y armas desbloqueables.", "GIRAR", ORANGE, function()
        local _, message, result, newProfile = Spin:InvokeServer()
        if newProfile then profile = newProfile refreshTop() end
        showToast(result and (tostring(message) .. " · " .. tostring(result.RewardId or "PREMIO")) or message)
    end)
    row("BATTLE PASS", "100 niveles de temporada con pista gratis y premium.", nil, MAGENTA)
end

local function queueNow()
    if player:GetAttribute("AFKMode") == true then
        local _, message = ToggleAFK:InvokeServer()
        showToast(message)
    else
        local connected = tonumber(currentState.ConnectedPlayers) or 1
        if connected < 2 then
            showToast("Entraste al calentamiento. La partida PvP empieza al llegar otro jugador.")
        else
            showToast("Estás en cola PvP. Preparando partida...")
        end
    end
end

playButton.Activated:Connect(queueNow)
playNow.Activated:Connect(queueNow)
arsenalButton.Activated:Connect(openArsenal)
shopButton.Activated:Connect(openShop)
rankingButton.Activated:Connect(openRanking)
rewardsButton.Activated:Connect(openRewards)
closeModal.Activated:Connect(function() modal.Visible = false panelMode = nil end)

local function updateState(data)
    if type(data) ~= "table" then return end
    currentState = data
    local phase = tostring(data.Phase or "Waiting")
    local combat = phase == "Combat" or phase == "Loading" or player:GetAttribute("InShooterMatch") == true
    root.Visible = not combat
    if combat then modal.Visible = false end

    local mapNames = {NeonDistrict = "DISTRITO NEÓN", InkDepot = "DEPÓSITO DE TINTA", RooftopRush = "AZOTEAS NEÓN"}
    local mapName = mapNames[data.CurrentMap] or "MAPA AUTOMÁTICO"
    local connected = tonumber(data.ConnectedPlayers) or 0
    if phase == "Warmup" then
        modeLabel.Text = "CALENTAMIENTO · " .. mapName
        statusLabel.Text = "PODÉS MOVERTE, APUNTAR, DISPARAR Y RECARGAR · ESPERANDO RIVAL"
    elseif phase == "Waiting" then
        modeLabel.Text = "PVP PURO · SIN BOTS"
        statusLabel.Text = string.format("ESPERANDO JUGADORES · %d/2", connected)
    elseif phase == "Intermission" then
        modeLabel.Text = "PVP · " .. mapName
        statusLabel.Text = tostring(data.Announcement or "PREPARANDO PARTIDA")
    else
        modeLabel.Text = "PVP · " .. mapName
        statusLabel.Text = tostring(data.Announcement or "LISTO")
    end
end

local function refreshSnapshot()
    local ok, snapshot = pcall(function() return GetSnapshot:InvokeServer() end)
    if not ok or type(snapshot) ~= "table" then
        showToast("Conectando con el servidor...")
        return
    end
    profile = snapshot.Profile or profile
    config = snapshot.Config or config
    currentState = snapshot.Game or currentState
    refreshTop()
    updateState(currentState)
end

ProfileState.OnClientEvent:Connect(function(newProfile)
    if type(newProfile) == "table" then profile = newProfile refreshTop() end
end)
GameState.OnClientEvent:Connect(updateState)
Victory.OnClientEvent:Connect(function(message) showToast(message or "¡Victoria!") end)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(function() updateState(currentState) end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _, purchased)
    if userId == player.UserId and purchased then task.delay(2, refreshSnapshot) end
end)

refreshSnapshot()
print("[TintaFinal] Lobby visual PvP limpio y jugable cargado.")