local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shotFX = remotes:WaitForChild("ShotFX")
local ammoState = remotes:WaitForChild("AmmoState")
local meleeFX = remotes:WaitForChild("MeleeFX")

local CYAN = Color3.fromRGB(0, 226, 239)
local ORANGE = Color3.fromRGB(255, 170, 35)
local WHITE = Color3.fromRGB(255, 250, 225)

local lastAmmo = {}
local shoulderBases = setmetatable({}, {__mode = "k"})
local recoilToken = 0

local function shoulderMotor(character)
    if not character then return nil end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return nil end
    return torso:FindFirstChild("RightShoulder") or torso:FindFirstChild("Right Shoulder")
end

local function animateShoulder(character, style)
    local shoulder = shoulderMotor(character)
    if not shoulder then return end

    local base = shoulderBases[shoulder]
    if not base then
        base = shoulder.C0
        shoulderBases[shoulder] = base
    end

    local target
    local outTime
    if style == "melee" then
        target = base * CFrame.Angles(math.rad(-42), math.rad(-18), math.rad(34))
        outTime = 0.11
    else
        target = base * CFrame.Angles(math.rad(-8), math.rad(2), math.rad(6))
        outTime = 0.045
    end

    shoulder.C0 = target
    task.delay(outTime, function()
        if shoulder.Parent then
            TweenService:Create(shoulder, TweenInfo.new(style == "melee" and 0.16 or 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = base}):Play()
        end
    end)
end

local function cameraKick(strength)
    local camera = workspace.CurrentCamera
    if not camera then return end
    recoilToken += 1
    local token = recoilToken
    local pitch = math.rad(-(strength or 0.9))
    local yaw = math.rad((math.random() - 0.5) * 0.7)
    camera.CFrame = camera.CFrame * CFrame.Angles(pitch, yaw, 0)

    local originalFov = camera.FieldOfView
    camera.FieldOfView = originalFov + 1.2
    task.delay(0.045, function()
        if token ~= recoilToken or not camera.Parent then return end
        TweenService:Create(camera, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = originalFov}):Play()
    end)
end

local function makeFlashPart(name, size, cframe, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = transparency or 0
    part.Size = size
    part.CFrame = cframe
    part.Parent = workspace
    return part
end

local function muzzleFlash(origin, destination, accent)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
    local delta = destination - origin
    if delta.Magnitude < 0.1 then return end
    local direction = delta.Unit
    local muzzle = origin + direction * 1.7

    local core = makeFlashPart("TintaMuzzleCore", Vector3.new(0.34, 0.34, 0.34), CFrame.new(muzzle), WHITE, 0.02)
    core.Shape = Enum.PartType.Ball
    local light = Instance.new("PointLight")
    light.Color = accent or CYAN
    light.Brightness = 3.5
    light.Range = 12
    light.Shadows = false
    light.Parent = core

    local length = 1.35
    local streak = makeFlashPart(
        "TintaMuzzleStreak",
        Vector3.new(0.13, 0.13, length),
        CFrame.lookAt(muzzle + direction * (length * 0.5), muzzle + direction * 2),
        accent or ORANGE,
        0.05
    )

    local attachment = Instance.new("Attachment")
    attachment.Parent = core
    local sparks = Instance.new("ParticleEmitter")
    sparks.Rate = 0
    sparks.Lifetime = NumberRange.new(0.05, 0.11)
    sparks.Speed = NumberRange.new(5, 11)
    sparks.SpreadAngle = Vector2.new(28, 28)
    sparks.LightEmission = 1
    sparks.Color = ColorSequence.new(accent or CYAN, WHITE)
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.14),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Parent = attachment
    sparks:Emit(9)

    Debris:AddItem(core, 0.09)
    Debris:AddItem(streak, 0.055)
end

local function slashSegment(origin, direction, sideOffset, verticalOffset, color)
    local right = direction:Cross(Vector3.yAxis)
    if right.Magnitude < 0.05 then right = Vector3.xAxis else right = right.Unit end
    local startPos = origin + right * sideOffset + Vector3.new(0, verticalOffset, 0)
    local endPos = startPos + direction * 5.2 + right * (-sideOffset * 0.7)
    local distance = (endPos - startPos).Magnitude
    local slash = makeFlashPart(
        "TintaMeleeSlash",
        Vector3.new(0.10, 0.22, distance),
        CFrame.lookAt((startPos + endPos) / 2, endPos),
        color or CYAN,
        0.08
    )
    Debris:AddItem(slash, 0.12)
end

local function meleeVisual(attackerUserId, origin, direction, color)
    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.1 then return end
    direction = direction.Unit
    slashSegment(origin, direction, -1.0, 0.7, color)
    slashSegment(origin, direction, 0.0, 0.2, WHITE)
    slashSegment(origin, direction, 1.0, -0.25, color)

    local attacker = Players:GetPlayerByUserId(tonumber(attackerUserId) or 0)
    if attacker and attacker.Character then animateShoulder(attacker.Character, "melee") end
    if attacker == player then cameraKick(1.35) end
end

shotFX.OnClientEvent:Connect(function(origin, destination, color)
    muzzleFlash(origin, destination, typeof(color) == "Color3" and color or CYAN)
end)

ammoState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    local weaponId = tostring(data.WeaponId or "Weapon")
    local ammo = tonumber(data.Ammo)
    if not ammo then return end

    local previous = lastAmmo[weaponId]
    if previous and ammo < previous and data.Reloading ~= true then
        animateShoulder(player.Character, "fire")
        cameraKick(0.85)
    end
    lastAmmo[weaponId] = ammo
end)

meleeFX.OnClientEvent:Connect(meleeVisual)

player.CharacterAdded:Connect(function()
    lastAmmo = {}
end)

print("[TintaFinal] Combat FX activo: muzzle flash, retroceso y animación de melee.")
