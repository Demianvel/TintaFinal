local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function activeCombat()
    return player:GetAttribute("InShooterMatch") == true and player:GetAttribute("ShooterActive") == true
end

local function configure(gui)
    if not gui:IsA("ScreenGui") then return end
    local active = activeCombat()

    if gui.Name == "TintaFinalCompetitiveUI" then
        -- Menú, tienda, ranking y ruleta solo fuera de combate/calientamiento.
        gui.Enabled = not active
    elseif gui.Name == "TintaFinalLiveOpsUI" then
        -- Live Ops queda en lobby; no debe tapar disparo/apuntado.
        gui.Enabled = not active
    elseif gui.Name == "TintaFinalUtilityHUD" then
        -- En móvil priorizamos controles fundamentales. En PC las utilidades siguen disponibles durante PvP.
        gui.Enabled = active and not UserInputService.TouchEnabled
    elseif gui.Name == "TintaFinalCinematics" then
        -- Sistema legacy reemplazado por TintaFinalSceneTransition.
        gui.Enabled = false
    elseif gui.Name == "TintaFinalShooterHUD" or gui.Name == "TintaFinalMovementControls" or gui.Name == "TintaFinalSceneTransition" then
        gui.Enabled = true
    end
end

local function refresh()
    for _, child in ipairs(playerGui:GetChildren()) do
        configure(child)
    end
end

playerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") then
        task.defer(configure, child)
    end
end)

player:GetAttributeChangedSignal("InShooterMatch"):Connect(refresh)
player:GetAttributeChangedSignal("ShooterActive"):Connect(refresh)

refresh()
print("[TintaFinal] Orquestador UI: lobby/LiveOps separados del combate.")