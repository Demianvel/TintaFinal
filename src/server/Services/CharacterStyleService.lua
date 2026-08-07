local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.WeaponDefinitions)
local ProfileService = require(script.Parent.ProfileService)

local CharacterStyleService = {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)
local DARK = Color3.fromRGB(12, 15, 24)

local function part(folder, name, size, color, material)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Color = color
    object.Material = material or Enum.Material.SmoothPlastic
    object.CanCollide = false
    object.CanTouch = false
    object.CanQuery = false
    object.Massless = true
    object.CastShadow = true
    object.Parent = folder
    return object
end

local function weldTo(folder, target, name, size, offset, color, material)
    if not target then return nil end
    local object = part(folder, name, size, color, material)
    object.CFrame = target.CFrame * offset
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = object
    weld.Parent = object
    return object
end

local function teamAccent(player, profile)
    if profile and profile.SelectedSkin == "CyanOperatorSkin" then return CYAN end
    if profile and profile.SelectedSkin == "MagentaOperatorSkin" then return MAGENTA end
    if profile and profile.SelectedSkin == "NeonRebelSkin" then return Color3.fromRGB(255, 70, 180) end
    local team = player:GetAttribute("ShooterTeam")
    if team == "Magenta" then return MAGENTA end
    if team == "Cyan" then return CYAN end
    return ORANGE
end

local function weaponDimensions(weaponId)
    local definition = Weapons[weaponId] or Weapons.InkRifle
    if definition.Class == "Sniper" then return 3.9, 0.42, 0.55 end
    if definition.Class == "LMG" then return 3.35, 0.72, 0.72 end
    if definition.Class == "Shotgun" then return 3.1, 0.55, 0.64 end
    if definition.Class == "Pistol" then return 1.7, 0.38, 0.52 end
    if definition.Class == "SMG" then return 2.35, 0.5, 0.58 end
    return 2.95, 0.48, 0.60
end

local function attachWeapon(folder, player, character, profile)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("RightLowerArm")
    if not hand then return end
    local weaponId = profile and profile.SelectedWeapon or "InkRifle"
    local definition = Weapons[weaponId] or Weapons.InkRifle
    local accent = definition.Accent or teamAccent(player, profile)
    local length, height, width = weaponDimensions(weaponId)
    local baseOffset = CFrame.new(0.08, -0.42, -(0.55 + length * 0.28)) * CFrame.Angles(math.rad(-7), 0, 0)

    weldTo(folder, hand, "WeaponReceiver_" .. weaponId, Vector3.new(width, height, length * 0.58), baseOffset, DARK, Enum.Material.Metal)
    weldTo(folder, hand, "WeaponBarrel_" .. weaponId, Vector3.new(width * 0.42, height * 0.42, length * 0.55), baseOffset * CFrame.new(0, 0.02, -length * 0.46), accent, Enum.Material.Neon)
    weldTo(folder, hand, "WeaponCore_" .. weaponId, Vector3.new(width * 0.62, height * 0.22, length * 0.28), baseOffset * CFrame.new(0, height * 0.62, -length * 0.05), accent, Enum.Material.Neon)
    weldTo(folder, hand, "WeaponGrip_" .. weaponId, Vector3.new(width * 0.48, 0.75, 0.38), baseOffset * CFrame.new(0, -0.55, length * 0.12) * CFrame.Angles(math.rad(-16), 0, 0), DARK, Enum.Material.Metal)

    if definition.Class == "Sniper" then
        weldTo(folder, hand, "WeaponScope_" .. weaponId, Vector3.new(0.44, 0.44, 1.0), baseOffset * CFrame.new(0, 0.55, 0.15), accent, Enum.Material.Neon)
    elseif definition.Class == "LMG" then
        weldTo(folder, hand, "WeaponMagazine_" .. weaponId, Vector3.new(0.72, 0.95, 0.72), baseOffset * CFrame.new(0, -0.62, -0.2), ORANGE, Enum.Material.Metal)
    elseif definition.Class == "Shotgun" then
        weldTo(folder, hand, "WeaponPump_" .. weaponId, Vector3.new(width * 0.9, height * 0.85, 0.85), baseOffset * CFrame.new(0, -0.05, -0.78), accent, Enum.Material.SmoothPlastic)
    end
end

function CharacterStyleService.Apply(player, character)
    if not character or not character.Parent then return end
    local previous = character:FindFirstChild("TintaCompetitiveStyle")
    if previous then previous:Destroy() end

    local profile = ProfileService.Get(player)
    local accent = teamAccent(player, profile)
    local folder = Instance.new("Folder")
    folder.Name = "TintaCompetitiveStyle"
    folder.Parent = character

    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
    local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")

    local chest = weldTo(folder, torso, "NeonChest", Vector3.new(2.35, 1.6, 0.35), CFrame.new(0, 0.1, -0.68), DARK, Enum.Material.Metal)
    if chest then
        local stripe = weldTo(folder, chest, "ChestStripe", Vector3.new(1.5, 0.16, 0.08), CFrame.new(0, 0.05, -0.22), accent, Enum.Material.Neon)
        if stripe then stripe.CastShadow = false end
    end

    weldTo(folder, torso, "BackTank", Vector3.new(1.25, 1.85, 0.65), CFrame.new(0, 0.15, 0.82), DARK, Enum.Material.Metal)
    weldTo(folder, torso, "BackGlow", Vector3.new(0.42, 1.25, 0.12), CFrame.new(0, 0.15, 1.18), accent, Enum.Material.Neon)
    weldTo(folder, leftArm, "LeftShoulder", Vector3.new(1.05, 0.55, 1.05), CFrame.new(0, 0.18, 0), DARK, Enum.Material.Metal)
    weldTo(folder, rightArm, "RightShoulder", Vector3.new(1.05, 0.55, 1.05), CFrame.new(0, 0.18, 0), DARK, Enum.Material.Metal)

    if head then
        weldTo(folder, head, "Mask", Vector3.new(1.5, 0.62, 0.18), CFrame.new(0, -0.18, -0.58), DARK, Enum.Material.Metal)
        local visor = weldTo(folder, head, "Visor", Vector3.new(1.35, 0.26, 0.09), CFrame.new(0, 0.15, -0.66), accent, Enum.Material.Neon)
        if visor then visor.Transparency = 0.08 visor.CastShadow = false end
        weldTo(folder, head, "CapPlate", Vector3.new(1.6, 0.18, 1.5), CFrame.new(0, 0.63, 0), DARK, Enum.Material.Metal)
    end

    attachWeapon(folder, player, character, profile)

    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("BasePart") then object:SetAttribute("TintaCosmetic", true) end
    end
end

return CharacterStyleService
