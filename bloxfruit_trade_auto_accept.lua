-- Blox Fruits auto-trade helper (educational use)
-- NOTE: This can break game rules and may stop working after updates.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function safeFire(remote, ...)
    if typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

-- Try common remote paths used by many Blox Fruits client builds.
local possibleRemotes = {
    game:GetService("ReplicatedStorage"):FindFirstChild("Remotes"),
    game:GetService("ReplicatedStorage"):FindFirstChild("Events"),
}

local function findRemote(remoteName)
    for _, folder in ipairs(possibleRemotes) do
        if folder and folder:FindFirstChild(remoteName) then
            return folder[remoteName]
        end
    end
    return nil
end

local tradeRequestRemote = findRemote("TradeRequest")
local tradeAcceptRemote = findRemote("TradeAccept")

-- Optional: auto-send trade request to the closest player every 15s.
local AUTO_SEND_REQUEST = false
local REQUEST_INTERVAL = 15

local function getClosestPlayer()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        return nil
    end

    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
            if d < dist then
                dist = d
                closest = plr
            end
        end
    end
    return closest
end

if AUTO_SEND_REQUEST and tradeRequestRemote then
    task.spawn(function()
        while task.wait(REQUEST_INTERVAL) do
            local target = getClosestPlayer()
            if target then
                safeFire(tradeRequestRemote, target)
            end
        end
    end)
end

-- Auto-accept incoming trade prompts.
-- If your build uses a different remote/event name, update this section.
local incomingTradeRemote = findRemote("TradeInvite") or findRemote("TradeIncoming")

if incomingTradeRemote and incomingTradeRemote:IsA("RemoteEvent") and tradeAcceptRemote then
    incomingTradeRemote.OnClientEvent:Connect(function(fromPlayer)
        if fromPlayer and fromPlayer ~= LocalPlayer then
            task.wait(0.2)
            safeFire(tradeAcceptRemote, fromPlayer)
            warn("[Trade Helper] Auto-accepted trade from", fromPlayer.Name)
        end
    end)
    warn("[Trade Helper] Auto-accept is ON")
else
    warn("[Trade Helper] Could not find expected trade remotes. Open Dex/Explorer and update remote names.")
end
