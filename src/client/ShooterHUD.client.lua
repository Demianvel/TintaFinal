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

local CYAN = Color3.fromRGB(0,226,239)
local MAGENTA = Color3.fromRGB(255,45,145)
local ORANGE = Color3.fromRGB(255,145,25)
local DARK = Color3.fromRGB(7,9,16)
local WHITE = Color3.fromRGB(246,249,255)
local MUTED = Color3.fromRGB(175,190,220)

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalShooterHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui
local function updateScale()
    camera = workspace.CurrentCamera or camera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280,720)
    scale.Scale = math.clamp(math.min(viewport.X/1280, viewport.Y/720), 0.62, 1.05)
end
updateScale()
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

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

local function panel(parent, size, position, color)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = position
    f.BackgroundColor3 = color or DARK
    f.BackgroundTransparency = 0.12
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f,12)
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

local top = panel(gui, UDim2.new(0,680,0,74), UDim2.new(0.5,-340,0,16))
stroke(top,CYAN,0.16,2)
local matchLabel = text(top,"TINTA FINAL · COMPETITIVE",UDim2.new(0.68,0,0,40),UDim2.new(0,18,0,7),20,WHITE)
local subLabel = text(top,"PREPARANDO ARENA",UDim2.new(0.68,0,0,22),UDim2.new(0,18,0,44),11,MUTED)
local timerLabel = text(top,"0:00",UDim2.new(0.26,0,1,0),UDim2.new(0.72,0,0,0),26,ORANGE,Enum.TextXAlignment.Center)

local scorePanel = panel(gui,UDim2.new(0,240,0,88),UDim2.new(0,18,0,110))
stroke(scorePanel,MAGENTA,0.2,2)
local scoreLabel = text(scorePanel,"CIAN 0 · 0 MAGENTA",UDim2.new(1,-14,0,46),UDim2.new(0,7,0,8),16,WHITE,Enum.TextXAlignment.Center)
local countLabel = text(scorePanel,"0 VS 0",UDim2.new(1,-14,0,25),UDim2.new(0,7,0,56),12,MUTED,Enum.TextXAlignment.Center)

local killBox = Instance.new("Frame")
killBox.AnchorPoint = Vector2.new(1,0)
killBox.Position = UDim2.new(1,-18,0,112)
killBox.Size = UDim2.new(0,330,0,175)
killBox.BackgroundTransparency = 1
killBox.Parent = gui
local killLayout = Instance.new("UIListLayout")
killLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
killLayout.Padding = UDim.new(0,5)
killLayout.Parent = killBox

local healthBack = panel(gui,UDim2.new(0,260,0,34),UDim2.new(0,24,1,-58),Color3.fromRGB(18,21,31))
healthBack.AnchorPoint = Vector2.new(0,1)
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1,1)
healthFill.BackgroundColor3 = CYAN
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
corner(healthFill,99)
local healthText = text(healthBack,"100 HP",UDim2.fromScale(1,1),UDim2.new(),14,WHITE,Enum.TextXAlignment.Center)
healthText.ZIndex = 3

local ammoPanel = panel(gui,UDim2.new(0,205,0,74),UDim2.new(1,-24,1,-28))
ammoPanel.AnchorPoint = Vector2.new(1,1)
stroke(ammoPanel,MAGENTA,0.18,2)
local weaponText = text(ammoPanel,"RIFLE DE TINTA",UDim2.new(1,-16,0,27),UDim2.new(0,8,0,8),12,MUTED,Enum.TextXAlignment.Center)
local ammoText = text(ammoPanel,"30 / 30",UDim2.new(1,-16,0,35),UDim2.new(0,8,0,34),23,WHITE,Enum.TextXAlignment.Center)

local crosshair = Instance.new("Frame")
crosshair.AnchorPoint = Vector2.new(0.5,0.5)
crosshair.Position = UDim2.fromScale(0.5,0.5)
crosshair.Size = UDim2.fromOffset(5,5)
crosshair.BackgroundColor3 = WHITE
crosshair.BorderSizePixel = 0
crosshair.Parent = gui
corner(crosshair,99)
for _, offset in ipairs({Vector2.new(0,-14),Vector2.new(0,14),Vector2.new(-14,0),Vector2.new(14,0)}) do
    local arm = Instance.new("Frame")
    arm.AnchorPoint = Vector2.new(0.5,0.5)
    arm.Position = UDim2.new(0.5,offset.X,0.5,offset.Y)
    arm.Size = offset.X == 0 and UDim2.fromOffset(3,10) or UDim2.fromOffset(10,3)
    arm.BackgroundColor3 = WHITE
    arm.BorderSizePixel = 0
    arm.Parent = crosshair
end

local weaponBar = panel(gui,UDim2.new(0,760,0,62),UDim2.new(0.5,-380,1,-22),Color3.fromRGB(8,10,18))
weaponBar.AnchorPoint = Vector2.new(0,1)
weaponBar.BackgroundTransparency = 0.26
local weaponHolder = Instance.new("ScrollingFrame")
weaponHolder.Size = UDim2.new(1,-12,1,-10)
weaponHolder.Position = UDim2.new(0,6,0,5)
weaponHolder.BackgroundTransparency = 1
weaponHolder.BorderSizePixel = 0
weaponHolder.ScrollBarThickness = 0
weaponHolder.ScrollingDirection = Enum.ScrollingDirection.X
weaponHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
weaponHolder.CanvasSize = UDim2.new()
weaponHolder.Parent = weaponBar
local weaponLayout = Instance.new("UIListLayout")
weaponLayout.FillDirection = Enum.FillDirection.Horizontal
weaponLayout.Padding = UDim.new(0,6)
weaponLayout.VerticalAlignment = Enum.VerticalAlignment.Center
weaponLayout.Parent = weaponHolder

local controls = Instance.new("Frame")
controls.AnchorPoint = Vector2.new(1,1)
controls.Position = UDim2.new(1,-22,1,-122)
controls.Size = UDim2.fromOffset(225,130)
controls.BackgroundTransparency = 1
controls.Parent = gui

local fireButton = Instance.new("TextButton")
fireButton.AnchorPoint = Vector2.new(1,1)
fireButton.Position = UDim2.new(1,0,1,0)
fireButton.Size = UDim2.fromOffset(112,112)
fireButton.BackgroundColor3 = MAGENTA
fireButton.BackgroundTransparency = 0.15
fireButton.BorderSizePixel = 0
fireButton.Text = "DISPARAR"
fireButton.TextColor3 = WHITE
fireButton.Font = Enum.Font.GothamBlack
fireButton.TextScaled = true
fireButton.Parent = controls
corner(fireButton,99)
stroke(fireButton,WHITE,0.45,2)

local reloadButton = Instance.new("TextButton")
reloadButton.AnchorPoint = Vector2.new(1,1)
reloadButton.Position = UDim2.new(0.48,0,0.84,0)
reloadButton.Size = UDim2.fromOffset(78,78)
reloadButton.BackgroundColor3 = CYAN
reloadButton.BackgroundTransparency = 0.17
reloadButton.BorderSizePixel = 0
reloadButton.Text = "RECARGAR"
reloadButton.TextColor3 = WHITE
reloadButton.Font = Enum.Font.GothamBlack
reloadButton.TextScaled = true
reloadButton.Parent = controls
corner(reloadButton,99)

local currentWeapon = "InkRifle"
local inventory = {InkRifle=1}
local weaponOrder = {"InkRifle","NeonSMG","SplashShotgun","PulseCarbine","ViperPistol","PrismSniper","VoltLMG","BurstRifle"}
local firing = false
local lastLocalShot = 0
local weaponButtons = {}

local function isCombat()
    return player:GetAttribute("ShooterActive") == true and player:GetAttribute("InShooterMatch") == true
end

local function setCombatVisible()
    local enabled = isCombat()
    top.Visible = enabled
    scorePanel.Visible = enabled
    killBox.Visible = enabled
    healthBack.Visible = enabled
    ammoPanel.Visible = enabled
    crosshair.Visible = enabled
    weaponBar.Visible = enabled
    controls.Visible = enabled and UserInputService.TouchEnabled
    if not enabled then firing = false end
end

local function refreshWeaponHighlights()
    for weaponId, button in pairs(weaponButtons) do
        button.BackgroundTransparency = weaponId == currentWeapon and 0.02 or 0.22
        local uiStroke = button:FindFirstChildOfClass("UIStroke")
        if uiStroke then uiStroke.Transparency = weaponId == currentWeapon and 0.05 or 0.55 end
    end
end

local function rebuildWeapons()
    for _, child in ipairs(weaponHolder:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    table.clear(weaponButtons)
    for index, weaponId in ipairs(weaponOrder) do
        if inventory[weaponId] and Weapons[weaponId] then
            local definition = Weapons[weaponId]
            local b = Instance.new("TextButton")
            b.Name = weaponId
            b.Size = UDim2.fromOffset(122,48)
            b.BackgroundColor3 = definition.Accent
            b.BackgroundTransparency = weaponId == currentWeapon and 0.02 or 0.22
            b.BorderSizePixel = 0
            b.Text = string.format("%d · %s", index, definition.DisplayName)
            b.TextColor3 = WHITE
            b.Font = Enum.Font.GothamBold
            b.TextScaled = true
            b.Parent = weaponHolder
            corner(b,9)
            stroke(b,WHITE,weaponId == currentWeapon and 0.05 or 0.55,1.5)
            b.Activated:Connect(function()
                local ok, _, newProfile = selectWeapon:InvokeServer(weaponId)
                if ok then
                    currentWeapon = weaponId
                    if newProfile and newProfile.Inventory then inventory = newProfile.Inventory end
                    refreshWeaponHighlights()
                end
            end)
            weaponButtons[weaponId] = b
        end
    end
end

local function fireOnce()
    if not isCombat() then return end
    local definition = Weapons[currentWeapon] or Weapons.InkRifle
    local now = os.clock()
    if now - lastLocalShot < definition.FireInterval * 0.92 then return end
    lastLocalShot = now
    camera = workspace.CurrentCamera or camera
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head or not camera then return end
    local center = camera.ViewportSize / 2
    local ray = camera:ViewportPointToRay(center.X,center.Y)
    fireRemote:FireServer(head.Position,ray.Direction.Unit)
end

local function startFire()
    if firing or not isCombat() then return end
    firing = true
    task.spawn(function()
        while firing and isCombat() do
            fireOnce()
            local definition = Weapons[currentWeapon] or Weapons.InkRifle
            if not definition.Automatic then break end
            task.wait(math.max(0.04,definition.FireInterval * 0.75))
        end
        firing = false
    end)
end

local function stopFire() firing = false end
fireButton.MouseButton1Down:Connect(startFire)
fireButton.MouseButton1Up:Connect(stopFire)
reloadButton.Activated:Connect(function() if isCombat() then reloadRemote:FireServer() end end)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed or not isCombat() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then startFire() end
    if input.KeyCode == Enum.KeyCode.R then reloadRemote:FireServer() end
    local numberKeys = {
        [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4,
        [Enum.KeyCode.Five]=5,[Enum.KeyCode.Six]=6,[Enum.KeyCode.Seven]=7,[Enum.KeyCode.Eight]=8,
    }
    local slot = numberKeys[input.KeyCode]
    local weaponId = slot and weaponOrder[slot]
    if weaponId and inventory[weaponId] then
        local ok = selectWeapon:InvokeServer(weaponId)
        if ok then currentWeapon = weaponId refreshWeaponHighlights() end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then stopFire() end
end)

local function bindHealth(character)
    local humanoid = character:WaitForChild("Humanoid",8)
    if not humanoid then return end
    local function update()
        local ratio = humanoid.MaxHealth > 0 and humanoid.Health/humanoid.MaxHealth or 0
        healthFill.Size = UDim2.fromScale(math.clamp(ratio,0,1),1)
        healthFill.BackgroundColor3 = ratio < 0.3 and Color3.fromRGB(255,65,80) or CYAN
        healthText.Text = string.format("%d HP",math.max(0,math.floor(humanoid.Health+0.5)))
    end
    humanoid.HealthChanged:Connect(update)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
    update()
end
player.CharacterAdded:Connect(bindHealth)
if player.Character then task.spawn(bindHealth,player.Character) end

ammoState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    currentWeapon = data.WeaponId or currentWeapon
    weaponText.Text = string.upper(data.DisplayName or currentWeapon)
    ammoText.Text = data.Reloading and "RECARGANDO..." or string.format("%d / %d",data.Ammo or 0,data.Magazine or 0)
    refreshWeaponHighlights()
end)

profileState.OnClientEvent:Connect(function(newProfile)
    if type(newProfile) ~= "table" then return end
    inventory = newProfile.Inventory or inventory
    currentWeapon = newProfile.SelectedWeapon or currentWeapon
    rebuildWeapons()
end)

hitConfirm.OnClientEvent:Connect(function(headshot)
    crosshair.BackgroundColor3 = headshot and ORANGE or CYAN
    TweenService:Create(crosshair,TweenInfo.new(0.11),{Size=UDim2.fromOffset(12,12)}):Play()
    task.delay(0.13,function()
        TweenService:Create(crosshair,TweenInfo.new(0.14),{Size=UDim2.fromOffset(5,5)}):Play()
        crosshair.BackgroundColor3 = WHITE
    end)
end)

killFeed.OnClientEvent:Connect(function(killer,victim,headshot)
    local l = text(killBox,string.format("%s  ›  %s%s",tostring(killer),tostring(victim),headshot and "  ★" or ""),UDim2.new(1,0,0,31),UDim2.new(),13,headshot and ORANGE or WHITE,Enum.TextXAlignment.Center)
    l.BackgroundColor3 = Color3.fromRGB(8,10,18)
    l.BackgroundTransparency = 0.16
    corner(l,7)
    Debris:AddItem(l,4)
end)

shotFX.OnClientEvent:Connect(function(origin,destination,color)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
    local distance = (destination-origin).Magnitude
    if distance <= 0 then return end
    local beam = Instance.new("Part")
    beam.Name = "TintaTracer"
    beam.Anchored = true
    beam.CanCollide = false
    beam.CanTouch = false
    beam.CanQuery = false
    beam.Material = Enum.Material.Neon
    beam.Color = typeof(color) == "Color3" and color or CYAN
    beam.Transparency = 0.18
    beam.Size = Vector3.new(0.075,0.075,distance)
    beam.CFrame = CFrame.lookAt((origin+destination)/2,destination)
    beam.Parent = workspace
    Debris:AddItem(beam,0.07)
end)

local function timerText(seconds)
    seconds = math.max(0,math.floor(tonumber(seconds) or 0))
    return string.format("%d:%02d",math.floor(seconds/60),seconds%60)
end

gameState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    local modeNames = {Survival="ENTRENAMIENTO",TeamSplash="10 VS 10",FreeSplash="TODOS CONTRA TODOS"}
    matchLabel.Text = string.format("TINTA FINAL · %s",modeNames[data.Mode] or string.upper(data.Phase or "LOBBY"))
    subLabel.Text = tostring(data.Announcement or "")
    timerLabel.Text = timerText(data.TimeLeft)
    if data.Mode == "TeamSplash" and data.TeamScores then
        scoreLabel.Text = string.format("CIAN %d  ·  %d MAGENTA",data.TeamScores.Cyan or 0,data.TeamScores.Magenta or 0)
        local counts = data.TeamCounts or {}
        countLabel.Text = string.format("%d VS %d",counts.Cyan or 0,counts.Magenta or 0)
    elseif data.Mode == "FreeSplash" then
        scoreLabel.Text = "TODOS CONTRA TODOS"
        countLabel.Text = string.format("%d JUGADORES",data.AliveCount or 0)
    else
        scoreLabel.Text = string.format("OLEADA %d / 5",data.Wave or 0)
        countLabel.Text = "ENTRENAMIENTO"
    end
end)

player:GetAttributeChangedSignal("ShooterActive"):Connect(setCombatVisible)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(setCombatVisible)

local success,snapshot = pcall(function() return getSnapshot:InvokeServer() end)
if success and type(snapshot) == "table" then
    local p = snapshot.Profile or {}
    local c = snapshot.Config or {}
    inventory = p.Inventory or inventory
    currentWeapon = p.SelectedWeapon or currentWeapon
    weaponOrder = c.Shooter and c.Shooter.WeaponOrder or weaponOrder
end
rebuildWeapons()
setCombatVisible()

print("[TintaFinal] HUD competitivo cargado con arsenal dinámico.")
