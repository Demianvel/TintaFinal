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
local ORANGE = Color3.fromRGB(255, 132, 21)
local FIRE_YELLOW = Color3.fromRGB(255, 226, 66)
local FIRE_RED = Color3.fromRGB(255, 72, 18)
local WHITE = Color3.fromRGB(255, 250, 225)

local lastAmmo = {}
local recoilToken = 0
local lastMuzzleAt = 0
local lastMuzzleOrigin

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

local function makePart(name, size, cframe, color, transparency)
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

local function emitMuzzleFire(origin, destination, accent)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
    local delta = destination - origin
    if delta.Magnitude < 0.1 then return end
    local direction = delta.Unit
    local muzzle = origin + direction * 1.8

    local core = makePart("TintaMuzzleCore", Vector3.new(0.44, 0.44, 0.44), CFrame.new(muzzle), WHITE, 0.01)
    core.Shape = Enum.PartType.Ball

    local light = Instance.new("PointLight")
    light.Color = FIRE_YELLOW
    light.Brightness = 5.5
    light.Range = 16
    light.Shadows = false
    light.Parent = core

    local flash = makePart("TintaMuzzleFlame", Vector3.new(0.22, 0.22, 1.8), CFrame.lookAt(muzzle + direction * 0.9, muzzle + direction * 3), FIRE_YELLOW, 0.02)

    local attachment = Instance.new("Attachment")
    attachment.Parent = core

    local flame = Instance.new("ParticleEmitter")
    flame.Name = "FireBurst"
    flame.Rate = 0
    flame.Lifetime = NumberRange.new(0.06, 0.16)
    flame.Speed = NumberRange.new(7, 15)
    flame.SpreadAngle = Vector2.new(22, 22)
    flame.LightEmission = 1
    flame.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, WHITE),
        ColorSequenceKeypoint.new(0.28, FIRE_YELLOW),
        ColorSequenceKeypoint.new(0.70, ORANGE),
        ColorSequenceKeypoint.new(1, FIRE_RED),
    })
    flame.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.34),
        NumberSequenceKeypoint.new(0.45, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    flame.Parent = attachment
    flame:Emit(14)

    local inkSparks = Instance.new("ParticleEmitter")
    inkSparks.Name = "InkSparks"
    inkSparks.Rate = 0
    inkSparks.Lifetime = NumberRange.new(0.05, 0.13)
    inkSparks.Speed = NumberRange.new(5, 12)
    inkSparks.SpreadAngle = Vector2.new(34, 34)
    inkSparks.LightEmission = 1
    inkSparks.Color = ColorSequence.new(accent or CYAN, WHITE)
    inkSparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.13),
        NumberSequenceKeypoint.new(1, 0),
    })
    inkSparks.Parent = attachment
    inkSparks:Emit(8)

    Debris:AddItem(core, 0.14)
    Debris:AddItem(flash, 0.07)
end

local function fieryProjectile(origin, destination, accent)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
    local delta = destination - origin
    local distance = delta.Magnitude
    if distance < 1 then return end

    local direction = delta.Unit
    local start = origin + direction * 2.1
    local endPos = destination
    local bullet = makePart("TintaFireAmmo", Vector3.new(0.24, 0.24, 0.55), CFrame.lookAt(start, endPos), FIRE_YELLOW, 0.02)
    bullet.Shape = Enum.PartType.Ball

    local back = Instance.new("Attachment")
    back.Position = Vector3.new(0, 0, 0.20)
    back.Parent = bullet
    local front = Instance.new("Attachment")
    front.Position = Vector3.new(0, 0, -0.20)
    front.Parent = bullet

    local trail = Instance.new("Trail")
    trail.Attachment0 = back
    trail.Attachment1 = front
    trail.Lifetime = 0.10
    trail.MinLength = 0.04
    trail.LightEmission = 1
    trail.FaceCamera = true
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent or CYAN),
        ColorSequenceKeypoint.new(0.35, FIRE_YELLOW),
        ColorSequenceKeypoint.new(1, FIRE_RED),
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.02),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Parent = bullet

    local flameAttachment = Instance.new("Attachment")
    flameAttachment.Parent = bullet
    local fire = Instance.new("ParticleEmitter")
    fire.Name = "ProjectileFire"
    fire.Rate = 80
    fire.Lifetime = NumberRange.new(0.05, 0.11)
    fire.Speed = NumberRange.new(0.5, 1.7)
    fire.LightEmission = 1
    fire.SpreadAngle = Vector2.new(180, 180)
    fire.Color = ColorSequence.new(FIRE_YELLOW, FIRE_RED)
    fire.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(1, 0),
    })
    fire.Parent = flameAttachment

    local glow = Instance.new("PointLight")
    glow.Color = FIRE_YELLOW
    glow.Brightness = 2.2
    glow.Range = 7
    glow.Shadows = false
    glow.Parent = bullet

    local duration = math.clamp(distance / 900, 0.045, 0.18)
    TweenService:Create(bullet, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.lookAt(endPos, endPos + direction),
    }):Play()

    Debris:AddItem(bullet, duration + 0.16)
end

local function impactSpark(position, accent)
    if typeof(position) ~= "Vector3" then return end
    local spark = makePart("TintaImpactSpark", Vector3.new(0.30, 0.30, 0.30), CFrame.new(position), accent or ORANGE, 0.03)
    spark.Shape = Enum.PartType.Ball

    local attachment = Instance.new("Attachment")
    attachment.Parent = spark
    local burst = Instance.new("ParticleEmitter")
    burst.Rate = 0
    burst.Lifetime = NumberRange.new(0.08, 0.18)
    burst.Speed = NumberRange.new(5, 14)
    burst.SpreadAngle = Vector2.new(180, 180)
    burst.LightEmission = 1
    burst.Color = ColorSequence.new(FIRE_YELLOW, accent or ORANGE)
    burst.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0),
    })
    burst.Parent = attachment
    burst:Emit(7)
    Debris:AddItem(spark, 0.15)
end

local function slashSegment(origin, direction, sideOffset, verticalOffset, color)
    local right = direction:Cross(Vector3.yAxis)
    if right.Magnitude < 0.05 then right = Vector3.xAxis else right = right.Unit end
    local startPos = origin + right * sideOffset + Vector3.new(0, verticalOffset, 0)
    local endPos = startPos + direction * 5.2 + right * (-sideOffset * 0.7)
    local distance = (endPos - startPos).Magnitude
    local slash = makePart("TintaMeleeSlash", Vector3.new(0.10, 0.22, distance), CFrame.lookAt((startPos + endPos) / 2, endPos), color or CYAN, 0.08)
    Debris:AddItem(slash, 0.12)
end

local function meleeVisual(attackerUserId, origin, direction, color)
    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.1 then return end
    direction = direction.Unit
    slashSegment(origin, direction, -1.0, 0.7, color)
    slashSegment(origin, direction, 0.0, 0.2, WHITE)
    slashSegment(origin, direction, 1.0, -0.25, color)

    local attacker = Players:GetPlayerByUserId(tonumber(attackerUserId) or 0)
    if attacker == player then cameraKick(1.35) end
end

shotFX.OnClientEvent:Connect(function(origin, destination, color)
    local accent = typeof(color) == "Color3" and color or CYAN
    local now = os.clock()
    local sameOrigin = typeof(origin) == "Vector3" and typeof(lastMuzzleOrigin) == "Vector3" and (origin - lastMuzzleOrigin).Magnitude < 0.75
    if not sameOrigin or now - lastMuzzleAt >= 0.035 then
        emitMuzzleFire(origin, destination, accent)
        lastMuzzleAt = now
        lastMuzzleOrigin = origin
    end
    fieryProjectile(origin, destination, accent)
    impactSpark(destination, accent)
end)

ammoState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    local weaponId = tostring(data.WeaponId or "Weapon")
    local ammo = tonumber(data.Ammo)
    if not ammo then return end

    local previous = lastAmmo[weaponId]
    if previous and ammo < previous and data.Reloading ~= true then
        cameraKick(0.85)
    end
    lastAmmo[weaponId] = ammo
end)

meleeFX.OnClientEvent:Connect(meleeVisual)

player.CharacterAdded:Connect(function()
    lastAmmo = {}
    lastMuzzleAt = 0
    lastMuzzleOrigin = nil
end)

print("[TintaFinal] Combat FX v2: munición de fuego, destello, impacto y retroceso activos sin duplicar muzzle flash por perdigones.")
