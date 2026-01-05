-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId
local currentRooms = workspace:WaitForChild("currentrooms")
local SAVE_FILE = "death_position.json"

-- UTILS
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
        x = cf.X, y = cf.Y, z = cf.Z,
        r00 = cf.R00, r01 = cf.R01, r02 = cf.R02,
        r10 = cf.R10, r11 = cf.R11, r12 = cf.R12,
        r20 = cf.R20, r21 = cf.R21, r22 = cf.R22,
        jobId = jobId
    }

    writefile(SAVE_FILE, HttpService:JSONEncode(data))
end

-- RESTORE POSITION AFTER REJOIN
local function restorePosition()
    if not isfile(SAVE_FILE) then return end
    local data = HttpService:JSONDecode(readfile(SAVE_FILE))
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
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sillydudescripts/one-thousand-rooms-script/refs/heads/main/main.lua"))()
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

if player.Character then
    hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

-- RESTORE AFTER RESPAWN
task.spawn(function()
    task.wait(1)
    restorePosition()
end)

-- LOOP TELEPORT TO DOOR + FIRE PROMPT
local running = true

RunService.Heartbeat:Connect(function()
    if not running then return end

    local lastRoom
    local highestNumber = -math.huge

    -- FIND LAST ROOM
    for _, room in pairs(currentRooms:GetChildren()) do
        local num = tonumber(room.Name:match("%d+"))
        if num and num > highestNumber then
            highestNumber = num
            lastRoom = room
        end
    end

    -- STOP AT ROOM 1000
    if highestNumber >= 1000 then
        running = false
        warn("Reached Room 1000. Script stopped.")
        return
    end

    if not lastRoom then return end

    -- FIND GAMEDOOR
    local gameDoor = lastRoom:FindFirstChild("gameDoor", true)
    if not gameDoor then return end

    -- FIND PROMPT + PART
    local prompt, doorPart
    for _, v in pairs(gameDoor:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent:IsA("BasePart") then
            prompt = v
            doorPart = v.Parent
            break
        end
    end

    if not prompt or not doorPart then return end

    -- TELEPORT PLAYER TO DOOR
    local hrp = getHRP(player.Character or player.CharacterAdded:Wait())
    hrp.CFrame = doorPart.CFrame * CFrame.new(0, 0, -3)

    -- FIRE PROMPT
    pcall(function()
        fireproximityprompt(prompt)
    end)
end)
