-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

-- FILE
local SAVE_FILE = "death_position.json"

-- UTIL
local function getHRP(char)
    return char:WaitForChild("HumanoidRootPart")
end

-- SAVE DEATH POSITION
local function saveDeathPosition()
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cf = hrp.CFrame
    local data = {
        x = cf.X,
        y = cf.Y,
        z = cf.Z,
        r00 = cf.R00, r01 = cf.R01, r02 = cf.R02,
        r10 = cf.R10, r11 = cf.R11, r12 = cf.R12,
        r20 = cf.R20, r21 = cf.R21, r22 = cf.R22,
        jobId = jobId
    }

    writefile(SAVE_FILE, game:GetService("HttpService"):JSONEncode(data))
end

-- RESTORE POSITION AFTER REJOIN
local function restorePosition()
    if not isfile(SAVE_FILE) then return end

    local data = game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))

    -- safety: only restore if same server
    if data.jobId ~= game.JobId then return end

    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = getHRP(char)

    local cf = CFrame.new(
        data.x, data.y, data.z,
        data.r00, data.r01, data.r02,
        data.r10, data.r11, data.r12,
        data.r20, data.r21, data.r22
    )

    hrp.CFrame = cf
end

-- QUEUE SCRIPT ON TELEPORT
queue_on_teleport([[
    loadstring(game:HttpGet("YOUR_RAW_SCRIPT_URL_HERE"))()
]])

-- DETECT DEATH
local function hookCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        saveDeathPosition()
        task.wait(0.1)
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    end)
end

-- INIT
if player.Character then
    hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

-- RESTORE AFTER RESPAWN
task.spawn(function()
    task.wait(1)
    restorePosition()
end)
