local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetSnapshot = remotes:WaitForChild("GetSnapshot")
local Spin = remotes:WaitForChild("Spin")
local ClaimBattlePass = remotes:WaitForChild("ClaimBattlePass")
local AdminCommand = remotes:WaitForChild("AdminCommand")
local GetAdminState = remotes:WaitForChild("GetAdminState")
local SendDirectMessage = remotes:WaitForChild("SendDirectMessage")
local WeatherState = remotes:WaitForChild("WeatherState")
local UniverseEventState = remotes:WaitForChild("UniverseEventState")
local GlobalAnnouncement = remotes:WaitForChild("GlobalAnnouncement")
local DirectMessage = remotes:WaitForChild("DirectMessage")
local AdminFeedback = remotes:WaitForChild("AdminFeedback")
local ProfileState = remotes:WaitForChild("ProfileState")

local snapshot = GetSnapshot:InvokeServer()
local profile = snapshot and snapshot.Profile or {}
local config = snapshot and snapshot.Config or {}
local adminState = GetAdminState:InvokeServer()
local liveState = snapshot and snapshot.LiveOps or {}

local CYAN = Color3.fromRGB(0, 226, 239)
local MAGENTA = Color3.fromRGB(255, 45, 145)
local ORANGE = Color3.fromRGB(255, 145, 25)
local DARK = Color3.fromRGB(8, 10, 18)
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
    s.Thickness = thickness or 1.4
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
    return b
end

local function textbox(parent, placeholder, size)
    local box = Instance.new("TextBox")
    box.Size = size
    box.BackgroundColor3 = Color3.fromRGB(22, 27, 43)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = MUTED
    box.Text = ""
    box.TextColor3 = WHITE
    box.TextSize = 14
    box.Font = Enum.Font.GothamMedium
    box.ClearTextOnFocus = false
    box.Parent = parent
    corner(box, 8)
    stroke(box, CYAN, 0.7, 1)
    return box
end

local toast = label(gui, "", UDim2.new(0, 570, 0, 56), UDim2.new(0.5, -285, 0, 90), 15, WHITE, Enum.TextXAlignment.Center)
toast.BackgroundColor3 = DARK
toast.BackgroundTransparency = 0.02
toast.Visible = false
corner(toast, 10)
stroke(toast, CYAN, 0.25, 1.5)
local toastToken = 0

local function showToast(text, color)
    toastToken += 1
    local token = toastToken
    toast.Text = tostring(text or "")
    toast.TextColor3 = color or WHITE
    toast.TextTransparency = 0
    toast.Visible = true
    task.delay(3.5, function()
        if token ~= toastToken then return end
        TweenService:Create(toast, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        task.wait(0.3)
        if token == toastToken then toast.Visible = false end
    end)
end

local dock = frame(gui, UDim2.new(0, 250, 0, 168), UDim2.new(1, -266, 0, 92), DARK, 0.03)
stroke(dock, MAGENTA, 0.2, 1.5)
label(dock, "LIVE OPS", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 8), 17, WHITE, Enum.TextXAlignment.Center)
local weatherLabel = label(dock, "CLIMA · ...", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 40), 11, CYAN, Enum.TextXAlignment.Center)
local eventLabel = label(dock, "EVENTO · SIN EVENTO", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 63), 11, ORANGE, Enum.TextXAlignment.Center)
local voiceLabel = label(dock, "MIC · VERIFICANDO", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 86), 11, MUTED, Enum.TextXAlignment.Center)

local dockButtons = Instance.new("Frame")
dockButtons.Size = UDim2.new(1, -16, 0, 48)
dockButtons.Position = UDim2.new(0, 8, 1, -56)
dockButtons.BackgroundTransparency = 1
dockButtons.Parent = dock
local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockLayout.Padding = UDim.new(0, 5)
dockLayout.Parent = dockButtons

local bpButton = button(dockButtons, "BP", UDim2.new(0, 52, 0, 44), MAGENTA)
local spinButton = button(dockButtons, "SPIN", UDim2.new(0, 52, 0, 44), ORANGE)
local dmButton = button(dockButtons, "DM", UDim2.new(0, 52, 0, 44), CYAN)
local adminButton = button(dockButtons, "ADM", UDim2.new(0, 52, 0, 44), Color3.fromRGB(120, 65, 220))
adminButton.Visible = adminState and adminState.CanModerate == true

local panel = frame(gui, UDim2.new(0, 760, 0, 530), UDim2.new(0.5, -380, 0.5, -245), DARK, 0.01)
panel.Visible = false
stroke(panel, MAGENTA, 0.15, 2)
local panelTitle = label(panel, "TINTA FINAL", UDim2.new(1, -80, 0, 54), UDim2.new(0, 20, 0, 8), 23, WHITE)
local close = button(panel, "X", UDim2.new(0, 46, 0, 42), Color3.fromRGB(90, 40, 65))
close.Position = UDim2.new(1, -60, 0, 11)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -32, 1, -76)
content.Position = UDim2.new(0, 16, 0, 66)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = MAGENTA
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 9)
contentLayout.Parent = content

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function row(titleText, description, actionText, actionColor, callback, height)
    local r = frame(content, UDim2.new(1, -8, 0, height or 90), nil, PANEL, 0.01)
    stroke(r, actionColor or CYAN, 0.63, 1)
    label(r, titleText, UDim2.new(0.62, -12, 0, 30), UDim2.new(0, 14, 0, 8), 16, WHITE)
    label(r, description or "", UDim2.new(0.62, -12, 0, 42), UDim2.new(0, 14, 0, 40), 11, MUTED)
    if actionText then
        local a = button(r, actionText, UDim2.new(0.31, 0, 0, 58), actionColor or CYAN)
        a.Position = UDim2.new(0.66, 0, 0, 15)
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
    panel.Visible = true
    panelTitle.Text = "BATTLE PASS · TEMPORADA"
    clearContent()

    local bp = config.BattlePass or {}
    local tier = tonumber(profile.BattlePassTier) or 1
    local xp = tonumber(profile.BattlePassXP) or 0
    local perTier = tonumber(bp.XPPerTier) or 100
    row("NIVEL " .. tier .. " / " .. tostring(bp.MaxTier or 50), string.format("XP de temporada: %d · próximo nivel cada %d XP", xp, perTier), nil, MAGENTA)

    local gamePasses = config.GamePasses and config.GamePasses.Passes or {}
    local premiumPass = gamePasses.BattlePassPremium
    if profile.PremiumPass then
        row("PISTA PREMIUM ACTIVA", "Tu cuenta ya tiene acceso a las recompensas premium.", nil, ORANGE)
    elseif premiumPass and tonumber(premiumPass.GamePassId) and tonumber(premiumPass.GamePassId) > 0 then
        row("DESBLOQUEAR PREMIUM", tostring(premiumPass.PriceRobux or "") .. " Robux · compra única", "COMPRAR", ORANGE, function()
            MarketplaceService:PromptGamePassPurchase(player, tonumber(premiumPass.GamePassId))
        end)
    else
        row("PISTA PREMIUM", "El Game Pass se está sincronizando con Roblox.", nil, ORANGE)
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

    for _, key in ipairs(config.GamePasses and config.GamePasses.PassOrder or {}) do
        if key ~= "BattlePassPremium" then
            local definition = gamePasses[key]
            if definition then
                local owned = player:GetAttribute("GamePass_" .. key) == true
                row(definition.DisplayName, definition.Description, owned and "ACTIVO" or (tostring(definition.PriceRobux or "") .. " R$"), owned and CYAN or MAGENTA, owned and nil or function()
                    local id = tonumber(definition.GamePassId) or 0
                    if id > 0 then MarketplaceService:PromptGamePassPurchase(player, id) else showToast("Game Pass todavía sin ID.", MAGENTA) end
                end)
            end
        end
    end
end

local function openSpin()
    panel.Visible = true
    panelTitle.Text = "RULETA DE TINTA"
    clearContent()
    row("TICKETS", tostring(profile.SpinTickets or 0) .. " disponibles", nil, ORANGE)
    row("GIRO COMPETITIVO", "Premios: Tinta Money, cosméticos, armas y utilidades. Pity para rarezas altas.", "GIRAR", MAGENTA, function()
        local ok, message, result, updated = Spin:InvokeServer()
        if updated then profile = updated end
        if ok and result then
            showToast("PREMIO " .. tostring(result.Rarity) .. " · " .. tostring(result.RewardId), ORANGE)
        else
            showToast(message, MAGENTA)
        end
    end, 106)
end

local function openMessages()
    panel.Visible = true
    panelTitle.Text = "MENSAJES ENTRE JUGADORES"
    clearContent()

    local target = textbox(content, "Usuario, DisplayName o User ID", UDim2.new(1, -8, 0, 52))
    local message = textbox(content, "Mensaje (filtrado por Roblox, máximo 140 caracteres)", UDim2.new(1, -8, 0, 78))
    message.MultiLine = true
    local send = button(content, "ENVIAR MENSAJE", UDim2.new(1, -8, 0, 54), CYAN)
    send.Activated:Connect(function()
        local ok, response = SendDirectMessage:InvokeServer(target.Text, message.Text)
        showToast(response, ok and CYAN or MAGENTA)
        if ok then message.Text = "" end
    end)
end

local function adminAction(action, payload)
    local ok, response = AdminCommand:InvokeServer(action, payload)
    showToast(response, ok and CYAN or MAGENTA)
    return ok
end

local function openAdmin()
    adminState = GetAdminState:InvokeServer()
    if not adminState or not adminState.CanModerate then
        showToast("No tenés permisos administrativos.", MAGENTA)
        return
    end

    panel.Visible = true
    panelTitle.Text = "PANEL ADMIN · " .. tostring(adminState.Role)
    clearContent()

    local target = textbox(content, "Jugador / User ID", UDim2.new(1, -8, 0, 50))
    local value = textbox(content, "Valor, arma, motivo o texto", UDim2.new(1, -8, 0, 60))

    if adminState.CanAdmin then
        row("DAR TINTA MONEY", "Entrega saldo al jugador conectado.", "EJECUTAR", ORANGE, function()
            adminAction("GiveMoney", { Target = target.Text, Amount = value.Text })
        end)
        row("DAR ARMA", "Usá el WeaponId exacto, por ejemplo InkRifle o PrismSniper.", "ENTREGAR", CYAN, function()
            adminAction("GiveWeapon", { Target = target.Text, WeaponId = value.Text })
        end)
        row("ANUNCIO GLOBAL", "El texto se filtra con los sistemas oficiales de Roblox.", "PUBLICAR", MAGENTA, function()
            adminAction("Announce", { Text = value.Text })
        end)
    end

    row("EXPULSAR", "Moderación del servidor actual.", "KICK", Color3.fromRGB(190, 75, 60), function()
        adminAction("Kick", { Target = target.Text, Reason = value.Text })
    end)

    if adminState.CanAdmin then
        row("BAN GLOBAL", "Bloquea el User ID en los servidores de Tinta Final.", "BAN", Color3.fromRGB(160, 45, 70), function()
            adminAction("Ban", { Target = target.Text, Reason = value.Text })
        end)
        row("QUITAR BAN", "Elimina un bloqueo persistente.", "UNBAN", Color3.fromRGB(55, 145, 100), function()
            adminAction("Unban", { Target = target.Text })
        end)
    end

    if adminState.IsOwner then
        row("DAR ADMIN", "Solo el Owner puede otorgar este rango.", "ADMIN", Color3.fromRGB(120, 65, 220), function()
            adminAction("SetRole", { Target = target.Text, Role = "Admin" })
        end)
        row("DAR MODERADOR", "Solo el Owner puede otorgar este rango.", "MOD", Color3.fromRGB(70, 105, 210), function()
            adminAction("SetRole", { Target = target.Text, Role = "Moderator" })
        end)
        row("QUITAR RANGO", "Devuelve el usuario al rango Player.", "PLAYER", Color3.fromRGB(80, 90, 110), function()
            adminAction("SetRole", { Target = target.Text, Role = "Player" })
        end)
    end

    if adminState.CanAdmin then
        for weatherId, weather in pairs(adminState.Weather or {}) do
            row("CLIMA · " .. weather.DisplayName, "Aplica este clima global por 10 minutos.", "ACTIVAR", CYAN, function()
                adminAction("Weather", { WeatherId = weatherId, Seconds = 600 })
            end)
        end
        for eventId, event in pairs(adminState.Events or {}) do
            row("EVENTO · " .. event.DisplayName, event.Announcement, "INICIAR", ORANGE, function()
                adminAction("StartEvent", { EventId = eventId, Seconds = 600 })
            end)
        end
        row("DETENER EVENTO", "Finaliza el evento global actual.", "DETENER", MAGENTA, function()
            adminAction("StopEvent", {})
        end)
    end
end

close.Activated:Connect(function() panel.Visible = false end)
bpButton.Activated:Connect(openBattlePass)
spinButton.Activated:Connect(openSpin)
dmButton.Activated:Connect(openMessages)
adminButton.Activated:Connect(openAdmin)

WeatherState.OnClientEvent:Connect(function(state)
    liveState.Weather = state
    weatherLabel.Text = "CLIMA · " .. tostring(state.DisplayName or state.Id or "...")
end)

UniverseEventState.OnClientEvent:Connect(function(state)
    liveState.Event = state
    eventLabel.Text = "EVENTO · " .. tostring(state.DisplayName or "SIN EVENTO")
end)

GlobalAnnouncement.OnClientEvent:Connect(function(text, category)
    showToast("[" .. tostring(category or "GLOBAL") .. "] " .. tostring(text), ORANGE)
end)

DirectMessage.OnClientEvent:Connect(function(fromName, _, text)
    showToast("DM de " .. tostring(fromName) .. ": " .. tostring(text), CYAN)
end)

AdminFeedback.OnClientEvent:Connect(function(ok, text)
    showToast(text, ok and CYAN or MAGENTA)
end)

ProfileState.OnClientEvent:Connect(function(updated)
    profile = updated or profile
end)

if liveState.Weather then
    weatherLabel.Text = "CLIMA · " .. tostring(liveState.Weather.DisplayName or liveState.Weather.Id or "...")
end
if liveState.Event then
    eventLabel.Text = "EVENTO · " .. tostring(liveState.Event.DisplayName or "SIN EVENTO")
end

local okVoice, voiceEnabled = pcall(function()
    local VoiceChatService = game:GetService("VoiceChatService")
    return VoiceChatService:IsVoiceEnabledForUserIdAsync(player.UserId)
end)
voiceLabel.Text = okVoice and (voiceEnabled and "MIC · DISPONIBLE" or "MIC · NO HABILITADO") or "MIC · SEGÚN CUENTA ROBLOX"
voiceLabel.TextColor3 = okVoice and voiceEnabled and CYAN or MUTED
