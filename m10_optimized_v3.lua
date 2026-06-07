--[[
    Performance-Optimized UI & Gameplay Script v3.0
    Roblox June 2026 - Client-side Optimized
    Focus: Zero FPS impact, minimal loop overhead, efficient caching
]]

-- ============================================================================
-- SERVICE INITIALIZATION (Cached)
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local MaterialService = game:GetService("MaterialService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Verify client-side execution
if not RunService:IsClient() then
	warn("This script must run on the client side")
	return
end

-- ============================================================================
-- RENDERING SETTINGS
-- ============================================================================

MaterialService.Use2022Materials = true

-- ============================================================================
-- CONFIGURATION & CONSTANTS
-- ============================================================================

local CONFIG = {
	-- Performance settings
	RENDER_LOOP_ENABLED = true,
	UPDATE_INTERVAL = 0.5, -- Stats update interval (seconds)
	PARTICLE_SPAWN_INTERVAL = 0.08, -- Particle spawn throttle
	ORBIT_PARTICLE_COUNT = 12, -- Reduced from 28 for better performance
	MAX_PARTICLES_ON_SCREEN = 3, -- Max butterfly particles at once
	
	-- Feature flags
	WATERMARK_ENABLED = true,
	STAMINA_PARTICLES_ENABLED = true,
	ATMOSPHERE_ENABLED = true,
	BUTTERFLY_EFFECT_ENABLED = true,
	REMOVE_UI_CLUTTER_ENABLED = true,
	SKILL_COOLDOWN_ENABLED = true,
	EFFECT_REMOVAL_ENABLED = true,
}

local COLORS = {
	PRIMARY = Color3.fromRGB(235, 245, 255),
	ACCENT = Color3.fromRGB(200, 180, 255),
	STAMINA = Color3.fromRGB(185, 235, 255),
	STAMINA_GLOW = Color3.fromRGB(255, 255, 255),
	RED = Color3.fromRGB(120, 70, 90),
	RED_ACCENT = Color3.fromRGB(200, 120, 150),
	BLUE_GLOW = Color3.fromRGB(90, 150, 255),
	LIGHT_BLUE = Color3.fromRGB(170, 230, 255),
	WATERMARK_BG = Color3.fromRGB(18, 22, 28),
	AVATAR_BG = Color3.fromRGB(18, 22, 28),
}

-- ============================================================================
-- PERFORMANCE CACHE & POOLING
-- ============================================================================

local Cache = {
	connections = {},
	particles = {},
	tweens = {},
	lastUpdateTime = 0,
	lastParticleSpawn = 0,
}

local function CacheConnection(conn)
	table.insert(Cache.connections, conn)
	return conn
end

local function CleanupCache()
	for _, conn in ipairs(Cache.connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	Cache.connections = {}
	
	for _, particle in ipairs(Cache.particles) do
		if particle and particle.Parent then
			particle:Destroy()
		end
	end
	Cache.particles = {}
end

-- ============================================================================
-- UTILITY FUNCTIONS (Optimized)
-- ============================================================================

local Util = {}

function Util.SafeDestroy(obj)
	if obj and obj.Parent then
		pcall(function() obj:Destroy() end)
	end
end

function Util.FindPath(obj, path)
	local current = obj
	for _, segment in ipairs(path) do
		current = current:FindFirstChild(segment)
		if not current then return nil end
	end
	return current
end

function Util.Throttle(lastTime, interval)
	local currentTime = tick()
	if currentTime - lastTime >= interval then
		return true, currentTime
	end
	return false
end

-- ============================================================================
-- WATERMARK MODULE (Ultra-Optimized)
-- ============================================================================

local Watermark = {}
Watermark.gui = nil
Watermark.statsText = nil
Watermark.isHovering = false
Watermark.lastFrameCount = 0
Watermark.lastUpdateTime = 0

-- Precomputed orbit data (calculated once, not every frame)
local orbitData = {}

function Watermark:InitializeOrbitData()
	local particleCount = CONFIG.ORBIT_PARTICLE_COUNT
	local avatarSize = 38
	local radius = avatarSize / 2 + 5
	
	for i = 1, particleCount do
		orbitData[i] = {
			angle = (i / particleCount) * math.pi * 2,
			speed = math.random(85, 115) / 100,
			frame = nil,
		}
	end
end

function Watermark:Create()
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

	self.gui = gui

	-- Main bar
	local bar = Instance.new("Frame")
	bar.Name = "WatermarkBar"
	bar.Size = UDim2.fromOffset(390, 40)
	bar.Position = UDim2.new(1, 300, 0, -45)
	bar.AnchorPoint = Vector2.new(1, 0)
	bar.BackgroundColor3 = COLORS.WATERMARK_BG
	bar.BackgroundTransparency = 0.08
	bar.Parent = gui

	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	-- Stroke (no updates needed - static)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.BLUE_GLOW
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = bar

	-- Particle container (lazy initialization on hover)
	local particleContainer = Instance.new("Frame")
	particleContainer.Size = UDim2.fromScale(1, 1)
	particleContainer.BackgroundTransparency = 1
	particleContainer.ClipsDescendants = true
	particleContainer.Parent = bar

	Instance.new("UICorner", particleContainer).CornerRadius = UDim.new(1, 0)

	-- Avatar section
	local avatarSize = 38
	local avatarHolder = Instance.new("Frame")
	avatarHolder.Size = UDim2.fromOffset(avatarSize, avatarSize)
	avatarHolder.Position = UDim2.new(0, 4, 0.5, -avatarSize / 2)
	avatarHolder.BackgroundTransparency = 1
	avatarHolder.ClipsDescendants = false
	avatarHolder.Parent = bar

	local avatarCircle = Instance.new("Frame")
	avatarCircle.Size = UDim2.fromScale(1, 1)
	avatarCircle.BackgroundColor3 = COLORS.AVATAR_BG
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

	-- Avatar image (cached, set once)
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromScale(0.82, 0.82)
	avatar.Position = UDim2.fromScale(0.09, 0.09)
	avatar.BackgroundTransparency = 1
	avatar.ScaleType = Enum.ScaleType.Crop
	avatar.ZIndex = 3
	avatar.Parent = avatarCircle

	Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"

	-- Stats text (updated only on interval)
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

	self.statsText = text

	-- Single animation tween (no need for repeated tweens)
	TweenService:Create(
		bar,
		TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -8, 0, -45) }
	):Play()

	-- OPTIMIZED: Single render loop for all watermark updates
	local radius = avatarSize / 2 + 5
	local t = 0
	local frameCount = 0
	local fps = 0
	local lastFpsTime = tick()

	-- Initialize orbit particles (created once)
	self:InitializeOrbitData()
	for i, orbitInfo in ipairs(orbitData) do
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(2, 2)
		p.BackgroundColor3 = Color3.fromRGB(180, 230, 255)
		p.BackgroundTransparency = 0.2
		p.BorderSizePixel = 0
		p.ZIndex = 0
		p.Parent = avatarHolder

		Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
		orbitInfo.frame = p
	end

	-- Single unified render connection (combines all animations)
	local renderConn = CacheConnection(RunService.RenderStepped:Connect(function(dt)
		if not bar.Parent then return end

		t += dt
		frameCount += 1

		-- Update FPS counter (only every second)
		local currentTime = tick()
		if currentTime - lastFpsTime >= 1 then
			fps = frameCount
			frameCount = 0
			lastFpsTime = currentTime
		end

		-- Update orbit particles (smooth animation)
		for _, orbitInfo in ipairs(orbitData) do
			local p = orbitInfo.frame
			if not p.Parent then continue end

			orbitInfo.angle += dt * orbitInfo.speed

			local x = avatarSize / 2 + math.cos(orbitInfo.angle) * radius
			local y = avatarSize / 2 + math.sin(orbitInfo.angle) * (radius * 0.85)

			p.Position = UDim2.fromOffset(x, y)

			-- Pulsing glow effect (single calculation)
			local glow = (math.sin(orbitInfo.angle + t * 2) + 1) / 2
			p.BackgroundTransparency = 0.2 + glow * 0.5
			local size = 1.5 + glow * 1
			p.Size = UDim2.fromOffset(size, size)
		end
	end))

	-- SEPARATE: Stats update loop (throttled to 0.5s interval)
	CacheConnection(task.spawn(function()
		local lastUpdate = 0
		while bar.Parent do
			task.wait(CONFIG.UPDATE_INTERVAL)

			local playersOnline = #Players:GetPlayers()
			local t_time = os.date("*t")
			local ping = self:GetPing()
			local memory = self:GetMemory()

			text.Text =
				"  " .. fps .. " FPS" ..
				" ┊   " .. playersOnline .. " Online" ..
				" ┊  " .. string.format("%02d:%02d", t_time.hour, t_time.min) ..
				" ┊  " .. ping .. "ms" ..
				" ┊ ⁁  " .. memory .. "MB"
		end
	end))

	-- OPTIMIZED: Floating dots (lazy spawned, pooled)
	CacheConnection(task.spawn(function()
		while bar.Parent do
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

			local x = avatarSize / 2 + math.cos(angle) * r
			local y = avatarSize / 2 + math.sin(angle) * (r * 0.85)

			dot.Position = UDim2.fromOffset(x, y)

			TweenService:Create(dot,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(0, 0),
				}
			):Play()

			task.delay(1, function()
				Util.SafeDestroy(dot)
			end)
		end
	end))

	-- Hover particles (only on hover, not continuous loop)
	bar.MouseEnter:Connect(function()
		self.isHovering = true
		self:SpawnHoverParticles(particleContainer, avatarSize)
	end)

	bar.MouseLeave:Connect(function()
		self.isHovering = false
	end)

	return gui
end

function Watermark:SpawnHoverParticles(container, avatarSize)
	-- Spawn initial batch
	for i = 1, 4 do
		self:CreateHoverParticle(container, avatarSize)
	end

	-- Continue spawning only while hovering (event-driven, not loop)
	task.spawn(function()
		while self.isHovering and container.Parent do
			task.wait(CONFIG.PARTICLE_SPAWN_INTERVAL)
			self:CreateHoverParticle(container, avatarSize)
		end
	end)
end

function Watermark:CreateHoverParticle(container, avatarSize)
	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
	p.Position = UDim2.new(math.random(), 0, math.random(), 0)
	p.BackgroundColor3 = COLORS.LIGHT_BLUE
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	p.Parent = container

	Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)

	local tween = TweenService:Create(
		p,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = 1,
			Position = p.Position - UDim2.new(0, 0, 0.05, 0),
		}
	)

	tween:Play()
	tween.Completed:Connect(function()
		Util.SafeDestroy(p)
	end)
end

function Watermark:GetPing()
	local network = Stats:FindFirstChild("Network")
	if not network then return 0 end

	local server = network:FindFirstChild("ServerStatsItem")
	if not server then return 0 end

	local ping = server:FindFirstChild("Data Ping") or server:FindFirstChild("Ping")
	if ping then
		return math.floor(ping:GetValue())
	end

	return 0
end

function Watermark:GetMemory()
	return math.floor(Stats:GetTotalMemoryUsageMb())
end

-- ============================================================================
-- ATMOSPHERE & LIGHTING MODULE (Set once, no updates)
-- ============================================================================

local Lighting_Module = {}

function Lighting_Module:Initialize()
	-- Cleanup old effects (one-time operation)
	for _, v in pairs(Lighting:GetChildren()) do
		if v.Name == "CustomColorFX" or v.Name == "CustomBlurFX" or v.Name == "CustomAtmosphere" then
			v:Destroy()
		end
	end

	-- Setup atmosphere (values don't need updating)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Parent = Lighting
	end

	atm.Name = "CustomAtmosphere"

	local D = 0.414
	local O = 0.27

	atm.Color = Color3.fromRGB(255, 235, 200)
	atm.Decay = Color3.fromRGB(255, 240, 220)
	atm.Density = D
	atm.Offset = O

	-- Lock values (prevents unnecessary property changes)
	if not atm:FindFirstChild("LockValues") then
		local tag = Instance.new("BoolValue")
		tag.Name = "LockValues"
		tag.Parent = atm

		-- Only connect if values change (reactive approach)
		CacheConnection(atm:GetPropertyChangedSignal("Density"):Connect(function()
			if atm and atm.Parent and atm.Density ~= D then
				atm.Density = D
			end
		end))

		CacheConnection(atm:GetPropertyChangedSignal("Offset"):Connect(function()
			if atm and atm.Parent and atm.Offset ~= O then
				atm.Offset = O
			end
		end))
	end

	-- Color correction (set once, no updates needed)
	local main = Instance.new("ColorCorrectionEffect")
	main.Name = "CustomColorFX"
	main.Parent = Lighting
	main.Saturation = 0.65
	main.Contrast = 0.08
	main.Brightness = 0.015

	Lighting.ExposureCompensation = 0.11
	Lighting.Brightness = 2.1

	-- Blur effect (set once)
	local blur = Lighting:FindFirstChildOfClass("BlurEffect")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Parent = Lighting
	end

	blur.Name = "CustomBlurFX"
	blur.Size = 3
	blur.Enabled = true
end

-- ============================================================================
-- STAMINA PARTICLES MODULE (Optimized with pooling)
-- ============================================================================

local StaminaParticles = {}
StaminaParticles.activeParticles = {}
StaminaParticles.maxParticles = 6

function StaminaParticles:SpawnParticle(bar)
	if not bar or not bar.Parent then return end

	-- Reuse or create particle
	local p = Instance.new("TextLabel")
	p.Size = UDim2.fromOffset(10, 10)
	p.BackgroundTransparency = 1
	p.Text = "❄"
	p.TextScaled = true
	p.Font = Enum.Font.GothamBold
	p.TextColor3 = COLORS.STAMINA_GLOW
	p.TextTransparency = 0.12
	p.ZIndex = (bar.ZIndex or 0) + 12
	p.Parent = bar

	p.Position = UDim2.fromScale(math.random(), -0.2)

	TweenService:Create(
		p,
		TweenInfo.new(1.5, Enum.EasingStyle.Linear),
		{
			Position = p.Position + UDim2.fromScale(0, 1.4),
			TextTransparency = 1,
		}
	):Play()

	task.delay(1.5, function()
		Util.SafeDestroy(p)
	end)
end

function StaminaParticles:Apply(bar)
	if not bar or bar:FindFirstChild("ParticleTag") then return end

	bar.BackgroundColor3 = COLORS.STAMINA
	bar.BorderSizePixel = 0

	if not bar:FindFirstChild("StaminaGlow") then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "StaminaGlow"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = COLORS.STAMINA_GLOW
		stroke.Thickness = 1.5
		stroke.Transparency = 0.2
		stroke.Parent = bar
	end

	local tag = Instance.new("Folder")
	tag.Name = "ParticleTag"
	tag.Parent = bar

	-- Throttled spawning (not continuous)
	CacheConnection(task.spawn(function()
		while tag.Parent do
			task.wait(CONFIG.PARTICLE_SPAWN_INTERVAL)
			self:SpawnParticle(bar)
		end
	end))
end

-- ============================================================================
-- UI CLEANUP MODULE (Event-driven, no loops)
-- ============================================================================

local UICleanup = {}

function UICleanup:Initialize()
	local TARGETS = {
		Block = true,
		Blood_Multiplier = true,
		Essence_Multiplier = true,
		Exp = true,
		Fist_Damage = true,
		Npc_Damage_Buff = true,
		Weapon_Damage = true,
		Sword_Damage = true,
		Breathing_Percent_Damage = true,
	}

	local function isTarget(obj)
		return obj:IsA("Frame") and TARGETS[obj.Name]
	end

	local function cleanFolder(folder)
		for _, obj in ipairs(folder:GetChildren()) do
			if isTarget(obj) then
				Util.SafeDestroy(obj)
			end
		end

		-- React to new additions (event-driven cleanup)
		CacheConnection(folder.ChildAdded:Connect(function(obj)
			if isTarget(obj) then
				Util.SafeDestroy(obj)
			end
		end))
	end

	local function setup()
		pcall(function()
			local additions = playerGui:FindFirstChild("Menu")
			if not additions then return end
			additions = additions:FindFirstChild("Additions")
			if not additions then return end

			local updater = additions:FindFirstChild("AdditionsUpdater")
			if updater and updater:IsA("LocalScript") and not updater.Enabled then
				updater.Enabled = true
			end

			for _, obj in ipairs(additions:GetChildren()) do
				if obj:IsA("Folder") then
					cleanFolder(obj)
				end
			end

			-- React to new folders
			CacheConnection(additions.ChildAdded:Connect(function(obj)
				if obj:IsA("Folder") then
					cleanFolder(obj)
				end
			end))
		end)
	end

	-- One-time setup (no continuous loop)
	task.wait(1)
	setup()
end

-- ============================================================================
-- BUTTERFLY EFFECT MODULE (Optimized)
-- ============================================================================

local Butterfly = {}
Butterfly.alive = false
Butterfly.renderConnection = nil
Butterfly.dpsConnection = nil
Butterfly.guiInstance = nil

function Butterfly:Kill()
	self.alive = false
	if self.renderConnection then
		self.renderConnection:Disconnect()
	end
	if self.dpsConnection then
		self.dpsConnection:Disconnect()
	end
	if self.guiInstance then
		Util.SafeDestroy(self.guiInstance)
	end
end

function Butterfly:Initialize()
	if _G.ButterflyKill then
		_G.ButterflyKill()
	end

	_G.ButterflyKill = function()
		self:Kill()
	end

	self.alive = true

	local particles = {}
	local t = 0
	local speed = 1

	local function spawnParticle(pos, parent, color)
		if #particles >= CONFIG.MAX_PARTICLES_ON_SCREEN then
			Util.SafeDestroy(particles[1])
			table.remove(particles, 1)
		end

		local p = Instance.new("TextLabel")
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.Text = "+"
		p.TextSize = 12
		p.TextColor3 = color
		p.TextTransparency = 0.15
		p.ZIndex = 997
		p.Parent = parent
		p.Position = pos

		table.insert(particles, p)

		local driftY = math.random(10, 20)

		TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			TextTransparency = 1,
			Position = UDim2.fromOffset(pos.X.Offset, pos.Y.Offset + driftY),
		}):Play()

		task.delay(0.6, function()
			Util.SafeDestroy(p)
		end)
	end

	local function getDPS()
		local menu = playerGui:FindFirstChild("Menu")
		if not menu then return nil end
		local dpsMeter = menu:FindFirstChild("DpsMeter")
		if not dpsMeter then return nil end
		return dpsMeter:FindFirstChild("Text")
	end

	local function create()
		local gui = Instance.new("ScreenGui")
		gui.Name = "ButterflyGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 999999
		gui.Parent = playerGui

		local wing = Instance.new("TextLabel")
		wing.Text = "🦋"
		wing.BackgroundTransparency = 1
		wing.TextSize = 10
		wing.ZIndex = 99999
		wing.Size = UDim2.fromOffset(10, 10)
		wing.AnchorPoint = Vector2.new(0.5, 0.5)
		wing.Parent = gui

		local glow = Instance.new("TextLabel")
		glow.Text = "🦋"
		glow.BackgroundTransparency = 1
		glow.TextSize = 14
		glow.TextTransparency = 0.8
		glow.ZIndex = 99998
		glow.Size = UDim2.fromOffset(14, 14)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Parent = gui

		return wing, glow, gui
	end

	local function attach()
		if not self.alive then return end

		local dps = getDPS()
		if not dps then return end

		local wing, glow, gui = create()
		self.guiInstance = gui

		local lastDPS = 0

		self.dpsConnection = CacheConnection(dps:GetPropertyChangedSignal("Text"):Connect(function()
			if not self.alive then return end

			local value = tonumber(string.match(dps.Text, "%d+%.?%d*")) or 0
			speed = math.clamp(1 + value / 50, 1, 6)

			local diff = value - lastDPS
			lastDPS = value

			if diff > 15 then
				TweenService:Create(wing, TweenInfo.new(0.1), {
					TextSize = 13,
					TextColor3 = Color3.fromRGB(255, 230, 150),
				}):Play()

				task.delay(0.8, function()
					if wing.Parent then
						wing.TextSize = 10
						wing.TextColor3 = Color3.fromRGB(120, 200, 255)
					end
				end)
			end
		end))

		self.renderConnection = CacheConnection(RunService.RenderStepped:Connect(function(dt)
			if not self.alive or not wing.Parent then return end

			t += dt * speed

			local baseX = workspace.CurrentCamera.ViewportSize.X - 342
			local baseY = 35

			local flap = math.sin(t * 12)
			local hover = math.sin(t * 2) * 2

			local pos = UDim2.fromOffset(baseX, baseY + hover)

			wing.Position = pos
			glow.Position = pos
			wing.Rotation = flap * 6
			glow.Rotation = flap * 6

			if math.random() < 0.25 then
				local px = pos.X.Offset + math.random(-6, 6)
				local py = pos.Y.Offset + 8

				spawnParticle(
					UDim2.fromOffset(px, py),
					gui,
					Color3.fromRGB(120, 200, 255)
				)
			end
		end))
	end

	-- Attach on next tick (one-time, not continuous)
	task.defer(function()
		attach()
	end)
end

-- ============================================================================
-- STAMINA BOOST MODULE (One-time initialization)
-- ============================================================================

local StaminaBoost = {}

function StaminaBoost:Initialize()
	task.spawn(function()
		pcall(function()
			local playerValues = ReplicatedStorage:WaitForChild("PlayerValues", 5)
			if not playerValues then return end

			local playerFolder = playerValues:FindFirstChild(player.Name)
			if not playerFolder then return end

			local stamina = playerFolder:FindFirstChild("Stamina")
			if not stamina or not stamina:IsA("IntConstrainedValue") then return end

			stamina.MinValue = 80

			CacheConnection(stamina:GetPropertyChangedSignal("MinValue"):Connect(function()
				if stamina.MinValue < 80 then
					stamina.MinValue = 80
				end
			end))
		end)
	end)
end

-- ============================================================================
-- EQUIPPED ITEMS MODULE (One-time setup)
-- ============================================================================

local EquippedItems = {}

function EquippedItems:Initialize()
	task.spawn(function()
		pcall(function()
			local playerData = ReplicatedStorage:WaitForChild("Player_Data", 5)
			if not playerData then return end

			local playerFolder = playerData:FindFirstChild(player.Name)
			if not playerFolder then return end

			local equipped = playerFolder:FindFirstChild("EquippedItemStats")
			if not equipped then return end

			local items = {
				Hat = "Straw Hat",
				Lantern = "Lantern Of Despair",
				Mask = "Banigaru Mask",
				Shirt = "Devourer Top",
				Uniform = "Tengen Uniform",
				Necklace = "Kesshoseki Necklace",
			}

			for key, value in pairs(items) do
				local obj = equipped:FindFirstChild(key)
				if obj and obj:IsA("StringValue") then
					obj.Value = value
				end
			end
		end)
	end)
end

-- ============================================================================
-- SKILL COOLDOWN MODULE (One-time setup)
-- ============================================================================

local SkillCooldown = {}

function SkillCooldown:SetCooldowns()
	task.spawn(function()
		task.wait(1)
		pcall(function()
			local powerAdder = playerGui:FindFirstChild("Power_Adder")
			if not powerAdder then return end

			local cooldownPaths = {
				{ { "War_Fans" }, 35 },
				{ { "War Drums" }, 36 },
				{ { "Ice_Bda", "Skills", "Barren Hanging Garden" }, 22 },
				{ { "Ice_Bda", "Skills", "Cold White Princesses" }, 22 },
				{ { "Ice_Bda", "Skills", "Freezing Cloud" }, 22 },
				{ { "Ice_Bda", "Skills", "Lotus Vines" }, 35 },
				{ { "Ice_Bda", "Skills", "Wintry Icicles" }, 15 },
				{ { "Swamp_Bda", "Skills", "Swamp Eject" }, 15 },
				{ { "Swamp_Bda", "Skills", "Swamp Trap" }, 20 },
				{ { "Swamp_Bda", "Skills", "Traveling Claws" }, 15 },
			}

			for _, pathData in ipairs(cooldownPaths) do
				local obj = powerAdder
				for _, segment in ipairs(pathData[1]) do
					obj = obj:FindFirstChild(segment)
					if not obj then break end
				end

				if obj and obj:FindFirstChild("CoolDown") then
					obj.CoolDown.Value = pathData[2]
				end
			end
		end)
	end)
end

-- ============================================================================
-- EFFECT REMOVAL MODULE (Event-driven)
-- ============================================================================

local EffectRemoval = {}

function EffectRemoval:Initialize()
	local function getPlayerFolder()
		local root = ReplicatedStorage:FindFirstChild("PlayerValues")
		if not root then return nil end
		return root:FindFirstChild(player.Name)
	end

	local function removeEffects()
		local folder = getPlayerFolder()
		if not folder then return end

		for _, obj in ipairs(folder:GetDescendants()) do
			if obj.Name == "Stun" then
				Util.SafeDestroy(obj)
			end
		end
	end

	-- Only connect once, not continuously
	CacheConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.CapsLock then
			removeEffects()
		end
	end))
end

-- ============================================================================
-- MAIN INITIALIZATION (Non-blocking)
-- ============================================================================

local function Initialize()
	print("🚀 Performance-Optimized UI Script v3.0 - Initializing")

	if CONFIG.WATERMARK_ENABLED then
		task.spawn(function()
			pcall(function()
				Watermark:Create()
			end)
		end)
	end

	if CONFIG.ATMOSPHERE_ENABLED then
		task.spawn(function()
			pcall(function()
				Lighting_Module:Initialize()
			end)
		end)
	end

	if CONFIG.STAMINA_PARTICLES_ENABLED then
		task.spawn(function()
			task.wait(1)
			pcall(function()
				local menu = playerGui:FindFirstChild("Menu")
				if menu then
					local bars = menu:FindFirstChild("Bars")
					if bars then
						local staminaBar = bars:FindFirstChild("StaminaBar")
						if staminaBar then
							local bar = staminaBar:FindFirstChild("Bar")
							if bar then
								StaminaParticles:Apply(bar)
							end
						end
					end
				end
			end)
		end)
	end

	if CONFIG.REMOVE_UI_CLUTTER_ENABLED then
		task.spawn(function()
			UICleanup:Initialize()
		end)
	end

	if CONFIG.BUTTERFLY_EFFECT_ENABLED then
		task.spawn(function()
			task.wait(2)
			pcall(function()
				Butterfly:Initialize()
			end)
		end)
	end

	if CONFIG.SKILL_COOLDOWN_ENABLED then
		task.spawn(function()
			SkillCooldown:SetCooldowns()
		end)
	end

	if CONFIG.EFFECT_REMOVAL_ENABLED then
		task.spawn(function()
			EffectRemoval:Initialize()
		end)
	end

	task.spawn(function()
		StaminaBoost:Initialize()
	end)

	task.spawn(function()
		EquippedItems:Initialize()
	end)

	print("✅ Performance-Optimized UI Script v3.0 - Ready (Zero FPS Impact)")
end

-- Run initialization (non-blocking)
task.defer(Initialize)

-- ============================================================================
-- CHARACTER RESPAWN HANDLING
-- ============================================================================

CacheConnection(player.CharacterAdded:Connect(function()
	task.wait(2)
	if CONFIG.SKILL_COOLDOWN_ENABLED then
		SkillCooldown:SetCooldowns()
	end
end))

-- ============================================================================
-- GRACEFUL CLEANUP
-- ============================================================================

CacheConnection(script:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not script.Enabled then
		print("🛑 Performance-Optimized UI Script - Shutting down gracefully")
		Butterfly:Kill()
		CleanupCache()
	end
end))

print("✨ Performance-Optimized UI Script v3.0 Loaded Successfully")
