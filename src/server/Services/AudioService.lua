local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)

local AudioService = {}
local sounds = {}

local function createSound(name, assetId, looped, volume)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.Looped = looped == true
    sound.Volume = volume or 0.45
    sound.RollOffMaxDistance = 180
    if tonumber(assetId) and tonumber(assetId) > 0 then
        sound.SoundId = "rbxassetid://" .. tostring(assetId)
    end
    sound.Parent = SoundService
    sounds[name] = sound
    return sound
end

function AudioService.Initialize()
    for _, child in ipairs(SoundService:GetChildren()) do
        if child:GetAttribute("TintaFinalAudio") then
            child:Destroy()
        end
    end

    local definitions = {
        LobbyMusic = { true, 0.35 },
        VotingMusic = { true, 0.40 },
        RoundMusic = { true, 0.45 },
        VictoryMusic = { false, 0.55 },
        EliminationSound = { false, 0.55 },
        VoteSound = { false, 0.40 },
        SpinSound = { false, 0.50 },
    }

    for name, settings in pairs(definitions) do
        local sound = createSound(name, Config.Audio[name], settings[1], settings[2])
        sound:SetAttribute("TintaFinalAudio", true)
    end
end

function AudioService.PlayOnly(name)
    for soundName, sound in pairs(sounds) do
        if sound.Looped then
            if soundName == name and sound.SoundId ~= "" then
                if not sound.IsPlaying then
                    sound:Play()
                end
            else
                sound:Stop()
            end
        end
    end
end

function AudioService.PlayEffect(name)
    local sound = sounds[name]
    if sound and sound.SoundId ~= "" then
        sound:Play()
    end
end

return AudioService
