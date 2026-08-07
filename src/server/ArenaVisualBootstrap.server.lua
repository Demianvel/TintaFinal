local Workspace = game:GetService("Workspace")
local ArenaVisualService = require(script.Parent.Services.ArenaVisualService)

local VALID_ARENAS = { NeonDistrict = true, InkDepot = true, RooftopRush = true }

local activeArena

local function decorate(child)
    if not child or not child.Parent or not VALID_ARENAS[child.Name] then return end
    local floor = child:FindFirstChild("Floor")
    if not floor or not floor:IsA("BasePart") then return end
    ArenaVisualService.Decorate(
        { Origin = floor.Position + Vector3.new(0, 3, 0) },
        Workspace:GetAttribute("TintaFinalShooterMode")
    )
end

local function connectArena(arena)
    arena.ChildAdded:Connect(function(child)
        if not VALID_ARENAS[child.Name] then return end
        activeArena = child
        task.defer(decorate, child)
    end)

    arena.ChildRemoved:Connect(function(child)
        if activeArena == child then activeArena = nil end
    end)

    Workspace:GetAttributeChangedSignal("TintaFinalShooterMode"):Connect(function()
        if activeArena and activeArena.Parent then
            task.defer(decorate, activeArena)
        end
    end)
end

local function boot()
    local world = Workspace:WaitForChild("TintaFinalWorld")
    local arena = world:WaitForChild("Arena")
    connectArena(arena)

    for _, child in ipairs(arena:GetChildren()) do
        if VALID_ARENAS[child.Name] then
            activeArena = child
            task.defer(decorate, child)
            break
        end
    end
end

task.spawn(boot)
