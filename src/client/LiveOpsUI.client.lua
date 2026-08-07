local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetSnapshot = remotes:WaitForChild("GetSnapshot")
local Spin = remotes:WaitForChild("Spin")
local ClaimBattlePass = remotes:WaitForChild("ClaimBattlePass")
local BuyPremiumWithTintaMoney = remotes:WaitForChild("BuyPremiumWithTintaMoney")
local ProfileState = remotes:WaitForChild("ProfileState")
local GlobalAnnouncement = remotes:FindFirstChild("GlobalAnnouncement")

local snapshot = {}
pcall(function() snapshot = GetSnapshot:InvokeServer() or {} end)
local profile = snapshot.Profile or {}
local config = snapshot.Config or {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)
local DARK = Color3.fromRGB(7, 9, 16)
local PANEL = Color3.fromRGB(15, 19, 31)
local WHITE = Color3.fromRGB(248, 250, 255)
local MUTED = Color3.fromRGB(165, 180, 210)

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalLiveOpsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
end

local function stroke(object, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CYAN
    s.Transparency = transparency or 0.4
    s.Thickness = thickness or 1.3
    s.Parent = object
end

local function frame(parent, size, position, color, transparency)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = position or UDim2.new()
    f.BackgroundColor3 = color or PANEL
    f.BackgroundTransparency = transparency or 0.03
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 11)
    return f
end

local function label(parent, text, size, position, textSize, color, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position or UDim2.new()
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextSize = textSize or 14
    l.TextColor3 = color or WHITE
    l.TextWrapped = true
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function button(parent, text, size, color)
    local b = Instance.new("TextButton")
    b.Size = size
    b.BackgroundColor3 = color or CYAN
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Font = Enum.Font.GothamBlack
    b.Text = text
    b.TextColor3 = WHITE
    b.TextScaled = true
    b.Parent = parent
    corner(b, 9)
    stroke(b, WHITE, 0.72, 1)
    return b
end

local toast = label(gui, "", UDim2.fromOffset(470, 44), UDim2.new(0.5, -235, 1, -58), 13, WHITE, Enum.TextXAlignment.Center)
toast.BackgroundColor3 = DARK
toast.BackgroundTransparency = 0.04
toast.Visible = false
corner(toast, 10)
stroke(toast, CYAN, 0.35, 1)
local toastToken = 0

local function showToast(text, color)
    toastToken += 1
    local token = toastToken
    toast.Text = tostring(text or "")
    toast.TextColor3 = color or WHITE
    toast.TextTransparency = 0
    toast.Visible = true
    task.delay(2.8, function()
        if token ~= toastToken then return end
        TweenService:Create(toast, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        task.wait(0.2)
        if token == toastToken then toast.Visible = false end
    end)
end

-- Un único botón chico reemplaza BP / SPIN / DM / ADM y el bloque Live Ops completo.
local menuButton = button(gui, "EXTRAS", UDim2.fromOffset(76, 38), MAGENTA)
menuButton.AnchorPoint = Vector2.new(1, 0)
menuButton.Position = UDim2.new(1, -18, 0, 84)

local quick = frame(gui, UDim2.fromOffset(200, 118), UDim2.new(1, -218, 0, 128), DARK, 0.04)
quick.Visible = false
stroke(quick, MAGENTA, 0.24, 1.3)
local passButton = button(quick, "PASE DE TINTA", UDim2.new(1, -16, 0, 45), MAGENTA)
passButton.Position = UDim2.new(0, 8, 0, 8)
local spinButton = button(quick, "RULETA", UDim2.new(1, -16, 0, 45), ORANGE)
spinButton.Position = UDim2.new(0, 8, 0, 63)

local panel = frame(gui, UDim2.new(0.72, 0, 0.72, 0), UDim2.new(0.14, 0, 0.14, 0), DARK, 0.01)
panel.Visible = false
stroke(panel, MAGENTA, 0.15, 2)
local panelTitle = label(panel, "TINTA FINAL", UDim2.new(1, -78, 0, 50), UDim2.new(0, 18, 0, 7), 21, WHITE)
local close = button(panel, "X", UDim2.fromOffset(44, 40), Color3.fromRGB(90, 40, 65))
close.Position = UDim2.new(1, -56, 0, 10)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -28, 1, -70)
content.Position = UDim2.new(0, 14, 0, 60)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = MAGENTA
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = content

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function row(titleText, description, actionText, actionColor, callback, height)
    local r = frame(content, UDim2.new(1, -8, 0, height or 82), nil, PANEL, 0.02)
    stroke(r, actionColor or CYAN, 0.64, 1)
    label(r, titleText, UDim2.new(0.63, -12, 0, 28), UDim2.new(0, 12, 0, 8), 15, WHITE)
    label(r, description or "", UDim2.new(0.63, -12, 0, 36), UDim2.new(0, 12, 0, 38), 11, MUTED)
    if actionText then
        local a = button(r, actionText, UDim2.new(0.30, 0, 0, 50), actionColor or CYAN)
        a.Position = UDim2.new(0.68, 0, 0, 15)
        if callback then a.Activated:Connect(callback) end
    end
    return r
end

local function rewardText(reward)
    if type(reward) ~= "table" then return "Recompensa" end
    if reward.Type == "TintaMoney" then return tostring(reward.Amount or 0) .. " Tinta Money" end
    if reward.Type == "SpinTicket" then return tostring(reward.Amount or 1) .. " ticket(s) de ruleta" end
    return tostring(reward.Id or reward.Type or "Recompensa")
end

local function openBattlePass()
    quick.Visible = false
    panel.Visible = true
    panelTitle.Text = "PASE DE TINTA"
    clearContent()

    local bp = config.BattlePass or {}
    local tier = tonumber(profile.BattlePassTier) or 1
    local xp = tonumber(profile.BattlePassXP) or 0
    local perTier = tonumber(bp.XPPerTier) or 100
    row("NIVEL " .. tier .. " / " .. tostring(bp.MaxTier or 100), string.format("XP de temporada: %d · cada nivel requiere %d XP", xp, perTier), nil, MAGENTA)

    if profile.PremiumPass then
        row("PISTA PREMIUM ACTIVA", "Las recompensas premium están habilitadas en tu cuenta.", nil, ORANGE)
    else
        local tmPrice = tonumber(config.Economy and config.Economy.BattlePassTintaMoneyPrice) or 200000
        row("ACTIVAR PISTA PREMIUM", string.format("Precio: %d Tinta Money", tmPrice), "ACTIVAR", ORANGE, function()
            local ok, message, updated = BuyPremiumWithTintaMoney:InvokeServer()
            if updated then profile = updated end
            showToast(message, ok and ORANGE or MAGENTA)
            if ok then task.defer(openBattlePass) end
        end)
    end

    local tiers = {}
    for tierId in pairs(bp.FreeRewards or {}) do tiers[tonumber(tierId)] = true end
    for tierId in pairs(bp.PremiumRewards or {}) do tiers[tonumber(tierId)] = true end
    local ordered = {}
    for tierId in pairs(tiers) do table.insert(ordered, tierId) end
    table.sort(ordered)

    for _, tierId in ipairs(ordered) do
        local freeReward = bp.FreeRewards and bp.FreeRewards[tierId]
        local premiumReward = bp.PremiumRewards and bp.PremiumRewards[tierId]
        if freeReward then
            row("NIVEL " .. tierId .. " · GRATIS", rewardText(freeReward), "RECLAMAR", CYAN, function()
                local ok, message, updated = ClaimBattlePass:InvokeServer(tierId, false)
                if updated then profile = updated end
                showToast(message, ok and CYAN or MAGENTA)
            end)
        end
        if premiumReward then
            row("NIVEL " .. tierId .. " · PREMIUM", rewardText(premiumReward), "RECLAMAR", ORANGE, function()
                local ok, message, updated = ClaimBattlePass:InvokeServer(tierId, true)
                if updated then profile = updated end
                showToast(message, ok and ORANGE or MAGENTA)
            end)
        end
    end
end

local function openSpin()
    quick.Visible = false
    panel.Visible = true
    panelTitle.Text = "RULETA DE TINTA"
    clearContent()
    row("TICKETS", tostring(profile.SpinTickets or 0) .. " disponibles", nil, ORANGE)
    row("GIRO COMPETITIVO", "Podés obtener Tinta Money, cosméticos, armas y utilidades.", "GIRAR", MAGENTA, function()
        local ok, message, result, updated = Spin:InvokeServer()
        if updated then profile = updated end
        if ok and result then
            showToast("PREMIO " .. tostring(result.Rarity or "") .. " · " .. tostring(result.RewardId or ""), ORANGE)
        else
            showToast(message, MAGENTA)
        end
    end, 96)
end

local function activeCombat()
    return player:GetAttribute("InShooterMatch") == true or player:GetAttribute("ShooterActive") == true
end

local function refreshVisibility()
    local visible = not activeCombat()
    menuButton.Visible = visible
    if not visible then
        quick.Visible = false
        panel.Visible = false
    end
end

menuButton.Activated:Connect(function()
    if activeCombat() then return end
    quick.Visible = not quick.Visible
    if quick.Visible then panel.Visible = false end
end)
passButton.Activated:Connect(openBattlePass)
spinButton.Activated:Connect(openSpin)
close.Activated:Connect(function() panel.Visible = false end)

ProfileState.OnClientEvent:Connect(function(updated)
    if type(updated) == "table" then profile = updated end
end)

if GlobalAnnouncement then
    GlobalAnnouncement.OnClientEvent:Connect(function(text, category)
        showToast("[" .. tostring(category or "GLOBAL") .. "] " .. tostring(text), ORANGE)
    end)
end

player:GetAttributeChangedSignal("InShooterMatch"):Connect(refreshVisibility)
player:GetAttributeChangedSignal("ShooterActive"):Connect(refreshVisibility)
refreshVisibility()

print("[TintaFinal] Menú compacto activo: EXTRAS abre Pase de Tinta y Ruleta sin tapar el lobby.")
