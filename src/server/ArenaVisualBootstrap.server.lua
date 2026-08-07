local Workspace = game:GetService("Workspace")
local ArenaVisualService = require(script.Parent.Services.ArenaVisualService)

local VALID_ARENAS = { NeonDistrict = true, InkDepot = true, RooftopRush = true }

local function connectArena(arena)
    arena.ChildAdded:Connect(function(child)
        if not VALID_ARENAS[child.Name] then return end
        task.defer(function()
            local floor = child:FindFirstChild("Floor")
            if not floor or not floor:IsA("BasePart") then return end
            ArenaVisualService.Decorate({ Origin = floor.Position + Vector3.new(0, 3, 0) }, Workspace:GetAttribute("TintaFinalShooterMode"))
        end)
    end)
end

local function boot()
    local world = Workspace:WaitForChild("TintaFinalWorld")
    local arena = world:WaitForChild("Arena")
    connectArena(arena)
end

task.spawn(boot)
