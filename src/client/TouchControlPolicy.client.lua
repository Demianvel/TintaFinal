local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- En teléfono usamos exclusivamente el joystick/botones de Tinta Final.
-- Así Roblox no dibuja un segundo thumbstick o botón de salto encima del HUD propio.
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    task.spawn(function()
        local playerScripts = player:WaitForChild("PlayerScripts")
        local playerModuleScript = playerScripts:WaitForChild("PlayerModule", 12)
        if not playerModuleScript then return end

        local ok, playerModule = pcall(require, playerModuleScript)
        if not ok or not playerModule or type(playerModule.GetControls) ~= "function" then return end

        local controls = playerModule:GetControls()
        if controls and type(controls.Disable) == "function" then
            controls:Disable()
            print("[TintaFinal] Controles móviles Roblox desactivados; joystick Tinta Final activo.")
        end
    end)
end
