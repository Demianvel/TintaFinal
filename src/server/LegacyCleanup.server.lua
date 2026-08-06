-- Removes objects inherited from the previous Eternal Survival place.
-- This script is intentionally independent from the new game loop so the
-- cleanup runs even if another service fails during startup.

local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")
local Lighting = game:GetService("Lighting")

local function safeDestroy(instance)
    if instance and instance.Parent then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function cleanWorkspace()
    for _, child in ipairs(Workspace:GetChildren()) do
        local allowed = child:IsA("Terrain")
            or child:IsA("Camera")
            or child.Name == "TintaFinalWorld"

        if not allowed then
            safeDestroy(child)
        end
    end
end

local function cleanStarterGui()
    for _, child in ipairs(StarterGui:GetChildren()) do
        safeDestroy(child)
    end
end

local function cleanReplicatedStorage()
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child.Name ~= "Shared" and child.Name ~= "Remotes" then
            safeDestroy(child)
        end
    end
end

local function cleanServerStorage()
    for _, child in ipairs(ServerStorage:GetChildren()) do
        safeDestroy(child)
    end
end

local function cleanTeams()
    for _, child in ipairs(Teams:GetChildren()) do
        safeDestroy(child)
    end
end

local function cleanLegacyLighting()
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky")
            or child:IsA("Atmosphere")
            or child:IsA("BloomEffect")
            or child:IsA("BlurEffect")
            or child:IsA("ColorCorrectionEffect")
            or child:IsA("DepthOfFieldEffect")
            or child:IsA("SunRaysEffect") then
            safeDestroy(child)
        end
    end
end

cleanWorkspace()
cleanStarterGui()
cleanReplicatedStorage()
cleanServerStorage()
cleanTeams()
cleanLegacyLighting()

Workspace:SetAttribute("LegacyEternalContentRemoved", true)
Workspace:SetAttribute("ActiveExperience", "TintaFinal")
print("[TintaFinal] Contenido heredado de Eternal Survival eliminado.")
