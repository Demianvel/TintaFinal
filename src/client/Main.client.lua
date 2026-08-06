local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Games = require(Shared:WaitForChild("MinigameDefinitions"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetSnapshot = remotes:WaitForChild("GetSnapshot")
local CastVote = remotes:WaitForChild("CastVote")
local ShopPurchase = remotes:WaitForChild("ShopPurchase")
local Spin = remotes:WaitForChild("Spin")
local BuyPremiumWithWon = remotes:WaitForChild("BuyPremiumWithWon")
local QueueGuard = remotes:WaitForChild("QueueGuard")
local ToggleAFK = remotes:WaitForChild("ToggleAFK")
local ClaimBattlePass = remotes:WaitForChild("ClaimBattlePass")
local SelectDifficulty = remotes:WaitForChild("SelectDifficulty")

local GameState = remotes:WaitForChild("GameState")
local ProfileState = remotes:WaitForChild("ProfileState")
local Eliminated = remotes:WaitForChild("Eliminated")
local Victory = remotes:WaitForChild("Victory")
local StageReward = remotes:WaitForChild("StageReward")
local AFKReward = remotes:WaitForChild("AFKReward")

local profile
local gameState
local config
local currentPanel
local voteButtons = {}
local shopButtons = {}
local difficultyButtons = {}
local passClaimButtons = {}

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local uiScale = Instance.new("UIScale")
uiScale.Parent = gui

local function updateScale()
    local camera = workspace.CurrentCamera
    local width = camera and camera.ViewportSize.X or 1280
    uiScale.Scale = math.clamp(width / 1280, 0.68, 1)
end
updateScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = object
end

local function outline(object, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.55
    stroke.Color = Color3.fromRGB(230, 235, 255)
    stroke.Parent = object
end

local function makeFrame(parent, name, size, position, color)
    local object = Instance.new("Frame")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = color or Color3.fromRGB(22, 24, 34)
    object.BackgroundTransparency = 0.06
    object.BorderSizePixel = 0
    object.Parent = parent
    round(object, 12)
    outline(object, 0.7)
    return object
end

local function makeLabel(parent, name, text, size, position, textSize, alignment)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextSize = textSize or 16
    object.TextColor3 = Color3.fromRGB(245, 247, 255)
    object.TextXAlignment = alignment or Enum.TextXAlignment.Left
    object.TextWrapped = true
    object.Parent = parent
    return object
end

local function makeButton(parent, name, text, size, position, color)
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = color or Color3.fromRGB(54, 114, 255)
    object.BorderSizePixel = 0
    object.AutoButtonColor = true
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextSize = 15
    object.TextColor3 = Color3.fromRGB(255, 255, 255)
    object.TextWrapped = true
    object.Parent = parent
    round(object, 9)
    return object
end

local function makeList(parent, padding)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding or 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

local topBar = makeFrame(gui, "TopBar", UDim2.new(1, -24, 0, 66), UDim2.new(0, 12, 0, 12))
local gameTitle = makeLabel(topBar, "GameTitle", "TINTA FINAL", UDim2.new(0, 220, 1, 0), UDim2.new(0, 18, 0, 0), 21)
local wonLabel = makeLabel(topBar, "Won", "₩ 0", UDim2.new(0, 145, 1, 0), UDim2.new(0, 235, 0, 0), 16)
local levelLabel = makeLabel(topBar, "Level", "Nivel 1", UDim2.new(0, 110, 1, 0), UDim2.new(0, 380, 0, 0), 16)
local winsLabel = makeLabel(topBar, "Wins", "Victorias 0", UDim2.new(0, 140, 1, 0), UDim2.new(0, 490, 0, 0), 16)
local passLabel = makeLabel(topBar, "Pass", "Pase 1", UDim2.new(0, 110, 1, 0), UDim2.new(1, -125, 0, 0), 16)

local statusBar = makeFrame(gui, "Status", UDim2.new(0, 430, 0, 62), UDim2.new(0.5, -215, 0, 90), Color3.fromRGB(34, 37, 50))
local statusTitle = makeLabel(statusBar, "StatusTitle", "Esperando jugadores", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 4), 17, Enum.TextXAlignment.Center)
local statusInfo = makeLabel(statusBar, "StatusInfo", "", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 34), 13, Enum.TextXAlignment.Center)
statusInfo.TextColor3 = Color3.fromRGB(190, 200, 225)

local sideMenu = makeFrame(gui, "SideMenu", UDim2.new(0, 170, 0, 360), UDim2.new(0, 14, 0.5, -180), Color3.fromRGB(26, 29, 40))
local menuList = Instance.new("Frame")
menuList.Size = UDim2.new(1, -16, 1, -16)
menuList.Position = UDim2.new(0, 8, 0, 8)
menuList.BackgroundTransparency = 1
menuList.Parent = sideMenu
makeList(menuList, 8)

local shopOpen = makeButton(menuList, "ShopOpen", "TIENDA", UDim2.new(1, 0, 0, 45), UDim2.new())
local spinOpen = makeButton(menuList, "SpinOpen", "GIROS", UDim2.new(1, 0, 0, 45), UDim2.new(), Color3.fromRGB(125, 75, 205))
local passOpen = makeButton(menuList, "PassOpen", "PASE", UDim2.new(1, 0, 0, 45), UDim2.new(), Color3.fromRGB(215, 135, 55))
local difficultyOpen = makeButton(menuList, "DifficultyOpen", "DIFICULTAD", UDim2.new(1, 0, 0, 45), UDim2.new(), Color3.fromRGB(55, 155, 125))
local guardButton = makeButton(menuList, "Guard", "SER GUARDIA", UDim2.new(1, 0, 0, 45), UDim2.new(), Color3.fromRGB(180, 55, 80))
local afkButton = makeButton(menuList, "AFK", "SALA AFK", UDim2.new(1, 0, 0, 45), UDim2.new(), Color3.fromRGB(55, 130, 105))

local panels = makeFrame(gui, "Panels", UDim2.new(0, 520, 0, 440), UDim2.new(0.5, -260, 0.5, -205), Color3.fromRGB(23, 25, 36))
panels.Visible = false
local panelTitle = makeLabel(panels, "PanelTitle", "PANEL", UDim2.new(1, -70, 0, 52), UDim2.new(0, 18, 0, 2), 23)
local panelClose = makeButton(panels, "Close", "X", UDim2.new(0, 44, 0, 38), UDim2.new(1, -54, 0, 10), Color3.fromRGB(180, 55, 75))

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -28, 1, -74)
content.Position = UDim2.new(0, 14, 0, 60)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panels

local votePanel = makeFrame(gui, "VotePanel", UDim2.new(0, 620, 0, 250), UDim2.new(0.5, -310, 1, -270), Color3.fromRGB(30, 33, 46))
votePanel.Visible = false
local voteTitle = makeLabel(votePanel, "Title", "VOTÁ LA PRÓXIMA PRUEBA", UDim2.new(1, -20, 0, 44), UDim2.new(0, 10, 0, 5), 20, Enum.TextXAlignment.Center)
local voteList = Instance.new("Frame")
voteList.Size = UDim2.new(1, -24, 1, -62)
voteList.Position = UDim2.new(0, 12, 0, 52)
voteList.BackgroundTransparency = 1
voteList.Parent = votePanel
local voteLayout = Instance.new("UIListLayout")
voteLayout.FillDirection = Enum.FillDirection.Horizontal
voteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
voteLayout.Padding = UDim.new(0, 10)
voteLayout.Parent = voteList

for index = 1, 3 do
    local vote = makeButton(voteList, "Vote" .. index, "Prueba", UDim2.new(0, 188, 1, 0), UDim2.new(), Color3.fromRGB(74, 90, 160))
    voteButtons[index] = vote
    vote.Activated:Connect(function()
        local offered = gameState and gameState.OfferedGames or {}
        local gameId = offered[index]
        if not gameId then
            return
        end
        local ok, success, message = pcall(function()
            return CastVote:InvokeServer(gameId)
        end)
        if not ok or not success then
            vote.Text = ok and message or "Error de conexión"
        end
    end)
end

local toast = makeLabel(gui, "Toast", "", UDim2.new(0, 420, 0, 48), UDim2.new(0.5, -210, 1, -64), 15, Enum.TextXAlignment.Center)
toast.BackgroundColor3 = Color3.fromRGB(20, 22, 31)
toast.BackgroundTransparency = 0.05
toast.Visible = false
round(toast, 10)
outline(toast, 0.75)

local overlay = makeFrame(gui, "Overlay", UDim2.new(0, 520, 0, 280), UDim2.new(0.5, -260, 0.5, -140), Color3.fromRGB(34, 38, 52))
overlay.Visible = false
local overlayTitle = makeLabel(overlay, "Title", "", UDim2.new(1, -30, 0, 80), UDim2.new(0, 15, 0, 20), 34, Enum.TextXAlignment.Center)
local overlayBody = makeLabel(overlay, "Body", "", UDim2.new(1, -50, 0, 140), UDim2.new(0, 25, 0, 105), 18, Enum.TextXAlignment.Center)
overlayBody.TextYAlignment = Enum.TextYAlignment.Top

local function showToast(text)
    toast.Text = tostring(text)
    toast.TextTransparency = 0
    toast.Visible = true
    task.delay(2.4, function()
        if toast.Visible then
            local tween = TweenService:Create(toast, TweenInfo.new(0.3), { TextTransparency = 1 })
            tween:Play()
            tween.Completed:Wait()
            toast.Visible = false
        end
    end)
end

local function showOverlay(titleText, bodyText, color)
    overlayTitle.Text = titleText
    overlayBody.Text = bodyText
    overlay.BackgroundColor3 = color or Color3.fromRGB(34, 38, 52)
    overlay.Visible = true
    overlay.Size = UDim2.new(0, 80, 0, 50)
    TweenService:Create(overlay, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 520, 0, 280),
    }):Play()
    task.delay(5.5, function()
        overlay.Visible = false
    end)
end

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        child:Destroy()
    end
end

local function openPanel(name)
    currentPanel = name
    panels.Visible = true
    clearContent()
    panelTitle.Text = name
end

local function invokeAndRefresh(remote, ...)
    local ok, success, message, newProfile = pcall(function(...)
        return remote:InvokeServer(...)
    end, ...)
    if ok and newProfile then
        profile = newProfile
    end
    showToast(ok and message or "No se pudo conectar con el servidor.")
    return ok and success
end

local function buildShop()
    openPanel("TIENDA")
    local layout = makeList(content, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    for _, itemId in ipairs(config.ShopOrder) do
        local item = config.Shop[itemId]
        local row = makeFrame(content, itemId, UDim2.new(1, -8, 0, 92), UDim2.new(), Color3.fromRGB(34, 38, 52))
        local level = profile.Upgrades[itemId] or 0
        makeLabel(row, "Name", item.DisplayName, UDim2.new(0.6, -20, 0, 34), UDim2.new(0, 14, 0, 8), 17)
        local desc = makeLabel(row, "Desc", item.Description, UDim2.new(0.6, -20, 0, 42), UDim2.new(0, 14, 0, 42), 12)
        desc.Font = Enum.Font.Gotham
        desc.TextColor3 = Color3.fromRGB(190, 198, 220)

        local currencyText = item.Currency == "Won" and "₩" or "Gemas"
        local buy = makeButton(row, "Buy", currencyText .. " " .. tostring(item.Price) .. "\nNivel " .. tostring(level), UDim2.new(0.36, 0, 0, 62), UDim2.new(0.62, 0, 0, 15))
        shopButtons[itemId] = buy
        buy.Activated:Connect(function()
            local ok, success, message, newProfile = pcall(function()
                return ShopPurchase:InvokeServer(itemId)
            end)
            if ok and newProfile then
                profile = newProfile
                buildShop()
            end
            showToast(ok and message or "Error de conexión")
        end)
    end
end

local function buildSpin()
    openPanel("GIROS Y PROBABILIDADES")
    local layout = makeList(content, 9)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local summary = makeLabel(content, "Summary", "Tickets: " .. tostring(profile.SpinTickets) .. " · Giro con Won: ₩" .. tostring(config.Economy.SpinWonPrice), UDim2.new(1, -10, 0, 42), UDim2.new(), 16, Enum.TextXAlignment.Center)
    summary.LayoutOrder = 1

    for index, odds in ipairs(config.Spin.Odds) do
        local row = makeFrame(content, odds.Rarity, UDim2.new(1, -10, 0, 48), UDim2.new(), Color3.fromRGB(36, 40, 55))
        row.LayoutOrder = index + 1
        makeLabel(row, "Odds", odds.DisplayName .. " — " .. tostring(odds.Weight) .. "%", UDim2.new(1, -24, 1, 0), UDim2.new(0, 12, 0, 0), 16)
    end

    local spinButton = makeButton(content, "Spin", "GIRAR AHORA", UDim2.new(1, -10, 0, 58), UDim2.new(), Color3.fromRGB(130, 75, 205))
    spinButton.LayoutOrder = 20
    spinButton.Activated:Connect(function()
        spinButton.Text = "GIRANDO..."
        local ok, success, message, result, newProfile = pcall(function()
            return Spin:InvokeServer()
        end)
        if ok and newProfile then
            profile = newProfile
        end
        if ok and success and result then
            showOverlay(result.Rarity, result.RewardId, Color3.fromRGB(75, 55, 115))
            buildSpin()
        else
            showToast(ok and message or "Error de conexión")
            spinButton.Text = "GIRAR AHORA"
        end
    end)
end

local function buildPass()
    openPanel("PASE DE BATALLA")
    local layout = makeList(content, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local progress = makeLabel(content, "Progress", "Nivel " .. tostring(profile.BattlePassTier) .. "/" .. tostring(config.BattlePass.MaxTier) .. " · XP " .. tostring(profile.BattlePassXP), UDim2.new(1, -10, 0, 42), UDim2.new(), 18, Enum.TextXAlignment.Center)
    progress.LayoutOrder = 1

    local premiumText = profile.PremiumPass and "PASE PREMIUM ACTIVO" or "COMPRAR PREMIUM POR ₩" .. tostring(config.Economy.BattlePassWonPrice)
    local premium = makeButton(content, "Premium", premiumText, UDim2.new(1, -10, 0, 54), UDim2.new(), Color3.fromRGB(215, 135, 55))
    premium.LayoutOrder = 2
    premium.Activated:Connect(function()
        if profile.PremiumPass then
            showToast("Ya tenés el pase premium.")
            return
        end
        local ok, success, message, newProfile = pcall(function()
            return BuyPremiumWithWon:InvokeServer()
        end)
        if ok and newProfile then
            profile = newProfile
            buildPass()
        end
        showToast(ok and message or "Error de conexión")
    end)

    if config.BattlePass.PremiumGamePassId and config.BattlePass.PremiumGamePassId > 0 then
        local robux = makeButton(content, "Robux", "COMPRAR CON ROBUX", UDim2.new(1, -10, 0, 50), UDim2.new(), Color3.fromRGB(75, 155, 95))
        robux.LayoutOrder = 3
        robux.Activated:Connect(function()
            MarketplaceService:PromptGamePassPurchase(player, config.BattlePass.PremiumGamePassId)
        end)
    end

    local milestones = { 1, 5, 10, 20, 30, 40, 50 }
    for index, tier in ipairs(milestones) do
        local row = makeFrame(content, "Tier" .. tier, UDim2.new(1, -10, 0, 64), UDim2.new(), Color3.fromRGB(36, 40, 55))
        row.LayoutOrder = 5 + index
        makeLabel(row, "Tier", "Nivel " .. tier, UDim2.new(0.35, 0, 1, 0), UDim2.new(0, 14, 0, 0), 16)
        local free = makeButton(row, "Free", "RECLAMAR GRATIS", UDim2.new(0.28, 0, 0, 42), UDim2.new(0.36, 0, 0, 11), Color3.fromRGB(55, 145, 110))
        local premiumClaim = makeButton(row, "Premium", "PREMIUM", UDim2.new(0.28, 0, 0, 42), UDim2.new(0.67, 0, 0, 11), Color3.fromRGB(205, 125, 50))
        free.Activated:Connect(function()
            local ok, success, message, newProfile = pcall(function()
                return ClaimBattlePass:InvokeServer(tier, false)
            end)
            if ok and newProfile then
                profile = newProfile
            end
            showToast(ok and message or "Error de conexión")
        end)
        premiumClaim.Activated:Connect(function()
            local ok, success, message, newProfile = pcall(function()
                return ClaimBattlePass:InvokeServer(tier, true)
            end)
            if ok and newProfile then
                profile = newProfile
            end
            showToast(ok and message or "Error de conexión")
        end)
    end
end

local function buildDifficulty()
    openPanel("DIFICULTAD")
    local layout = makeList(content, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    for _, difficultyId in ipairs(config.DifficultyOrder) do
        local definition = config.Difficulties[difficultyId]
        local selected = profile.SelectedDifficulty == difficultyId
        local unlocked = profile.Wins >= definition.RequiredWins
        local text = definition.DisplayName
        if selected then
            text ..= " · SELECCIONADA"
        elseif not unlocked then
            text ..= " · " .. definition.RequiredWins .. " victorias"
        end
        local choose = makeButton(content, difficultyId, text, UDim2.new(1, -10, 0, 58), UDim2.new(), selected and Color3.fromRGB(45, 170, 105) or Color3.fromRGB(65, 100, 165))
        difficultyButtons[difficultyId] = choose
        choose.Activated:Connect(function()
            local ok, success, message, newProfile = pcall(function()
                return SelectDifficulty:InvokeServer(difficultyId)
            end)
            if ok and newProfile then
                profile = newProfile
                buildDifficulty()
            end
            showToast(ok and message or "Error de conexión")
        end)
    end
end

local function renderProfile(newProfile)
    if not newProfile then
        return
    end
    profile = newProfile
    wonLabel.Text = "₩ " .. tostring(profile.Won or 0)
    levelLabel.Text = "Nivel " .. tostring(profile.Level or 1)
    winsLabel.Text = "Victorias " .. tostring(profile.Wins or 0)
    passLabel.Text = "Pase " .. tostring(profile.BattlePassTier or 1)
    guardButton.Text = profile.GuardQueued and "GUARDIA EN COLA" or "SER GUARDIA"
end

local function renderGame(newState)
    if not newState then
        return
    end
    gameState = newState
    statusTitle.Text = newState.Announcement or newState.Phase or ""
    statusInfo.Text = string.format(
        "Etapa %d · %ds · %d vivos · %d guardias",
        newState.MatchStage or 0,
        newState.TimeLeft or 0,
        newState.AliveCount or 0,
        newState.GuardCount or 0
    )

    local voting = newState.Phase == "Voting"
    votePanel.Visible = voting
    if voting then
        for index, button in ipairs(voteButtons) do
            local gameId = newState.OfferedGames[index]
            if gameId and Games[gameId] then
                local definition = Games[gameId]
                button.Visible = true
                button.Text = definition.DisplayName .. "\n" .. definition.Description .. "\nVotos: " .. tostring(newState.Votes[gameId] or 0)
            else
                button.Visible = false
            end
        end
    end
end

shopOpen.Activated:Connect(buildShop)
spinOpen.Activated:Connect(buildSpin)
passOpen.Activated:Connect(buildPass)
difficultyOpen.Activated:Connect(buildDifficulty)
panelClose.Activated:Connect(function()
    panels.Visible = false
    currentPanel = nil
end)

guardButton.Activated:Connect(function()
    local ok, success, message, newProfile = pcall(function()
        return QueueGuard:InvokeServer()
    end)
    if ok and newProfile then
        renderProfile(newProfile)
    end
    showToast(ok and message or "Error de conexión")
end)

afkButton.Activated:Connect(function()
    local ok, success, message = pcall(function()
        return ToggleAFK:InvokeServer()
    end)
    if ok and success then
        afkButton.Text = player:GetAttribute("AFKMode") and "SALIR DE AFK" or "SALA AFK"
    end
    showToast(ok and message or "Error de conexión")
end)

player:GetAttributeChangedSignal("AFKMode"):Connect(function()
    afkButton.Text = player:GetAttribute("AFKMode") and "SALIR DE AFK" or "SALA AFK"
end)

GameState.OnClientEvent:Connect(renderGame)
ProfileState.OnClientEvent:Connect(renderProfile)
Eliminated.OnClientEvent:Connect(function(reason)
    showOverlay("ELIMINADO", reason, Color3.fromRGB(100, 35, 50))
end)
Victory.OnClientEvent:Connect(function(result)
    showOverlay(
        "¡VICTORIA!",
        "Ganaste ₩" .. tostring(result.Won) .. "\nSobrevivientes: " .. tostring(result.Winners) .. "\nEtapas: " .. tostring(result.Stages),
        Color3.fromRGB(35, 95, 65)
    )
end)
StageReward.OnClientEvent:Connect(function(amount, gameId)
    local name = Games[gameId] and Games[gameId].DisplayName or "Prueba"
    showToast(name .. " superada: +₩" .. tostring(amount))
end)
AFKReward.OnClientEvent:Connect(function(amount, total)
    showToast("AFK: +₩" .. tostring(amount) .. " · Total sesión ₩" .. tostring(total))
end)

task.spawn(function()
    for _ = 1, 12 do
        local ok, snapshot = pcall(function()
            return GetSnapshot:InvokeServer()
        end)
        if ok and snapshot and snapshot.Profile then
            config = snapshot.Config
            gameTitle.Text = string.upper(config.GameName or "Tinta Final")
            renderProfile(snapshot.Profile)
            renderGame(snapshot.Game)
            return
        end
        task.wait(1)
    end
    showToast("No se pudo cargar la interfaz.")
end)
