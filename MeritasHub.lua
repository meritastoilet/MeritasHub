-- Meritas Hub | Versión Optimizada (Menos Lag)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "M E R I T A S   H U B",
   LoadingTitle = "Iniciando Sistema Cuántico...",
   LoadingSubtitle = "v3.3 - Optimizado",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "MeritasHub",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvite",
      RememberJoins = true
   },
   KeySystem = false,
   Theme = "Amethyst"
})

local TabAdmin = Window:CreateTab("Panel Cuántico", 4483362458)

--------------------------------------------------------------------------------
-- SERVICIOS
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------------------------------------
-- 1. ESP (Optimizado)
--------------------------------------------------------------------------------
TabAdmin:CreateSection("Sistemas Visuales")

local espEnabled = false
local highlights = {}

local function clearHighlights()
    for _, hl in pairs(highlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    table.clear(highlights)
end

local function addHighlight(model, isNPC)
    if highlights[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "OwnerESP"
    hl.FillColor = isNPC and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(0, 242, 255)
    hl.OutlineColor = Color3.fromRGB(255, 0, 128)
    hl.FillTransparency = 0.45
    hl.Parent = model
    highlights[model] = hl
end

local function toggleESP(state)
    espEnabled = state
    clearHighlights()

    if not state then return end

    -- Jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            addHighlight(player.Character, false)
        end
    end

    -- NPCs (solo una vez al activar)
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("Head") then
            local isPlayerChar = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == obj then
                    isPlayerChar = true
                    break
                end
            end
            if not isPlayerChar then
                addHighlight(obj, true)
            end
        end
    end
end

TabAdmin:CreateToggle({
   Name = "Resaltar Jugadores + NPCs (ESP)",
   CurrentValue = false,
   Flag = "ESPFlag",
   Callback = function(Value)
       toggleESP(Value)
   end,
})

--------------------------------------------------------------------------------
-- 2. FLY
--------------------------------------------------------------------------------
TabAdmin:CreateSection("Movilidad Avanzada")

local flyEnabled = false
local flyConnection = nil

local function toggleFly(state)
    flyEnabled = state
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end

    -- Limpiar
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    for _, v in ipairs(hrp:GetChildren()) do
        if v.Name == "FlyVelocity" or v.Name == "FlyOrientation" or v.Name == "FlyAttachment" then
            v:Destroy()
        end
    end
    if humanoid then humanoid.PlatformStand = false end

    if not state then return end

    local att = Instance.new("Attachment")
    att.Name = "FlyAttachment"
    att.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Name = "FlyVelocity"
    lv.Attachment0 = att
    lv.MaxForce = math.huge
    lv.VectorVelocity = Vector3.zero
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.Parent = hrp

    local ao = Instance.new("AlignOrientation")
    ao.Name = "FlyOrientation"
    ao.Attachment0 = att
    ao.MaxTorque = math.huge
    ao.Responsiveness = 200
    ao.Parent = hrp

    if humanoid then humanoid.PlatformStand = true end

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not hrp.Parent then return end
        local moveDir = Vector3.zero
        local cam = workspace.CurrentCamera

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end

        lv.VectorVelocity = moveDir.Magnitude > 0 and moveDir.Unit * 60 or Vector3.zero
        ao.CFrame = cam.CFrame
    end)
end

TabAdmin:CreateToggle({
   Name = "Propulsión Cuántica (Fly)",
   CurrentValue = false,
   Flag = "FlyFlag",
   Callback = function(Value)
       toggleFly(Value)
   end,
})

--------------------------------------------------------------------------------
-- 3. AIMBOT + AUTO-SHOOT (Optimizado)
--------------------------------------------------------------------------------
TabAdmin:CreateSection("Módulos de Combate")

local aimbotEnabled = false
local autoShootEnabled = false

-- Cache de targets (se actualiza cada 0.25s en vez de cada frame)
local cachedTarget = nil
local lastTargetUpdate = 0

local function updateClosestTarget()
    local closest = nil
    local shortest = 120 -- FOV máximo en píxeles (puedes bajarlo)

    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    -- Jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = head
                    end
                end
            end
        end
    end

    -- NPCs (solo busca en los hijos directos de workspace + algunas carpetas comunes)
    local placesToSearch = {workspace}
    for _, name in ipairs({"NPCs", "Mobs", "Enemies", "Zombies", "Bots", "Characters"}) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            table.insert(placesToSearch, folder)
        end
    end

    for _, place in ipairs(placesToSearch) do
        for _, obj in ipairs(place:GetChildren()) do
            if obj:IsA("Model") then
                local head = obj:FindFirstChild("Head")
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                if head and humanoid and humanoid.Health > 0 then
                    -- Evitar personajes de jugadores
                    local isPlayer = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character == obj then
                            isPlayer = true
                            break
                        end
                    end
                    if not isPlayer then
                        local pos, onScreen = camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if dist < shortest then
                                shortest = dist
                                closest = head
                            end
                        end
                    end
                end
            end
        end
    end

    cachedTarget = closest
end

-- Aimbot (ligero)
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end

    -- Actualizar target solo cada 0.2 segundos
    if tick() - lastTargetUpdate > 0.2 then
        updateClosestTarget()
        lastTargetUpdate = tick()
    end

    if cachedTarget and cachedTarget.Parent then
        camera.CFrame = CFrame.new(camera.CFrame.Position, cachedTarget.Position)
    end
end)

-- Auto-Disparo
task.spawn(function()
    while true do
        task.wait(0.04)
        if autoShootEnabled then
            local char = localPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end

                -- Clic
                pcall(function()
                    local cx, cy = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    task.wait(0.012)
                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                end)

                -- VirtualUser backup
                pcall(function()
                    VirtualUser:Button1Down(Vector2.zero, camera.CFrame)
                    task.wait(0.01)
                    VirtualUser:Button1Up(Vector2.zero, camera.CFrame)
                end)
            end
        end
    end
end)

TabAdmin:CreateToggle({
   Name = "Lock-On Orbital (Aimbot)",
   CurrentValue = false,
   Flag = "AimbotFlag",
   Callback = function(Value)
       aimbotEnabled = Value
       if not Value then cachedTarget = nil end
   end,
})

TabAdmin:CreateToggle({
   Name = "Fuego Sincronizado (Auto-Disparo)",
   CurrentValue = false,
   Flag = "AutoShootFlag",
   Callback = function(Value)
       autoShootEnabled = Value
   end,
})

print("Meritas Hub Optimizado cargado")
