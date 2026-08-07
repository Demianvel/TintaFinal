local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Visual = require(shared:WaitForChild("VisualConfig"))
local Resolver = require(shared:WaitForChild("VisualAssetResolver"))

local knownIds = {}
for _, id in pairs(Visual.Assets or {}) do
    id = tonumber(id) or 0
    if id > 0 then knownIds[id] = true end
end

local function bindImage(imageLabel, forcedId)
    if not imageLabel:IsA("ImageLabel") and not imageLabel:IsA("ImageButton") then return end
    local id = tonumber(forcedId)
    if not id then
        id = tonumber(string.match(tostring(imageLabel.Image or ""), "(%d+)") or "")
    end
    if id and knownIds[id] then
        task.spawn(function()
            Resolver.Apply(imageLabel, id, 1.5)
        end)
    end
end

local playerGui = player:WaitForChild("PlayerGui")

local function attachToCompetitiveUi(gui)
    if gui.Name ~= "TintaFinalCompetitiveUI" then return end

    local lobbyRoot = gui:FindFirstChild("LobbyRoot", true)
    if lobbyRoot then
        local lobbyArt = lobbyRoot:FindFirstChild("LobbyArt", true)
        if lobbyArt and lobbyArt:IsA("ImageLabel") then
            bindImage(lobbyArt, Visual.Assets.Lobby)
        end
    end

    for _, descendant in ipairs(gui:GetDescendants()) do
        if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            bindImage(descendant)
        end
    end

    gui.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            task.defer(bindImage, descendant)
        end
    end)
end

for _, child in ipairs(playerGui:GetChildren()) do
    attachToCompetitiveUi(child)
end

playerGui.ChildAdded:Connect(function(child)
    if child.Name == "TintaFinalCompetitiveUI" then
        task.wait(0.1)
        attachToCompetitiveUi(child)
    end
end)

task.spawn(function()
    Resolver.Preload({
        Visual.Assets.MainMenu,
        Visual.Assets.Loading,
        Visual.Assets.Lobby,
        Visual.Assets.Round1,
        Visual.Assets.Round2,
        Visual.Assets.Shop,
    })
end)

print("[TintaFinal] Binder de imágenes visuales activo.")
