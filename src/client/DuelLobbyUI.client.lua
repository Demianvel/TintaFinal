local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = remotes:WaitForChild("GameState")
local duelQueueState = remotes:WaitForChild("DuelQueueState")
local getSnapshot = remotes:WaitForChild("GetSnapshot")

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalDuelLobbyUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 71
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Ya no mostramos el cartel grande "ELEGÍ UNA PARCELA". Las parcelas 3D se explican solas.
-- Solo aparece una barra compacta cuando el jugador ya entró a una cola.
local queueToast = Instance.new("Frame")
queueToast.Name = "QueueToast"
queueToast.AnchorPoint = Vector2.new(0.5, 0)
queueToast.Position = UDim2.new(0.5, 0, 0, 76)
queueToast.Size = UDim2.fromOffset(390, 42)
queueToast.BackgroundColor3 = Color3.fromRGB(7, 9, 16)
queueToast.BackgroundTransparency = 0.08
queueToast.BorderSizePixel = 0
queueToast.Visible = false
queueToast.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = queueToast

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 226, 239)
stroke.Transparency = 0.22
stroke.Thickness = 1.4
stroke.Parent = queueToast

local queueText = Instance.new("TextLabel")
queueText.Size = UDim2.new(1, -16, 1, 0)
queueText.Position = UDim2.new(0, 8, 0, 0)
queueText.BackgroundTransparency = 1
queueText.Text = ""
queueText.TextColor3 = Color3.new(1, 1, 1)
queueText.Font = Enum.Font.GothamBold
queueText.TextSize = 14
queueText.TextXAlignment = Enum.TextXAlignment.Center
queueText.Parent = queueToast

local currentPhase = "Waiting"
local toastToken = 0

local function inCombat()
    return player:GetAttribute("InShooterMatch") == true or player:GetAttribute("ShooterActive") == true
end

local function hideLegacyLobbyUI()
    local existing = playerGui:FindFirstChild("TintaFinalCompetitiveUI")
    if not existing then return end
    local root = existing:FindFirstChild("LobbyRoot", true)
    if not root then return end
    root.BackgroundTransparency = 1
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("GuiObject") then child.Visible = false end
    end
end

local function syncWorldDuelSigns()
    local enabled = not inCombat() and (currentPhase == "Waiting" or currentPhase == "Queueing")
    local world = workspace:FindFirstChild("TintaFinalWorld")
    local lobby = world and world:FindFirstChild("Lobby")
    if not lobby then return end

    for _, object in ipairs(lobby:GetDescendants()) do
        if object:IsA("BillboardGui") and object.Name == "DuelStatus" then
            object.Enabled = enabled
            pcall(function() object.MaxDistance = 150 end)
        end
    end
end

local function hideQueueToast()
    toastToken += 1
    queueToast.Visible = false
end

local function showTemporary(message, seconds)
    toastToken += 1
    local token = toastToken
    queueText.Text = tostring(message or "")
    queueToast.Visible = not inCombat()
    task.delay(seconds or 2.2, function()
        if token == toastToken then queueToast.Visible = false end
    end)
end

local function refreshState(data)
    if type(data) == "table" then currentPhase = tostring(data.Phase or currentPhase) end
    if inCombat() or currentPhase == "Combat" or currentPhase == "Loading" then
        hideQueueToast()
    end
    hideLegacyLobbyUI()
    syncWorldDuelSigns()
end

duelQueueState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    if inCombat() then
        hideQueueToast()
        return
    end

    if data.Joined then
        toastToken += 1
        local mode = math.max(1, math.floor(tonumber(data.TeamSize) or 1))
        local remaining = math.max(0, math.floor(tonumber(data.Remaining) or 0))
        local count = math.max(1, math.floor(tonumber(data.Count) or 1))
        local capacity = math.max(2, math.floor(tonumber(data.Capacity) or mode * 2))
        queueText.Text = string.format("%dV%d  ·  %d/%d JUGADORES  ·  %ds", mode, mode, count, capacity, remaining)
        queueToast.Visible = true
    elseif data.Message then
        showTemporary(data.Message, 2.5)
    else
        hideQueueToast()
    end
end)

gameState.OnClientEvent:Connect(refreshState)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(function() refreshState() end)
player:GetAttributeChangedSignal("ShooterActive"):Connect(function() refreshState() end)

workspace.DescendantAdded:Connect(function(object)
    if object:IsA("BillboardGui") and object.Name == "DuelStatus" then
        task.defer(syncWorldDuelSigns)
    end
end)

local ok, snapshot = pcall(function() return getSnapshot:InvokeServer() end)
if ok and type(snapshot) == "table" and type(snapshot.Game) == "table" then
    currentPhase = tostring(snapshot.Game.Phase or currentPhase)
end

hideLegacyLobbyUI()
syncWorldDuelSigns()

print("[TintaFinal] Lobby de duelos limpio: sin cartel gigante y sin parcelas visibles dentro del PvP.")
