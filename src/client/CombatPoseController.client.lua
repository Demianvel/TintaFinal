local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ammoState = remotes:WaitForChild("AmmoState")
local meleeFX = remotes:WaitForChild("MeleeFX")

local character
local humanoid
local motors = {}
local current = {}
local target = {}
local lastAmmoByWeapon = {}
local reloading = false
local firePulse = 0
local meleePulse = 0
local elapsed = 0

local IDENTITY = CFrame.new()

local function findMotor(names)
    if not character then return nil end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Motor6D") then
            for _, name in ipairs(names) do
                if descendant.Name == name then return descendant end
            end
        end
    end
    return nil
end

local function bindCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 8)
    motors = {
        RightShoulder = findMotor({"RightShoulder", "Right Shoulder"}),
        LeftShoulder = findMotor({"LeftShoulder", "Left Shoulder"}),
        Waist = findMotor({"Waist", "RootJoint", "Root Joint"}),
        Neck = findMotor({"Neck"}),
        RightHip = findMotor({"RightHip", "Right Hip"}),
        LeftHip = findMotor({"LeftHip", "Left Hip"}),
    }
    current = {}
    target = {}
    for name in pairs(motors) do
        current[name] = IDENTITY
        target[name] = IDENTITY
    end
    lastAmmoByWeapon = {}
    reloading = false
    firePulse = 0
    meleePulse = 0
end

local function combatActive()
    return player:GetAttribute("InShooterMatch") == true and player:GetAttribute("ShooterActive") == true
end

local function cfAngles(x, y, z)
    return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local function setTarget(name, value)
    if motors[name] then target[name] = value or IDENTITY end
end

local function resetTargets()
    for name in pairs(motors) do target[name] = IDENTITY end
end

local function buildPose(dt)
    resetTargets()
    if not humanoid or humanoid.Health <= 0 or not combatActive() then return end

    elapsed += dt
    firePulse = math.max(0, firePulse - dt * 8.5)
    meleePulse = math.max(0, meleePulse - dt * 4.2)

    local moving = humanoid.MoveDirection.Magnitude > 0.08
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    local sprinting = moving and grounded and humanoid.WalkSpeed >= 20
    local aiming = player:GetAttribute("ADSActive") == true

    -- Postura base de arma: torso ligeramente preparado y brazos hacia delante.
    setTarget("RightShoulder", cfAngles(-20, 5, 9))
    setTarget("LeftShoulder", cfAngles(-14, -12, -8))
    setTarget("Waist", cfAngles(-2, 0, 0))

    if sprinting then
        local swing = math.sin(elapsed * 10.5)
        local bounce = math.abs(math.sin(elapsed * 10.5))
        setTarget("RightShoulder", cfAngles(22 + swing * 25, 4, 10))
        setTarget("LeftShoulder", cfAngles(-22 - swing * 25, -5, -10))
        setTarget("Waist", CFrame.new(0, -0.05 * bounce, -0.10) * cfAngles(-13 + bounce * 3, swing * 2.2, 0))
        setTarget("Neck", cfAngles(8, -swing * 1.5, 0))
        setTarget("RightHip", cfAngles(-swing * 6, 0, 0))
        setTarget("LeftHip", cfAngles(swing * 6, 0, 0))
    elseif aiming then
        -- ADS: ambas manos sostienen el arma y el torso se inclina apenas hacia el objetivo.
        setTarget("RightShoulder", cfAngles(-58, 2, 12))
        setTarget("LeftShoulder", cfAngles(-53, -4, -14))
        setTarget("Waist", CFrame.new(0, 0, -0.08) * cfAngles(-6, 0, 0))
        setTarget("Neck", cfAngles(4, 0, 0))
    elseif moving then
        local walk = math.sin(elapsed * 7.5)
        setTarget("RightShoulder", cfAngles(-20 + walk * 7, 5, 9))
        setTarget("LeftShoulder", cfAngles(-14 - walk * 7, -12, -8))
        setTarget("Waist", cfAngles(-4, walk * 1.5, 0))
    end

    if reloading then
        -- Recarga: arma baja y mano de apoyo se acerca al cargador.
        setTarget("RightShoulder", cfAngles(-12, 18, 24))
        setTarget("LeftShoulder", cfAngles(-58, -24, -28))
        setTarget("Waist", cfAngles(-4, 8, 0))
        setTarget("Neck", cfAngles(7, -5, 0))
    end

    if firePulse > 0 then
        local kick = math.sin(math.clamp(firePulse, 0, 1) * math.pi) * 8
        setTarget("RightShoulder", target.RightShoulder * cfAngles(kick, 0, 0))
        setTarget("LeftShoulder", target.LeftShoulder * cfAngles(kick * 0.45, 0, 0))
        setTarget("Waist", target.Waist * CFrame.new(0, 0, 0.035 * firePulse) * cfAngles(kick * 0.18, 0, 0))
    end

    if meleePulse > 0 then
        local phase = 1 - meleePulse
        local swing = math.sin(math.clamp(phase, 0, 1) * math.pi)
        setTarget("RightShoulder", cfAngles(-55 + swing * 65, -20 + swing * 42, 40 - swing * 62))
        setTarget("LeftShoulder", cfAngles(-8, -16, -8))
        setTarget("Waist", cfAngles(-5, swing * 18, 0))
    end
end

local function applyPose(dt)
    local alpha = 1 - math.exp(-dt * 14)
    for name, motor in pairs(motors) do
        if motor and motor.Parent then
            local from = current[name] or IDENTITY
            local to = target[name] or IDENTITY
            local blended = from:Lerp(to, alpha)
            current[name] = blended
            motor.Transform = blended
        end
    end
end

ammoState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    reloading = data.Reloading == true
    local weaponId = tostring(data.WeaponId or "Weapon")
    local ammo = tonumber(data.Ammo)
    if ammo then
        local previous = lastAmmoByWeapon[weaponId]
        if previous and ammo < previous and not reloading then
            firePulse = 1
        end
        lastAmmoByWeapon[weaponId] = ammo
    end
end)

meleeFX.OnClientEvent:Connect(function(attackerUserId)
    if tonumber(attackerUserId) == player.UserId then
        meleePulse = 1
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    task.defer(bindCharacter, newCharacter)
end)
if player.Character then task.defer(bindCharacter, player.Character) end

RunService.RenderStepped:Connect(function(dt)
    if not character or not character.Parent then return end
    buildPose(dt)
    applyPose(dt)
end)

print("[TintaFinal] CombatPoseController activo: apuntar, correr, disparar, recargar y melee con poses procedurales.")