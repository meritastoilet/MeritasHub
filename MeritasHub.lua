-- Meritas Hub | v3.8 - Fix Fly / Speed / ESP / Aimbot
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "M E R I T A S   H U B",
   LoadingTitle = "Iniciando Sistema Cuántico...",
   LoadingSubtitle = "v3.8",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
   Theme = "Amethyst"
})

local Tab = Window:CreateTab("Panel Cuántico", 4483362458)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

-- Siempre pedimos la cámara actual (la referencia vieja se rompe al respawnear)
local function Cam() return workspace.CurrentCamera end
local function GetHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------------------------------------
-- ESP (Jugadores + NPCs)
--------------------------------------------------------------------------------
Tab:CreateSection("Visuales")

local ESPEnabled = false
local ESPLoopId = 0
local Highlights = {}

local function removeHighlight(model)
    local h = Highlights[model]
    if h then h:Destroy() end
    Highlights[model] = nil
end

local function addHighlight(model, fill, outline)
    if Highlights[model] then return end
    local h = Instance.new("Highlight")
    h.Adornee = model
    h.FillColor = fill
    h.OutlineColor = outline
    h.FillTransparency = 0.4
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = model
    Highlights[model] = h
end

local function clearESP()
    for model in pairs(Highlights) do removeHighlight(model) end
end

local function scanESP()
    -- limpiar los que ya no existen
    for model in pairs(Highlights) do
        if not model.Parent then removeHighlight(model) end
    end

    -- jugadores
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            addHighlight(p.Character, Color3.fromRGB(0, 242, 255), Color3.fromRGB(255, 0, 128))
        end
    end

    -- NPCs (modelos con Humanoid que no son jugadores)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") then
            local model = d.Parent
            if model and model:IsA("Model")
                and model ~= LP.Character
                and not Players:GetPlayerFromCharacter(model) then
                addHighlight(model, Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 80, 0))
            end
        end
    end
end

Tab:CreateToggle({
    Name = "ESP (Jugadores + NPCs)",
    CurrentValue = false,
    Callback = function(Value)
        ESPEnabled = Value
        ESPLoopId += 1
        clearESP()
        if not Value then return end

        local myId = ESPLoopId
        task.spawn(function()
            while ESPEnabled and ESPLoopId == myId do
                pcall(scanESP)
                task.wait(1.5)
            end
        end)
    end
})

--------------------------------------------------------------------------------
-- MOVILIDAD
--------------------------------------------------------------------------------
Tab:CreateSection("Movilidad")

-- FLY ------------------------------------------------------------------------
local FlyEnabled = false
local FlySpeed = 55
local FlyConn

local function stopFly()
    if FlyConn then FlyConn:Disconnect() FlyConn = nil end
    local hrp = GetHRP()
    if hrp then
        for _, v in ipairs(hrp:GetChildren()) do
            if v.Name:find("Fly") then v:Destroy() end
        end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    stopFly()
    local hrp, hum = GetHRP(), GetHum()
    if not hrp then return end

    local att = Instance.new("Attachment")
    att.Name = "FlyAtt"
    att.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Name = "FlyVel"
    lv.Attachment0 = att
    lv.MaxForce = math.huge
    -- ESTE era el error: sin esto LinearVelocity ignora VectorVelocity
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VectorVelocity = Vector3.zero
    lv.Parent = hrp

    local ao = Instance.new("AlignOrientation")
    ao.Name = "FlyOri"
    ao.Attachment0 = att
    -- Sin esto necesita un Attachment1 y no hace nada
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.MaxTorque = math.huge
    ao.Responsiveness = 200
    ao.Parent = hrp

    if hum then hum.PlatformStand = true end

    FlyConn = RunService.RenderStepped:Connect(function()
        if not FlyEnabled or not hrp.Parent then return end
        local cam = Cam()
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        lv.VectorVelocity = dir.Magnitude > 0 and dir.Unit * FlySpeed or Vector3.zero
        ao.CFrame = cam.CFrame
    end)
end

Tab:CreateToggle({
    Name = "Fly (WASD + Espacio / Shift)",
    CurrentValue = false,
    Callback = function(Value)
        FlyEnabled = Value
        if Value then startFly() else stopFly() end
    end
})

Tab:CreateSlider({
    Name = "Velocidad de Fly",
    Range = {20, 200},
    Increment = 5,
    CurrentValue = 55,
    Callback = function(v) FlySpeed = v end
})

-- NOCLIP ---------------------------------------------------------------------
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

-- SPEED ----------------------------------------------------------------------
local SpeedEnabled = false
local SpeedValue = 30
local DefaultSpeed = 16

-- Una sola conexión permanente: siempre toma el Humanoid actual (sirve tras respawn)
RunService.Heartbeat:Connect(function()
    if not SpeedEnabled then return end
    local hum = GetHum()
    if hum and hum.WalkSpeed ~= SpeedValue then
        hum.WalkSpeed = SpeedValue
    end
end)

Tab:CreateToggle({
    Name = "Speed (Correr Rápido)",
    CurrentValue = false,
    Callback = function(Value)
        SpeedEnabled = Value
        if not Value then
            local hum = GetHum()
            if hum then hum.WalkSpeed = DefaultSpeed end
        end
    end
})

Tab:CreateSlider({
    Name = "Velocidad de Correr",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = 30,
    Callback = function(v) SpeedValue = v end
})

-- Reaplicar Fly tras respawn
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if FlyEnabled then startFly() end
end)

--------------------------------------------------------------------------------
-- COMBATE
--------------------------------------------------------------------------------
Tab:CreateSection("Combate")

local Aimbot = false
local AutoShoot = false
local AimRadius = 130
local Target = nil

local function hasWeapon()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Tool") ~= nil
end

local TeamCheck = true

local function isTeammate(p)
    return LP.Team ~= nil and p.Team == LP.Team
end

local function GetClosest()
    local cam = Cam()
    local closest, dist = nil, AimRadius
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if p ~= LP and not (TeamCheck and isTeammate(p)) and char and char:FindFirstChild("Head") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, vis = cam:WorldToViewportPoint(char.Head.Position)
                if vis then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist then
                        dist = mag
                        closest = char.Head
                    end
                end
            end
        end
    end
    return closest
end

-- Se ejecuta DESPUÉS del script de cámara de Roblox; antes éste te pisaba el CFrame
RunService:BindToRenderStep("MeritasAim", Enum.RenderPriority.Camera.Value + 1, function()
    if not Aimbot or not hasWeapon() then
        Target = nil
        return
    end
    Target = GetClosest()
    if Target then
        local cam = Cam()
        cam.CFrame = CFrame.new(cam.CFrame.Position, Target.Position)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.06)
        if AutoShoot and Aimbot and hasWeapon() and Target and Target.Parent then
            local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
            end
            pcall(function()
                local cam = Cam()
                local cx, cy = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
                VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                task.wait(0.012)
                VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
            end)
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

Tab:CreateSlider({
    Name = "Radio del Aimbot (px)",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 130,
    Callback = function(v) AimRadius = v end
})

Tab:CreateToggle({
    Name = "Ignorar mi equipo",
    CurrentValue = true,
    Callback = function(Value)
        TeamCheck = Value
    end
})

Tab:CreateToggle({
    Name = "Auto-Disparo",
    CurrentValue = false,
    Callback = function(Value)
        AutoShoot = Value
    end
})

print("Meritas Hub v3.8 cargado")
