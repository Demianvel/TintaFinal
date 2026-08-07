local ArenaVisualService = require(script.Parent:WaitForChild("Services"):WaitForChild("ArenaVisualService"))

local ARENA_ORIGIN = Vector3.new(0, 0, 850)
local refreshToken = 0

local function refreshStyle()
    refreshToken += 1
    local token = refreshToken
    task.delay(0.20, function()
        if token ~= refreshToken then return end
        local world = workspace:FindFirstChild("TintaFinalWorld")
        if not world then return end

        local mode = tostring(workspace:GetAttribute("TintaFinalShooterMode") or "Lobby")
        if mode == "Lobby" then
            ArenaVisualService.DecorateLobby()
        else
            local arenaFolder = world:FindFirstChild("Arena")
            if arenaFolder and #arenaFolder:GetChildren() > 0 then
                ArenaVisualService.Decorate({Origin = ARENA_ORIGIN}, mode)
            end
        end
    end)
end

workspace:GetAttributeChangedSignal("TintaFinalShooterMode"):Connect(refreshStyle)
workspace.ChildAdded:Connect(function(child)
    if child.Name == "TintaFinalWorld" then refreshStyle() end
end)

task.spawn(function()
    workspace:WaitForChild("TintaFinalWorld", 20)
    refreshStyle()
end)

print("[TintaFinal] Estilo 3D neón PvP sincronizado con el modo de juego.")