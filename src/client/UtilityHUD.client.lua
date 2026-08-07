local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local UseUtility = remotes:WaitForChild("UseUtility")
local GetUtilityState = remotes:WaitForChild("GetUtilityState")
local UtilityState = remotes:WaitForChild("UtilityState")

local initial = GetUtilityState:InvokeServer() or { Counts = {}, Definitions = {} }
local counts = initial.Counts or {}
local definitions = initial.Definitions or {}

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalUtilityHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 35
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.Size = UDim2.new(0, 330, 0, 74)
holder.Position = UDim2.new(1, -350, 1, -92)
holder.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
holder.BackgroundTransparency = 0.12
holder.BorderSizePixel = 0
holder.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = holder
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 226, 239)
stroke.Transparency = 0.45
stroke.Parent = holder

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 7)
layout.Parent = holder

local order = {
    { Id = "UtilityMedkit", Short = "MED", Key = "H", Color = Color3.fromRGB(60, 205, 125) },
    { Id = "UtilityInkGrenade", Short = "INK", Key = "G", Color = Color3.fromRGB(255, 45, 145) },
    { Id = "UtilitySmoke", Short = "HUMO", Key = "C", Color = Color3.fromRGB(105, 115, 135) },
    { Id = "UtilityStim", Short = "STIM", Key = "V", Color = Color3.fromRGB(0, 190, 235) },
}

local buttons = {}

local function use(id)
    local camera = workspace.CurrentCamera
    local direction = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
    task.spawn(function()
        local ok, message = UseUtility:InvokeServer(id, direction)
        if not ok then
            local button = buttons[id]
            if button then
                local original = button.Text
                button.Text = "NO"
                task.wait(0.7)
                if button.Parent then button.Text = original end
            end
        end
    end)
end

local function updateButton(id)
    local button = buttons[id]
    if not button then return end
    local info
    for _, item in ipairs(order) do if item.Id == id then info = item break end end
    if not info then return end
    button.Text = string.format("%s [%s]\n×%d", info.Short, info.Key, math.max(0, counts[id] or 0))
end

for _, info in ipairs(order) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 74, 0, 58)
    button.BackgroundColor3 = info.Color
    button.BackgroundTransparency = 0.12
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBlack
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.TextWrapped = true
    button.Parent = holder
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = button
    buttons[info.Id] = button
    updateButton(info.Id)
    button.Activated:Connect(function() use(info.Id) end)
end

UtilityState.OnClientEvent:Connect(function(updated)
    if type(updated) ~= "table" then return end
    counts = updated
    for id in pairs(buttons) do updateButton(id) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then use("UtilityMedkit") end
    if input.KeyCode == Enum.KeyCode.G then use("UtilityInkGrenade") end
    if input.KeyCode == Enum.KeyCode.C then use("UtilitySmoke") end
    if input.KeyCode == Enum.KeyCode.V then use("UtilityStim") end
end)

player:GetAttributeChangedSignal("InShooterMatch"):Connect(function()
    holder.BackgroundTransparency = player:GetAttribute("InShooterMatch") and 0.12 or 0.35
end)
