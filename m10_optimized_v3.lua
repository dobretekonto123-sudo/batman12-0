--[[
    Performance-Optimized UI & Gameplay Script v3.0
    Roblox June 2026 - Client-side Optimized
    Focus: Zero FPS impact, minimal loop overhead, efficient caching
    FIXED: Memory leaks, particle spawning, crash prevention
]]

-- ============================================================================
-- SERVICE INITIALIZATION (Cached)
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local MaterialService = game:GetService("MaterialService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Verify client-side execution
if not RunService:IsClient() then
	return
end

-- ============================================================================
-- RENDERING SETTINGS
-- ============================================================================

pcall(function()
	MaterialService.Use2022Materials = true
end)

-- ============================================================================
-- CONFIGURATION & CONSTANTS
-- ============================================================================

local CONFIG = {
	-- Performance settings
	RENDER_LOOP_ENABLED = true,
	UPDATE_INTERVAL = 0.5,
	PARTICLE_SPAWN_INTERVAL = 0.08,
	ORBIT_PARTICLE_COUNT = 12,
	MAX_PARTICLES_ON_SCREEN = 3,
	MAX_HOVER_PARTICLES = 20,
	
	-- Feature flags
	WATERMARK_ENABLED = true,
	STAMINA_PARTICLES_ENABLED = true,
	ATMOSPHERE_ENABLED = true,
	BUTTERFLY_EFFECT_ENABLED = true,
	REMOVE_UI_CLUTTER_ENABLED = false,
	SKILL_COOLDOWN_ENABLED = true,
	EQUIPPED_ITEMS_ENABLED = true,
}

local COLORS = {
	PRIMARY = Color3.fromRGB(235, 245, 255),
	ACCENT = Color3.fromRGB(200, 180, 255),
	STAMINA = Color3.fromRGB(185, 235, 255),
	STAMINA_GLOW = Color3.fromRGB(255, 255, 255),
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
	hoverParticles = {},
}

local function CacheConnection(conn)
	if conn then
		table.insert(Cache.connections, conn)
	end
	return conn
end

local function CleanupCache()
	for _, conn in ipairs(Cache.connections) do
		if conn and conn.Connected then
			pcall(function() conn:Disconnect() end)
		end
	end
	Cache.connections = {}
	
	for _, particle in ipairs(Cache.particles) do
		if particle and particle.Parent then
			pcall(function() particle:Destroy() end)
		end
	end
	Cache.particles = {}
	
	for _, particle in ipairs(Cache.hoverParticles) do
		if particle and particle.Parent then
			pcall(function() particle:Destroy() end)
		end
	end
	Cache.hoverParticles = {}
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

-- ============================================================================
-- WATERMARK MODULE (Ultra-Optimized)
-- ============================================================================

local Watermark = {}
Watermark.gui = nil
Watermark.statsText = nil
Watermark.isHovering = false
Watermark.orbitFrames = {}
Watermark.hoverParticleCount = 0
Watermark.hoverSpawning = false

function Watermark:InitializeOrbitData()
	local particleCount = CONFIG.ORBIT_PARTICLE_COUNT
	local avatarSize = 38
	local radius = avatarSize / 2 + 5
	
	self.orbitData = {}
	for i = 1, particleCount do
		self.orbitData[i] = {
			angle = (i / particleCount) * math.pi * 2,
			speed = math.random(85, 115) / 100,
			frame = nil,
		}
	end
end

function Watermark:Create()
	if not playerGui then return end
	
	pcall(function()
		if playerGui:FindFirstChild("Watermark") then
			playerGui.Watermark:Destroy()
		end
	end)

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

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.BLUE_GLOW
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = bar

	local particleContainer = Instance.new("Frame")
	particleContainer.Size = UDim2.fromScale(1, 1)
	particleContainer.BackgroundTransparency = 1
	particleContainer.ClipsDescendants = true
	particleContainer.Parent = bar

	Instance.new("UICorner", particleContainer).CornerRadius = UDim.new(1, 0)

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

	self.statsText = text

	pcall(function()
		TweenService:Create(
			bar,
			TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = UDim2.new(1, -8, 0, -45) }
		):Play()
	end)

	local radius = avatarSize / 2 + 5
	local t = 0
	local frameCount = 0
	local fps = 0
	local lastFpsTime = tick()

	self:InitializeOrbitData()
	for i, orbitInfo in ipairs(self.orbitData) do
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(2, 2)
		p.BackgroundColor3 = Color3.fromRGB(180, 230, 255)
		p.BackgroundTransparency = 0.2
		p.BorderSizePixel = 0
		p.ZIndex = 0
		p.Parent = avatarHolder

		Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
		orbitInfo.frame = p
		table.insert(self.orbitFrames, p)
	end

	local renderConn = CacheConnection(RunService.RenderStepped:Connect(function(dt)
		pcall(function()
			if not bar or not bar.Parent then return end

			t += dt
			frameCount += 1

			local currentTime = tick()
			if currentTime - lastFpsTime >= 1 then
				fps = frameCount
				frameCount = 0
				lastFpsTime = currentTime
			end

			for _, orbitInfo in ipairs(self.orbitData) do
				if not orbitInfo.frame or not orbitInfo.frame.Parent then 
					orbitInfo.frame = nil
					continue 
				end

				orbitInfo.angle += dt * orbitInfo.speed

				local x = avatarSize / 2 + math.cos(orbitInfo.angle) * radius
				local y = avatarSize / 2 + math.sin(orbitInfo.angle) * (radius * 0.85)

				orbitInfo.frame.Position = UDim2.fromOffset(x, y)

				local glow = (math.sin(orbitInfo.angle + t * 2) + 1) / 2
				orbitInfo.frame.BackgroundTransparency = 0.2 + glow * 0.5
				local size = 1.5 + glow * 1
				orbitInfo.frame.Size = UDim2.fromOffset(size, size)
			end
		end)
	end))

	CacheConnection(task.spawn(function()
		while bar and bar.Parent do
			task.wait(CONFIG.UPDATE_INTERVAL)

			pcall(function()
				local playersOnline = #Players:GetPlayers()
				local t_time = os.date("*t")
				local ping = self:GetPing()
				local memory = self:GetMemory()

				if text and text.Parent then
					text.Text =
						"  " .. fps .. " FPS" ..
						" ┊   " .. playersOnline .. " Online" ..
						" ┊  " .. string.format("%02d:%02d", t_time.hour, t_time.min) ..
						" ┊  " .. ping .. "ms" ..
						" ┊ ⁁  " .. memory .. "MB"
				end
			end)
		end
	end))

	CacheConnection(task.spawn(function()
		while bar and bar.Parent do
			task.wait(0.12)

			pcall(function()
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
			end)
		end
	end))

	if bar then
		CacheConnection(bar.MouseEnter:Connect(function()
			self.isHovering = true
			self:SpawnHoverParticles(particleContainer, avatarSize)
		end))

		CacheConnection(bar.MouseLeave:Connect(function()
			self.isHovering = false
			self.hoverParticleCount = 0
		end))
	end

	return gui
end

function Watermark:SpawnHoverParticles(container, avatarSize)
	if self.hoverSpawning then return end
	self.hoverSpawning = true
	
	for i = 1, 4 do
		if self.hoverParticleCount < CONFIG.MAX_HOVER_PARTICLES then
			self:CreateHoverParticle(container, avatarSize)
		end
	end

	task.spawn(function()
		while self.isHovering and container and container.Parent do
			task.wait(CONFIG.PARTICLE_SPAWN_INTERVAL)
			if self.hoverParticleCount < CONFIG.MAX_HOVER_PARTICLES then
				self:CreateHoverParticle(container, avatarSize)
			end
		end
		self.hoverSpawning = false
	end)
end

function Watermark:CreateHoverParticle(container, avatarSize)
	if not container or not container.Parent then return end
	if self.hoverParticleCount >= CONFIG.MAX_HOVER_PARTICLES then return end

	self.hoverParticleCount += 1

	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
	p.Position = UDim2.new(math.random(), 0, math.random(), 0)
	p.BackgroundColor3 = COLORS.LIGHT_BLUE
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	p.Parent = container

	Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
	table.insert(Cache.hoverParticles, p)

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
		self.hoverParticleCount = math.max(0, self.hoverParticleCount - 1)
	end)
end

function Watermark:GetPing()
	local result = 0
	pcall(function()
		local stats = game:FindFirstChildOfClass("Stats")
		if not stats then return end
		
		local network = stats:FindFirstChild("Network")
		if not network then return end
		
		local ping = network:FindFirstChild("ClientPing")
		if ping then
			result = math.floor(ping.Value)
		else
			local server = network:FindFirstChild("ServerStatsItem")
			if server then
				ping = server:FindFirstChild("Data Ping") or server:FindFirstChild("Ping")
				if ping then
					result = math.floor(ping:GetValue())
				end
			end
		end
	end)
	return result
end

function Watermark:GetMemory()
	local result = 0
	pcall(function()
		result = math.floor(Stats:GetTotalMemoryUsageMb())
	end)
	return result
end

-- ============================================================================
-- ATMOSPHERE & LIGHTING MODULE (Set once, no updates)
-- ============================================================================

local Lighting_Module = {}

function Lighting_Module:Initialize()
	pcall(function()
		for _, v in pairs(Lighting:GetChildren()) do
			if v.Name == "CustomColorFX" or v.Name == "CustomBlurFX" or v.Name == "CustomAtmosphere" then
				v:Destroy()
			end
		end

		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atm then
			atm = Instance.new("Atmosphere")
			atm.Parent = Lighting
		end

		atm.Name = "CustomAtmosphere"

		atm.Color = Color3.fromRGB(255, 235, 200)
		atm.Decay = Color3.fromRGB(255, 240, 220)
		atm.Density = 0.414
		atm.Offset = 0.27

		local main = Instance.new("ColorCorrectionEffect")
		main.Name = "CustomColorFX"
		main.Parent = Lighting
		main.Saturation = 0.65
		main.Contrast = 0.08
		main.Brightness = 0.015

		Lighting.ExposureCompensation = 0.11
		Lighting.Brightness = 2.1

		local blur = Lighting:FindFirstChildOfClass("BlurEffect")
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Parent = Lighting
		end

		blur.Name = "CustomBlurFX"
		blur.Size = 3
		blur.Enabled = true
	end)
end

-- ============================================================================
-- STAMINA PARTICLES MODULE (Optimized with pooling)
-- ============================================================================

local StaminaParticles = {}
StaminaParticles.activeParticles = 0
StaminaParticles.maxParticles = 15

function StaminaParticles:SpawnParticle(bar)
	if not bar or not bar.Parent then return end
	if self.activeParticles >= self.maxParticles then return end

	pcall(function()
		self.activeParticles += 1
		
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
			self.activeParticles = math.max(0, self.activeParticles - 1)
		end)
	end)
end

function StaminaParticles:Apply(bar)
	if not bar or bar:FindFirstChild("ParticleTag") then return end

	pcall(function()
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

		CacheConnection(task.spawn(function()
			while tag and tag.Parent do
				task.wait(CONFIG.PARTICLE_SPAWN_INTERVAL)
				self:SpawnParticle(bar)
			end
		end))
	end)
end

-- ============================================================================
-- BUTTERFLY EFFECT MODULE (Optimized)
-- ============================================================================

local Butterfly = {}
Butterfly.alive = false
Butterfly.renderConnection = nil
Butterfly.dpsConnection = nil
Butterfly.guiInstance = nil
Butterfly.butterflyParticles = {}
Butterfly.particleCleanupTasks = {}

function Butterfly:Kill()
	self.alive = false
	
	for _, task_id in ipairs(self.particleCleanupTasks) do
		pcall(function() task.cancel(task_id) end)
	end
	self.particleCleanupTasks = {}
	
	if self.renderConnection then
		pcall(function() self.renderConnection:Disconnect() end)
	end
	if self.dpsConnection then
		pcall(function() self.dpsConnection:Disconnect() end)
	end
	if self.guiInstance then
		Util.SafeDestroy(self.guiInstance)
	end
	
	for _, p in ipairs(self.butterflyParticles) do
		if p and p.Parent then
			Util.SafeDestroy(p)
		end
	end
	self.butterflyParticles = {}
end

function Butterfly:Initialize()
	pcall(function()
		if _G.ButterflyKill then
			pcall(function() _G.ButterflyKill() end)
		end

		_G.ButterflyKill = function()
			self:Kill()
		end

		self.alive = true

		local t = 0
		local speed = 1

		local function spawnParticle(pos, parent, color)
			if not parent or not parent.Parent then return end
			if not self.alive then return end

			if #self.butterflyParticles >= CONFIG.MAX_PARTICLES_ON_SCREEN then
				Util.SafeDestroy(self.butterflyParticles[1])
				table.remove(self.butterflyParticles, 1)
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

			table.insert(self.butterflyParticles, p)

			local driftY = math.random(10, 20)

			TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
				TextTransparency = 1,
				Position = UDim2.fromOffset(pos.X.Offset, pos.Y.Offset + driftY),
			}):Play()

			local cleanupId = task.delay(0.6, function()
				Util.SafeDestroy(p)
				for i, particle in ipairs(self.butterflyParticles) do
					if particle == p then
						table.remove(self.butterflyParticles, i)
						break
					end
				end
			end)
			
			table.insert(self.particleCleanupTasks, cleanupId)
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
				pcall(function()
					if not self.alive or not wing or not wing.Parent then return end

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
							if wing and wing.Parent then
								wing.TextSize = 10
								wing.TextColor3 = Color3.fromRGB(120, 200, 255)
							end
						end)
					end
				end)
			end))

			self.renderConnection = CacheConnection(RunService.RenderStepped:Connect(function(dt)
				pcall(function()
					if not self.alive or not wing or not wing.Parent then return end

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
				end)
			end))
		end

		task.defer(function()
			attach()
		end)
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
				if stamina and stamina.MinValue < 80 then
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
-- SKILL COOLDOWN MODULE (CD Function - One-time setup)
-- ============================================================================

local SkillCooldown = {}

function SkillCooldown:CD()
	task.spawn(function()
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
-- MAIN INITIALIZATION (Non-blocking)
-- ============================================================================

local function Initialize()
	if CONFIG.SKILL_COOLDOWN_ENABLED then
		SkillCooldown:CD()
	end

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

	if CONFIG.BUTTERFLY_EFFECT_ENABLED then
		task.spawn(function()
			task.wait(2)
			pcall(function()
				Butterfly:Initialize()
			end)
		end)
	end

	if CONFIG.EQUIPPED_ITEMS_ENABLED then
		task.spawn(function()
			EquippedItems:Initialize()
		end)
	end

	task.spawn(function()
		StaminaBoost:Initialize()
	end)
end

task.defer(Initialize)

-- ============================================================================
-- CHARACTER RESPAWN HANDLING
-- ============================================================================

CacheConnection(player.CharacterAdded:Connect(function()
	task.wait(2)
	if CONFIG.SKILL_COOLDOWN_ENABLED then
		SkillCooldown:CD()
	end
end))

-- ============================================================================
-- GRACEFUL CLEANUP
-- ============================================================================

CacheConnection(script:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not script.Enabled then
		Butterfly:Kill()
		CleanupCache()
	end
end))
