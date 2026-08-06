-- Removes every legacy ScreenGui from the previous experience.
-- Only interfaces whose name belongs to Tinta Final are allowed to remain.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function isAllowed(gui)
    local name = string.lower(gui.Name)
    return string.find(name, "tintafinal", 1, true) ~= nil
end

local function removeLegacyGui(child)
    if child:IsA("ScreenGui") and not isAllowed(child) then
        child:Destroy()
    end
end

for _, child in ipairs(playerGui:GetChildren()) do
    removeLegacyGui(child)
end

playerGui.ChildAdded:Connect(function(child)
    task.defer(function()
        if child.Parent == playerGui then
            removeLegacyGui(child)
        end
    end)
end)

print("[TintaFinal] Interfaces antiguas y tienda heredada eliminadas.")
