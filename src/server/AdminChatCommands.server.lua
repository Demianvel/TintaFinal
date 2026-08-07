local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Services = script.Parent:WaitForChild("Services")
local AdminService = require(Services:WaitForChild("AdminService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local feedback = remotes:WaitForChild("AdminFeedback")

local function ensureCommand(name, alias, secondary)
    local existing = TextChatService:FindFirstChild(name)
    if existing and existing:IsA("TextChatCommand") then return existing end
    if existing then existing:Destroy() end
    local command = Instance.new("TextChatCommand")
    command.Name = name
    command.PrimaryAlias = alias
    if secondary then command.SecondaryAlias = secondary end
    command.Parent = TextChatService
    return command
end

local function execute(textSource, unfilteredText)
    if not textSource then return end
    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not player then return end

    local text = tostring(unfilteredText or "")
    text = text:gsub("^/tf%s*", "", 1)
    text = text:gsub("^/tinta%s*", "", 1)
    text = text:gsub("^%s+", "")

    if text == "" then
        feedback:FireClient(player, true, "Usá /tf <comando>. Ej.: /tf money Usuario 5000")
        return
    end

    local success, message = AdminService.ExecuteText(player, "!" .. text)
    feedback:FireClient(player, success, message)
end

local command = ensureCommand("TintaFinalAdminCommand", "/tf", "/tinta")
command.Triggered:Connect(execute)
