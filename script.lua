pcall(function()
    workspace.StreamingEnabled = false
    workspace.SimulationRadius = math.huge
end)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local hrp      = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local networkFolder    = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network")
local RemotePromiseMod = require(networkFolder:WaitForChild("RemotePromise"))
local ActivatePromise  = RemotePromiseMod.new("ActivateObject")

local remotesRoot       = ReplicatedStorage:WaitForChild("Remotes")
local EndDecisionRemote = remotesRoot:WaitForChild("EndDecision")

local queue_on_tp = (syn and syn.queue_on_teleport)
    or queue_on_teleport
    or (fluxus and fluxus.queue_on_teleport)

local bondData = {}
local seenKeys = {}
local bondCount = 0

-- Create UI
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Parent = gui
label.Size = UDim2.new(0, 200, 0, 50)
label.Position = UDim2.new(0.5, -100, 0.1, 0)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Text = "Bonds Collected: 0"

local creditLabel = Instance.new("TextLabel")
creditLabel.Parent = gui
creditLabel.Size = UDim2.new(0, 300, 0, 30)
creditLabel.Position = UDim2.new(0.5, -150, 0.15, 0)
creditLabel.BackgroundTransparency = 1
creditLabel.TextColor3 = Color3.new(1, 1, 1)
creditLabel.TextScaled = true
creditLabel.Text = "Created by PenguinCre8te based on CyberSeall aka Terry Davis"

-- Tracking bonds
local function updateBondCount()
    bondCount = bondCount + 1
    label.Text = "Bonds Collected: " .. bondCount
    print("Collected bonds:", bondCount)
end

local function recordBonds()
    local runtime = Workspace:WaitForChild("RuntimeItems")
    for _, item in ipairs(runtime:GetChildren()) do
        if item.Name:match("Bond") then
            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if part then
                local key = ("%.1f_%.1f_%.1f"):format(
                    part.Position.X, part.Position.Y, part.Position.Z
                )
                if not seenKeys[key] then
                    seenKeys[key] = true
                    table.insert(bondData, { item = item, pos = part.Position, key = key })
                end
            end
        end
    end
end

print("=== Starting map scan ===")
local scanTarget = CFrame.new(-424.448975, 26.055481, -49040.6562, -1,0,0, 0,1,0, 0,0,-1)
local scanSteps = 50
for i = 1, scanSteps do
    hrp.CFrame = hrp.CFrame:Lerp(scanTarget, i/scanSteps)
    task.wait(0.3)
    recordBonds()
    task.wait(0.1)
end
hrp.CFrame = scanTarget
task.wait(0.3)
recordBonds()

print(("→ %d Bonds found"):format(#bondData))
if #bondData == 0 then
    warn("No Bonds found – check Runtime Items")
    return
end

local chair = Workspace:WaitForChild("RuntimeItems"):FindFirstChild("Chair")
assert(chair and chair:FindFirstChild("Seat"), "Chair.Seat not found")
local seat = chair.Seat

seat:Sit(humanoid)
task.wait(0.2)
assert(humanoid.SeatPart == seat, "Seat error")

for idx, entry in ipairs(bondData) do
    print(("--- Bond %d/%d: %s ---"):format(idx, #bondData, entry.key))

    local targetCFrame = CFrame.new(entry.pos) * CFrame.new(0, 2, 0)
    seat:PivotTo(targetCFrame)
    task.wait(0.05)

    if humanoid.SeatPart ~= seat then
        seat:Sit(humanoid)
        task.wait(0.05)
    end

    ActivatePromise:InvokeServer(entry.item)
    task.wait(0.2)

    if not entry.item.Parent then
        print("Bond collected")
        updateBondCount()
    else
        warn("Increase timeout when not collecting")
    end
end

humanoid:TakeDamage(999999)
EndDecisionRemote:FireServer(false)

if queue_on_tp then
    queue_on_tp('PUT YOUR SCRIPT HERE')
end

print("=== Script finished ===")
