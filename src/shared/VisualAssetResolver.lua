local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualAssetResolver = {}
local resolved = {}

local function directUrl(id)
    return "rbxassetid://" .. tostring(id)
end

local function thumbnailUrl(id)
    return string.format("rbxthumb://type=Asset&id=%s&w=768&h=432", tostring(id))
end

local function preload(imageObject, timeoutSeconds)
    local success = false
    local finished = false

    task.spawn(function()
        local ok = pcall(function()
            ContentProvider:PreloadAsync({imageObject}, function(_, fetchStatus)
                if fetchStatus == Enum.AssetFetchStatus.Success then
                    success = true
                end
            end)
        end)
        success = success or (ok and imageObject.IsLoaded)
        finished = true
    end)

    local deadline = os.clock() + (tonumber(timeoutSeconds) or 1.5)
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end

    return success or imageObject.IsLoaded
end

function VisualAssetResolver.Url(id)
    id = tonumber(id) or 0
    if id <= 0 then return "" end
    return resolved[id] or directUrl(id)
end

function VisualAssetResolver.Apply(imageObject, id, timeoutSeconds)
    id = tonumber(id) or 0
    if not imageObject or id <= 0 then
        if imageObject then imageObject.Image = "" end
        return false
    end

    local cached = resolved[id]
    if cached then
        imageObject.Image = cached
        return true
    end

    local primary = directUrl(id)
    imageObject.Image = primary
    if preload(imageObject, timeoutSeconds) then
        resolved[id] = primary
        return true
    end

    local fallback = thumbnailUrl(id)
    imageObject.Image = fallback
    preload(imageObject, 1.0)
    resolved[id] = fallback
    return imageObject.IsLoaded
end

function VisualAssetResolver.Preload(ids)
    for _, rawId in ipairs(ids or {}) do
        local id = tonumber(rawId) or 0
        if id > 0 and not resolved[id] then
            local probe = Instance.new("ImageLabel")
            probe.Name = "TintaFinalVisualProbe"
            probe.Size = UDim2.fromOffset(2, 2)
            probe.BackgroundTransparency = 1
            probe.ImageTransparency = 1
            probe.Visible = false
            probe.Parent = ReplicatedStorage
            VisualAssetResolver.Apply(probe, id, 1.2)
            probe:Destroy()
        end
    end
end

return VisualAssetResolver
