local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UtilityDefinitions = require(ReplicatedStorage.Shared.UtilityDefinitions)
local ProfileService = require(script.Parent.ProfileService)

local UtilityService = {}
local remotes
local cooldowns = {}
local stimTokens = {}

local function profile(player)
    return ProfileService.Get(player)
end

local function count(player, utilityId)
    local p = profile(player)
    return p and math.max(0, math.floor(tonumber(p.Inventory[utilityId]) or 0)) or 0
end

local function push(player)
    if not remotes or not remotes:FindFirstChild("UtilityState") or not player.Parent then return end
    local counts = {}
    for utilityId in pairs(UtilityDefinitions) do counts[utilityId] = count(player, utilityId) end
    remotes.UtilityState:FireClient(player, counts)
end

local function consume(player, utilityId)
    local p = profile(player)
    if not p then return false end
    local current = math.max(0, math.floor(tonumber(p.Inventory[utilityId]) or 0))
    if current <= 0 then return false end
    p.Inventory[utilityId] = current - 1
    push(player)
    return true
end

local function aliveCharacter(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not root then return nil end
    return character, humanoid, root
end

local function isFriendly(source, target)
    if source == target then return true end
    if workspace:GetAttribute("TintaFinalShooterMode") ~= "TeamSplash" then return false end
    local a = source:GetAttribute("ShooterTeam")
    local b = target:GetAttribute("ShooterTeam")
    return a ~= nil and a == b
end

local function pulseVisual(position, radius, color)
    local part = Instance.new("Part")
    part.Name = "TintaPulseFX"
    part.Shape = Enum.PartType.Ball
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.35
    part.Size = Vector3.new(2, 2, 2)
    part.Position = position
    part.Parent = workspace
    TweenService:Create(part, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(radius * 2, radius * 2, radius * 2),
        Transparency = 1,
    }):Play()
    task.delay(0.4, function() if part.Parent then part:Destroy() end end)
end

local function useMedkit(player, definition)
    local _, humanoid = aliveCharacter(player)
    if not humanoid then return false, "No podés usar el botiquín ahora." end
    if humanoid.Health >= humanoid.MaxHealth - 1 then return false, "Tu vida ya está completa." end
    if not consume(player, "UtilityMedkit") then return false, "No tenés botiquines." end
    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (definition.Heal or 45))
    return true, "Botiquín utilizado."
end

local function useGrenade(player, definition, direction)
    local _, _, root = aliveCharacter(player)
    if not root or player:GetAttribute("InShooterMatch") ~= true then return false, "Solo disponible durante la partida." end
    if not consume(player, "UtilityInkGrenade") then return false, "No tenés granadas de tinta." end

    direction = typeof(direction) == "Vector3" and direction or root.CFrame.LookVector
    if direction.Magnitude < 0.1 then direction = root.CFrame.LookVector end
    direction = direction.Unit

    local projectile = Instance.new("Part")
    projectile.Name = "InkGrenadeProjectile"
    projectile.Shape = Enum.PartType.Ball
    projectile.Size = Vector3.new(1.15, 1.15, 1.15)
    projectile.Material = Enum.Material.Neon
    projectile.Color = player:GetAttribute("ShooterTeam") == "Magenta" and Color3.fromRGB(255, 45, 145) or Color3.fromRGB(0, 226, 239)
    projectile.CanCollide = true
    projectile.Position = root.Position + Vector3.new(0, 2.2, 0) + direction * 2
    projectile.Parent = workspace
    pcall(function() projectile:SetNetworkOwner(nil) end)
    projectile.AssemblyLinearVelocity = direction * 62 + Vector3.new(0, 24, 0)

    task.delay(1.25, function()
        if not projectile.Parent then return end
        local position = projectile.Position
        local color = projectile.Color
        projectile:Destroy()
        pulseVisual(position, definition.Radius or 18, color)
        for _, target in ipairs(Players:GetPlayers()) do
            if not isFriendly(player, target) then
                local _, humanoid, targetRoot = aliveCharacter(target)
                if humanoid and targetRoot then
                    local distance = (targetRoot.Position - position).Magnitude
                    if distance <= (definition.Radius or 18) then
                        local scale = 1 - math.clamp(distance / (definition.Radius or 18), 0, 0.75)
                        humanoid:TakeDamage(math.max(12, (definition.Damage or 42) * scale))
                    end
                end
            end
        end
    end)
    return true, "Granada de tinta lanzada."
end

local function smokeCloud(position, definition)
    local duration = definition.Duration or 8
    local radius = definition.Radius or 15
    local folder = Instance.new("Folder")
    folder.Name = "TintaSmokeCloud"
    folder.Parent = workspace
    local random = Random.new()
    for index = 1, 12 do
        local cloud = Instance.new("Part")
        cloud.Name = "SmokeOrb"
        cloud.Shape = Enum.PartType.Ball
        cloud.Anchored = true
        cloud.CanCollide = false
        cloud.CanTouch = false
        cloud.CanQuery = false
        cloud.Material = Enum.Material.SmoothPlastic
        cloud.Color = Color3.fromRGB(48, 54, 66)
        cloud.Transparency = 0.35 + index * 0.018
        local size = random:NextNumber(radius * 0.45, radius * 0.8)
        cloud.Size = Vector3.new(size, size, size)
        cloud.Position = position + Vector3.new(random:NextNumber(-radius * 0.55, radius * 0.55), random:NextNumber(1, radius * 0.35), random:NextNumber(-radius * 0.55, radius * 0.55))
        cloud.Parent = folder
        TweenService:Create(cloud, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Transparency = 1,
            Size = cloud.Size * 1.35,
        }):Play()
    end
    task.delay(duration + 0.2, function() if folder.Parent then folder:Destroy() end end)
end

local function useSmoke(player, definition, direction)
    local _, _, root = aliveCharacter(player)
    if not root or player:GetAttribute("InShooterMatch") ~= true then return false, "Solo disponible durante la partida." end
    if not consume(player, "UtilitySmoke") then return false, "No tenés humo táctico." end
    direction = typeof(direction) == "Vector3" and direction.Magnitude > 0.1 and direction.Unit or root.CFrame.LookVector
    local destination = root.Position + direction * 20
    smokeCloud(destination, definition)
    return true, "Humo táctico desplegado."
end

local function useStim(player, definition)
    local _, humanoid = aliveCharacter(player)
    if not humanoid then return false, "No podés usar el stim ahora." end
    if not consume(player, "UtilityStim") then return false, "No tenés stim." end
    local oldSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = oldSpeed + (definition.SpeedBonus or 6)
    stimTokens[player] = (stimTokens[player] or 0) + 1
    local token = stimTokens[player]
    task.delay(definition.Duration or 6, function()
        if stimTokens[player] ~= token then return end
        if humanoid.Parent and humanoid.Health > 0 then humanoid.WalkSpeed = oldSpeed end
    end)
    return true, "Stim de movilidad activo."
end

function UtilityService.Grant(player, utilityId, amount)
    local definition = UtilityDefinitions[utilityId]
    local p = profile(player)
    if not definition or not p then return false end
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    p.Inventory[utilityId] = math.max(0, math.floor(tonumber(p.Inventory[utilityId]) or 0)) + amount
    push(player)
    return true
end

function UtilityService.GetState(player)
    local counts = {}
    for utilityId, definition in pairs(UtilityDefinitions) do
        counts[utilityId] = count(player, utilityId)
    end
    return { Counts = counts, Definitions = UtilityDefinitions }
end

function UtilityService.Use(player, utilityId, direction)
    utilityId = tostring(utilityId or "")
    local definition = UtilityDefinitions[utilityId]
    if not definition then return false, "Utilidad inválida." end

    cooldowns[player] = cooldowns[player] or {}
    local now = os.clock()
    if now - (cooldowns[player][utilityId] or 0) < (definition.Cooldown or 5) then
        return false, "Utilidad en enfriamiento."
    end

    local success, message
    if definition.Type == "Medkit" then success, message = useMedkit(player, definition)
    elseif definition.Type == "InkGrenade" then success, message = useGrenade(player, definition, direction)
    elseif definition.Type == "Smoke" then success, message = useSmoke(player, definition, direction)
    elseif definition.Type == "Stim" then success, message = useStim(player, definition)
    else return false, "Tipo de utilidad no soportado." end

    if success then cooldowns[player][utilityId] = now end
    return success, message
end

function UtilityService.Initialize(remoteFolder)
    remotes = remoteFolder
end

function UtilityService.RemovePlayer(player)
    cooldowns[player] = nil
    stimTokens[player] = nil
end

return UtilityService
