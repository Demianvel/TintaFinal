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
local meleeRemote = remotes:WaitForChild("MeleeHit")
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
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
end

local function stroke(object, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CYAN
    s.Transparency = transparency or 0.30
    s.Thickness = thickness or 1.4
    s.Parent = object
end

local function panel(parent, size, position, color, transparency)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = color or DARK
    frame.BackgroundTransparency = transparency or 0.16
    frame.BorderSizePixel = 0
    frame.Parent = parent
    corner(frame, 12)
    return frame
end

local function label(parent, value, size, position, fontSize, color, align)
    local text = Instance.new("TextLabel")
    text.Size = size
    text.Position = position or UDim2.new()
    text.BackgroundTransparency = 1
    text.Text = value
    text.Font = Enum.Font.GothamBold
    text.TextSize = fontSize or 16
    text.TextColor3 = color or WHITE
    text.TextWrapped = true
    text.TextXAlignment = align or Enum.TextXAlignment.Left
    text.Parent = parent
    return text
end

local matchBar = panel(gui, UDim2.fromOffset(430, 52), UDim2.new(0.5, -215, 0, 18), DARK, 0.12)
stroke(matchBar, CYAN, 0.34, 1.3)
local scoreLabel = label(matchBar, "DUELO", UDim2.new(0.73, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, WHITE, Enum.TextXAlignment.Center)
local timerLabel = label(matchBar, "0:00", UDim2.new(0.23, 0, 1, 0), UDim2.new(0.75, 0, 0, 0), 18, ORANGE, Enum.TextXAlignment.Center)

local health = panel(gui, UDim2.fromOffset(190, 30), UDim2.new(0, 22, 0, 132), Color3.fromRGB(17, 20, 31), 0.10)
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = CYAN
healthFill.BorderSizePixel = 0
healthFill.Parent = health
corner(healthFill, 99)
local healthText = label(health, "100 HP", UDim2.fromScale(1, 1), UDim2.new(), 13, WHITE, Enum.TextXAlignment.Center)
healthText.ZIndex = 3

local ammo = panel(gui, UDim2.fromOffset(190, 58), UDim2.new(0.5, -95, 1, -20), DARK, 0.10)
ammo.AnchorPoint = Vector2.new(0, 1)
stroke(ammo, MAGENTA, 0.30, 1.3)
local weaponText = label(ammo, "RIFLE DE TINTA", UDim2.new(1, -12, 0, 22), UDim2.new(0, 6, 0, 5), 11, MUTED, Enum.TextXAlignment.Center)
local ammoText = label(ammo, "30 / 30", UDim2.new(1, -12, 0, 28), UDim2.new(0, 6, 0, 27), 20, WHITE, Enum.TextXAlignment.Center)

local killBox = Instance.new("Frame")
killBox.AnchorPoint = Vector2.new(1, 0)
killBox.Position = UDim2.new(1, -18, 0, 80)
killBox.Size = UDim2.fromOffset(280, 116)
killBox.BackgroundTransparency = 1
killBox.Parent = gui
local killLayout = Instance.new("UIListLayout")
killLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
killLayout.Padding = UDim.new(0, 4)
killLayout.Parent = killBox

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

local function touchButton(textValue, color, rightOffset, bottomOffset, size)
    local button = Instance.new("TextButton")
    button.Name = "Touch" .. textValue
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.new(1, -rightOffset, 1, -bottomOffset)
    button.Size = UDim2.fromOffset(size, size)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0.18
    button.BorderSizePixel = 0
    button.Text = textValue
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBlack
    button.TextScaled = true
    button.AutoButtonColor = true
    button.Visible = false
    button.Parent = gui
    corner(button, 99)
    stroke(button, WHITE, 0.62, 1.2)
    return button
end

local fireButton = touchButton("FUEGO", MAGENTA, 24, 24, 100)
local reloadButton = touchButton("REC", CYAN, 136, 24, 62)
local nextButton = touchButton("ARMA", ORANGE, 208, 24, 62)
local meleeButton = touchButton("PEGAR", Color3.fromRGB(210, 70, 95), 24, 136, 76)

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
    health.Visible = enabled
    ammo.Visible = enabled
    killBox.Visible = enabled
    crosshair.Visible = enabled
    local touchEnabled = enabled and UserInputService.TouchEnabled
    fireButton.Visible = touchEnabled
    reloadButton.Visible = touchEnabled
    nextButton.Visible = touchEnabled
    meleeButton.Visible = touchEnabled
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

-- InputBegan mantiene fuego automático; Activated garantiza al menos un tiro en Android aun si se pierde el gesto.
fireButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then startFire() end
end)
fireButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then stopFire() end
end)
fireButton.Activated:Connect(function()
    fireOnce()
end)
reloadButton.Activated:Connect(function()
    if isCombat() then reloadRemote:FireServer() end
end)
nextButton.Activated:Connect(nextWeapon)
meleeButton.Activated:Connect(function()
    if isCombat() then meleeRemote:FireServer() end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isCombat() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then startFire() end
    if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then reloadRemote:FireServer() end
    if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR3 then meleeRemote:FireServer() end

    local slots = {
        [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
        [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9,
    }
    local slot = slots[input.KeyCode]
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
        healthFill.BackgroundColor3 = ratio < 0.30 and Color3.fromRGB(255, 70, 80) or CYAN
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
    ammoText.Text = data.Reloading and "RECARGANDO" or string.format("%d / %d", data.Ammo or 0, data.Magazine or 0)
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
    local entry = label(
        killBox,
        string.format("%s  >  %s%s", tostring(killer), tostring(victim), headshot and "  ★" or ""),
        UDim2.new(1, 0, 0, 26),
        UDim2.new(),
        11,
        headshot and ORANGE or WHITE,
        Enum.TextXAlignment.Center
    )
    entry.BackgroundColor3 = DARK
    entry.BackgroundTransparency = 0.16
    corner(entry, 7)
    Debris:AddItem(entry, 3.4)
end)

shotFX.OnClientEvent:Connect(function(origin, destination, color)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
    local distance = (destination - origin).Magnitude
    if distance <= 0 then return end
    local tracer = Instance.new("Part")
    tracer.Name = "TintaTracer"
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.CanTouch = false
    tracer.CanQuery = false
    tracer.Material = Enum.Material.Neon
    tracer.Color = typeof(color) == "Color3" and color or CYAN
    tracer.Transparency = 0.20
    tracer.Size = Vector3.new(0.07, 0.07, distance)
    tracer.CFrame = CFrame.lookAt((origin + destination) / 2, destination)
    tracer.Parent = workspace
    Debris:AddItem(tracer, 0.065)
end)

local function timerText(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

gameState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    timerLabel.Text = timerText(data.TimeLeft)
    local duelSize = tonumber(data.DuelTeamSize)
    if duelSize then
        local scores = data.TeamScores or {}
        scoreLabel.Text = string.format("%dV%d · CIAN %d - %d MAGENTA", duelSize, duelSize, scores.Cyan or 0, scores.Magenta or 0)
    elseif data.Phase == "Warmup" then
        scoreLabel.Text = "CALENTAMIENTO"
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
    local offsets = {Vector2.new(0, -distance), Vector2.new(0, distance), Vector2.new(-distance, 0), Vector2.new(distance, 0)}
    for index, offset in ipairs(offsets) do
        local arm = crossArms[index]
        if arm then arm.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y) end
    end
end)

local ok, snapshot = pcall(function()
    return getSnapshot:InvokeServer()
end)
if ok and type(snapshot) == "table" then
    local profile = snapshot.Profile or {}
    local config = snapshot.Config or {}
    inventory = profile.Inventory or inventory
    currentWeapon = profile.SelectedWeapon or currentWeapon
    weaponOrder = config.Shooter and config.Shooter.WeaponOrder or weaponOrder
end

setVisible()
print("[TintaFinal] HUD de combate v2: FUEGO reforzado, PEGAR, recarga y arma.")