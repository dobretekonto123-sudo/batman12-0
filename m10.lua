local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MaterialService = game:GetService("MaterialService")
local player = Players.LocalPlayer

MaterialService.Use2022Materials = true


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
bar.Size = UDim2.fromOffset(390,40)
bar.Position = UDim2.new(1,-8,0,-45)
bar.AnchorPoint = Vector2.new(1,0)
bar.BackgroundColor3 = Color3.fromRGB(18,22,28)
bar.BackgroundTransparency = 0.08
bar.Parent = gui

Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90,150,255)
stroke.Transparency = 0.8
stroke.Thickness = 1
stroke.Parent = bar

local glowGradient = Instance.new("UIGradient")
glowGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150,220,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(90,160,255))
}
glowGradient.Parent = shoreGlow

local particleContainer = Instance.new("Frame")
particleContainer.Size = UDim2.fromScale(1,1)
particleContainer.BackgroundTransparency = 1
particleContainer.ClipsDescendants = true
particleContainer.Parent = bar

Instance.new("UICorner", particleContainer).CornerRadius = UDim.new(1,0)

local function spawnParticle()

	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(math.random(2,4), math.random(2,4))
	p.Position = UDim2.new(
		math.random(),
		0,
		math.random(),
		0
	)
	p.BackgroundColor3 = Color3.fromRGB(170,230,255)
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	p.Parent = particleContainer

	Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)

	local tween = TweenService:Create(
		p,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = 1,
			Position = p.Position - UDim2.new(0,0,0.05,0)
		}
	)

	tween:Play()

	tween.Completed:Connect(function()
		p:Destroy()
	end)
end

local hovering = false

bar.MouseEnter:Connect(function()

	hovering = true

	for i = 1,12 do
		spawnParticle()
	end

	task.spawn(function()
		while hovering do
			spawnParticle()
			task.wait(0.08)
		end
	end)

end)

bar.MouseLeave:Connect(function()

	hovering = false

	TweenService:Create(
		shoreGlow,
		TweenInfo.new(0.25),
		{
			Transparency = 1,
			Thickness = 1
		}
	):Play()

end)

local avatarSize = 38

local avatarHolder = Instance.new("Frame")
avatarHolder.Size = UDim2.fromOffset(avatarSize, avatarSize)
avatarHolder.Position = UDim2.new(0,4,0.5,-avatarSize/2)
avatarHolder.BackgroundTransparency = 1
avatarHolder.ClipsDescendants = false
avatarHolder.Parent = bar

local avatarCircle = Instance.new("Frame")
avatarCircle.Size = UDim2.fromScale(1,1)
avatarCircle.BackgroundColor3 = Color3.fromRGB(18,22,28)
avatarCircle.ZIndex = 2
avatarCircle.Parent = avatarHolder

Instance.new("UICorner", avatarCircle).CornerRadius = UDim.new(1,0)

local innerGlow = Instance.new("Frame")
innerGlow.Size = UDim2.fromScale(1,1)
innerGlow.BackgroundColor3 = Color3.fromRGB(200,230,255)
innerGlow.BackgroundTransparency = 0.95
innerGlow.ZIndex = 1
innerGlow.Parent = avatarCircle

Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(1,0)

local orbitParticles = {}
local particleCount = 28
local radius = avatarSize/2 + 5

for i = 1, particleCount do
	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(2,2)
	p.BackgroundColor3 = Color3.fromRGB(180,230,255)
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	p.ZIndex = 0
	p.Parent = avatarHolder

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1,0)
	c.Parent = p

	orbitParticles[i] = {
		frame = p,
		angle = (i/particleCount) * math.pi * 2,
		speed = math.random(85,115)/100,
	}
end

local t = 0

RunService.RenderStepped:Connect(function(dt)
	t += dt

	for _,data in ipairs(orbitParticles) do
		local p = data.frame

		data.angle += dt * data.speed

		local x = avatarSize/2 + math.cos(data.angle) * radius
		local y = avatarSize/2 + math.sin(data.angle) * (radius * 0.85)

		p.Position = UDim2.fromOffset(x,y)

		local glow = (math.sin(data.angle + t*2) + 1)/2

		p.BackgroundTransparency = 0.2 + glow * 0.5

		local size = 1.5 + glow * 1
		p.Size = UDim2.fromOffset(size,size)
	end
end)

task.spawn(function()
	while avatarHolder.Parent do
		task.wait(0.12)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(1,1)
		dot.BackgroundColor3 = Color3.fromRGB(220,240,255)
		dot.BackgroundTransparency = 0.2
		dot.BorderSizePixel = 0
		dot.ZIndex = 0
		dot.Parent = avatarHolder

		Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

		local angle = math.random() * math.pi * 2
		local r = radius + math.random(-2,4)

		local x = avatarSize/2 + math.cos(angle) * r
		local y = avatarSize/2 + math.sin(angle) * (r * 0.85)

		dot.Position = UDim2.fromOffset(x,y)

		TweenService:Create(dot,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(0,0)
			}
		):Play()

		task.delay(1,function()
			if dot then dot:Destroy() end
		end)
	end
end)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromScale(0.82,0.82)
avatar.Position = UDim2.fromScale(0.09,0.09)
avatar.BackgroundTransparency = 1
avatar.ScaleType = Enum.ScaleType.Crop
avatar.ZIndex = 3
avatar.Parent = avatarCircle

Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)

avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"

local text = Instance.new("TextLabel")
text.Size = UDim2.new(1,-80,1,0)
text.Position = UDim2.new(0,70,0,0)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.fromRGB(235,245,255)
text.Font = Enum.Font.GothamMedium
text.TextSize = 13
text.TextXAlignment = Enum.TextXAlignment.Left
text.Text = "Loading..."
text.Parent = bar

	local frames = 0
	local fps = 0

	RunService.RenderStepped:Connect(function()
		frames += 1
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			fps = frames
			frames = 0
		end
	end)

	local function getPing()
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

     local function getMemory()
	local mem = Stats:GetTotalMemoryUsageMb()
	return math.floor(mem)
end

	task.spawn(function()
		while true do
			task.wait(0.5)

			local playersOnline = #Players:GetPlayers()
			local t = os.date("*t")
			local ping = getPing()
            local memory = getMemory()

        text.Text =
	"  " .. fps .. " FPS"
	.. " ┊   " .. playersOnline .. " Online"
	.. " ┊  " .. string.format("%02d:%02d", t.hour, t.min)
	.. " ┊  " .. ping .. "ms"
	.. " ┊ ⁁  " .. memory .. "MB" 
                
		end
	end)

bar.Position = UDim2.new(1,300,0,-45)

TweenService:Create(
	bar,
	TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	{Position = UDim2.new(1,-8,0,-45)}
):Play()

end

CreateWatermark()

local stamina = ReplicatedStorage:WaitForChild("PlayerValues"):WaitForChild(player.Name):WaitForChild("Stamina")

if stamina:IsA("IntConstrainedValue") then
	stamina.MinValue = 80
	stamina:GetPropertyChangedSignal("MinValue"):Connect(function()
		if stamina.MinValue < 80 then
			stamina.MinValue = 80
		end
	end)
end

local equipped = ReplicatedStorage:WaitForChild("Player_Data"):WaitForChild(player.Name):WaitForChild("EquippedItemStats")

for k,v in pairs({
	Hat="Straw Hat",
	Lantern="Lantern Of Despair",
	Mask="Banigaru Mask",
	Shirt="Devourer Top",
	Uniform="Tengen Uniform",
	Necklace="Kesshoseki Necklace"
}) do
	local obj = equipped:WaitForChild(k)
	if obj:IsA("StringValue") then
		obj.Value = v
	end
end


local Lighting = game:GetService("Lighting")

for _, v in pairs(Lighting:GetChildren()) do
	if v.Name == "CustomColorFX" or v.Name == "CustomBlurFX" then
		v:Destroy()
	end
end

local atm = Lighting:FindFirstChildOfClass("Atmosphere")
if not atm then
	atm = Instance.new("Atmosphere")
	atm.Parent = Lighting
end

atm.Name = "CustomAtmosphere"

local D = 0.414
local O = 0.27

atm.Color = Color3.fromRGB(255,235,200)
atm.Decay = Color3.fromRGB(255,240,220)
atm.Density = D
atm.Offset = O

if not atm:FindFirstChild("LockValues") then
	local tag = Instance.new("BoolValue")
	tag.Name = "LockValues"
	tag.Parent = atm

	atm:GetPropertyChangedSignal("Density"):Connect(function()
		if atm and atm.Parent then
			atm.Density = D
		end
	end)

	atm:GetPropertyChangedSignal("Offset"):Connect(function()
		if atm and atm.Parent then
			atm.Offset = O
		end
	end)
end

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

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
--[[
local FPS_SEQ = ColorSequence.new{
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,182,193)),
	ColorSequenceKeypoint.new(0.18, Color3.fromRGB(255,215,228)),
	ColorSequenceKeypoint.new(0.36, Color3.fromRGB(255,245,248)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255,225,236)),
	ColorSequenceKeypoint.new(0.70, Color3.fromRGB(248,195,215)),
	ColorSequenceKeypoint.new(0.86, Color3.fromRGB(255,238,244)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,190,220))
}

local function lockGradient(obj)
	if not obj or not obj:IsA("UIGradient") then return end

	obj.Color = FPS_SEQ
	obj.Rotation = 20

	obj:GetPropertyChangedSignal("Color"):Connect(function()
		obj.Color = FPS_SEQ
	end)

	obj:GetPropertyChangedSignal("Rotation"):Connect(function()
		obj.Rotation = 20
	end)
end

local function applyFPS(frame)
	if not frame then return end

	for _,v in ipairs(frame:GetDescendants()) do
		lockGradient(v)
	end

	frame.DescendantAdded:Connect(lockGradient)
end
]]











local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
--[[

local C1 = Color3.fromRGB(255, 245, 255)
local C2 = Color3.fromRGB(210, 190, 255)
local C3 = Color3.fromRGB(170, 140, 255)

local MAIN_COLOR = Color3.fromRGB(235, 225, 255)
local ACCENT_COLOR = Color3.fromRGB(200, 180, 255)

local RED_COLOR = Color3.fromRGB(120, 70, 90)
local RED_ACCENT = Color3.fromRGB(200, 120, 150)


local animated = {}


local function styleMain(bar)
	if not bar then return end

	bar.BackgroundColor3 = MAIN_COLOR
	bar.BorderSizePixel = 0

	for _, v in ipairs(bar:GetChildren()) do
		if v:IsA("UIGradient") then
			v:Destroy()
		end
	end

	local grad = Instance.new("UIGradient")
	grad.Name = "FlowGradient"
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.0, C1),
		ColorSequenceKeypoint.new(0.4, C2),
		ColorSequenceKeypoint.new(0.7, C3),
		ColorSequenceKeypoint.new(1.0, C1)
	}
	grad.Rotation = 0
	grad.Parent = bar

	if not bar:FindFirstChild("Glow") then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "Glow"
		stroke.Thickness = 2
		stroke.Transparency = 0.3
		stroke.Color = ACCENT_COLOR
		stroke.Parent = bar
	end

	bar:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if bar.BackgroundColor3 ~= MAIN_COLOR then
			bar.BackgroundColor3 = MAIN_COLOR
		end
	end)

	return grad
end

local function styleRed(bar)
	if not bar then return end

	bar.BackgroundColor3 = RED_COLOR
	bar.BorderSizePixel = 0

	for _, v in ipairs(bar:GetChildren()) do
		if v:IsA("UIGradient") then
			v:Destroy()
		end
	end

	local grad = Instance.new("UIGradient")
	grad.Name = "FlowGradient"
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, RED_COLOR),
		ColorSequenceKeypoint.new(1, RED_ACCENT)
	}
	grad.Rotation = 0
	grad.Parent = bar

	if not bar:FindFirstChild("Glow") then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "Glow"
		stroke.Thickness = 2
		stroke.Transparency = 0.4
		stroke.Color = RED_ACCENT
		stroke.Parent = bar
	end

	bar:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if bar.BackgroundColor3 ~= RED_COLOR then
			bar.BackgroundColor3 = RED_COLOR
		end
	end)

	return grad
end


local t = 0

RunService.RenderStepped:Connect(function(dt)
	t += dt * 0.25

	for grad in pairs(animated) do
		if grad and grad.Parent then
			grad.Offset = Vector2.new(t % 1, 0)
		else
			animated[grad] = nil
		end
	end
end)

local function animateGradient(grad)
	if not grad or animated[grad] then return end
	animated[grad] = true
end

local function styleBackground(holder)
	if not holder then return end

	local BG = Color3.fromRGB(18, 18, 22)

	holder.BackgroundColor3 = BG
	holder.BorderSizePixel = 0

	if not holder:FindFirstChild("BGGlow") then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "BGGlow"
		stroke.Thickness = 1
		stroke.Transparency = 0.7
		stroke.Color = Color3.fromRGB(120, 120, 140)
		stroke.Parent = holder
	end

	holder:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if holder.BackgroundColor3 ~= BG then
			holder.BackgroundColor3 = BG
		end
	end)
end


local function apply()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return end

	local menu = gui:FindFirstChild("Menu")
	if not menu then return end

	local bars = menu:FindFirstChild("Bars")
	if not bars then return end

	local holder = bars:FindFirstChild("Bar_Holder")
	if not holder then return end

	local bar = holder:FindFirstChild("Bar")
	local added = holder:FindFirstChild("AddedBar")
	local red = holder:FindFirstChild("BarRed")

	styleBackground(holder)

	local g1 = styleMain(bar)
	local g2 = styleMain(added)
	local g3 = styleRed(red)

	animateGradient(g1)
	animateGradient(g2)
	animateGradient(g3)
end


task.spawn(function()
	while true do
		apply()
		task.wait(1.5)
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(2)
	apply()
end)


local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")


if _G.FPS_UI_LOADED then
	return
end
_G.FPS_UI_LOADED = true

local CONNECTIONS = {}

local function bind(conn)
	table.insert(CONNECTIONS, conn)
	return conn
end

local function w(path)
	local obj = player
	for _, v in ipairs(path) do
		obj = obj:WaitForChild(v)
	end
	return obj
end

local ACTIVE = false

local function spark(label)
	if label:FindFirstChild("SparkLoaded") then
		return
	end

	Instance.new("BoolValue", label).Name = "SparkLoaded"

	local last = 999

	task.spawn(function()
		while label and label.Parent do
			task.wait(0.5)

			local num = tonumber(string.match(label.Text, "%d+")) or 0

			if num < last - 20 then
				local old = label:FindFirstChild("HitFlash")
				if old then
					old:Destroy()
				end

				local s = Instance.new("UIStroke")
				s.Name = "HitFlash"
				s.Thickness = 2
				s.Transparency = 1
				s.Color = Color3.fromRGB(255,255,255)
				s.Parent = label

				TweenService:Create(s, TweenInfo.new(0.2), {
					Transparency = 0
				}):Play()

				task.wait(0.15)

				TweenService:Create(s, TweenInfo.new(0.4), {
					Transparency = 1
				}):Play()

				task.delay(0.5, function()
					if s and s.Parent then
						s:Destroy()
					end
				end)
			end

			last = num
		end
	end)
end



local sakuraRunning = false

local function createPetal(parent)
	if not parent then return end

	local p = Instance.new("TextLabel")
	p.Size = UDim2.fromOffset(12,12)
	p.BackgroundTransparency = 1
	p.Text = "❀"
	p.TextScaled = true
	p.Font = Enum.Font.GothamBold
	p.TextColor3 = Color3.fromRGB(255,200,220)
	p.ZIndex = 999
	p.Parent = parent

	local x = math.random(-10, 25) / 100
local y = math.random(-10, 0) / 100

p.Position = UDim2.fromScale(x, y)

	local tween = TweenService:Create(
		p,
		TweenInfo.new(4),
		{
			Position = p.Position + UDim2.fromScale(0, 1.5),
			TextTransparency = 1
		}
	)

	tween:Play()

	task.delay(4, function()
		if p then p:Destroy() end
	end)
end

local function startSakura(frame)
	if sakuraRunning then return end
	sakuraRunning = true

	task.spawn(function()
		while frame and frame.Parent do
			task.wait(0.25)
			createPetal(frame)
		end
		sakuraRunning = false
	end)
end
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer


local function spawnParticle(bar)
	if not bar then return end

	local p = Instance.new("TextLabel")
	p.Size = UDim2.fromOffset(10,10)
	p.BackgroundTransparency = 1
	p.Text = "❄"
	p.TextScaled = true
	p.Font = Enum.Font.GothamBold
	p.TextColor3 = Color3.fromRGB(215,245,255)
	p.ZIndex = bar.ZIndex + 12
	p.Parent = bar

	p.Position = UDim2.fromScale(math.random(), -0.2)

	TweenService:Create(
		p,
		TweenInfo.new(1.5),
		{
			Position = p.Position + UDim2.fromScale(0, 1.4),
			TextTransparency = 1
		}
	):Play()

	task.delay(1.5, function()
		if p then p:Destroy() end
	end)
end

local function applyStaminaParticles(bar)
	if not bar or bar:FindFirstChild("ParticleTag") then return end

	bar.BackgroundColor3 = Color3.fromRGB(185,235,255)

	local tag = Instance.new("Folder")
	tag.Name = "ParticleTag"
	tag.Parent = bar

	task.spawn(function()
		while tag.Parent do
			spawnParticle(bar)
			task.wait(0.15)
		end
	end)
end


local function startGoat()

	if goatRunning then return end

	local gui = player:WaitForChild("PlayerGui")
	local root = gui:WaitForChild("ver")
	local goat = root:WaitForChild("ver")

	if not goat:IsA("TextLabel") then
		warn("Goat is not TextLabel")
		return
	end

	goatTarget = goat
	goatRunning = true

	if goatConnection then
		goatConnection:Disconnect()
		goatConnection = nil
	end

	for _, v in pairs(goat:GetChildren()) do
		if v:IsA("UIGradient") then
			v:Destroy()
		end
	end

	local grad = Instance.new("UIGradient")
	grad.Parent = goat

	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,175,205)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180,140,255))
	}

	local states = {
		{ text = "#goatlife", hold = 8 },
		{ text = "#g0atl1fe", hold = 1.2 },
		{ text = "#goat.life", hold = 1.2 },
		{ text = "#>|3a..---", hold = 1.2 },
		{ text = "#go4tlife", hold = 1.2 },
		{ text = "#>|m3ssi|<", hold = 4 },
		{ text = "#m3ssi", hold = 1.5 },
		{ text = "#m3ssi//", hold = 1.5 },
	}

	local function melt(obj)
		for i = 1, 8 do
			obj.Text = string.char(math.random(33,126))
			task.wait(0.05)
		end
	end

	task.spawn(function()
		while goatRunning and goatTarget and goatTarget.Parent do
			for _, s in ipairs(states) do
				if not goatRunning then break end

				melt(goatTarget)

				goatTarget.Text = s.text

				task.wait(s.hold)
			end
		end

		goatRunning = false
	end)

	local t = 0

	goatConnection = RunService.RenderStepped:Connect(function(dt)
		if goatTarget and goatTarget.Parent and grad and grad.Parent then
			t += dt
			grad.Rotation = 20 + math.sin(t) * 6
		end
	end)
end

local function bindUI()

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("Menu", 10)
	if not gui then return end

	local bars = gui:FindFirstChild("Bars")
	if not bars then return end

	local hp = bars:FindFirstChild("Bar_Holder")
	local hpBar = hp and hp:FindFirstChild("Bar")

	local staminaBar = bars:FindFirstChild("StaminaBar")
	staminaBar = staminaBar and staminaBar:FindFirstChild("Bar")

	local fpsHolder = gui:FindFirstChild("Fps_and_ping")
	local fps = fpsHolder and fpsHolder:FindFirstChild("Fps")


	if fps then
		applyFPS(fps)
		startSakura(fps)
	end

	if staminaBar then
		applyStaminaParticles(staminaBar)
	end
end

task.spawn(function()
	while true do
		bindUI()
		task.wait(1)
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(2)

	goatRunning = false
	goatTarget = nil

	if goatConnection then
		goatConnection:Disconnect()
		goatConnection = nil
	end

	startGoat()
end)

startGoat()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

if _G.ButterflyKill then
	_G.ButterflyKill()
end

local alive = true
_G.ButterflyKill = function()
	alive = false
end

local renderConnection
local dpsConnection
local guiInstance

local function cleanup()
	alive = false

	if renderConnection then renderConnection:Disconnect() end
	if dpsConnection then dpsConnection:Disconnect() end
	if guiInstance then guiInstance:Destroy() end

	renderConnection = nil
	dpsConnection = nil
	guiInstance = nil
end

local function getDPS()
	local gui = player:WaitForChild("PlayerGui")
	local menu = gui:WaitForChild("Menu")
	return menu:WaitForChild("DpsMeter"):WaitForChild("Text")
end

local maxParticles = 5
local particles = {}

local function spawnParticle(pos, parent, color)
	if #particles >= maxParticles then
		particles[1]:Destroy()
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
		Position = UDim2.fromOffset(pos.X.Offset, pos.Y.Offset + driftY)
	}):Play()

	task.delay(0.6, function()
		if p then p:Destroy() end
	end)
end

local function create()
	local playerGui = player:WaitForChild("PlayerGui")

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

	if not alive then return end
cleanup()
alive = true

	local mySession = sessionId

	local dps = getDPS()
	local wing, glow, gui = create()
	guiInstance = gui

	local t = 0
	local speed = 1
	local lastDPS = 0
	local highMode = false

	dpsConnection = dps:GetPropertyChangedSignal("Text"):Connect(function()
		if mySession ~= sessionId then return end

		local value = tonumber(string.match(dps.Text, "%d+%.?%d*")) or 0

		speed = math.clamp(1 + value / 50, 1, 6)
		highMode = value >= 1000

		local diff = value - lastDPS
		lastDPS = value

		if diff > 15 then
			TweenService:Create(wing, TweenInfo.new(0.1), {
				TextSize = 13,
				TextColor3 = Color3.fromRGB(255, 230, 150)
			}):Play()

			task.delay(0.8, function()
				if wing.Parent then
					wing.TextSize = 10
					wing.TextColor3 = Color3.fromRGB(120, 200, 255)
				end
			end)
		end
	end)

	renderConnection = RunService.RenderStepped:Connect(function(dt)

		if not alive then return end
		if not wing.Parent then return end

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

		wing.Size = UDim2.fromOffset(10, 10)
		glow.Size = UDim2.fromOffset(14, 14)

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
end

task.spawn(function()
	while alive do
		task.wait(1)
		pcall(attach)
	end
end)


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

local STAMINA_MAIN = Color3.fromRGB(205,240,255)
local STAMINA_GLOW = Color3.fromRGB(255,255,255)

	task.spawn(function()
		while current.Parent do
			current.BackgroundColor3 = BLACK
			trail.BackgroundColor3 = GOLD
			task.wait(0.08)
		end
	end)

local function spawnParticle(bar)

	if not bar then
		return
	end

	local p = Instance.new("TextLabel")
	p.Size = UDim2.fromOffset(10,10)
	p.BackgroundTransparency = 1
	p.Text = "❄"
	p.TextScaled = true
	p.Font = Enum.Font.GothamBold
	p.TextColor3 = Color3.fromRGB(255,255,255)
	p.TextTransparency = 0.12
	p.ZIndex = bar.ZIndex + 12
	p.Parent = bar

	p.Position = UDim2.fromScale(
		math.random(),
		-0.2
	)

	TweenService:Create(
		p,
		TweenInfo.new(1.5, Enum.EasingStyle.Linear),
		{
			Position = p.Position + UDim2.fromScale(0, 1.4),
			TextTransparency = 1
		}
	):Play()

	task.delay(1.5, function()
		if p then
			p:Destroy()
		end
	end)
end

local function applyStaminaParticles(bar)

	if not bar or bar:FindFirstChild("ParticleTag") then
		return
	end

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

	local tag = Instance.new("Folder")
	tag.Name = "ParticleTag"
	tag.Parent = bar

	task.spawn(function()
		while tag.Parent do
			bar.BackgroundColor3 = STAMINA_MAIN
			spawnParticle(bar)
			task.wait(0.15)
		end
	end)
end

local function apply()

	local gui = player:WaitForChild("PlayerGui")
	local menu = gui:WaitForChild("Menu")
	local bars = menu:WaitForChild("Bars")
	local staminaBar = bars.StaminaBar.Bar

	applyStaminaParticles(staminaBar)
end

apply()

player.CharacterAdded:Connect(function()
	task.wait(1)
	apply()
end)



local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

local TARGETS = {
	Block = true,
	Blood_Multiplier = true,
	Essence_Multiplier = true,
	Exp = true,
	Fist_Damage = true,
	Npc_Damage_Buff = true,
	Weapon_Damage = true,
	Sword_Damage = true,
	Breathing_Percent_Damage = true
}

local function isTarget(obj)
	return obj:IsA("Frame") and TARGETS[obj.Name]
end

local CLEANER_RUNNING = false

local function cleanFolder(folder)

	for _, obj in ipairs(folder:GetChildren()) do
		if isTarget(obj) then
			obj:Destroy()
		end
	end

	folder.ChildAdded:Connect(function(obj)
		if isTarget(obj) then
			obj:Destroy()
		end
	end)
end

local function setup()

	local additions = player:WaitForChild("PlayerGui")
		:WaitForChild("Menu")
		:WaitForChild("Additions")

	local updater = additions:FindFirstChild("AdditionsUpdater")

	if updater and updater:IsA("LocalScript") and not updater.Enabled then
		updater.Enabled = true
	end

	for _, obj in ipairs(additions:GetChildren()) do
		if obj:IsA("Folder") then
			cleanFolder(obj)
		end
	end

	additions.ChildAdded:Connect(function(obj)
		if obj:IsA("Folder") then
			cleanFolder(obj)
		end
	end)
end

local function init()

	if CLEANER_RUNNING then
		return
	end

	CLEANER_RUNNING = true

	task.spawn(function()
		while true do
			task.wait(2)
			pcall(function()
				setup()
			end)
		end
	end)
end

init()

-- Cooldowns
local function CD()

	local p = player.PlayerGui:FindFirstChild("Power_Adder")
	if not p then
		return
	end

	for _,s in ipairs({

		{{"War_Fans"},35},
		{{"War Drums"},36},
		{{"Ice_Bda","Skills","Barren Hanging Garden"},22},
		{{"Ice_Bda","Skills","Cold White Princesses"},22},
		{{"Ice_Bda","Skills","Freezing Cloud"},22},
		{{"Ice_Bda","Skills","Lotus Vines"},35},
		{{"Ice_Bda","Skills","Wintry Icicles"},15},
		{{"Swamp_Bda","Skills","Swamp Eject"},15},
		{{"Swamp_Bda","Skills","Swamp Trap"},20},
		{{"Swamp_Bda","Skills","Traveling Claws"},15}

	}) do

		local obj = p

		for _,n in ipairs(s[1]) do
			obj = obj:FindFirstChild(n)
			if not obj then
				break
			end
		end

		if obj and obj:FindFirstChild("CoolDown") then
			obj.CoolDown.Value = s[2]
		end
	end
end

CD()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local function getPlayerFolder()
	local root = ReplicatedStorage:WaitForChild("PlayerValues")
	return root:FindFirstChild(player.Name)
end

local function removeEffects()
	local folder = getPlayerFolder()
	if not folder then return end

	for _, obj in ipairs(folder:GetDescendants()) do
		if obj.Name == "Stun" then
			obj:Destroy()
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.CapsLock then
		removeEffects()
	end
end)