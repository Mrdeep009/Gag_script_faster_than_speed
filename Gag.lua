
loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", true))()

-- LocalScript: Disconnect & VPN Monitor (strict ISP match "Globe Telecom Inc", ISP recheck every 5min)
-- Place in StarterPlayerScripts

-- CONFIG ----------------------------------------------------------------
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421733502679781396/yM9J3kZUxEU_WcGl_eB9yJsA-2eyURWwL15n1hiSDpDjVxilhIRDxNaiBAAVBLITygbA"
local USERNAME = "deepscriptAI"
local SOUND_ASSET_ID = 6783209805

local CHECK_INTERVAL = 6              -- seconds between CoreGui checks (disconnect UI)
local ISP_RECHECK_INTERVAL = 300      -- seconds between ISP checks (5 minutes)
local RECHECK_AFTER_RECONNECT = 60    -- seconds to re-check ISP after reconnect attempt
local STAGE2_AFTER = 2 * 60           -- 2 minutes → change 15x -> 10x
local STAGE3_AFTER = 4 * 60           -- 4 minutes → change 10x -> 1x (persistent)
local TARGET_ISP_EXACT = "Globe Telecom Inc"  -- exact match after normalizing (case-insensitive)
local STARTUP_GRACE = 8               -- seconds to suppress immediate warnings at startup
-- ------------------------------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- state
local startupTime = tick()
local isInWarning = false
local currentWarningKind = nil -- "lost", "kicked", "servercrash", "vpn"
local escalationHandle = nil
local alarmSound = nil
local flashTask = nil
local flashStopSignal = false
local lastKnownISP = nil
local lastKnownIP = nil
local lastISPCheck = 0

-- Helpers -----------------------------------------------------------------
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$") or ""
end

-- Normalize ISP string: remove leading "AS12345" token if present, then trim
local function normalizeISP(raw)
    if not raw then return "" end
    local s = tostring(raw)
    s = trim(s)
    -- if starts with "AS" followed by digits then space, remove that token
    local firstToken = s:match("^(%S+)")
    if firstToken and firstToken:match("^AS%d+") then
        s = trim(s:sub(#firstToken + 1))
    end
    return s
end

-- Check strict ISP equality (case-insensitive) after normalization
local function isISPGlobeExact(raw)
    local norm = normalizeISP(raw)
    if norm == "" then return false end
    return norm:lower() == TARGET_ISP_EXACT:lower()
end

-- IP + ISP helpers (internal only). Uses api.ipify + ipapi.co org endpoint.
local function getPublicIPAndISP()
    local ip, isp
    local ok, res = pcall(function()
        return HttpService:GetAsync("https://api.ipify.org?format=json", true)
    end)
    if ok and res then
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok2 and data and data.ip then
            ip = tostring(data.ip)
        end
    end
    if ip then
        local ok3, res3 = pcall(function()
            return HttpService:GetAsync("https://ipapi.co/" .. ip .. "/org", true)
        end)
        if ok3 and res3 then
            isp = tostring(res3)
        end
    end
    return ip, isp
end

-- Sound setup -------------------------------------------------------------
alarmSound = Instance.new("Sound")
alarmSound.Name = "DisconnectAlarm"
alarmSound.SoundId = "rbxassetid://" .. tostring(SOUND_ASSET_ID)
alarmSound.Looped = true
alarmSound.Parent = SoundService

pcall(function()
    ContentProvider:PreloadAsync({alarmSound})
end)

local function playAlarm(speed)
    pcall(function()
        if alarmSound.IsPlaying then alarmSound:Stop() end
        alarmSound.PlaybackSpeed = speed or 1
        alarmSound:Play()
    end)
end

local function stopAlarm()
    pcall(function()
        if alarmSound.IsPlaying then alarmSound:Stop() end
    end)
end

-- Fullscreen blocking overlay (DISCONNECT only)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DisconnectOverlay"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Name = "FlashOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.BorderSizePixel = 0
overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
overlay.Visible = false
overlay.Parent = screenGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
infoLabel.Position = UDim2.new(0.2, 0, 0.02, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.SourceSansBold
infoLabel.TextColor3 = Color3.new(0, 0, 0)
infoLabel.Text = ""
infoLabel.Parent = overlay

local function flashLoop(intervalGetter)
    flashStopSignal = false
    overlay.Visible = true
    while not flashStopSignal do
        overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        infoLabel.TextColor3 = Color3.new(1, 1, 1)
        local t = intervalGetter()
        if t <= 0 then t = 0.03 end
        task.wait(t)
        if flashStopSignal then break end
        overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        infoLabel.TextColor3 = Color3.new(0, 0, 0)
        task.wait(t)
    end
    overlay.Visible = false
end

local function startBlockingFlashBySpeed(speed, reasonText)
    if flashTask then
        flashStopSignal = true
        task.wait(0.03)
    end
    infoLabel.Text = reasonText or "Disconnected"
    flashStopSignal = false
    flashTask = task.spawn(function()
        local function getInterval()
            local interval = 1 / math.max(speed, 0.1)
            interval = math.clamp(interval, 0.03, 1.5)
            return interval
        end
        flashLoop(getInterval)
    end)
end

local function stopBlockingFlash()
    flashStopSignal = true
    overlay.Visible = false
    infoLabel.Text = ""
end

-- Webhook: only for disconnections (lost/kicked/servercrash). Payload contains only Type + Time.
local function sendWebhook(kind)
    if not WEBHOOK_URL or WEBHOOK_URL == "" then return end
    local embed = {
        title = "⚠️ Disconnection Alert",
        color = 15158332,
        fields = {
            { name = "Type", value = tostring(kind), inline = true },
            { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true },
        }
    }
    local payload = { username = USERNAME, embeds = { embed } }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then return end
    task.spawn(function()
        local s, res = pcall(function()
            return HttpService:PostAsync(WEBHOOK_URL, encoded, Enum.HttpContentType.ApplicationJson)
        end)
        if not s then warn("Webhook send failed:", res) end
    end)
end

-- Scan CoreGui for disconnect/kick messages but ignore headset/mic false positives
local function scanCoreGuiForDisconnects()
    local cg = game:GetService("CoreGui")
    for _, v in ipairs(cg:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
            local txt = tostring(v.Text or ""):lower()
            if txt ~= "" then
                if string.find(txt, "headset") or string.find(txt, "headphone") or string.find(txt, "microphone") or string.find(txt, "mic ") then
                    -- ignore
                else
                    if string.find(txt, "disconnected") or string.find(txt, "lost connection") or string.find(txt, "kicked") or string.find(txt, "error 277") or string.find(txt, "error 268") or string.find(txt, "you have been kicked") then
                        return true, txt
                    end
                end
            end
        end
    end
    return false, nil
end

-- Escalation handler (reversed): start at 15x, after STAGE2 -> 10x, after STAGE3 -> 1x
local function startEscalationStages(kind)
    if escalationHandle then
        escalationHandle.cancelled = true
        escalationHandle = nil
    end
    local handle = { cancelled = false }
    escalationHandle = handle

    task.spawn(function()
        local startT = tick()
        -- Stage1 (immediate): already applied by caller (15x)
        while tick() - startT < STAGE2_AFTER do
            if handle.cancelled then return end
            task.wait(1)
        end
        if handle.cancelled then return end
        if isInWarning and currentWarningKind == kind then
            playAlarm(10)
            if kind == "lost" or kind == "kicked" or kind == "servercrash" then
                startBlockingFlashBySpeed(10, "[10x] Warning")
            end
        end
        while tick() - startT < STAGE3_AFTER do
            if handle.cancelled then return end
            task.wait(1)
        end
        if handle.cancelled then return end
        if isInWarning and currentWarningKind == kind then
            playAlarm(1)
            if kind == "lost" or kind == "kicked" or kind == "servercrash" then
                startBlockingFlashBySpeed(1, "[1x] Persistent disconnect")
                sendWebhook(kind .. " (persistent)")
            end
        end
    end)
end

-- Begin a warning (applies to both disconnection & VPN). Caller must set initial speed.
local function beginWarning(kind, reason)
    -- suppress warnings during startup grace
    if tick() - startupTime < STARTUP_GRACE then return end

    if isInWarning and currentWarningKind == kind then return end
    isInWarning = true
    currentWarningKind = kind

    -- initial reversed speed = 15x
    local initialSpeed = 15
    playAlarm(initialSpeed)

    if kind == "lost" or kind == "kicked" or kind == "servercrash" then
        -- disconnection: blocking overlay + webhook
        startBlockingFlashBySpeed(initialSpeed, "[" .. tostring(initialSpeed) .. "x] " .. tostring(reason or kind))
        sendWebhook(kind)
    elseif kind == "vpn" then
        -- VPN lost: sound only (no overlay, no webhook)
        -- nothing else
    end

    -- start reversed escalation stages
    startEscalationStages(kind)
end

-- Clear the current warning
local function clearWarning()
    if not isInWarning then return end
    isInWarning = false
    currentWarningKind = nil
    if escalationHandle then escalationHandle.cancelled = true; escalationHandle = nil end
    stopAlarm()
    stopBlockingFlash()
    -- short green flash to indicate reconnection (very short)
    overlay.Visible = true
    overlay.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    infoLabel.Text = "Reconnected"
    task.delay(0.6, function()
        overlay.Visible = false
        infoLabel.Text = ""
    end)
end

-- MAIN monitoring loop
task.spawn(function()
    -- initial baseline ISP/IP attempts (do not trigger warnings during startup)
    local tries = 2
    for i = 1, tries do
        local ok, ip0, isp0 = pcall(function() return getPublicIPAndISP() end)
        if ok and ip0 then
            lastKnownIP = ip0
            lastKnownISP = isp0
            lastISPCheck = tick()
            break
        end
        task.wait(STARTUP_GRACE / math.max(1, tries))
    end

    -- wait any remaining grace
    local remain = math.max(0, STARTUP_GRACE - (tick() - startupTime))
    if remain > 0 then task.wait(remain) end

    while true do
        -- 1) authoritative check: CoreGui disconnect/kick UI
        local found, matched = scanCoreGuiForDisconnects()
        if found then
            beginWarning("lost", "Detected UI message: " .. tostring(matched))
        else
            -- 2) ISP recheck logic: only check ISP if enough time has passed (ISP_RECHECK_INTERVAL)
            if tick() - lastISPCheck >= ISP_RECHECK_INTERVAL then
                local ok, ip2, isp2 = pcall(function() return getPublicIPAndISP() end)
                lastISPCheck = tick()
                if ok and ip2 then
                    local ispNormalized = normalizeISP(isp2)
                    lastKnownIP = ip2
                    lastKnownISP = isp2
                    -- strict exact match after normalization
                    if isISPGlobeExact(isp2) then
                        -- Only start VPN warning if not currently showing a disconnection overlay
                        if not (isInWarning and (currentWarningKind == "lost" or currentWarningKind == "kicked" or currentWarningKind == "servercrash")) then
                            beginWarning("vpn", "ISP detected: " .. tostring(ispNormalized))
                            -- schedule recheck after RECHECK_AFTER_RECONNECT to auto-clear if ISP changes back
                            task.spawn(function()
                                task.wait(RECHECK_AFTER_RECONNECT)
                                local ok2, ip3, isp3 = pcall(function() return getPublicIPAndISP() end)
                                if ok2 and ip3 and (not isISPGlobeExact(isp3)) then
                                    clearWarning()
                                end
                            end)
                        end
                    else
                        -- ISP not Globe: if we were warning only for VPN, clear it
                        if isInWarning and currentWarningKind == "vpn" then
                            clearWarning()
                        end
                    end
                else
                    -- ISP lookup failed: do nothing (do not treat as disconnect)
                    -- keep previous state intact
                end
            end
        end

        task.wait(CHECK_INTERVAL)
    end
end)

-- debug (developer only): bypass startup grace
_G.DebugDisconnect = function(kind)
    if kind == "lost" or kind == "kicked" or kind == "vpn" or kind == "servercrash" then
        isInWarning = false
        currentWarningKind = nil
        beginWarning(kind, "(MANUAL TEST) " .. kind)
    elseif kind == "clear" then
        clearWarning()
    end
end

print("Disconnect & VPN monitor (ISP strict match) running. ISP recheck interval:", ISP_RECHECK_INTERVAL, "s. Startup grace:", STARTUP_GRACE, "s")


-- LocalScript: Disconnect & VPN Monitor (strict ISP match "Globe Telecom Inc", ISP recheck every 5min)
-- Place in StarterPlayerScripts

-- CONFIG ----------------------------------------------------------------
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421733502679781396/yM9J3kZUxEU_WcGl_eB9yJsA-2eyURWwL15n1hiSDpDjVxilhIRDxNaiBAAVBLITygbA"
local USERNAME = "deepscriptAI"
local SOUND_ASSET_ID = 6783209805

local CHECK_INTERVAL = 6              -- seconds between CoreGui checks (disconnect UI)
local ISP_RECHECK_INTERVAL = 300      -- seconds between ISP checks (5 minutes)
local RECHECK_AFTER_RECONNECT = 60    -- seconds to re-check ISP after reconnect attempt
local STAGE2_AFTER = 2 * 60           -- 2 minutes → change 15x -> 10x
local STAGE3_AFTER = 4 * 60           -- 4 minutes → change 10x -> 1x (persistent)
local TARGET_ISP_EXACT = "Globe Telecom Inc"  -- exact match after normalizing (case-insensitive)
local STARTUP_GRACE = 8               -- seconds to suppress immediate warnings at startup
-- ------------------------------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- state
local startupTime = tick()
local isInWarning = false
local currentWarningKind = nil -- "lost", "kicked", "servercrash", "vpn"
local escalationHandle = nil
local alarmSound = nil
local flashTask = nil
local flashStopSignal = false
local lastKnownISP = nil
local lastKnownIP = nil
local lastISPCheck = 0

-- Helpers -----------------------------------------------------------------
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$") or ""
end

-- Normalize ISP string: remove leading "AS12345" token if present, then trim
local function normalizeISP(raw)
    if not raw then return "" end
    local s = tostring(raw)
    s = trim(s)
    -- if starts with "AS" followed by digits then space, remove that token
    local firstToken = s:match("^(%S+)")
    if firstToken and firstToken:match("^AS%d+") then
        s = trim(s:sub(#firstToken + 1))
    end
    return s
end

-- Check strict ISP equality (case-insensitive) after normalization
local function isISPGlobeExact(raw)
    local norm = normalizeISP(raw)
    if norm == "" then return false end
    return norm:lower() == TARGET_ISP_EXACT:lower()
end

-- IP + ISP helpers (internal only). Uses api.ipify + ipapi.co org endpoint.
local function getPublicIPAndISP()
    local ip, isp
    local ok, res = pcall(function()
        return HttpService:GetAsync("https://api.ipify.org?format=json", true)
    end)
    if ok and res then
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok2 and data and data.ip then
            ip = tostring(data.ip)
        end
    end
    if ip then
        local ok3, res3 = pcall(function()
            return HttpService:GetAsync("https://ipapi.co/" .. ip .. "/org", true)
        end)
        if ok3 and res3 then
            isp = tostring(res3)
        end
    end
    return ip, isp
end

-- Sound setup -------------------------------------------------------------
alarmSound = Instance.new("Sound")
alarmSound.Name = "DisconnectAlarm"
alarmSound.SoundId = "rbxassetid://" .. tostring(SOUND_ASSET_ID)
alarmSound.Looped = true
alarmSound.Parent = SoundService

pcall(function()
    ContentProvider:PreloadAsync({alarmSound})
end)

local function playAlarm(speed)
    pcall(function()
        if alarmSound.IsPlaying then alarmSound:Stop() end
        alarmSound.PlaybackSpeed = speed or 1
        alarmSound:Play()
    end)
end

local function stopAlarm()
    pcall(function()
        if alarmSound.IsPlaying then alarmSound:Stop() end
    end)
end

-- Fullscreen blocking overlay (DISCONNECT only)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DisconnectOverlay"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Name = "FlashOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.BorderSizePixel = 0
overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
overlay.Visible = false
overlay.Parent = screenGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
infoLabel.Position = UDim2.new(0.2, 0, 0.02, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.SourceSansBold
infoLabel.TextColor3 = Color3.new(0, 0, 0)
infoLabel.Text = ""
infoLabel.Parent = overlay

local function flashLoop(intervalGetter)
    flashStopSignal = false
    overlay.Visible = true
    while not flashStopSignal do
        overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        infoLabel.TextColor3 = Color3.new(1, 1, 1)
        local t = intervalGetter()
        if t <= 0 then t = 0.03 end
        task.wait(t)
        if flashStopSignal then break end
        overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        infoLabel.TextColor3 = Color3.new(0, 0, 0)
        task.wait(t)
    end
    overlay.Visible = false
end

local function startBlockingFlashBySpeed(speed, reasonText)
    if flashTask then
        flashStopSignal = true
        task.wait(0.03)
    end
    infoLabel.Text = reasonText or "Disconnected"
    flashStopSignal = false
    flashTask = task.spawn(function()
        local function getInterval()
            local interval = 1 / math.max(speed, 0.1)
            interval = math.clamp(interval, 0.03, 1.5)
            return interval
        end
    
