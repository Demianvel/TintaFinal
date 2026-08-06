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
local ammoState = remotes:WaitForChild("AmmoState")
local gameState = remotes:WaitForChild("GameState")
local hitConfirm = remotes:WaitForChild("HitConfirm")
local killFeed = remotes:WaitForChild("KillFeed")
local shotFX = remotes:WaitForChild("ShotFX")

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalShooterHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 2
    s.Transparency = transparency or 0
    s.Parent = parent
end

local top = Instance.new("Frame")
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.fromScale(0.5, 0.025)
top.Size = UDim2.new(0.62, 0, 0, 70)
top.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
top.BackgroundTransparency = 0.12
top.BorderSizePixel = 0
top.Parent = gui
corner(top, 14)
stroke(top, Color3.fromRGB(0, 226, 239), 2, 0.15)

local matchLabel = Instance.new("TextLabel")
matchLabel.Size = UDim2.new(0.72, 0, 0.55, 0)
matchLabel.Position = UDim2.fromScale(0.03, 0.05)
matchLabel.BackgroundTransparency = 1
matchLabel.Font = Enum.Font.GothamBlack
matchLabel.Text = "TINTA FINAL · LOBBY"
matchLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
matchLabel.TextScaled = true
matchLabel.TextXAlignment = Enum.TextXAlignment.Left
matchLabel.Parent = top

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(0.72, 0, 0.32, 0)
subLabel.Position = UDim2.fromScale(0.03, 0.62)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.GothamMedium
subLabel.Text = "Preparando arena shooter..."
subLabel.TextColor3 = Color3.fromRGB(174, 190, 218)
subLabel.TextScaled = true
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Parent = top

local timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(1, 0.5)
timerLabel.Position = UDim2.fromScale(0.97, 0.5)
timerLabel.Size = UDim2.new(0.20, 0, 0.74, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.Text = "0:00"
timerLabel.TextColor3 = Color3.fromRGB(255, 145, 25)
timerLabel.TextScaled = true
timerLabel.Parent = top

local scorePanel = Instance.new("Frame")
scorePanel.Position = UDim2.fromScale(0.02, 0.15)
scorePanel.Size = UDim2.new(0, 190, 0, 78)
scorePanel.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
scorePanel.BackgroundTransparency = 0.15
scorePanel.BorderSizePixel = 0
scorePanel.Parent = gui
corner(scorePanel, 12)

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.fromScale(1, 1)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Text = "CIAN 0  ·  0 MAGENTA"
scoreLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
scoreLabel.TextWrapped = true
scoreLabel.TextScaled = true
scoreLabel.Parent = scorePanel

local healthBack = Instance.new("Frame")
healthBack.AnchorPoint = Vector2.new(0, 1)
healthBack.Position = UDim2.new(0.035, 0, 0.965, 0)
healthBack.Size = UDim2.new(0, 250, 0, 30)
healthBack.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
healthBack.BorderSizePixel = 0
healthBack.Parent = gui
corner(healthBack, 99)
stroke(healthBack, Color3.fromRGB(255, 255, 255), 1, 0.65)

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(0, 226, 239)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
corner(healthFill, 99)

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.fromScale(1, 1)
healthText.BackgroundTransparency = 1
healthText.Font = Enum.Font.GothamBold
healthText.Text = "100 HP"
healthText.TextColor3 = Color3.new(1,1,1)
healthText.TextSize = 15
healthText.Parent = healthBack

local ammoPanel = Instance.new("Frame")
ammoPanel.AnchorPoint = Vector2.new(1, 1)
ammoPanel.Position = UDim2.new(0.965, 0, 0.965, 0)
ammoPanel.Size = UDim2.new(0, 180, 0, 64)
ammoPanel.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
ammoPanel.BackgroundTransparency = 0.12
ammoPanel.BorderSizePixel = 0
ammoPanel.Parent = gui
corner(ammoPanel, 12)
stroke(ammoPanel, Color3.fromRGB(255, 45, 145), 2, 0.22)

local weaponText = Instance.new("TextLabel")
weaponText.Size = UDim2.new(1, -12, 0.38, 0)
weaponText.Position = UDim2.new(0, 6, 0, 4)
weaponText.BackgroundTransparency = 1
weaponText.Font = Enum.Font.GothamBold
weaponText.Text = "RIFLE DE TINTA"
weaponText.TextColor3 = Color3.fromRGB(186, 198, 222)
weaponText.TextScaled = true
weaponText.Parent = ammoPanel

local ammoText = Instance.new("TextLabel")
ammoText.Size = UDim2.new(1, -12, 0.58, 0)
ammoText.Position = UDim2.new(0, 6, 0.39, 0)
ammoText.BackgroundTransparency = 1
ammoText.Font = Enum.Font.GothamBlack
ammoText.Text = "30 / 30"
ammoText.TextColor3 = Color3.new(1,1,1)
ammoText.TextScaled = true
ammoText.Parent = ammoPanel

local crosshair = Instance.new("Frame")
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(6, 6)
crosshair.BackgroundColor3 = Color3.new(1,1,1)
crosshair.BorderSizePixel = 0
crosshair.Parent = gui
corner(crosshair, 99)
for _, offset in ipairs({Vector2.new(0,-13), Vector2.new(0,13), Vector2.new(-13,0), Vector2.new(13,0)}) do
    local arm = Instance.new("Frame")
    arm.AnchorPoint = Vector2.new(0.5,0.5)
    arm.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
    arm.Size = offset.X == 0 and UDim2.fromOffset(3,9) or UDim2.fromOffset(9,3)
    arm.BackgroundColor3 = Color3.new(1,1,1)
    arm.BorderSizePixel = 0
    arm.Parent = crosshair
end

local killBox = Instance.new("Frame")
killBox.AnchorPoint = Vector2.new(1,0)
killBox.Position = UDim2.new(0.98,0,0.14,0)
killBox.Size = UDim2.new(0,300,0,160)
killBox.BackgroundTransparency = 1
killBox.Parent = gui
local killLayout = Instance.new("UIListLayout")
killLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
killLayout.Padding = UDim.new(0,5)
killLayout.Parent = killBox

local controls = Instance.new("Frame")
controls.AnchorPoint = Vector2.new(1,1)
controls.Position = UDim2.new(0.97,0,0.84,0)
controls.Size = UDim2.fromOffset(220,120)
controls.BackgroundTransparency = 1
controls.Parent = gui

local fireButton = Instance.new("TextButton")
fireButton.AnchorPoint = Vector2.new(1,1)
fireButton.Position = UDim2.new(1,0,1,0)
fireButton.Size = UDim2.fromOffset(104,104)
fireButton.BackgroundColor3 = Color3.fromRGB(255,45,145)
fireButton.BackgroundTransparency = 0.18
fireButton.Text = "DISPARAR"
fireButton.TextColor3 = Color3.new(1,1,1)
fireButton.Font = Enum.Font.GothamBlack
fireButton.TextScaled = true
fireButton.Parent = controls
corner(fireButton,99)
stroke(fireButton, Color3.new(1,1,1), 2, 0.35)

local reloadButton = Instance.new("TextButton")
reloadButton.AnchorPoint = Vector2.new(1,1)
reloadButton.Position = UDim2.new(0.46,0,0.8,0)
reloadButton.Size = UDim2.fromOffset(76,76)
reloadButton.BackgroundColor3 = Color3.fromRGB(0,160,180)
reloadButton.BackgroundTransparency = 0.2
reloadButton.Text = "RECARGAR"
reloadButton.TextColor3 = Color3.new(1,1,1)
reloadButton.Font = Enum.Font.GothamBold
reloadButton.TextScaled = true
reloadButton.Parent = controls
corner(reloadButton,99)

local weaponBar = Instance.new("Frame")
weaponBar.AnchorPoint = Vector2.new(0.5,1)
weaponBar.Position = UDim2.new(0.5,0,0.97,0)
weaponBar.Size = UDim2.new(0,390,0,58)
weaponBar.BackgroundTransparency = 1
weaponBar.Parent = gui
local weaponLayout = Instance.new("UIListLayout")
weaponLayout.FillDirection = Enum.FillDirection.Horizontal
weaponLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
weaponLayout.Padding = UDim.new(0,8)
weaponLayout.Parent = weaponBar

local currentWeapon = "InkRifle"
local inventory = { InkRifle = 1 }
local ammo = 30
local magazine = 30
local firing = false
local lastLocalShot = 0

local function setCombatVisible()
    local enabled = player:GetAttribute("ShooterActive") == true and player:GetAttribute("InShooterMatch") == true
    controls.Visible = enabled
    crosshair.Visible = enabled
    ammoPanel.Visible = enabled
end

local function fireOnce()
    if not controls.Visible then return end
    local definition = Weapons[currentWeapon] or Weapons.InkRifle
    local now = os.clock()
    if now - lastLocalShot < definition.FireInterval * 0.92 then return end
    lastLocalShot = now
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head or not camera then return end
    local center = camera.ViewportSize / 2
    local ray = camera:ViewportPointToRay(center.X, center.Y)
    fireRemote:FireServer(head.Position, ray.Direction.Unit)
end

local function startFire()
    if firing then return end
    firing = true
    task.spawn(function()
        while firing do
            fireOnce()
            local definition = Weapons[currentWeapon] or Weapons.InkRifle
            if not definition.Automatic then break end
            task.wait(math.max(0.04, definition.FireInterval * 0.75))
        end
        firing = false
    end)
end

local function stopFire() firing = false end
fireButton.MouseButton1Down:Connect(startFire)
fireButton.MouseButton1Up:Connect(stopFire)
fireButton.TouchLongPress:Connect(function(_, state) if state == Enum.UserInputState.Begin then startFire() else stopFire() end end)
reloadButton.Activated:Connect(function() reloadRemote:FireServer() end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then startFire() end
    if input.KeyCode == Enum.KeyCode.R then reloadRemote:FireServer() end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then stopFire() end
end)

local weaponButtons = {}
local function rebuildWeapons()
    for _, child in ipairs(weaponBar:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, weaponId in ipairs({"InkRifle","NeonSMG","SplashShotgun"}) do
        local definition = Weapons[weaponId]
        local button = Instance.new("TextButton")
        button.Name = weaponId
        button.Size = UDim2.fromOffset(118,50)
        button.BackgroundColor3 = definition.Accent
        button.BackgroundTransparency = inventory[weaponId] and 0.12 or 0.72
        button.Text = inventory[weaponId] and definition.DisplayName or "BLOQUEADA"
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
        button.Parent = weaponBar
        corner(button,10)
        if inventory[weaponId] then
            button.Activated:Connect(function()
                local ok = selectWeapon:InvokeServer(weaponId)
                if ok then currentWeapon = weaponId end
            end)
        end
        weaponButtons[weaponId] = button
    end
end

local function bindHealth(character)
    local humanoid = character:WaitForChild("Humanoid",8)
    if not humanoid then return end
    local function update()
        local ratio = humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth or 0
        healthFill.Size = UDim2.fromScale(math.clamp(ratio,0,1),1)
        healthFill.BackgroundColor3 = ratio < 0.3 and Color3.fromRGB(255,70,80) or Color3.fromRGB(0,226,239)
        healthText.Text = string.format("%d HP", math.max(0, math.floor(humanoid.Health + 0.5)))
    end
    humanoid.HealthChanged:Connect(update)
    update()
end
player.CharacterAdded:Connect(bindHealth)
if player.Character then task.spawn(bindHealth,player.Character) end

ammoState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    currentWeapon = data.WeaponId or currentWeapon
    ammo = data.Ammo or ammo
    magazine = data.Magazine or magazine
    weaponText.Text = string.upper(data.DisplayName or currentWeapon)
    ammoText.Text = data.Reloading and "RECARGANDO..." or string.format("%d / %d", ammo, magazine)
end)

hitConfirm.OnClientEvent:Connect(function(headshot)
    crosshair.BackgroundColor3 = headshot and Color3.fromRGB(255,170,25) or Color3.fromRGB(0,226,239)
    TweenService:Create(crosshair,TweenInfo.new(0.15),{Size=UDim2.fromOffset(12,12)}):Play()
    task.delay(0.16,function()
        TweenService:Create(crosshair,TweenInfo.new(0.15),{Size=UDim2.fromOffset(6,6)}):Play()
        crosshair.BackgroundColor3 = Color3.new(1,1,1)
    end)
end)

killFeed.OnClientEvent:Connect(function(killer,victim,headshot)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,30)
    label.BackgroundColor3 = Color3.fromRGB(8,10,18)
    label.BackgroundTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.Text = string.format("%s  ›  %s%s", tostring(killer), tostring(victim), headshot and "  ★" or "")
    label.TextColor3 = headshot and Color3.fromRGB(255,170,25) or Color3.fromRGB(235,240,255)
    label.TextScaled = true
    label.Parent = killBox
    corner(label,7)
    Debris:AddItem(label,4)
end)

shotFX.OnClientEvent:Connect(function(origin,destination,color)
    if typeof(origin)~="Vector3" or typeof(destination)~="Vector3" then return end
    local distance=(destination-origin).Magnitude
    if distance<=0 then return end
    local beam=Instance.new("Part")
    beam.Anchored=true
    beam.CanCollide=false
    beam.CanQuery=false
    beam.CanTouch=false
    beam.Material=Enum.Material.Neon
    beam.Color=typeof(color)=="Color3" and color or Color3.fromRGB(0,226,239)
    beam.Transparency=0.18
    beam.Size=Vector3.new(0.08,0.08,distance)
    beam.CFrame=CFrame.lookAt((origin+destination)/2,destination)
    beam.Parent=workspace
    Debris:AddItem(beam,0.07)
end)

local function timerText(seconds)
    seconds=math.max(0,tonumber(seconds) or 0)
    return string.format("%d:%02d",math.floor(seconds/60),seconds%60)
end

gameState.OnClientEvent:Connect(function(data)
    if type(data)~="table" then return end
    local modeNames={Survival="SUPERVIVENCIA DE TINTA",TeamSplash="CIAN VS MAGENTA",FreeSplash="TODOS CONTRA TODOS"}
    matchLabel.Text=string.format("TINTA FINAL · %s", modeNames[data.Mode] or string.upper(data.Phase or "LOBBY"))
    subLabel.Text=tostring(data.Announcement or "")
    timerLabel.Text=timerText(data.TimeLeft)
    if data.Mode=="TeamSplash" and data.TeamScores then
        scoreLabel.Text=string.format("CIAN %d  ·  %d MAGENTA",data.TeamScores.Cyan or 0,data.TeamScores.Magenta or 0)
    elseif data.Mode=="Survival" then
        scoreLabel.Text=string.format("OLEADA %d / 5",data.Wave or 0)
    else
        scoreLabel.Text="ELIMINÁ · MOVETE · SOBREVIVÍ"
    end
end)

player:GetAttributeChangedSignal("ShooterActive"):Connect(setCombatVisible)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(setCombatVisible)

local success,snapshot=pcall(function() return getSnapshot:InvokeServer() end)
if success and type(snapshot)=="table" and snapshot.Profile then
    inventory=snapshot.Profile.Inventory or inventory
    currentWeapon=snapshot.Profile.SelectedWeapon or currentWeapon
end
rebuildWeapons()
setCombatVisible()
print("[TintaFinal] HUD shooter profesional cargado.")
