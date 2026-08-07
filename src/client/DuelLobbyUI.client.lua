local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = remotes:WaitForChild("GameState")
local duelQueueState = remotes:WaitForChild("DuelQueueState")

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalDuelLobbyUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 71
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 92)
banner.Size = UDim2.fromOffset(620, 72)
banner.BackgroundColor3 = Color3.fromRGB(7, 9, 16)
banner.BackgroundTransparency = 0.08
banner.BorderSizePixel = 0
banner.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = banner
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 226, 239)
stroke.Transparency = 0.18
stroke.Thickness = 1.5
stroke.Parent = banner

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "ELEGÍ UNA PARCELA: 1V1 · 2V2 · 6V6 · 10V10"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = banner

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 26)
status.Position = UDim2.new(0, 10, 0, 40)
status.BackgroundTransparency = 1
status.Text = "CAMINÁ HASTA LA PARCELA Y PISALA PARA ENTRAR"
status.TextColor3 = Color3.fromRGB(255, 145, 25)
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.Parent = banner

local function makeWorldVisible()
    local existing = player.PlayerGui:FindFirstChild("TintaFinalCompetitiveUI")
    if not existing then return end
    local root = existing:FindFirstChild("LobbyRoot", true)
    if not root then return end
    root.BackgroundTransparency = 1
    local art = root:FindFirstChild("LobbyArt", true)
    if art then art.Visible = false end
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("Frame") and child ~= root and child.Size == UDim2.fromScale(1, 1) then
            child.Visible = false
        end
    end
end

local function refreshVisibility(state)
    local phase = type(state) == "table" and tostring(state.Phase or "Waiting") or "Waiting"
    local lobby = phase == "Waiting" or phase == "Queueing"
    banner.Visible = lobby and player:GetAttribute("InShooterMatch") ~= true
    if banner.Visible then task.defer(makeWorldVisible) end
end

duelQueueState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    if data.Joined then
        local mode = tonumber(data.TeamSize) or 1
        local remaining = math.max(0, math.floor(tonumber(data.Remaining) or 0))
        local count = math.max(1, math.floor(tonumber(data.Count) or 1))
        local capacity = math.max(2, math.floor(tonumber(data.Capacity) or mode * 2))
        status.Text = string.format("%dV%d · %d/%d JUGADORES · VIAJE EN %d", mode, mode, count, capacity, remaining)
    elseif data.Message then
        status.Text = tostring(data.Message)
    end
end)

gameState.OnClientEvent:Connect(refreshVisibility)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(function()
    refreshVisibility({Phase = player:GetAttribute("InShooterMatch") and "Combat" or "Waiting"})
end)

task.spawn(function()
    task.wait(1)
    makeWorldVisible()
end)

print("[TintaFinal] Lobby físico de duelos visible y guía de parcelas activa.")
