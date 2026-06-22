-- wip charge dem hoes a fee

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MaterialService = game:GetService("MaterialService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

MaterialService.Use2022Materials = true

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sessionId = tick()
local goatRunning, goatTarget, goatConnection = false, nil, nil
local butterflyAlive = true
local CLEANER_RUNNING = false

local STAMINA_MAIN = Color3.fromRGB(205, 240, 255)
local STAMINA_GLOW = Color3.fromRGB(255, 255, 255)

local function CreateWatermark()
    if playerGui:FindFirstChild("Watermark") then
        playerGui.Watermark:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Watermark"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = playerGui

    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromOffset(390, 40)
    bar.Position = UDim2.new(1, 300, 0, -45)
    bar.AnchorPoint = Vector2.new(1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    bar.BackgroundTransparency = 0.08
    bar.Parent = gui

    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 150, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = bar

    local glowGradient = Instance.new("UIGradient")
    glowGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 160, 255))
    }
    glowGradient.Parent = stroke -- Naprawiono odwołanie do shoreGlow

    local particleContainer = Instance.new("Frame")
    particleContainer.Size = UDim2.fromScale(1, 1)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ClipsDescendants = true
    particleContainer.Parent = bar
    Instance.new("UICorner", particleContainer).CornerRadius = UDim.new(1, 0)

    local function spawnWatermarkParticle()
        local p = Instance.new("Frame")
        p.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
        p.Position = UDim2.new(math.random(), 0, math.random(), 0)
        p.BackgroundColor3 = Color3.fromRGB(170, 230, 255)
        p.BackgroundTransparency = 0.2
        p.BorderSizePixel = 0
        p.Parent = particleContainer
        Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)

        local tween = TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            Position = p.Position - UDim2.new(0, 0, 0.05, 0)
        })
        tween:Play()
        tween.Completed:Connect(function() p:Destroy() end)
    end

    local hovering = false
    bar.MouseEnter:Connect(function()
        hovering = true
        for i = 1, 12 do spawnWatermarkParticle() end
        task.spawn(function()
            while hovering do
                spawnWatermarkParticle()
                task.wait(0.08)
            end
        end)
    end)

    bar.MouseLeave:Connect(function()
        hovering = false
        TweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 1, Thickness = 1 }):Play()
    end)

    local avatarSize = 38
    local avatarHolder = Instance.new("Frame")
    avatarHolder.Size = UDim2.fromOffset(avatarSize, avatarSize)
    avatarHolder.Position = UDim2.new(0, 4, 0.5, -avatarSize / 2)
    avatarHolder.BackgroundTransparency = 1
    avatarHolder.ClipsDescendants = false
    avatarHolder.Parent = bar

    local avatarCircle = Instance.new("Frame")
    avatarCircle.Size = UDim2.fromScale(1, 1)
    avatarCircle.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    avatarCircle.ZIndex = 2
    avatarCircle.Parent = avatarHolder
    Instance.new("UICorner", avatarCircle).CornerRadius = UDim.new(1, 0)

    local innerGlow = Instance.new("Frame")
    innerGlow.Size = UDim2.fromScale(1, 1)
    innerGlow.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    innerGlow.BackgroundTransparency = 0.95
    innerGlow.ZIndex = 1
    innerGlow.Parent = avatarCircle
    Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(1, 0)

    local orbitParticles = {}
    local particleCount = 28
    local radius = avatarSize / 2 + 5

    for i = 1, particleCount do
        local p = Instance.new("Frame")
        p.Size = UDim2.fromOffset(2, 2)
        p.BackgroundColor3 = Color3.fromRGB(180, 230, 255)
        p.BackgroundTransparency = 0.2
        p.BorderSizePixel = 0
        p.ZIndex = 0
        p.Parent = avatarHolder
        Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)

        orbitParticles[i] = {
            frame = p,
            angle = (i / particleCount) * math.pi * 2,
            speed = math.random(85, 115) / 100,
        }
    end

    local t = 0
    RunService.RenderStepped:Connect(function(dt)
        t += dt
        for _, data in ipairs(orbitParticles) do
            local p = data.frame
            data.angle += dt * data.speed
            local x = avatarSize / 2 + math.cos(data.angle) * radius
            local y = avatarSize / 2 + math.sin(data.angle) * (radius * 0.85)
            p.Position = UDim2.fromOffset(x, y)
            local glow = (math.sin(data.angle + t * 2) + 1) / 2
            p.BackgroundTransparency = 0.2 + glow * 0.5
            local size = 1.5 + glow * 1
            p.Size = UDim2.fromOffset(size, size)
        end
    end)

    task.spawn(function()
        while avatarHolder.Parent do
            task.wait(0.12)
            local dot = Instance.new("Frame")
            dot.Size = UDim2.fromOffset(1, 1)
            dot.BackgroundColor3 = Color3.fromRGB(220, 240, 255)
            dot.BackgroundTransparency = 0.2
            dot.BorderSizePixel = 0
            dot.ZIndex = 0
            dot.Parent = avatarHolder
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

            local angle = math.random() * math.pi * 2
            local r = radius + math.random(-2, 4)
            dot.Position = UDim2.fromOffset(avatarSize/2 + math.cos(angle) * r, avatarSize/2 + math.sin(angle) * (r * 0.85))

            TweenService:Create(dot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0)
            }):Play()
            task.delay(1, function() if dot then dot:Destroy() end end)
        end
    end)

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromScale(0.82, 0.82)
    avatar.Position = UDim2.fromScale(0.09, 0.09)
    avatar.BackgroundTransparency = 1
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.ZIndex = 3
    avatar.Parent = avatarCircle
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -80, 1, 0)
    text.Position = UDim2.new(0, 70, 0, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(235, 245, 255)
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 13
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = "Loading..."
    text.Parent = bar

    local frames, fps = 0, 0
    RunService.RenderStepped:Connect(function() frames += 1 end)
    task.spawn(function()
        while true do
            task.wait(1)
            fps = frames
            frames = 0
        end
    end)

    local function getPing()
        local network = Stats:FindFirstChild("Network")
        local server = network and network:FindFirstChild("ServerStatsItem")
        local ping = server and (server:FindFirstChild("Data Ping") or server:FindFirstChild("Ping"))
        return ping and math.floor(ping:GetValue()) or 0
    end

    task.spawn(function()
        while true do
            task.wait(0.5)
            local t_date = os.date("*t")
            text.Text = "  " .. fps .. " FPS ┊   " .. #Players:GetPlayers() .. " Online ┊  " 
            .. string.format("%02d:%02d", t_date.hour, t_date.min) .. " ┊  " 
            .. getPing() .. "ms ┊ ⁁  " .. math.floor(Stats:GetTotalMemoryUsageMb()) .. "MB"
        end
    end)

    TweenService:Create(bar, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -8, 0, -45)}):Play()
end
CreateWatermark()

task.spawn(function()
    local stamina = ReplicatedStorage:WaitForChild("PlayerValues"):WaitForChild(player.Name):WaitForChild("Stamina")
    if stamina:IsA("IntConstrainedValue") then
        stamina.MinValue = 80
        stamina:GetPropertyChangedSignal("MinValue"):Connect(function()
            if stamina.MinValue < 80 then stamina.MinValue = 80 end
        end)
    end
end)

task.spawn(function()
    local folder = player:WaitForChild("Player_Titles_List")
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("IntValue") and obj.Name:lower():find("rothschild") then
            obj.Value = 100000001
        end
    end
end)

task.spawn(function()
    local equipped = ReplicatedStorage:WaitForChild("Player_Data"):WaitForChild(player.Name):WaitForChild("EquippedItemStats")
    if equipped then
        local itemsToEquip = {
            Hat="Straw Hat", Lantern="Lantern Of Despair", Mask="Banigaru Mask", 
            Shirt="Devourer Top", Uniform="Tengen Uniform", Necklace="Kesshoseki Necklace"
        }
        for k, v in pairs(itemsToEquip) do
            local obj = equipped:FindFirstChild(k)
            if obj and obj:IsA("StringValue") then obj.Value = v end
        end
    end
end)

for _, v in pairs(Lighting:GetChildren()) do
    if v.Name == "CustomColorFX" or v.Name == "CustomBlurFX" then v:Destroy() end
end

local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atm.Name = "CustomAtmosphere"
atm.Color = Color3.fromRGB(255, 235, 200)
atm.Decay = Color3.fromRGB(255, 240, 220)
atm.Density = 0.414
atm.Offset = 0.27

if not atm:FindFirstChild("LockValues") then
    Instance.new("BoolValue", atm).Name = "LockValues"
    atm:GetPropertyChangedSignal("Density"):Connect(function() if atm.Parent then atm.Density = 0.414 end end)
    atm:GetPropertyChangedSignal("Offset"):Connect(function() if atm.Parent then atm.Offset = 0.27 end end)
end

local main = Instance.new("ColorCorrectionEffect", Lighting)
main.Name = "CustomColorFX"
main.Saturation = 0.65
main.Contrast = 0.08
main.Brightness = 0.015

Lighting.ExposureCompensation = 0.11
Lighting.Brightness = 2.1

local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect", Lighting)
blur.Name = "CustomBlurFX"
blur.Size = 3
blur.Enabled = true

local function spawnSnowParticle(bar)
    if not bar then return end
    local p = Instance.new("TextLabel")
    p.Size = UDim2.fromOffset(10, 10)
    p.BackgroundTransparency = 1
    p.Text = "❄"
    p.TextScaled = true
    p.Font = Enum.Font.GothamBold
    p.TextColor3 = STAMINA_GLOW
    p.TextTransparency = 0.12
    p.ZIndex = bar.ZIndex + 12
    p.Parent = bar
    p.Position = UDim2.fromScale(math.random(), -0.2)

    TweenService:Create(p, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {
        Position = p.Position + UDim2.fromScale(0, 1.4), TextTransparency = 1
    }):Play()
    task.delay(1.5, function() if p then p:Destroy() end end)
end

local function applyStaminaParticles(bar)
    if not bar or bar:FindFirstChild("ParticleTag") then return end

    bar.BackgroundColor3 = STAMINA_MAIN
    bar.BorderSizePixel = 0

    if not bar:FindFirstChild("StaminaGlow") then
        local stroke = Instance.new("UIStroke")
        stroke.Name = "StaminaGlow"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = STAMINA_GLOW
        stroke.Thickness = 1.5
        stroke.Transparency = 0.2
        stroke.Parent = bar
    end

    local tag = Instance.new("Folder", bar)
    tag.Name = "ParticleTag"

    task.spawn(function()
        while tag.Parent do
            bar.BackgroundColor3 = STAMINA_MAIN
            spawnSnowParticle(bar)
            task.wait(0.15)
        end
    end)
end

local function startGoat()
    if goatRunning then return end

    local gui = player:WaitForChild("PlayerGui")
    local root = gui:WaitForChild("ver")
    local goat = root:WaitForChild("ver")
    if not goat:IsA("TextLabel") then return end

    goatTarget = goat
    goatRunning = true

    if goatConnection then goatConnection:Disconnect() end
    for _, v in pairs(goat:GetChildren()) do
        if v:IsA("UIGradient") then v:Destroy() end
    end

    local grad = Instance.new("UIGradient", goat)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 175, 205)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 140, 255))
    }

    local states = {
        { text = "#goatlife", hold = 8 }, { text = "#g0atl1fe", hold = 1.2 }, { text = "#goat.life", hold = 1.2 },
        { text = "#>|3a..---", hold = 1.2 }, { text = "#go4tlife", hold = 1.2 }, { text = "#>|m3ssi|<", hold = 4 },
        { text = "#m3ssi", hold = 1.5 }, { text = "#m3ssi//", hold = 1.5 },
    }

    task.spawn(function()
        while goatRunning and goatTarget and goatTarget.Parent do
            for _, s in ipairs(states) do
                if not goatRunning then break end
                for _ = 1, 8 do
                    goatTarget.Text = string.char(math.random(33, 126))
                    task.wait(0.05)
                end
                goatTarget.Text = s.text
                task.wait(s.hold)
            end
        end
        goatRunning = false
    end)

    local t = 0
    goatConnection = RunService.RenderStepped:Connect(function(dt)
        if goatTarget and goatTarget.Parent and grad.Parent then
            t += dt
            grad.Rotation = 20 + math.sin(t) * 6
        end
    end)
end

if _G.ButterflyKill then _G.ButterflyKill() end
_G.ButterflyKill = function() butterflyAlive = false end

local butterflyRender, butterflyDPS, butterflyGui

local function getDPS()
    return player:WaitForChild("PlayerGui"):WaitForChild("Menu"):WaitForChild("DpsMeter"):WaitForChild("Text")
end

local butterflyParticles = {}
local function spawnButterflyParticle(pos, parent, color)
    if #butterflyParticles >= 5 then
        butterflyParticles[1]:Destroy()
        table.remove(butterflyParticles, 1)
    end
    local p = Instance.new("TextLabel")
    p.BackgroundTransparency = 1; p.BorderSizePixel = 0; p.Text = "+"
    p.TextSize = 12; p.TextColor3 = color; p.TextTransparency = 0.15
    p.ZIndex = 997; p.Parent = parent; p.Position = pos
    table.insert(butterflyParticles, p)

    TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
        TextTransparency = 1, Position = UDim2.fromOffset(pos.X.Offset, pos.Y.Offset + math.random(10, 20))
    }):Play()
    task.delay(0.6, function() if p then p:Destroy() end end)
end

local function attachButterfly()
    if not butterflyAlive then return end
    if butterflyRender then butterflyRender:Disconnect() end
    if butterflyDPS then butterflyDPS:Disconnect() end
    if butterflyGui then butterflyGui:Destroy() end

    local mySession = sessionId
    local dps = getDPS()

    butterflyGui = Instance.new("ScreenGui")
    butterflyGui.Name = "ButterflyGui"
    butterflyGui.IgnoreGuiInset = true
    butterflyGui.DisplayOrder = 999999
    butterflyGui.Parent = player:WaitForChild("PlayerGui")

    local wing = Instance.new("TextLabel", butterflyGui)
    wing.Text = "🦋"; wing.BackgroundTransparency = 1; wing.TextSize = 10
    wing.ZIndex = 99999; wing.Size = UDim2.fromOffset(10, 10); wing.AnchorPoint = Vector2.new(0.5, 0.5)

    local glow = Instance.new("TextLabel", butterflyGui)
    glow.Text = "🦋"; glow.BackgroundTransparency = 1; glow.TextSize = 14
    glow.TextTransparency = 0.8; glow.ZIndex = 99998; glow.Size = UDim2.fromOffset(14, 14); glow.AnchorPoint = Vector2.new(0.5, 0.5)

    local t, speed, lastDPS = 0, 1, 0
    butterflyDPS = dps:GetPropertyChangedSignal("Text"):Connect(function()
        if mySession ~= sessionId then return end
        local value = tonumber(string.match(dps.Text, "%d+%.?%d*")) or 0
        speed = math.clamp(1 + value / 50, 1, 6)

        if value - lastDPS > 15 then
            TweenService:Create(wing, TweenInfo.new(0.1), {TextSize = 13, TextColor3 = Color3.fromRGB(255, 230, 150)}):Play()
            task.delay(0.8, function()
                if wing.Parent then wing.TextSize = 10; wing.TextColor3 = Color3.fromRGB(120, 200, 255) end
            end)
        end
        lastDPS = value
    end)

    butterflyRender = RunService.RenderStepped:Connect(function(dt)
        if not butterflyAlive or not wing.Parent then return end
        t += dt * speed
        local flap = math.sin(t * 12)
        local pos = UDim2.fromOffset(workspace.CurrentCamera.ViewportSize.X - 342, 35 + math.sin(t * 2) * 2)

        wing.Position = pos; glow.Position = pos
        wing.Rotation = flap * 6; glow.Rotation = flap * 6
        wing.Size = UDim2.fromOffset(10, 10); glow.Size = UDim2.fromOffset(14, 14)

        if math.random() < 0.25 then
            spawnButterflyParticle(UDim2.fromOffset(pos.X.Offset + math.random(-6, 6), pos.Y.Offset + 8), butterflyGui, Color3.fromRGB(120, 200, 255))
        end
    end)
end

task.spawn(function()
    while butterflyAlive do
        task.wait(1)
        pcall(attachButterfly)
    end
end)

local function bindUI()
    local gui = player:WaitForChild("PlayerGui"):WaitForChild("Menu", 10)
    if not gui then return end

    local bars = gui:FindFirstChild("Bars")
    local staminaBar = bars and bars:FindFirstChild("StaminaBar")
    staminaBar = staminaBar and staminaBar:FindFirstChild("Bar")

    if staminaBar then applyStaminaParticles(staminaBar) end

    local fpsHolder = gui:FindFirstChild("Fps_and_ping")
    local fps = fpsHolder and fpsHolder:FindFirstChild("Fps")
    if fps then
        pcall(function()
            if applyFPS then applyFPS(fps) end
            if startSakura then startSakura(fps) end
        end)
    end
end

task.spawn(function() while true do bindUI() task.wait(1) end end)

local function applyDodges(character)
    local value = character:FindFirstChild("Perfect_Dodges_Left")
    if not value then
        value = Instance.new("IntValue")
        value.Name = "Perfect_Dodges_Left"
        value.Value = 47
        value.Parent = character
    else
        if value.Value <= 0 then value.Value = 47 end
    end
    value:GetPropertyChangedSignal("Value"):Connect(function()
        if value.Value <= 0 then value.Value = 47 end
    end)
end

local function onCharacterAdded(character)
    task.wait(1)
    
    goatRunning = false
    goatTarget = nil
    if goatConnection then goatConnection:Disconnect() goatConnection = nil end
    startGoat()

    applyDodges(character)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

local function CD()
    local p = playerGui:FindFirstChild("Power_Adder")
    if not p then return end

    local cooldowns = {
        {{"War_Fans"}, 35}, {{"War Drums"}, 36}, {{"Ice_Bda","Skills","Barren Hanging Garden"}, 22},
        {{"Ice_Bda","Skills","Cold White Princesses"}, 22}, {{"Ice_Bda","Skills","Freezing Cloud"}, 22},
        {{"Ice_Bda","Skills","Lotus Vines"}, 35}, {{"Ice_Bda","Skills","Wintry Icicles"}, 15},
        {{"Swamp_Bda","Skills","Swamp Eject"}, 15}, {{"Swamp_Bda","Skills","Swamp Trap"}, 20},
        {{"Swamp_Bda","Skills","Traveling Claws"}, 15}
    }

    for _, s in ipairs(cooldowns) do
        local obj = p
        for _, n in ipairs(s[1]) do
            obj = obj:FindFirstChild(n)
            if not obj then break end
        end
        if obj and obj:FindFirstChild("CoolDown") then
            obj.CoolDown.Value = s[2]
        end
    end
end

if not CLEANER_RUNNING then
    CLEANER_RUNNING = true
    task.spawn(function()
        while true do
            task.wait(2)
            pcall(function() CD() end)
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.CapsLock then
        local folder = ReplicatedStorage:WaitForChild("PlayerValues"):FindFirstChild(player.Name)
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj.Name == "Stun" then obj:Destroy() end
            end
        end
    end
end)

local ESP_FOLDER = workspace:FindFirstChild("Ghost_ESP") or Instance.new("Folder", workspace)
ESP_FOLDER.Name = "Ghost_ESP"

local REAPER_COLOR = Color3.fromRGB(0, 150, 255)
local ghostCache = {}

local BODY_PARTS = {
    "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", 
    "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"
}

local function RemoveGhost(playerName)
    if ghostCache[playerName] then
        for _, part in pairs(ghostCache[playerName]) do part:Destroy() end
        ghostCache[playerName] = nil
    end
end

local function CreateGhost(targetPlayer)
    if ghostCache[targetPlayer.Name] then return end
    
    local parts = {}
    for _, partName in ipairs(BODY_PARTS) do
        local p = Instance.new("Part")
        p.Name = partName
        p.Size = Vector3.new(1, 1, 1)
        p.Color = REAPER_COLOR
        p.Material = Enum.Material.Neon
        p.CanCollide = false
        p.Anchored = true
        p.Parent = ESP_FOLDER
        parts[partName] = p
    end
    ghostCache[targetPlayer.Name] = parts
end

RunService.Heartbeat:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == Players.LocalPlayer then continue end
        
        local data = ReplicatedStorage:FindFirstChild("Player_Data")
        local pData = data and data:FindFirstChild(p.Name)
        local isReaper = pData and pData:FindFirstChild("Demon_Art") and pData.Demon_Art.Value == "Reaper"
        
        if isReaper and p.Character then
            if not ghostCache[p.Name] then CreateGhost(p) end
            
            local ghostParts = ghostCache[p.Name]
            for _, partName in ipairs(BODY_PARTS) do
                local realPart = p.Character:FindFirstChild(partName)
                local ghostPart = ghostParts[partName]
                
                if realPart and ghostPart then
                    ghostPart.CFrame = realPart.CFrame
                    ghostPart.Size = realPart.Size * 0.75

                    if realPart.Transparency > 0.5 then
                        ghostPart.Transparency = 0.2
                    else
                        ghostPart.Transparency = 0.9
                    end
                end
            end
        else
            if ghostCache[p.Name] then RemoveGhost(p.Name) end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p) RemoveGhost(p.Name) end)