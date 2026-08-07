local ContentProvider = game:GetService("ContentProvider")

local VisualAssetResolver = {}
local resolved = {}

local function directUrl(id)
    return "rbxassetid://" .. tostring(id)
end

local function thumbnailUrl(id)
    return string.format("rbxthumb://type=Asset&id=%s&w=768&h=432", tostring(id))
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

    local success = false
    local finished = false
    task.spawn(function()
        local ok = pcall(function()
            ContentProvider:PreloadAsync({imageObject})
        end)
        success = ok and imageObject.IsLoaded
        finished = true
    end)

    local deadline = os.clock() + (tonumber(timeoutSeconds) or 1.6)
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end

    if imageObject.IsLoaded or success then
        resolved[id] = primary
        return true
    end

    local fallback = thumbnailUrl(id)
    imageObject.Image = fallback
    resolved[id] = fallback
    return false
end

function VisualAssetResolver.Preload(ids)
    for _, id in ipairs(ids or {}) do
        id = tonumber(id) or 0
        if id > 0 and not resolved[id] then
            local probe = Instance.new("ImageLabel")
            probe.Size = UDim2.fromOffset(2, 2)
            probe.BackgroundTransparency = 1
            probe.ImageTransparency = 1
            probe.Visible = false
            probe.Parent = game:GetService("ReplicatedStorage")
            VisualAssetResolver.Apply(probe, id, 1.2)
            probe:Destroy()
        end
    end
end

return VisualAssetResolver
