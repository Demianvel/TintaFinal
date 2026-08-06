local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetSnapshot = remotes:WaitForChild("GetSnapshot")
local CastVote = remotes:WaitForChild("CastVote")
local ShopPurchase = remotes:WaitForChild("ShopPurchase")
local Spin = remotes:WaitForChild("Spin")
local ToggleAFK = remotes:WaitForChild("ToggleAFK")
local SelectWeapon = remotes:WaitForChild("SelectWeapon")
local GameState = remotes:WaitForChild("GameState")
local ProfileState = remotes:WaitForChild("ProfileState")
local Victory = remotes:WaitForChild("Victory")

local profile
local config
local currentState

local gui = Instance.new("ScreenGui")
gui.Name = "TintaFinalUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui
local function updateScale()
    local camera = workspace.CurrentCamera
    local width = camera and camera.ViewportSize.X or 1280
    scale.Scale = math.clamp(width / 1280, 0.68, 1)
end
updateScale()

local function corner(object,radius)
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,radius or 10) c.Parent=object
end
local function stroke(object,color,transparency)
    local s=Instance.new("UIStroke") s.Thickness=1.5 s.Color=color s.Transparency=transparency or 0.3 s.Parent=object
end
local function frame(parent,size,pos)
    local f=Instance.new("Frame") f.Size=size f.Position=pos f.BackgroundColor3=Color3.fromRGB(9,12,22) f.BackgroundTransparency=0.08 f.BorderSizePixel=0 f.Parent=parent corner(f,12) return f
end
local function label(parent,text,size,pos,fontSize)
    local l=Instance.new("TextLabel") l.Size=size l.Position=pos l.BackgroundTransparency=1 l.Font=Enum.Font.GothamBold l.Text=text l.TextColor3=Color3.fromRGB(245,248,255) l.TextSize=fontSize or 16 l.TextWrapped=true l.Parent=parent return l
end
local function button(parent,text,size,color)
    local b=Instance.new("TextButton") b.Size=size b.BackgroundColor3=color or Color3.fromRGB(0,160,180) b.BorderSizePixel=0 b.Font=Enum.Font.GothamBold b.Text=text b.TextColor3=Color3.new(1,1,1) b.TextScaled=true b.Parent=parent corner(b,9) return b
end

local top=frame(gui,UDim2.new(1,-24,0,64),UDim2.new(0,12,0,12))
stroke(top,Color3.fromRGB(0,226,239),0.25)
label(top,"TINTA FINAL · ARENA SHOOTER",UDim2.new(0.42,0,1,0),UDim2.new(0,18,0,0),21)
local won=label(top,"₩ 0",UDim2.new(0,145,1,0),UDim2.new(0.48,0,0,0),16)
local level=label(top,"NIVEL 1",UDim2.new(0,130,1,0),UDim2.new(0.63,0,0,0),16)
local wins=label(top,"VICTORIAS 0",UDim2.new(0,160,1,0),UDim2.new(0.78,0,0,0),16)

local status=frame(gui,UDim2.new(0,460,0,72),UDim2.new(0.5,-230,0,88))
stroke(status,Color3.fromRGB(255,45,145),0.35)
local statusTitle=label(status,"LOBBY",UDim2.new(1,-20,0,34),UDim2.new(0,10,0,5),18)
statusTitle.TextXAlignment=Enum.TextXAlignment.Center
local statusInfo=label(status,"Preparando partida shooter...",UDim2.new(1,-20,0,28),UDim2.new(0,10,0,38),13)
statusInfo.TextXAlignment=Enum.TextXAlignment.Center
statusInfo.TextColor3=Color3.fromRGB(180,194,220)

local menu=frame(gui,UDim2.new(0,180,0,310),UDim2.new(0,14,0.5,-145))
local menuInner=Instance.new("Frame") menuInner.Size=UDim2.new(1,-16,1,-16) menuInner.Position=UDim2.new(0,8,0,8) menuInner.BackgroundTransparency=1 menuInner.Parent=menu
local menuLayout=Instance.new("UIListLayout") menuLayout.Padding=UDim.new(0,8) menuLayout.Parent=menuInner
local arsenalButton=button(menuInner,"ARSENAL",UDim2.new(1,0,0,48),Color3.fromRGB(0,155,175))
local shopButton=button(menuInner,"TIENDA",UDim2.new(1,0,0,48),Color3.fromRGB(210,36,120))
local rewardsButton=button(menuInner,"RECOMPENSAS",UDim2.new(1,0,0,48),Color3.fromRGB(225,115,35))
local afkButton=button(menuInner,"SALA AFK",UDim2.new(1,0,0,48),Color3.fromRGB(55,125,100))
local closeButton=button(menuInner,"CERRAR PANEL",UDim2.new(1,0,0,48),Color3.fromRGB(65,70,90))

local panel=frame(gui,UDim2.new(0,560,0,430),UDim2.new(0.5,-280,0.5,-190))
panel.Visible=false
stroke(panel,Color3.fromRGB(255,45,145),0.25)
local panelTitle=label(panel,"PANEL",UDim2.new(1,-30,0,52),UDim2.new(0,15,0,5),24)
local content=Instance.new("ScrollingFrame") content.Size=UDim2.new(1,-30,1,-76) content.Position=UDim2.new(0,15,0,62) content.BackgroundTransparency=1 content.BorderSizePixel=0 content.ScrollBarThickness=5 content.AutomaticCanvasSize=Enum.AutomaticSize.Y content.CanvasSize=UDim2.new() content.Parent=panel
local contentLayout=Instance.new("UIListLayout") contentLayout.Padding=UDim.new(0,10) contentLayout.Parent=content

local votePanel=frame(gui,UDim2.new(0,650,0,185),UDim2.new(0.5,-325,1,-205))
votePanel.Visible=false
local voteTitle=label(votePanel,"VOTÁ EL PRÓXIMO MAPA",UDim2.new(1,-20,0,40),UDim2.new(0,10,0,5),20) voteTitle.TextXAlignment=Enum.TextXAlignment.Center
local voteHolder=Instance.new("Frame") voteHolder.Size=UDim2.new(1,-20,0,120) voteHolder.Position=UDim2.new(0,10,0,50) voteHolder.BackgroundTransparency=1 voteHolder.Parent=votePanel
local voteLayout=Instance.new("UIListLayout") voteLayout.FillDirection=Enum.FillDirection.Horizontal voteLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center voteLayout.Padding=UDim.new(0,10) voteLayout.Parent=voteHolder
local voteButtons={}
for i=1,3 do
    local b=button(voteHolder,"MAPA",UDim2.new(0,200,1,0),i==1 and Color3.fromRGB(0,155,175) or (i==2 and Color3.fromRGB(210,36,120) or Color3.fromRGB(225,115,35)))
    voteButtons[i]=b
    b.Activated:Connect(function()
        local mapId=currentState and currentState.OfferedGames and currentState.OfferedGames[i]
        if mapId then CastVote:InvokeServer(mapId) end
    end)
end

local toast=label(gui,"",UDim2.new(0,430,0,48),UDim2.new(0.5,-215,1,-62),15)
toast.BackgroundColor3=Color3.fromRGB(10,12,20) toast.BackgroundTransparency=0.08 toast.TextXAlignment=Enum.TextXAlignment.Center toast.Visible=false corner(toast,10)
local function showToast(text)
    toast.Text=tostring(text) toast.TextTransparency=0 toast.Visible=true
    task.delay(2.4,function() if toast.Visible then TweenService:Create(toast,TweenInfo.new(0.25),{TextTransparency=1}):Play() task.wait(0.3) toast.Visible=false end end)
end

local mapNames={NeonDistrict="DISTRITO NEÓN",InkDepot="DEPÓSITO DE TINTA",RooftopRush="AZOTEAS NEÓN"}
local function clearContent()
    for _,child in ipairs(content:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
end
local function row(text,desc,actionText,color,callback)
    local r=frame(content,UDim2.new(1,-8,0,88),UDim2.new())
    label(r,text,UDim2.new(0.60,-10,0,32),UDim2.new(0,12,0,8),17)
    local d=label(r,desc,UDim2.new(0.60,-10,0,40),UDim2.new(0,12,0,42),12) d.TextColor3=Color3.fromRGB(180,192,215)
    if actionText then
        local a=button(r,actionText,UDim2.new(0.34,0,0,60),color) a.Position=UDim2.new(0.64,0,0,14)
        if callback then a.Activated:Connect(callback) end
    end
    return r
end

local function refreshTop()
    if not profile then return end
    won.Text="₩ "..tostring(profile.Won or 0)
    level.Text="NIVEL "..tostring(profile.Level or 1)
    wins.Text="VICTORIAS "..tostring(profile.Wins or 0)
end

local function openArsenal()
    panel.Visible=true panelTitle.Text="ARSENAL" clearContent()
    for _,weaponId in ipairs(config.Shooter.WeaponOrder) do
        local def=config.Weapons[weaponId]
        local unlocked=profile.Inventory and profile.Inventory[weaponId]
        local selected=profile.SelectedWeapon==weaponId
        row(def.DisplayName,string.format("Daño %d · Cargador %d · %s",def.Damage,def.Magazine,def.Automatic and "Automática" or "Semiautomática"),selected and "EQUIPADA" or (unlocked and "EQUIPAR" or "BLOQUEADA"),def.Accent,function()
            if not unlocked then showToast("Desbloqueala desde la tienda.") return end
            local ok,msg,newProfile=SelectWeapon:InvokeServer(weaponId)
            if newProfile then profile=newProfile refreshTop() openArsenal() end
            showToast(msg)
        end)
    end
end

local function openShop()
    panel.Visible=true panelTitle.Text="TIENDA SHOOTER" clearContent()
    for _,itemId in ipairs(config.ShopOrder) do
        local item=config.Shop[itemId]
        local owned=item.Type=="Weapon" and profile.Inventory and profile.Inventory[item.WeaponId or itemId]
        local action=owned and "COMPRADA" or ((item.Currency=="Gems" and "💎 " or "₩ ")..tostring(item.Price))
        row(item.DisplayName,item.Description,action,item.Type=="Weapon" and Color3.fromRGB(210,36,120) or Color3.fromRGB(0,155,175),function()
            if owned then showToast("Ya tenés este objeto.") return end
            local ok,msg,newProfile=ShopPurchase:InvokeServer(itemId)
            if newProfile then profile=newProfile refreshTop() openShop() end
            showToast(msg)
        end)
    end
end

local function openRewards()
    panel.Visible=true panelTitle.Text="RECOMPENSAS" clearContent()
    row("GIRO DE RECOMPENSA","Usa un ticket o Won obtenidos jugando.","GIRAR",Color3.fromRGB(225,115,35),function()
        local ok,msg,result,newProfile=Spin:InvokeServer()
        if newProfile then profile=newProfile refreshTop() end
        showToast(result and (msg.." · "..tostring(result.RewardId)) or msg)
    end)
    row("VICTORIA SHOOTER","Ganá rondas para recibir Won y XP.",nil)
    row("HEADSHOTS","Los impactos a la cabeza causan daño adicional.",nil)
end

arsenalButton.Activated:Connect(openArsenal)
shopButton.Activated:Connect(openShop)
rewardsButton.Activated:Connect(openRewards)
afKButton=afkButton
afKButton.Activated:Connect(function()
    local ok,msg=ToggleAFK:InvokeServer()
    showToast(msg)
end)
closeButton.Activated:Connect(function() panel.Visible=false end)

local function updateState(data)
    currentState=data
    local phase=tostring(data.Phase or "Lobby")
    statusTitle.Text=string.upper(phase)
    statusInfo.Text=tostring(data.Announcement or "")
    votePanel.Visible=phase=="Voting"
    if phase=="Voting" then
        for i,b in ipairs(voteButtons) do
            local mapId=data.OfferedGames and data.OfferedGames[i]
            b.Text=mapId and ((mapNames[mapId] or mapId).."\n"..tostring((data.Votes and data.Votes[mapId]) or 0).." VOTOS") or "-"
        end
    end
    local combat=phase=="Playing" or phase=="Loading"
    menu.Visible=not combat
    panel.Visible=panel.Visible and not combat
end

ProfileState.OnClientEvent:Connect(function(newProfile) profile=newProfile refreshTop() end)
GameState.OnClientEvent:Connect(updateState)
Victory.OnClientEvent:Connect(function(message) showToast(message or "¡Victoria!") end)

local success,snapshot=pcall(function() return GetSnapshot:InvokeServer() end)
if success and type(snapshot)=="table" then
    profile=snapshot.Profile
    config=snapshot.Config
    currentState=snapshot.Game
    refreshTop()
    updateState(currentState or {})
else
    showToast("Conectando con el servidor...")
end

print("[TintaFinal] Lobby shooter cargado.")
