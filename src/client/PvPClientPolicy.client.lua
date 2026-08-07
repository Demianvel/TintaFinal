local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = remotes:WaitForChild("GameState")

local function removeVotingUI(root)
    for _, object in ipairs(root:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") then
            local text = string.upper(tostring(object.Text or ""))
            if string.find(text, "VOTÁ EL PRÓXIMO MAPA", 1, true)
                or string.find(text, "VOTACION DE MAPA", 1, true)
                or string.find(text, "VOTACIÓN DE MAPA", 1, true) then
                local parent = object.Parent
                if parent and parent:IsA("GuiObject") then parent.Visible = false end
                object.Visible = false
            end
        end
    end
end

removeVotingUI(playerGui)
playerGui.DescendantAdded:Connect(function()
    task.defer(removeVotingUI, playerGui)
end)

gameState.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    if state.VotingEnabled == false or state.RotationMode == "AUTO" then
        removeVotingUI(playerGui)
    end
end)

print("[TintaFinal] Política PvP activa: sin bots y sin votación de mapas.")
