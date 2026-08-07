local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Weapons = require(ReplicatedStorage.Shared:WaitForChild("WeaponDefinitions"))

local fireRemote = remotes:WaitForChild("FireWeapon")
local reloadRemote = remotes:WaitForChild("ReloadWeapon")
local selectWeapon = remotes:WaitForChild("SelectWeapon")
local getSnapshot = remotes:WaitForChild("GetSnapshot")
local profileState = remotes:WaitForChild("ProfileState")
local ammoState = remotes:WaitForChild("AmmoState")
local gameState = remotes:WaitForChild("GameState")
local hitConfirm = remotes:WaitForChild("HitConfirm")
local killFeed = remotes:WaitForChild("KillFeed")
local shotFX = remotes:WaitForChild("ShotFX")

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 22, 142)
local ORANGE = Color3.fromRGB(255, 132, 21)
local DARK = Color3.fromRGB(5, 7, 14)
local WHITE = Color3.fromRGB(248, 250, 255)
local MUTED = Color3.fromRGB(175, 188, 218)

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalShooterHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
end

local function stroke(object, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CYAN
    s.Transparency = transparency or 0.25
    s.Thickness = thickness or 1.5
    s.Parent = object
end

local function panel(parent, size, position, color, transparency)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = position
    f.BackgroundColor3 = color or DARK
    f.BackgroundTransparency = transparency or 0.14
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 12)
    return f
end

local function text(parent, value, size, position, fontSize, color, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position or UDim2.new()
    l.BackgroundTransparency = 1
    l.Text = value
    l.Font = Enum.Font.GothamBold
    l.TextSize = fontSize or 16
    l.TextColor3 = color or WHITE
    l.TextWrapped = true
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local matchBar = panel(gui, UDim2.fromOffset(470, 58), UDim2.new(0.5, -235, 0, 18), DARK, 0.12)
stroke(matchBar, CYAN, 0.28, 1.5)
local scoreLabel = text(matchBar, "CIAN 0  ·  0 MAGENTA", UDim2.new(0.72, 0, 1, 0), UDim2.new(0, 12, 0, 0), 17, WHITE, Enum.TextXAlignment.Center)
local timerLabel = text(matchBar, "0:00", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.74, 0, 0, 0), 20, ORANGE, Enum.TextXAlignment.Center)

local killBox = Instance.new("Frame")
killBox.AnchorPoint = Vector2.new(1, 0)
killBox.Position = UDim2.new(1, -18, 0, 82)
killBox.Size = UDim2.fromOffset(310, 140)
killBox.BackgroundTransparency = 1
killBox.Parent = gui
local killLayout = Instance.new("UIListLayout")
killLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
killLayout.Padding = UDim.new(0, 5)
killLayout.Parent = killBox

local health = panel(gui, UDim2.fromOffset(240, 34), UDim2.new(0, 24, 1, -52), Color3.fromRGB(17, 20, 31), 0.08)
health.AnchorPoint = Vector2.new(0, 1)
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = CYAN
healthFill.BorderSizePixel = 0
healthFill.Parent = health
corner(healthFill, 99)
local healthText = text(health, "100 HP", UDim2.fromScale(1, 1), UDim2.new(), 14, WHITE, Enum.TextXAlignment.Center)
healthText.ZIndex = 3

local ammo = panel(gui, UDim2.fromOffset(220, 70), UDim2.new(1, -24, 1, -24), DARK, 0.10)
ammo.AnchorPoint = Vector2.new(1, 1)
stroke(ammo, MAGENTA, 0.24, 1.5)
local weaponText = text(ammo, "RIFLE", UDim2.new(1, -16, 0, 25), UDim2.new(0, 8, 0, 7), 12, MUTED, Enum.TextXAlignment.Center)
local ammoText = text(ammo, "30 / 30", UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 0, 32), 22, WHITE, Enum.TextXAlignment.Center)

local crosshair = Instance.new("Frame")
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(4, 4)
crosshair.BackgroundColor3 = WHITE
crosshair.BorderSizePixel = 0
crosshair.Parent = gui
corner(crosshair, 99)
local crossArms = {}
for _, offset in ipairs({Vector2.new(0, -12), Vector2.new(0, 12), Vector2.new(-12, 0), Vector2.new(12, 0)}) do
    local arm = Instance.new("Frame")
    arm.AnchorPoint = Vector2.new(0.5, 0.5)
    arm.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
    arm.Size = offset.X == 0 and UDim2.fromOffset(2, 8) or UDim2.fromOffset(8, 2)
    arm.BackgroundColor3 = WHITE
    arm.BorderSizePixel = 0
    arm.Parent = crosshair
    table.insert(crossArms, arm)
end

local touch = Instance.new("Frame")
touch.AnchorPoint = Vector2.new(1, 1)
touch.Position = UDim2.new(1, -18, 1, -92)
touch.Size = UDim2.fromOffset(250, 185)
touch.BackgroundTransparency = 1
touch.Parent = gui

local function touchButton(value, position, size, color)
    local b = Instance.new("TextButton")
    b.AnchorPoint = Vector2.new(1, 1)
    b.Position = position
    b.Size = UDim2.fromOffset(size, size)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = 0.12
    b.BorderSizePixel = 0
    b.Text = value
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBlack
    b.TextScaled = true
    b.Parent = touch
    corner(b, 99)
    stroke(b, WHITE, 0.55, 1.5)
    return b
end

local fireButton = touchButton("FUEGO", UDim2.new(1, 0, 1, 0), 108, MAGENTA)
local reloadButton = touchButton("R", UDim2.new(0.52, 0, 0.58, 0), 64, CYAN)
local nextButton = touchButton("↻", UDim2.new(0.58, 0, 1, 0), 58, ORANGE)

local currentWeapon = "InkRifle"
local inventory = {InkRifle = 1}
local weaponOrder = {"InkRifle"}
local firing = false
local lastLocalShot = 0

local function isCombat()
    return player:GetAttribute("ShooterActive") == true and player:GetAttribute("InShooterMatch") == true
end

local function setVisible()
    local enabled = isCombat()
    matchBar.Visible = enabled
    killBox.Visible = enabled
    health.Visible = enabled
    ammo.Visible = enabled
    crosshair.Visible = enabled
    touch.Visible = enabled and UserInputService.TouchEnabled
    if not enabled then firing = false end
end

local function fireOnce()
    if not isCombat() then return end
    camera = workspace.CurrentCamera or camera
    if not camera then return end
    local definition = Weapons[currentWeapon] or Weapons.InkRifle
    local now = os.clock()
    if now - lastLocalShot < (definition.FireInterval or 0.12) * 0.92 then return end
    lastLocalShot = now
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return end
    local center = camera.ViewportSize / 2
    local ray = camera:ViewportPointToRay(center.X, center.Y)
    fireRemote:FireServer(head.Position, ray.Direction.Unit)
end

local function startFire()
    if firing or not isCombat() then return end
    firing = true
    task.spawn(function()
        while firing and isCombat() do
            fireOnce()
            local definition = Weapons[currentWeapon] or Weapons.InkRifle
            if not definition.Automatic then break end
            task.wait(math.max(0.035, (definition.FireInterval or 0.12) * 0.75))
        end
        firing = false
    end)
end

local function stopFire()
    firing = false
end

local function equipWeapon(weaponId)
    if not weaponId or not inventory[weaponId] or not Weapons[weaponId] then return end
    local ok = selectWeapon:InvokeServer(weaponId)
    if ok then currentWeapon = weaponId end
end

local function nextWeapon()
    if #weaponOrder == 0 then return end
    local startIndex = table.find(weaponOrder, currentWeapon) or 0
    for step = 1, #weaponOrder do
        local index = ((startIndex + step - 1) % #weaponOrder) + 1
        local id = weaponOrder[index]
        if inventory[id] and Weapons[id] then
            equipWeapon(id)
            return
        end
    end
end

fireButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then startFire() end
end)
fireButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then stopFire() end
end)
reloadButton.Activated:Connect(function() if isCombat() then reloadRemote:FireServer() end end)
nextButton.Activated:Connect(nextWeapon)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isCombat() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then startFire() end
    if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then reloadRemote:FireServer() end
    local keys = {
        [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
        [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9,
    }
    local slot = keys[input.KeyCode]
    if slot then equipWeapon(weaponOrder[slot]) end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then stopFire() end
end)

local function bindHealth(character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then return end
    local function update()
        local ratio = humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth or 0
        healthFill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
        healthFill.BackgroundColor3 = ratio < 0.3 and Color3.fromRGB(255, 70, 80) or CYAN
        healthText.Text = string.format("%d HP", math.max(0, math.floor(humanoid.Health + 0.5)))
    end
    humanoid.HealthChanged:Connect(update)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
    update()
end
player.CharacterAdded:Connect(bindHealth)
if player.Character then task.defer(bindHealth, player.Character) end

ammoState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    currentWeapon = data.WeaponId or currentWeapon
    weaponText.Text = string.upper(data.DisplayName or currentWeapon)
    ammoText.Text = data.Reloading and "RECARGANDO..." or string.format("%d / %d", data.Ammo or 0, data.Magazine or 0)
end)

profileState.OnClientEvent:Connect(function(newProfile)
    if type(newProfile) ~= "table" then return end
    inventory = newProfile.Inventory or inventory
    currentWeapon = newProfile.SelectedWeapon or currentWeapon
end)

hitConfirm.OnClientEvent:Connect(function(headshot)
    local hitColor = headshot and ORANGE or CYAN
    crosshair.BackgroundColor3 = hitColor
    for _, arm in ipairs(crossArms) do arm.BackgroundColor3 = hitColor end
    TweenService:Create(crosshair, TweenInfo.new(0.08), {Size = UDim2.fromOffset(9, 9)}):Play()
    task.delay(0.12, function()
        crosshair.BackgroundColor3 = WHITE
        for _, arm in ipairs(crossArms) do arm.BackgroundColor3 = WHITE end
        TweenService:Create(crosshair, TweenInfo.new(0.10), {Size = UDim2.fromOffset(4, 4)}):Play()
    end)
end)

killFeed.OnClientEvent:Connect(function(killer, victim, headshot)
    local l = text(killBox, string.format("%s  ›  %s%s", tostring(killer), tostring(victim), headshot and "  ★" or ""), UDim2.new(1, 0, 0, 28), UDim2.new(), 12, headshot and ORANGE or WHITE, Enum.TextXAlignment.Center)
    l.BackgroundColor3 = DARK
    l.BackgroundTransparency = 0.15
    corner(l, 7)
    Debris:AddItem(l, 3.5)
end)

shotFX.OnClientEvent:Connect(function(origin, destination, color)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
    local distance = (destination - origin).Magnitude
    if distance <= 0 then return end
    local beam = Instance.new("Part")
    beam.Name = "TintaTracer"
    beam.Anchored = true
    beam.CanCollide = false
    beam.CanTouch = false
    beam.CanQuery = false
    beam.Material = Enum.Material.Neon
    beam.Color = typeof(color) == "Color3" and color or CYAN
    beam.Transparency = 0.20
    beam.Size = Vector3.new(0.07, 0.07, distance)
    beam.CFrame = CFrame.lookAt((origin + destination) / 2, destination)
    beam.Parent = workspace
    Debris:AddItem(beam, 0.065)
end)

local function timerText(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

gameState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    timerLabel.Text = timerText(data.TimeLeft)
    if data.Phase == "Warmup" then
        scoreLabel.Text = "CALENTAMIENTO · ESPERANDO RIVAL"
    elseif data.Mode == "TeamSplash" then
        local scores = data.TeamScores or {}
        scoreLabel.Text = string.format("CIAN %d  ·  %d MAGENTA", scores.Cyan or 0, scores.Magenta or 0)
    else
        scoreLabel.Text = "TODOS CONTRA TODOS"
    end
end)

player:GetAttributeChangedSignal("ShooterActive"):Connect(setVisible)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(setVisible)
player:GetAttributeChangedSignal("ADSActive"):Connect(function()
    local ads = player:GetAttribute("ADSActive") == true
    local distance = ads and 8 or 12
    for index, offset in ipairs({Vector2.new(0, -distance), Vector2.new(0, distance), Vector2.new(-distance, 0), Vector2.new(distance, 0)}) do
        local arm = crossArms[index]
        if arm then arm.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y) end
    end
end)

local ok, snapshot = pcall(function() return getSnapshot:InvokeServer() end)
if ok and type(snapshot) == "table" then
    local p = snapshot.Profile or {}
    local c = snapshot.Config or {}
    inventory = p.Inventory or inventory
    currentWeapon = p.SelectedWeapon or currentWeapon
    weaponOrder = c.Shooter and c.Shooter.WeaponOrder or weaponOrder
end

setVisible()
print("[TintaFinal] HUD compacto de combate cargado.")