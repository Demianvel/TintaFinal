local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local BASE_FOV = 70
local ADS_FOV = 56
local DEFAULT_WALK_SPEED = 16
local SPRINT_MULTIPLIER = 1.45
local MAX_SPRINT_SPEED = 25
local JOYSTICK_DEADZONE = 0.10

local humanoid
local rootPart
local baseWalkSpeed = DEFAULT_WALK_SPEED
local sprinting = false
local aiming = false
local joystickTouch
local joystickVector = Vector2.zero
local keyboardWasMoving = false

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalMovementControls"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 72
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = object
end

local function outline(object, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = transparency or 0.65
    stroke.Thickness = 1.3
    stroke.Parent = object
end

local function makeButton(textValue, color, position, size, anchor)
    local button = Instance.new("TextButton")
    button.AnchorPoint = anchor or Vector2.new(1, 1)
    button.Position = position
    button.Size = UDim2.fromOffset(size, size)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0.20
    button.BorderSizePixel = 0
    button.Text = textValue
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBlack
    button.TextScaled = true
    button.AutoButtonColor = true
    button.Visible = false
    button.Parent = gui
    round(button)
    outline(button, 0.62)
    return button
end

-- Joystick propio: evita depender de que Roblox muestre correctamente su thumbstick predeterminado.
local joystickBase = Instance.new("Frame")
joystickBase.Name = "MoveJoystick"
joystickBase.AnchorPoint = Vector2.new(0, 1)
joystickBase.Position = UDim2.new(0, 24, 1, -24)
joystickBase.Size = UDim2.fromOffset(150, 150)
joystickBase.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
joystickBase.BackgroundTransparency = 0.42
joystickBase.BorderSizePixel = 0
joystickBase.Active = true
joystickBase.Visible = false
joystickBase.Parent = gui
round(joystickBase)
outline(joystickBase, 0.48)

local joystickKnob = Instance.new("Frame")
joystickKnob.Name = "Knob"
joystickKnob.AnchorPoint = Vector2.new(0.5, 0.5)
joystickKnob.Position = UDim2.fromScale(0.5, 0.5)
joystickKnob.Size = UDim2.fromOffset(62, 62)
joystickKnob.BackgroundColor3 = Color3.fromRGB(0, 226, 239)
joystickKnob.BackgroundTransparency = 0.16
joystickKnob.BorderSizePixel = 0
joystickKnob.Parent = joystickBase
round(joystickKnob)
outline(joystickKnob, 0.45)

local sprintButton = makeButton(
    "CORRER",
    Color3.fromRGB(255, 132, 21),
    UDim2.new(0, 265, 1, -35),
    70,
    Vector2.new(0, 1)
)

local aimButton = makeButton(
    "APUNTAR",
    Color3.fromRGB(0, 226, 239),
    UDim2.new(1, -26, 1, -166),
    78
)

local jumpButton = makeButton(
    "SALTAR",
    Color3.fromRGB(96, 83, 220),
    UDim2.new(1, -116, 1, -158),
    64
)

local function isCombat()
    return player:GetAttribute("ShooterActive") == true and player:GetAttribute("InShooterMatch") == true
end

local function currentHumanoid()
    if humanoid and humanoid.Parent and humanoid.Health > 0 then return humanoid end
    local character = player.Character
    humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
    rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil
    return humanoid
end

local function ensureMovable()
    local hum = currentHumanoid()
    if not hum then return end

    hum.AutoRotate = true
    hum.PlatformStand = false
    hum.Sit = false
    hum.UseJumpPower = true
    if hum.JumpPower < 42 then hum.JumpPower = 50 end

    if rootPart and rootPart.Parent then
        rootPart.Anchored = false
    end

    local desired = baseWalkSpeed
    if sprinting and isCombat() then
        desired = math.min(MAX_SPRINT_SPEED, baseWalkSpeed * SPRINT_MULTIPLIER)
    end
    if hum.WalkSpeed ~= desired then hum.WalkSpeed = desired end
end

local function setAim(enabled)
    aiming = enabled == true and isCombat()
    camera = workspace.CurrentCamera or camera
    if camera then
        TweenService:Create(camera, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FieldOfView = aiming and ADS_FOV or BASE_FOV,
        }):Play()
    end
    player:SetAttribute("ADSActive", aiming)
    aimButton.BackgroundTransparency = aiming and 0.04 or 0.20
end

local function setSprint(enabled)
    sprinting = enabled == true and isCombat()
    if sprinting and aiming then setAim(false) end
    sprintButton.BackgroundTransparency = sprinting and 0.04 or 0.20
    ensureMovable()
end

local function resetJoystick()
    joystickTouch = nil
    joystickVector = Vector2.zero
    joystickKnob.Position = UDim2.fromScale(0.5, 0.5)
    local hum = currentHumanoid()
    if hum and UserInputService.TouchEnabled then
        hum:Move(Vector3.zero, true)
    end
end

local function updateJoystick(screenPosition)
    if not joystickBase.Visible then return end
    local center = joystickBase.AbsolutePosition + joystickBase.AbsoluteSize / 2
    local delta = Vector2.new(screenPosition.X, screenPosition.Y) - center
    local radius = math.max(1, math.min(joystickBase.AbsoluteSize.X, joystickBase.AbsoluteSize.Y) * 0.36)
    local magnitude = delta.Magnitude
    if magnitude > radius then delta = delta.Unit * radius end

    joystickVector = delta / radius
    if joystickVector.Magnitude < JOYSTICK_DEADZONE then joystickVector = Vector2.zero end
    joystickKnob.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)
end

local function updateTouchVisibility()
    local visible = UserInputService.TouchEnabled and isCombat()
    joystickBase.Visible = visible
    sprintButton.Visible = visible
    aimButton.Visible = visible
    jumpButton.Visible = visible
    if not visible then resetJoystick() end
end

local function bindCharacter(character)
    humanoid = character:WaitForChild("Humanoid", 8)
    rootPart = character:WaitForChild("HumanoidRootPart", 8)
    if not humanoid then return end

    local detected = tonumber(humanoid.WalkSpeed) or DEFAULT_WALK_SPEED
    baseWalkSpeed = math.clamp(detected > 0 and detected or DEFAULT_WALK_SPEED, 14, 20)
    sprinting = false
    aiming = false
    resetJoystick()
    ensureMovable()
end

player.CharacterAdded:Connect(function(character)
    task.defer(bindCharacter, character)
end)
if player.Character then task.defer(bindCharacter, player.Character) end

-- Joystick touch.
joystickBase.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch or not isCombat() then return end
    if joystickTouch then return end
    joystickTouch = input
    updateJoystick(input.Position)
end)

UserInputService.TouchMoved:Connect(function(input)
    if joystickTouch and input == joystickTouch then updateJoystick(input.Position) end
end)

UserInputService.TouchEnded:Connect(function(input)
    if joystickTouch and input == joystickTouch then resetJoystick() end
end)

-- Sprint móvil: mantener pulsado.
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

aimButton.Activated:Connect(function()
    setAim(not aiming)
end)

jumpButton.Activated:Connect(function()
    local hum = currentHumanoid()
    if hum and isCombat() and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Teclado / gamepad.
local function sprintAction(_, state)
    if state == Enum.UserInputState.Begin then setSprint(true) end
    if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then setSprint(false) end
    return Enum.ContextActionResult.Pass
end

local function aimAction(_, state)
    if state == Enum.UserInputState.Begin then setAim(true) end
    if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then setAim(false) end
    return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("TintaSprint", sprintAction, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:BindAction("TintaAim", aimAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)

local function keyboardVector()
    local x, y = 0, 0
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then x -= 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then x += 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then y += 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then y -= 1 end
    local vector = Vector2.new(x, y)
    if vector.Magnitude > 1 then vector = vector.Unit end
    return vector
end

-- Fallback de movimiento. En móvil usa el joystick Tinta; en PC garantiza WASD aunque PlayerModule se haya deshabilitado.
RunService.RenderStepped:Connect(function()
    if not isCombat() then return end
    local hum = currentHumanoid()
    if not hum then return end
    ensureMovable()

    if UserInputService.TouchEnabled and joystickVector.Magnitude >= JOYSTICK_DEADZONE then
        hum:Move(Vector3.new(joystickVector.X, 0, -joystickVector.Y), true)
        return
    end

    local keys = keyboardVector()
    if keys.Magnitude > 0 then
        keyboardWasMoving = true
        hum:Move(Vector3.new(keys.X, 0, -keys.Y), true)
    elseif keyboardWasMoving then
        keyboardWasMoving = false
        hum:Move(Vector3.zero, true)
    end
end)

local function stateChanged()
    if not isCombat() then
        setSprint(false)
        setAim(false)
        resetJoystick()
    else
        task.defer(ensureMovable)
    end
    updateTouchVisibility()
end

player:GetAttributeChangedSignal("ShooterActive"):Connect(stateChanged)
player:GetAttributeChangedSignal("InShooterMatch"):Connect(stateChanged)
stateChanged()

print("[TintaFinal] Movimiento PvP reforzado: joystick, caminar, correr, saltar y apuntar.")