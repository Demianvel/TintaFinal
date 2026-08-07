local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Visual = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualConfig"))

local order = {"MainMenu", "Loading", "Lobby", "Round1", "Round2", "Shop"}
local preload = {}

for _, key in ipairs(order) do
    local id = tonumber(Visual.Assets[key]) or 0
    if id > 0 then
        local image = Instance.new("ImageLabel")
        image.Name = "Preload_" .. key
        image.BackgroundTransparency = 1
        image.Image = "rbxassetid://" .. tostring(id)
        image.Size = UDim2.fromOffset(1, 1)
        table.insert(preload, image)
    end
end

local ok, err = pcall(function()
    ContentProvider:PreloadAsync(preload)
end)

for _, object in ipairs(preload) do
    object:Destroy()
end

if ok then
    script:SetAttribute("VisualAssetsReady", true)
    print(string.format("[TintaFinal] %d escenas visuales precargadas.", #preload))
else
    script:SetAttribute("VisualAssetsReady", false)
    warn("[TintaFinal] La precarga visual no pudo completarse; Roblox cargará los assets bajo demanda: " .. tostring(err))
end
