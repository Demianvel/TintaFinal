local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LiveOpsConfig = require(ReplicatedStorage.Shared.LiveOpsConfig)

local AdminService = {}
local remotes
local deps
local ownerUserId = LiveOpsConfig.Admin.OwnerUserId or 0
local roleStore = DataStoreService:GetDataStore(LiveOpsConfig.Admin.RoleStore)
local banStore = DataStoreService:GetDataStore(LiveOpsConfig.Admin.BanStore)
local requestTimes = {}

local function level(role)
    return LiveOpsConfig.Admin.RoleLevels[role or "Player"] or 0
end

local function resolveOwner()
    if ownerUserId > 0 then return ownerUserId end
    local ok, id = pcall(function()
        return Players:GetUserIdFromNameAsync(LiveOpsConfig.Admin.OwnerUsername)
    end)
    if ok and id and id > 0 then ownerUserId = id end
    return ownerUserId
end

local function isOwnerIdentity(player)
    if not player then return false end
    if ownerUserId > 0 and player.UserId == ownerUserId then return true end
    return string.lower(player.Name) == string.lower(LiveOpsConfig.Admin.OwnerUsername)
end

local function resolveUser(reference)
    reference = tostring(reference or ""):gsub("^@", "")
    local numeric = tonumber(reference)
    if numeric and numeric > 0 then
        local id = math.floor(numeric)
        return id, Players:GetPlayerByUserId(id)
    end
    local lowered = string.lower(reference)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == lowered or string.lower(player.DisplayName) == lowered then
            return player.UserId, player
        end
    end
    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(reference) end)
    if ok and id and id > 0 then return id, nil end
    return nil, nil
end

local function roleForUserId(userId)
    if userId == resolveOwner() then return "Owner" end
    local ok, stored = pcall(function() return roleStore:GetAsync("user_" .. tostring(userId)) end)
    if ok and (stored == "Admin" or stored == "Moderator") then return stored end
    return "Player"
end

local function setPlayerRoleAttribute(player, role)
    if not player then return end
    player:SetAttribute("TintaRole", role)
    player:SetAttribute("TintaIsStaff", level(role) >= level("Moderator"))
    if remotes and remotes:FindFirstChild("AdminState") then
        remotes.AdminState:FireClient(player, AdminService.GetState(player))
    end
end

local function getRole(player)
    if not player then return "Player" end
    if isOwnerIdentity(player) then return "Owner" end
    return tostring(player:GetAttribute("TintaRole") or "Player")
end

local function requireLevel(player, minimum)
    return level(getRole(player)) >= level(minimum)
end

local function throttle(player, key, seconds)
    requestTimes[player] = requestTimes[player] or {}
    local now = os.clock()
    if now - (requestTimes[player][key] or 0) < (seconds or 0.3) then return false end
    requestTimes[player][key] = now
    return true
end

local function setRole(actor, targetReference, role)
    if getRole(actor) ~= "Owner" then return false, "Solo el Owner puede administrar rangos." end
    if role ~= "Admin" and role ~= "Moderator" and role ~= "Player" then return false, "Rango inválido." end
    local targetUserId, targetPlayer = resolveUser(targetReference)
    if not targetUserId then return false, "Usuario no encontrado." end
    if targetUserId == resolveOwner() then return false, "El Owner no puede perder su rango." end

    local ok, err = pcall(function()
        if role == "Player" then
            roleStore:RemoveAsync("user_" .. targetUserId)
        else
            roleStore:SetAsync("user_" .. targetUserId, role)
        end
    end)
    if not ok then return false, "No se pudo guardar el rango: " .. tostring(err) end
    if targetPlayer then setPlayerRoleAttribute(targetPlayer, role) end
    return true, "Rango actualizado a " .. role .. "."
end

local function giveMoney(actor, targetReference, amount)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    amount = math.clamp(math.floor(tonumber(amount) or 0), 1, 10_000_000_000)
    local _, target = resolveUser(targetReference)
    if not target then return false, "El jugador debe estar conectado." end
    deps.ProfileService.AddTintaMoney(target, amount, true)
    if remotes and remotes:FindFirstChild("ProfileState") then
        remotes.ProfileState:FireClient(target, deps.ProfileService.Public(target))
    end
    return true, string.format("Se entregaron %d Tinta Money a %s.", amount, target.Name)
end

local function giveWeapon(actor, targetReference, weaponId)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    weaponId = tostring(weaponId or "")
    if weaponId == "" then return false, "Indicá un arma." end
    local _, target = resolveUser(targetReference)
    if not target then return false, "El jugador debe estar conectado." end
    local weapons = require(ReplicatedStorage.Shared.WeaponDefinitions)
    if not weapons[weaponId] then return false, "Arma inexistente." end
    deps.ProfileService.GrantItem(target, weaponId)
    if remotes and remotes:FindFirstChild("ProfileState") then
        remotes.ProfileState:FireClient(target, deps.ProfileService.Public(target))
    end
    return true, weaponId .. " entregada a " .. target.Name .. "."
end

local function startEvent(actor, eventId, seconds)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    seconds = math.clamp(math.floor(tonumber(seconds) or LiveOpsConfig.Events.DefaultDurationSeconds), 30, 7_200)
    local definition = LiveOpsConfig.Events.Definitions[tostring(eventId)]
    if not definition then return false, "Evento inexistente." end
    deps.UniverseMessagingService.BroadcastEvent({
        Action = "Start",
        Id = tostring(eventId),
        Seconds = seconds,
        EndsAt = workspace:GetServerTimeNow() + seconds,
    })
    return true, definition.DisplayName .. " activado globalmente."
end

local function stopEvent(actor)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    deps.UniverseMessagingService.BroadcastEvent({ Action = "Stop" })
    return true, "Evento global detenido."
end

local function setWeather(actor, weatherId, seconds)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    weatherId = tostring(weatherId or "")
    local definition = LiveOpsConfig.Weather.Profiles[weatherId]
    if not definition then return false, "Clima inexistente." end
    seconds = math.clamp(math.floor(tonumber(seconds) or 600), 30, 7_200)
    deps.WeatherService.SetOverride(weatherId, seconds)
    deps.UniverseMessagingService.BroadcastWeather({ Id = weatherId, Override = true })
    return true, definition.DisplayName .. " aplicado."
end

local function announce(actor, text)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    return deps.UniverseMessagingService.BroadcastAnnouncement(actor, text, "Staff")
end

local function kickPlayer(actor, targetReference, reason)
    if not requireLevel(actor, "Moderator") then return false, "Requiere Moderador." end
    local _, target = resolveUser(targetReference)
    if not target then return false, "Jugador no conectado." end
    if level(getRole(target)) >= level(getRole(actor)) and getRole(actor) ~= "Owner" then
        return false, "No podés expulsar a un rango igual o superior."
    end
    target:Kick("Tinta Final Moderation: " .. tostring(reason or "Expulsado por moderación."))
    return true, "Jugador expulsado."
end

local function banPlayer(actor, targetReference, reason)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    local targetUserId, target = resolveUser(targetReference)
    if not targetUserId then return false, "Usuario no encontrado." end
    if targetUserId == resolveOwner() then return false, "El Owner no puede ser bloqueado." end
    local payload = {
        Active = true,
        Reason = tostring(reason or "Bloqueo administrativo."),
        By = actor.Name,
        At = os.time(),
    }
    local ok, err = pcall(function() banStore:SetAsync("user_" .. targetUserId, payload) end)
    if not ok then return false, "No se pudo guardar el ban: " .. tostring(err) end
    if target then target:Kick("Tinta Final Ban: " .. payload.Reason) end
    return true, "Usuario bloqueado."
end

local function unbanPlayer(actor, targetReference)
    if not requireLevel(actor, "Admin") then return false, "Requiere Admin." end
    local targetUserId = resolveUser(targetReference)
    if not targetUserId then return false, "Usuario no encontrado." end
    local ok, err = pcall(function() banStore:RemoveAsync("user_" .. targetUserId) end)
    if not ok then return false, "No se pudo quitar el ban: " .. tostring(err) end
    return true, "Ban eliminado."
end

function AdminService.GetRole(player)
    return getRole(player)
end

function AdminService.IsAtLeast(player, role)
    return requireLevel(player, role)
end

function AdminService.GetState(player)
    local role = getRole(player)
    local online = {}
    for _, other in ipairs(Players:GetPlayers()) do
        table.insert(online, {
            UserId = other.UserId,
            Username = other.Name,
            DisplayName = other.DisplayName,
            Role = getRole(other),
        })
    end
    return {
        Role = role,
        IsOwner = role == "Owner",
        CanModerate = level(role) >= level("Moderator"),
        CanAdmin = level(role) >= level("Admin"),
        OwnerUsername = LiveOpsConfig.Admin.OwnerUsername,
        Events = LiveOpsConfig.Events.Definitions,
        Weather = LiveOpsConfig.Weather.Profiles,
        OnlinePlayers = online,
    }
end

function AdminService.CheckBan(player)
    if isOwnerIdentity(player) then return false end
    local ok, payload = pcall(function() return banStore:GetAsync("user_" .. player.UserId) end)
    if ok and type(payload) == "table" and payload.Active == true then
        return true, payload
    end
    return false
end

function AdminService.SetupPlayer(player)
    resolveOwner()
    local role = isOwnerIdentity(player) and "Owner" or roleForUserId(player.UserId)
    setPlayerRoleAttribute(player, role)

    player.Chatted:Connect(function(message)
        if string.sub(message, 1, #LiveOpsConfig.Admin.Prefix) ~= LiveOpsConfig.Admin.Prefix then return end
        local success, response = AdminService.ExecuteText(player, message)
        if remotes and remotes:FindFirstChild("AdminFeedback") then
            remotes.AdminFeedback:FireClient(player, success, response)
        end
    end)
end

function AdminService.RemovePlayer(player)
    requestTimes[player] = nil
end

function AdminService.ExecuteStructured(player, action, payload)
    if not throttle(player, "AdminAction", 0.2) then return false, "Esperá un momento." end
    action = tostring(action or "")
    payload = type(payload) == "table" and payload or {}

    if action == "SetRole" then return setRole(player, payload.Target, tostring(payload.Role or "Player")) end
    if action == "GiveMoney" then return giveMoney(player, payload.Target, payload.Amount) end
    if action == "GiveWeapon" then return giveWeapon(player, payload.Target, payload.WeaponId) end
    if action == "StartEvent" then return startEvent(player, payload.EventId, payload.Seconds) end
    if action == "StopEvent" then return stopEvent(player) end
    if action == "Weather" then return setWeather(player, payload.WeatherId, payload.Seconds) end
    if action == "Announce" then return announce(player, payload.Text) end
    if action == "Kick" then return kickPlayer(player, payload.Target, payload.Reason) end
    if action == "Ban" then return banPlayer(player, payload.Target, payload.Reason) end
    if action == "Unban" then return unbanPlayer(player, payload.Target) end
    return false, "Acción administrativa desconocida."
end

function AdminService.ExecuteText(player, message)
    local text = tostring(message or "")
    text = string.sub(text, #LiveOpsConfig.Admin.Prefix + 1)
    local words = string.split(text, " ")
    local command = string.lower(table.remove(words, 1) or "")

    if command == "admin" and string.lower(words[1] or "") == "add" then return setRole(player, words[2], "Admin") end
    if command == "mod" and string.lower(words[1] or "") == "add" then return setRole(player, words[2], "Moderator") end
    if command == "role" and string.lower(words[1] or "") == "remove" then return setRole(player, words[2], "Player") end
    if command == "money" then return giveMoney(player, words[1], words[2]) end
    if command == "weapon" then return giveWeapon(player, words[1], words[2]) end
    if command == "event" and string.lower(words[1] or "") == "start" then return startEvent(player, words[2], words[3]) end
    if command == "event" and string.lower(words[1] or "") == "stop" then return stopEvent(player) end
    if command == "weather" then return setWeather(player, words[1], words[2]) end
    if command == "announce" then return announce(player, table.concat(words, " ")) end
    if command == "kick" then return kickPlayer(player, words[1], table.concat(words, " ", 2)) end
    if command == "ban" then return banPlayer(player, words[1], table.concat(words, " ", 2)) end
    if command == "unban" then return unbanPlayer(player, words[1]) end
    return false, "Comando desconocido."
end

function AdminService.Initialize(remoteFolder, dependencies)
    remotes = remoteFolder
    deps = dependencies
    resolveOwner()
end

return AdminService
