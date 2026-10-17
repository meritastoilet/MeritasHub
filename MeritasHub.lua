-- Meritas Hub | v3.7 - Noclip + Speed
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "M E R I T A S   H U B",
   LoadingTitle = "Iniciando Sistema Cuántico...",
   LoadingSubtitle = "v3.7 - Noclip + Speed",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
   Theme = "Amethyst"
})

local Tab = Window:CreateTab("Panel Cuántico", 4483362458)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local VU = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--------------------------------------------------------------------------------
-- ESP
--------------------------------------------------------------------------------
Tab:CreateSection("Visuales")

local ESPEnabled = false
local Highlights = {}

Tab:CreateToggle({
    Name = "ESP (Jugadores + NPCs)",
    CurrentValue = false,
    Callback = function(Value)
        ESPEnabled = Value
        for _, h in pairs(Highlights) do if h then h:Destroy() end end
        table.clear(Highlights)
        if not Value then return end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local h = Instance.new("Highlight")
                h.FillColor = Color3.fromRGB(0, 242, 255)
                h.OutlineColor = Color3.fromRGB(255, 0, 128)
                h.FillTransparency = 0.4
                h.Parent = p.Character
                Highlights[p.Character] = h
            end
        end
    end
})

--------------------------------------------------------------------------------
-- MOVILIDAD
--------------------------------------------------------------------------------
Tab:CreateSection("Movilidad")

-- FLY
local FlyEnabled = false
local FlyConn

Tab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        FlyEnabled = Value
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp then return end

        if FlyConn then FlyConn:Disconnect() FlyConn = nil end
        for _, v in ipairs(hrp:GetChildren()) do
            if v.Name:find("Fly") then v:Destroy() end
        end
        if hum then hum.PlatformStand = false end
        if not Value then return end

        local att = Instance.new("Attachment", hrp)
        att.Name = "FlyAtt"
        local lv = Instance.new("LinearVelocity", hrp)
        lv.Name = "FlyVel"
        lv.Attachment0 = att
        lv.MaxForce = math.huge
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        local ao = Instance.new("AlignOrientation", hrp)
        ao.Name = "FlyOri"
        ao.Attachment0 = att
        ao.MaxTorque = math.huge
        ao.Responsiveness = 200
        if hum then hum.PlatformStand = true end

        FlyConn = RunService.RenderStepped:Connect(function()
            if not FlyEnabled or not hrp.Parent then return end
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
            lv.VectorVelocity = dir.Magnitude > 0 and dir.Unit * 55 or Vector3.zero
            ao.CFrame = Camera.CFrame
        end)
    end
})

-- NOCLIP
local NoclipEnabled = false
local NoclipConn

Tab:CreateToggle({
    Name = "Noclip (Atravesar Paredes)",
    CurrentValue = false,
    Callback = function(Value)
        NoclipEnabled = Value
        if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
        if not Value then return end

        NoclipConn = RunService.Stepped:Connect(function()
            if not NoclipEnabled then return end
            local char = LP.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
})

-- SPEED
local SpeedEnabled = false
local SpeedValue = 30 -- velocidad (puedes cambiar este número)
local DefaultSpeed = 16
local SpeedConn

Tab:CreateToggle({
    Name = "Speed (Correr Rápido)",
    CurrentValue = false,
    Callback = function(Value)
        SpeedEnabled = Value
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if SpeedConn then SpeedConn:Disconnect() SpeedConn = nil end
        
        if Value and hum then
            hum.WalkSpeed = SpeedValue
            SpeedConn = RunService.Heartbeat:Connect(function()
                if SpeedEnabled and hum and hum.Parent then
                    hum.WalkSpeed = SpeedValue
                end
            end)
        elseif hum then
            hum.WalkSpeed = DefaultSpeed
        end
    end
})

--------------------------------------------------------------------------------
-- COMBATE
--------------------------------------------------------------------------------
Tab:CreateSection("Combate")

local Aimbot = false
local AutoShoot = false
local Target = nil

local function hasWeapon()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Tool") ~= nil
end

local function GetClosest()
    local closest, dist = nil, 130
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if vis then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist then
                        dist = mag
                        closest = p.Character.Head
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Aimbot or not hasWeapon() then 
        Target = nil
        return 
    end

    Target = GetClosest()
    if Target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.045)
        if AutoShoot and Aimbot and hasWeapon() and Target and Target.Parent then
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
                pcall(function()
                    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
                    VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    task.wait(0.012)
                    VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                end)
                pcall(function()
                    VU:Button1Down(Vector2.zero, Camera.CFrame)
                    task.wait(0.01)
                    VU:Button1Up(Vector2.zero, Camera.CFrame)
                end)
            end
        end
    end
end)

Tab:CreateToggle({
    Name = "Aimbot (Cabeza)",
    CurrentValue = false,
    Callback = function(Value)
        Aimbot = Value
        if not Value then Target = nil end
    end
})

Tab:CreateToggle({
    Name = "Auto-Disparo",
    CurrentValue = false,
    Callback = function(Value)
        AutoShoot = Value
    end
})

print("Meritas Hub v3.7 cargado | Noclip + Speed")
