local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local BASE_FOV = 70
local ADS_FOV = 55
local SPRINT_MULTIPLIER = 1.35
local WALK_MIN = 14
local WALK_MAX = 24

local humanoid
local rootPart
local baseWalkSpeed = 16
local sprinting = false
local aiming = false

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalMovementControls"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 75
gui.Parent = player:WaitForChild("PlayerGui")

local function roundButton(text, color, position, size)
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = position
    button.Size = UDim2.fromOffset(size, size)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0.14
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBlack
    button.TextScaled = true
    button.Visible = false
    button.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.55
    stroke.Thickness = 1.5
    stroke.Parent = button
    return button
end

local sprintButton = roundButton("CORRER", Color3.fromRGB(255, 132, 21), UDim2.new(1, -238, 1, -78), 74)
local aimButton = roundButton("APUNTAR", Color3.fromRGB(0, 226, 239), UDim2.new(1, -148, 1, -170), 74)

local function isCombat()
    return player:GetAttribute("ShooterActive") == true and player:GetAttribute("InShooterMatch") == true
end

local function updateButtons()
    local visible = UserInputService.TouchEnabled and isCombat()
    sprintButton.Visible = visible
    aimButton.Visible = visible
end

local function setAim(enabled)
    aiming = enabled == true and isCombat()
    camera = workspace.CurrentCamera or camera
    if camera then
        TweenService:Create(camera, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FieldOfView = aiming and ADS_FOV or BASE_FOV,
        }):Play()
    end
    player:SetAttribute("ADSActive", aiming)
    aimButton.BackgroundTransparency = aiming and 0.02 or 0.14
end

local function applySprint()
    if not humanoid or humanoid.Health <= 0 then return end
    local desired = baseWalkSpeed
    if sprinting and isCombat() then desired = math.min(WALK_MAX, baseWalkSpeed * SPRINT_MULTIPLIER) end
    humanoid.WalkSpeed = desired
    sprintButton.BackgroundTransparency = sprinting and 0.02 or 0.14
end

local function setSprint(enabled)
    sprinting = enabled == true and isCombat()
    if sprinting and aiming then setAim(false) end
    applySprint()
end

local function bindCharacter(character)
    humanoid = character:WaitForChild("Humanoid", 8)
    rootPart = character:WaitForChild("HumanoidRootPart", 8)
    if not humanoid then return end

    humanoid.AutoRotate = true
    humanoid.UseJumpPower = true
    if humanoid.JumpPower < 42 then humanoid.JumpPower = 50 end
    baseWalkSpeed = math.clamp(humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16, WALK_MIN, 20)
    humanoid.WalkSpeed = baseWalkSpeed

    if rootPart then rootPart.Anchored = false end

    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not sprinting and humanoid and humanoid.WalkSpeed > 0 then
            baseWalkSpeed = math.clamp(humanoid.WalkSpeed, WALK_MIN, 20)
        end
    end)
end

player.CharacterAdded:Connect(function(character)
    sprinting = false
    aiming = false
    task.defer(bindCharacter, character)
end)
if player.Character then task.defer(bindCharacter, player.Character) end

local function sprintAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then setSprint(true) end
    if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then setSprint(false) end
    return Enum.ContextActionResult.Pass
end

local function aimAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then setAim(true) end
    if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then setAim(false) end
    return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("TintaSprint", sprintAction, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:BindAction("TintaAim", aimAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)

sprintButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setSprint(true)
    end
end)
sprintButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setSprint(false)
    end
end)
aimButton.Activated:Connect(function() setAim(not aiming) end)

player:GetAttributeChangedSignal("ShooterActive"):Connect(function()
    if not isCombat() then
        setSprint(false)
        setAim(false)
    end
    updateButtons()
end)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(function()
    if not isCombat() then
        setSprint(false)
        setAim(false)
    end
    updateButtons()
end)

pcall(function()
    player.DevTouchMovementMode = Enum.DevTouchMovementMode.DynamicThumbstick
end)

updateButtons()
print("[TintaFinal] Movimiento, sprint y apuntado PvP cargados.")