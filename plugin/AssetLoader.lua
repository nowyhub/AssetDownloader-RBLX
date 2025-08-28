-- Roblox Asset Loader Plugin
-- Downloads animations and sounds from your API and loads them into workspace

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local InsertService = game:GetService("InsertService")

-- Plugin configuration - CHANGE THIS TO YOUR DEPLOYED API URL
local API_BASE_URL = "https://your-app-name.onrender.com/api" -- Replace with your Render URL
local plugin = plugin or script.Parent

-- Create toolbar and button
local toolbar = plugin:CreateToolbar("Asset Loader")
local button = toolbar:CreateButton("Load Asset", "Load Roblox animations and sounds", "rbxasset://textures/icon_place@2x.png")

-- Cleanup existing GUI
local existingGui = CoreGui:FindFirstChild("AssetLoaderGui")
if existingGui then
    existingGui:Destroy()
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AssetLoaderGui"
screenGui.Parent = CoreGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 450, 0, 600)
frame.Position = UDim2.new(0.5, -225, 0.5, -300)
frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Visible = false
frame.Active = true
frame.Draggable = true

-- Add corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 8)
titleBarCorner.Parent = titleBar

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🎮 Asset Loader"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 4)
closeBtnCorner.Parent = closeBtn

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 60)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🔌 Checking API connection..."
statusLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Asset ID Input
local assetIdLabel = Instance.new("TextLabel")
assetIdLabel.Name = "AssetIdLabel"
assetIdLabel.Size = UDim2.new(1, -20, 0, 25)
assetIdLabel.Position = UDim2.new(0, 10, 0, 100)
assetIdLabel.BackgroundTransparency = 1
assetIdLabel.Text = "Asset ID:"
assetIdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
assetIdLabel.TextScaled = true
assetIdLabel.Font = Enum.Font.SourceSansBold
assetIdLabel.TextXAlignment = Enum.TextXAlignment.Left
assetIdLabel.Parent = frame

local assetIdInput = Instance.new("TextBox")
assetIdInput.Name = "AssetIdInput"
assetIdInput.Size = UDim2.new(1, -20, 0, 35)
assetIdInput.Position = UDim2.new(0, 10, 0, 125)
assetIdInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
assetIdInput.Text = ""
assetIdInput.PlaceholderText = "Enter asset ID (e.g., 507766388)"
assetIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
assetIdInput.TextScaled = true
assetIdInput.Font = Enum.Font.SourceSans
assetIdInput.ClearTextOnFocus = false
assetIdInput.Parent = frame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = assetIdInput

-- Quick Select Buttons
local quickLabel = Instance.new("TextLabel")
quickLabel.Name = "QuickLabel"
quickLabel.Size = UDim2.new(1, -20, 0, 25)
quickLabel.Position = UDim2.new(0, 10, 0, 170)
quickLabel.BackgroundTransparency = 1
quickLabel.Text = "Quick Select:"
quickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
quickLabel.TextScaled = true
quickLabel.Font = Enum.Font.SourceSansBold
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.Parent = frame

-- Quick select buttons container
local quickFrame = Instance.new("Frame")
quickFrame.Name = "QuickFrame"
quickFrame.Size = UDim2.new(1, -20, 0, 80)
quickFrame.Position = UDim2.new(0, 10, 0, 195)
quickFrame.BackgroundTransparency = 1
quickFrame.Parent = frame

local quickGrid = Instance.new("UIGridLayout")
quickGrid.CellSize = UDim2.new(0, 100, 0, 35)
quickGrid.CellPadding = UDim2.new(0, 5, 0, 5)
quickGrid.Parent = quickFrame

-- Quick select asset buttons
local quickAssets = {
    {id = "507766388", name = "Default Dance"},
    {id = "180426354", name = "Running"},
    {id = "182393478", name = "Climbing"},
    {id = "131961136", name = "Oof Sound"}
}

for _, asset in ipairs(quickAssets) do
    local quickBtn = Instance.new("TextButton")
    quickBtn.Size = UDim2.new(0, 100, 0, 35)
    quickBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    quickBtn.Text = asset.name
    quickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickBtn.TextScaled = true
    quickBtn.Font = Enum.Font.SourceSans
    quickBtn.Parent = quickFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = quickBtn
    
    quickBtn.MouseButton1Click:Connect(function()
        assetIdInput.Text = asset.id
    end)
end

-- Cookie Input (Optional)
local cookieLabel = Instance.new("TextLabel")
cookieLabel.Name = "CookieLabel"
cookieLabel.Size = UDim2.new(1, -20, 0, 25)
cookieLabel.Position = UDim2.new(0, 10, 0, 285)
cookieLabel.BackgroundTransparency = 1
cookieLabel.Text = "Roblox Cookie (Optional - for private assets):"
cookieLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cookieLabel.TextScaled = true
cookieLabel.Font = Enum.Font.SourceSansBold
cookieLabel.TextXAlignment = Enum.TextXAlignment.Left
cookieLabel.Parent = frame

local cookieInput = Instance.new("TextBox")
cookieInput.Name = "CookieInput"
cookieInput.Size = UDim2.new(1, -20, 0, 60)
cookieInput.Position = UDim2.new(0, 10, 0, 310)
cookieInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
cookieInput.Text = ""
cookieInput.PlaceholderText = "Paste .ROBLOSECURITY cookie here"
cookieInput.TextColor3 = Color3.fromRGB(255, 255, 255)
cookieInput.TextSize = 12
cookieInput.Font = Enum.Font.SourceSans
cookieInput.TextWrapped = true
cookieInput.ClearTextOnFocus = false
cookieInput.MultiLine = true
cookieInput.Parent = frame

local cookieCorner = Instance.new("UICorner")
cookieCorner.CornerRadius = UDim.new(0, 4)
cookieCorner.Parent = cookieInput

-- Place ID Input (Optional)
local placeIdLabel = Instance.new("TextLabel")
placeIdLabel.Name = "PlaceIdLabel"
placeIdLabel.Size = UDim2.new(1, -20, 0, 25)
placeIdLabel.Position = UDim2.new(0, 10, 0, 380)
placeIdLabel.BackgroundTransparency = 1
placeIdLabel.Text = "Place ID (Optional):"
placeIdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
placeIdLabel.TextScaled = true
placeIdLabel.Font = Enum.Font.SourceSansBold
placeIdLabel.TextXAlignment = Enum.TextXAlignment.Left
placeIdLabel.Parent = frame

local placeIdInput = Instance.new("TextBox")
placeIdInput.Name = "PlaceIdInput"
placeIdInput.Size = UDim2.new(1, -20, 0, 35)
placeIdInput.Position = UDim2.new(0, 10, 0, 405)
placeIdInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
placeIdInput.Text = ""
placeIdInput.PlaceholderText = "Enter place ID (e.g., 1818)"
placeIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
placeIdInput.TextScaled = true
placeIdInput.Font = Enum.Font.SourceSans
placeIdInput.ClearTextOnFocus = false
placeIdInput.Parent = frame

local placeCorner = Instance.new("UICorner")
placeCorner.CornerRadius = UDim.new(0, 4)
placeCorner.Parent = placeIdInput

-- Download Button
local downloadBtn = Instance.new("TextButton")
downloadBtn.Name = "DownloadButton"
downloadBtn.Size = UDim2.new(1, -20, 0, 50)
downloadBtn.Position = UDim2.new(0, 10, 0, 450)
downloadBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
downloadBtn.Text = "📥 Download & Load Asset"
downloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downloadBtn.TextScaled = true
downloadBtn.Font = Enum.Font.SourceSansBold
downloadBtn.Parent = frame

local downloadCorner = Instance.new("UICorner")
downloadCorner.CornerRadius = UDim.new(0, 6)
downloadCorner.Parent = downloadBtn

-- Result Label
local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -20, 0, 80)
resultLabel.Position = UDim2.new(0, 10, 0, 510)
resultLabel.BackgroundColor3 = Color3.fromRGB(33, 37, 41)
resultLabel.Text = "Ready to download assets..."
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.TextSize = 12
resultLabel.Font = Enum.Font.SourceSans
resultLabel.TextWrapped = true
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.TextYAlignment = Enum.TextYAlignment.Top
resultLabel.Parent = frame

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 4)
resultCorner.Parent = resultLabel

local resultPadding = Instance.new("UIPadding")
resultPadding.PaddingTop = UDim.new(0, 5)
resultPadding.PaddingBottom = UDim.new(0, 5)
resultPadding.PaddingLeft = UDim.new(0, 8)
resultPadding.PaddingRight = UDim.new(0, 8)
resultPadding.Parent = resultLabel

-- Functions
local function updateStatus(message, color)
    statusLabel.Text = message
    statusLabel.TextColor3 = color
end

local function updateResult(message, isSuccess)
    resultLabel.Text = message
    if isSuccess then
        resultLabel.BackgroundColor3 = Color3.fromRGB(25, 135, 84)
    else
        resultLabel.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end

local function setButtonLoading(loading)
    downloadBtn.Active = not loading
    if loading then
        downloadBtn.Text = "⏳ Downloading..."
        downloadBtn.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
    else
        downloadBtn.Text = "📥 Download & Load Asset"
        downloadBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    end
end

-- Check API health with timeout
local function checkAPIHealth()
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_BASE_URL .. "/health",
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if success and response.Success and response.StatusCode == 200 then
        local parseSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if parseSuccess and data.success then
            updateStatus("✅ API Connected", Color3.fromRGB(40, 167, 69))
            return true
        end
    end
    
    updateStatus("❌ API Offline", Color3.fromRGB(220, 53, 69))
    return false
end

-- Load asset directly using InsertService or create instance
local function loadAssetDirect(assetId, assetType)
    local success, result = pcall(function()
        -- Try InsertService first for models/meshes
        if assetType == "model" or assetType == "mesh" or assetType == "decal" then
            local model = InsertService:LoadAsset(tonumber(assetId))
            if model then
                model.Parent = workspace
                model.Name = assetType:upper() .. "_" .. assetId
                return {model}
            end
        end
        
        -- Create instance directly for animations and sounds
        if assetType == "animation" then
            local anim = Instance.new("Animation")
            anim.Name = "Animation_" .. assetId
            anim.AnimationId = "rbxassetid://" .. assetId
            anim.Parent = workspace
            return {anim}
        elseif assetType == "sound" then
            local sound = Instance.new("Sound")
            sound.Name = "Sound_" .. assetId
            sound.SoundId = "rbxassetid://" .. assetId
            sound.Volume = 0.5
            sound.Parent = workspace
            return {sound}
        end
        
        return nil
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Download and load asset
local function downloadAsset()
    local assetId = assetIdInput.Text:gsub("%s+", "")
    if assetId == "" then
        updateResult("❌ Please enter an Asset ID", false)
        return
    end
    
    -- Validate asset ID is numeric
    if not tonumber(assetId) then
        updateResult("❌ Asset ID must be numeric", false)
        return
    end
    
    setButtonLoading(true)
    updateResult("📡 Requesting download from API...", true)
    
    -- Prepare request data
    local requestData = {
        assetId = assetId
    }
    
    -- Add optional fields if provided
    local cookie = cookieInput.Text:gsub("%s+", "")
    if cookie ~= "" then
        requestData.robloxCookie = cookie
    end
    
    local placeId = placeIdInput.Text:gsub("%s+", "")
    if placeId ~= "" and tonumber(placeId) then
        requestData.placeId = placeId
    end
    
    local requestJson = HttpService:JSONEncode(requestData)
    
    -- Download asset via API
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_BASE_URL .. "/download",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = requestJson
        })
    end)
    
    if not success or not response.Success then
        setButtonLoading(false)
        local errorMsg = response and response.StatusMessage or tostring(response)
        updateResult("❌ Failed to connect to API: " .. errorMsg, false)
        return
    end
    
    -- Parse API response
    local apiData
    success, apiData = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not success or not apiData or not apiData.success then
        setButtonLoading(false)
        local errorMsg = apiData and apiData.error or "Unknown API error"
        updateResult("❌ API Error: " .. errorMsg, false)
        return
    end
    
    -- Try to load via API download first
    local loadedObjects = nil
    
    if apiData.downloadUrl then
        updateResult("📥 Downloading " .. (apiData.assetType or "asset") .. " file...", true)
        
        -- Try to download and load the .rbxm file
        local fileSuccess, fileResponse = pcall(function()
            return HttpService:RequestAsync({
                Url = apiData.downloadUrl,
                Method = "GET"
            })
        end)
        
        if fileSuccess and fileResponse.Success then
            -- Try to load the downloaded content
            local loadSuccess, objects = pcall(function()
                -- This would need special handling for .rbxm files
                -- For now, we'll fall back to direct loading
                return nil
            end)
            
            if loadSuccess and objects and #objects > 0 then
                loadedObjects = objects
            end
        end
    end
    
    -- Fallback: Load asset directly using Roblox services
    if not loadedObjects then
        updateResult("🔄 Loading asset directly...", true)
        loadedObjects = loadAssetDirect(assetId, apiData.assetType or "unknown")
    end
    
    setButtonLoading(false)
    
    if loadedObjects and #loadedObjects > 0 then
        -- Select the loaded objects
        Selection:Set(loadedObjects)
        
        -- Record the action for undo/redo
        ChangeHistoryService:SetWaypoint("Asset Loader - Loaded " .. (apiData.assetType or "asset"))
        
        local objectNames = {}
        for _, obj in ipairs(loadedObjects) do
            table.insert(objectNames, obj.Name)
        end
        
        updateResult(string.format(
            "✅ Successfully loaded %s!\n\n📁 Type: %s\n🎯 Objects: %s\n🆔 Asset ID: %s", 
            (apiData.assetType or "asset"):upper(),
            apiData.assetType or "unknown",
            table.concat(objectNames, ", "),
            assetId
        ), true)
    else
        updateResult("❌ Failed to load asset. The asset may be private, deleted, or incompatible.", false)
    end
end

-- Event connections
button.Click:Connect(function()
    frame.Visible = not frame.Visible
    if frame.Visible then
        spawn(checkAPIHealth)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

downloadBtn.MouseButton1Click:Connect(function()
    spawn(downloadAsset)
end)

-- Handle Enter key in asset ID input
assetIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed and assetIdInput.Text ~= "" then
        spawn(downloadAsset)
    end
end)

-- Plugin cleanup
plugin.Unloading:Connect(function()
    if screenGui then
        screenGui:Destroy()
    end
end)

-- Initial setup
spawn(function()
    wait(0.5)
    if frame.Visible then
        checkAPIHealth()
    end
end)

print("Asset Loader Plugin loaded successfully!")
print("API URL: " .. API_BASE_URL)
