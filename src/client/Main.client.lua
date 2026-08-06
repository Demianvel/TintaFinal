local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetState = remotes:WaitForChild("GetState")
local Purchase = remotes:WaitForChild("Purchase")
local SelectDifficulty = remotes:WaitForChild("SelectDifficulty")
local StateUpdated = remotes:WaitForChild("StateUpdated")
local RoundUpdated = remotes:WaitForChild("RoundUpdated")
local Victory = remotes:WaitForChild("Victory")

local state
local shopButtons = {}
local difficultyButtons = {}

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = instance
end

local function stroke(instance, transparency)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 1
    uiStroke.Transparency = transparency or 0.65
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Parent = instance
end

local function frame(parent, name, size, position)
    local object = Instance.new("Frame")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
    object.BackgroundTransparency = 0.08
    object.BorderSizePixel = 0
    object.Parent = parent
    round(object, 12)
    stroke(object)
    return object
end

local function label(parent, name, text, size, position, textSize)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextSize = textSize or 18
    object.TextColor3 = Color3.fromRGB(245, 247, 255)
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.Parent = parent
    return object
end

local function button(parent, name, text, size, position)
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = Color3.fromRGB(54, 114, 255)
    object.AutoButtonColor = true
    object.BorderSizePixel = 0
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextSize = 17
    object.TextColor3 = Color3.fromRGB(255, 255, 255)
    object.Parent = parent
    round(object, 10)
    return object
end

local topBar = frame(gui, "TopBar", UDim2.new(1, -24, 0, 66), UDim2.new(0, 12, 0, 12))
local title = label(topBar, "Title", Config.GameName, UDim2.new(0, 170, 1, 0), UDim2.new(0, 18, 0, 0), 22)
local coinsLabel = label(topBar, "Coins", "Monedas: 0", UDim2.new(0, 150, 1, 0), UDim2.new(0, 190, 0, 0), 16)
local gemsLabel = label(topBar, "Gems", "Gemas: 0", UDim2.new(0, 120, 1, 0), UDim2.new(0, 340, 0, 0), 16)
local levelLabel = label(topBar, "Level", "Nivel: 1", UDim2.new(0, 115, 1, 0), UDim2.new(0, 460, 0, 0), 16)
local winsLabel = label(topBar, "Wins", "Victorias: 0", UDim2.new(0, 130, 1, 0), UDim2.new(0, 575, 0, 0), 16)
local passLabel = label(topBar, "BattlePass", "Pase: 1", UDim2.new(0, 105, 1, 0), UDim2.new(1, -120, 0, 0), 16)

local status = frame(gui, "RoundStatus", UDim2.new(0, 300, 0, 52), UDim2.new(0.5, -150, 0, 88))
local statusLabel = label(status, "Text", "Esperando jugadores", UDim2.new(1, -24, 1, 0), UDim2.new(0, 12, 0, 0), 17)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

local menu = frame(gui, "Menu", UDim2.new(0, 170, 0, 116), UDim2.new(1, -182, 0.5, -58))
local shopOpen = button(menu, "Shop", "TIENDA", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 10))
local difficultyOpen = button(menu, "Difficulty", "DIFICULTAD", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 64))

local shopPanel = frame(gui, "ShopPanel", UDim2.new(0, 410, 0, 360), UDim2.new(0.5, -205, 0.5, -180))
shopPanel.Visible = false
local shopTitle = label(shopPanel, "Title", "TIENDA", UDim2.new(1, -70, 0, 48), UDim2.new(0, 18, 0, 4), 23)
local shopClose = button(shopPanel, "Close", "X", UDim2.new(0, 44, 0, 38), UDim2.new(1, -54, 0, 9))
shopClose.BackgroundColor3 = Color3.fromRGB(190, 55, 70)

local shopList = Instance.new("Frame")
shopList.Size = UDim2.new(1, -28, 1, -70)
shopList.Position = UDim2.new(0, 14, 0, 60)
shopList.BackgroundTransparency = 1
shopList.Parent = shopPanel
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 10)
shopLayout.Parent = shopList

for _, itemId in ipairs(Config.ShopOrder) do
    local item = Config.Shop[itemId]
    local row = frame(shopList, itemId, UDim2.new(1, 0, 0, 82), UDim2.new())
    row.BackgroundColor3 = Color3.fromRGB(34, 39, 54)
    local itemName = label(row, "Name", item.DisplayName, UDim2.new(0.62, -12, 0, 32), UDim2.new(0, 12, 0, 7), 17)
    local description = label(row, "Description", item.Description, UDim2.new(0.62, -12, 0, 35), UDim2.new(0, 12, 0, 38), 12)
    description.Font = Enum.Font.Gotham
    description.TextWrapped = true
    description.TextColor3 = Color3.fromRGB(195, 201, 220)
    local buy = button(row, "Buy", "COMPRAR", UDim2.new(0.36, -12, 0, 54), UDim2.new(0.64, 0, 0, 14))
    shopButtons[itemId] = buy

    buy.Activated:Connect(function()
        local ok, success, message, newState = pcall(function()
            return Purchase:InvokeServer(itemId)
        end)
        if ok and newState then
            state = newState
        end
        local text = ok and message or "No se pudo conectar."
        buy.Text = text
        task.delay(1.5, function()
            if buy.Parent then
                buy.Text = "COMPRAR"
            end
        end)
    end)
end

local difficultyPanel = frame(gui, "DifficultyPanel", UDim2.new(0, 390, 0, 320), UDim2.new(0.5, -195, 0.5, -160))
difficultyPanel.Visible = false
local difficultyTitle = label(difficultyPanel, "Title", "ELEGIR DIFICULTAD", UDim2.new(1, -70, 0, 48), UDim2.new(0, 18, 0, 4), 22)
local difficultyClose = button(difficultyPanel, "Close", "X", UDim2.new(0, 44, 0, 38), UDim2.new(1, -54, 0, 9))
difficultyClose.BackgroundColor3 = Color3.fromRGB(190, 55, 70)

local difficultyList = Instance.new("Frame")
difficultyList.Size = UDim2.new(1, -28, 1, -72)
difficultyList.Position = UDim2.new(0, 14, 0, 62)
difficultyList.BackgroundTransparency = 1
difficultyList.Parent = difficultyPanel
local difficultyLayout = Instance.new("UIListLayout")
difficultyLayout.Padding = UDim.new(0, 12)
difficultyLayout.Parent = difficultyList

for _, difficultyName in ipairs(Config.DifficultyOrder) do
    local difficulty = Config.Difficulties[difficultyName]
    local choose = button(
        difficultyList,
        difficultyName,
        difficulty.DisplayName,
        UDim2.new(1, 0, 0, 64),
        UDim2.new()
    )
    difficultyButtons[difficultyName] = choose

    choose.Activated:Connect(function()
        local ok, success, message, newState = pcall(function()
            return SelectDifficulty:InvokeServer(difficultyName)
        end)
        if ok and newState then
            state = newState
        end
        choose.Text = ok and message or "Error de conexión"
        task.delay(1.5, function()
            if choose.Parent then
                choose.Text = difficulty.DisplayName
            end
        end)
    end)
end

local victoryPanel = frame(gui, "Victory", UDim2.new(0, 440, 0, 260), UDim2.new(0.5, -220, 0.5, -130))
victoryPanel.Visible = false
victoryPanel.BackgroundColor3 = Color3.fromRGB(35, 70, 45)
local victoryTitle = label(victoryPanel, "Title", "¡GANASTE!", UDim2.new(1, -30, 0, 70), UDim2.new(0, 15, 0, 15), 34)
victoryTitle.TextXAlignment = Enum.TextXAlignment.Center
local victoryDetails = label(victoryPanel, "Details", "", UDim2.new(1, -40, 0, 130), UDim2.new(0, 20, 0, 88), 19)
victoryDetails.TextXAlignment = Enum.TextXAlignment.Center
victoryDetails.TextYAlignment = Enum.TextYAlignment.Top
victoryDetails.TextWrapped = true

local toast = label(gui, "Toast", "", UDim2.new(0, 330, 0, 42), UDim2.new(0.5, -165, 1, -58), 15)
toast.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
toast.BackgroundTransparency = 0.1
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.Visible = false
round(toast, 10)

local function showToast(text)
    toast.Text = text
    toast.Visible = true
    toast.TextTransparency = 0
    task.delay(2, function()
        if toast.Visible then
            local tween = TweenService:Create(toast, TweenInfo.new(0.35), { TextTransparency = 1 })
            tween:Play()
            tween.Completed:Wait()
            toast.Visible = false
        end
    end)
end

local function render(newState)
    if not newState then
        return
    end
    state = newState

    coinsLabel.Text = "Monedas: " .. tostring(state.Coins or 0)
    gemsLabel.Text = "Gemas: " .. tostring(state.Gems or 0)
    levelLabel.Text = "Nivel: " .. tostring(state.Level or 1)
    winsLabel.Text = "Victorias: " .. tostring(state.Wins or 0)
    passLabel.Text = "Pase: " .. tostring(state.BattlePassTier or 1)

    for itemId, buy in pairs(shopButtons) do
        local item = Config.Shop[itemId]
        local level = state.Upgrades and state.Upgrades[itemId] or 0
        local priceText = item.Currency == "Coins" and " monedas" or " gemas"
        if level >= item.MaxPurchases then
            buy.Text = "MÁXIMO"
            buy.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
        else
            buy.Text = tostring(item.Price) .. priceText .. " · Nv. " .. level
            buy.BackgroundColor3 = Color3.fromRGB(54, 114, 255)
        end
    end

    for difficultyName, choose in pairs(difficultyButtons) do
        local difficulty = Config.Difficulties[difficultyName]
        if (state.Wins or 0) < difficulty.RequiredWins then
            choose.Text = difficulty.DisplayName .. " · " .. difficulty.RequiredWins .. " victorias"
            choose.BackgroundColor3 = Color3.fromRGB(85, 88, 100)
        elseif state.SelectedDifficulty == difficultyName then
            choose.Text = difficulty.DisplayName .. " · SELECCIONADA"
            choose.BackgroundColor3 = Color3.fromRGB(45, 175, 105)
        else
            choose.Text = difficulty.DisplayName
            choose.BackgroundColor3 = Color3.fromRGB(54, 114, 255)
        end
    end
end

shopOpen.Activated:Connect(function()
    shopPanel.Visible = not shopPanel.Visible
    difficultyPanel.Visible = false
end)

shopClose.Activated:Connect(function()
    shopPanel.Visible = false
end)

difficultyOpen.Activated:Connect(function()
    difficultyPanel.Visible = not difficultyPanel.Visible
    shopPanel.Visible = false
end)

difficultyClose.Activated:Connect(function()
    difficultyPanel.Visible = false
end)

StateUpdated.OnClientEvent:Connect(render)

RoundUpdated.OnClientEvent:Connect(function(roundState)
    local phase = roundState.phase or ""
    local timeLeft = roundState.timeLeft or 0
    statusLabel.Text = phase .. " · " .. tostring(timeLeft) .. "s"
end)

Victory.OnClientEvent:Connect(function(reward)
    victoryDetails.Text = string.format(
        "%s\n+%d monedas\n+%d XP · +%d XP de pase\nVictorias totales: %d",
        reward.Difficulty,
        reward.Coins,
        reward.XP,
        reward.BattlePassXP,
        reward.Wins
    )
    victoryPanel.Visible = true
    victoryPanel.Size = UDim2.new(0, 40, 0, 40)
    TweenService:Create(victoryPanel, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 440, 0, 260),
    }):Play()
    showToast("La recompensa fue acreditada en el servidor.")
    task.delay(5.5, function()
        victoryPanel.Visible = false
    end)
end)

task.spawn(function()
    for _ = 1, 10 do
        local ok, initialState = pcall(function()
            return GetState:InvokeServer()
        end)
        if ok and initialState then
            render(initialState)
            return
        end
        task.wait(1)
    end
    showToast("No se pudo cargar el perfil.")
end)
