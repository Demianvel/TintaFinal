local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.WeaponDefinitions)
local ProfileService = require(script.Parent.ProfileService)
local CharacterStyleService = require(script.Parent.CharacterStyleService)

local WeaponService = {}
local remotes
local active = false
local sessions = {}
local callbacks = {}
local random = Random.new()

local function session(player)
    local profile = ProfileService.Get(player)
    local weaponId = profile and profile.SelectedWeapon or "InkRifle"
    local definition = Weapons[weaponId] or Weapons.InkRifle
    local current = sessions[player]
    if not current or current.WeaponId ~= weaponId then
        current = {
            WeaponId = weaponId,
            Ammo = definition.Magazine,
            LastShot = 0,
            Reloading = false,
            ReloadToken = 0,
        }
        sessions[player] = current
    end
    return current, definition
end

local function pushAmmo(player)
    local current, definition = session(player)
    if remotes and player.Parent then
        remotes.AmmoState:FireClient(player, {
            WeaponId = current.WeaponId,
            DisplayName = definition.DisplayName,
            Ammo = current.Ammo,
            Magazine = definition.Magazine,
            Reloading = current.Reloading,
        })
    end
end

local function spreadDirection(direction, degrees)
    if degrees <= 0 then return direction.Unit end
    local pitch = math.rad(random:NextNumber(-degrees, degrees))
    local yaw = math.rad(random:NextNumber(-degrees, degrees))
    return (CFrame.lookAt(Vector3.zero, direction.Unit) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

local function targetHumanoid(instance)
    local model = instance and instance:FindFirstAncestorOfClass("Model")
    if not model then return nil, nil, nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil, nil, nil end
    return model, humanoid, Players:GetPlayerFromCharacter(model)
end

local function friendlyFire(shooter, targetPlayer)
    if not targetPlayer or shooter == targetPlayer then return shooter == targetPlayer end
    local mode = workspace:GetAttribute("TintaFinalShooterMode")
    if mode ~= "TeamSplash" then return false end
    return shooter:GetAttribute("ShooterTeam") == targetPlayer:GetAttribute("ShooterTeam")
end

local function canDamagePlayers()
    local mode = workspace:GetAttribute("TintaFinalShooterMode")
    return mode == "TeamSplash" or mode == "FreeSplash"
end

local function visualShot(origin, destination, weaponId)
    if not remotes then return end
    local definition = Weapons[weaponId] or Weapons.InkRifle
    remotes.ShotFX:FireAllClients(origin, destination, definition.Accent)
end

function WeaponService.Initialize(remoteFolder, handlers)
    remotes = remoteFolder
    callbacks = handlers or {}
    remotes.FireWeapon.OnServerEvent:Connect(function(player, origin, direction)
        WeaponService.Fire(player, origin, direction)
    end)
    remotes.ReloadWeapon.OnServerEvent:Connect(function(player)
        WeaponService.Reload(player)
    end)
end

function WeaponService.SetActive(value)
    active = value == true
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("InShooterMatch") then
            player:SetAttribute("ShooterActive", active)
            if active then pushAmmo(player) end
        elseif not active then
            player:SetAttribute("ShooterActive", false)
        end
    end
end

function WeaponService.SetPlayerActive(player, value)
    if not player or not player.Parent then return end
    player:SetAttribute("ShooterActive", value == true)
    if value then pushAmmo(player) end
end

function WeaponService.ResetPlayer(player)
    sessions[player] = nil
    if active and player:GetAttribute("InShooterMatch") then pushAmmo(player) end
end

function WeaponService.SelectWeapon(player, weaponId)
    weaponId = tostring(weaponId)
    if not Weapons[weaponId] then return false, "Arma inválida." end
    if not ProfileService.SetSelectedWeapon(player, weaponId) then return false, "Primero desbloqueá esa arma." end
    sessions[player] = nil
    if player.Character then CharacterStyleService.Apply(player, player.Character) end
    pushAmmo(player)
    return true, "Arma equipada.", ProfileService.Public(player)
end

function WeaponService.AddAmmo(player, amount)
    local current, definition = session(player)
    current.Ammo = math.clamp(current.Ammo + math.max(1, math.floor(amount)), 0, definition.Magazine)
    pushAmmo(player)
end

function WeaponService.Reload(player)
    if not active or not player:GetAttribute("InShooterMatch") then return end
    local current, definition = session(player)
    if current.Reloading or current.Ammo >= definition.Magazine then return end
    current.Reloading = true
    current.ReloadToken += 1
    local token = current.ReloadToken
    pushAmmo(player)
    task.delay(definition.ReloadSeconds, function()
        if not sessions[player] or sessions[player].ReloadToken ~= token then return end
        current.Reloading = false
        current.Ammo = definition.Magazine
        pushAmmo(player)
    end)
end

function WeaponService.Fire(player, origin, direction)
    if not active or not player:GetAttribute("InShooterMatch") then return end
    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 then return end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not root or not head then return end
    if (origin - head.Position).Magnitude > 12 then origin = head.Position end

    local current, definition = session(player)
    local now = os.clock()
    if current.Reloading or current.Ammo <= 0 or now - current.LastShot < definition.FireInterval * 0.82 then
        if current.Ammo <= 0 then WeaponService.Reload(player) end
        return
    end
    current.LastShot = now
    current.Ammo -= 1
    pushAmmo(player)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character}
    rayParams.IgnoreWater = true

    local registeredHit = false
    local registeredHeadshot = false
    local damageEnabled = canDamagePlayers()

    for _ = 1, definition.Pellets do
        local shotDirection = spreadDirection(direction, definition.SpreadDegrees)
        local result = workspace:Raycast(origin, shotDirection * definition.Range, rayParams)
        local hitPosition = result and result.Position or (origin + shotDirection * definition.Range)
        visualShot(origin, hitPosition, current.WeaponId)

        if result and damageEnabled then
            local model, targetHumanoidObject, targetPlayer = targetHumanoid(result.Instance)
            if targetHumanoidObject and targetPlayer and not friendlyFire(player, targetPlayer) then
                local headshot = result.Instance.Name == "Head"
                local damage = definition.Damage * (headshot and definition.HeadshotMultiplier or 1)
                local before = targetHumanoidObject.Health
                targetHumanoidObject:TakeDamage(damage)
                local dealt = math.max(0, math.min(before, damage))
                local profile = ProfileService.Get(player)
                if profile then profile.Stats.Damage += math.floor(dealt) end
                registeredHit = true
                registeredHeadshot = registeredHeadshot or headshot

                if before > 0 and targetHumanoidObject.Health <= 0 and not model:GetAttribute("TintaKillRegistered") then
                    model:SetAttribute("TintaKillRegistered", true)
                    if callbacks.OnPlayerKilled then callbacks.OnPlayerKilled(player, targetPlayer, headshot) end
                end
            end
        end
    end

    if registeredHit and remotes then remotes.HitConfirm:FireClient(player, registeredHeadshot) end
end

function WeaponService.PlayerRemoving(player)
    sessions[player] = nil
end

return WeaponService