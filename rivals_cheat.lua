-- Rivals Cheat v2 | ESP + Skin + Auto Kill | Real Executor Compatible
-- Fixed: position (right side), more robust ESP/Rage

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local Settings = {
	ESP = true,
	ESP_Dist = true,
	Skin = true,
	Skin_Color = Color3.fromRGB(0, 170, 255),
	Rage = true,
	Rage_Distance = 20,
	Rage_Jump = true,
	Rage_Auto = true,
	AimBot = false,
	AimFOV = 120,
	AimPart = "Head",
	SilentAim = false,
	TriggerBot = false,
	TriggerDelay = 0.05,
}

-- ===== UI (right side) =====
local UI = Instance.new("ScreenGui")
UI.Name = "RivalsUI"
UI.ResetOnSpawn = false
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 260)
frame.Position = UDim2.new(1, -240, 0.5, -130) -- right side
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0
frame.Parent = UI
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "  RIVALS CHEAT"
title.TextColor3 = Color3.fromRGB(255, 60, 60)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- toggle helper
local y = 35
local function makeBtn(text, val, fn)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, y)
	btn.BackgroundColor3 = val and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(30, 30, 38)
	btn.Text = "  " .. text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
	btn.MouseButton1Click:Connect(function()
		val = not val
		btn.BackgroundColor3 = val and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(30, 30, 38)
		fn(val)
	end)
	y = y + 34
end

makeBtn("ESP", Settings.ESP, function(v) Settings.ESP = v end)
makeBtn("ESP Distance", Settings.ESP_Dist, function(v) Settings.ESP_Dist = v end)
makeBtn("Skin Changer", Settings.Skin, function(v) Settings.Skin = v end)
makeBtn("Auto Kill (Rage)", Settings.Rage_Auto, function(v) Settings.Rage_Auto = v end)
makeBtn("High Jump", Settings.Rage_Jump, function(v)
	Settings.Rage_Jump = v
	local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if h then h.JumpPower = v and 100 or 50 end
end)
makeBtn("AimBot", Settings.AimBot, function(v) Settings.AimBot = v end)
makeBtn("Silent Aim", Settings.SilentAim, function(v) Settings.SilentAim = v end)
makeBtn("Trigger Bot", Settings.TriggerBot, function(v) Settings.TriggerBot = v end)

-- ===== Right Shift to toggle UI =====
local UIS = game:GetService("UserInputService")
local uiVisible = true
UIS.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.RightShift then
		uiVisible = not uiVisible
		frame.Visible = uiVisible
	end
end)

-- ===== ESP =====
local ESP = {}
local function addESP(p)
	if p == LocalPlayer then return end
	p.CharacterAdded:Connect(function(c)
		local bf = Instance.new("BillboardGui")
		bf.AlwaysOnTop = true
		bf.Size = UDim2.new(0, 100, 0, 100)
		bf.StudsOffset = Vector3.new(0, 3, 0)
		bf.Adornee = c
		bf.Parent = c
		local sl = Instance.new("Frame")
		sl.BackgroundTransparency = 1
		sl.Size = UDim2.new(1, 0, 1, 0)
		sl.Parent = bf
		ESP[p] = {gui = bf, frame = sl}
	end)
end
for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
Players.PlayerAdded:Connect(addESP)

-- ===== Render loop =====
RunService.RenderStepped:Connect(function()
	local me = LocalPlayer.Character
	if not me then return end
	local myHRP = me:FindFirstChild("HumanoidRootPart")
	local myHum = me:FindFirstChild("Humanoid")
	if not myHRP then return end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local c = p.Character
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local hum = c:FindFirstChild("Humanoid")
			if hrp and hum then
				local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)

				-- ESP
				if Settings.ESP and ESP[p] then
					local f = ESP[p].frame
					f:ClearAllChildren()
					local t = Instance.new("TextLabel")
					t.BackgroundTransparency = 1
					t.TextColor3 = Color3.fromRGB(255, 60, 60)
					t.TextSize = 12
					t.Size = UDim2.new(1, 0, 0, 16)
					t.Position = UDim2.new(0, 0, 0, 0)
					local txt = p.Name
					if Settings.ESP_Dist then txt = txt .. " [" .. dist .. "m]" end
					t.Text = txt
					t.Parent = f
					if hum.Health <= 0 then
						local d = Instance.new("TextLabel")
						d.BackgroundTransparency = 1
						d.Text = "DEAD"
						d.TextColor3 = Color3.fromRGB(150, 150, 150)
						d.TextSize = 11
						d.Parent = f
					end
				end

				-- Rage auto-kill
				if Settings.Rage and Settings.Rage_Auto and hum.Health > 0 then
					if dist <= Settings.Rage_Distance then
						local tool = me:FindFirstChildWhichIsA("Tool", true)
						if tool then
							if tool.Activated then tool.Activated:Fire() end
						end
					end
				end
			end
		end
	end

	-- Skin changer
	if Settings.Skin and me then
		local col = Settings.Skin_Color
		for _, part in ipairs(me:GetDescendants()) do
			if part:IsA("Part") and (part.Name == "Head" or part.Name == "Torso" or part.Name == "UpperArm" or part.Name == "UpperLeg") then
				part.Color = col
			end
		end
	end

	-- ===== AimBot / Silent Aim =====
	local closest, closestDist
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			local part = p.Character:FindFirstChild(Settings.AimPart) or p.Character:FindFirstChild("Head")
			if hum and part and hum.Health > 0 then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				local camPos = Camera.CFrame.Position
				local diff = (screenPos - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
				if diff <= Settings.AimFOV then
					if not closest or diff < closestDist then
						closest = part
						closestDist = diff
					end
				end
			end
		end
	end

	if closest then
		local target = closest.Parent
		-- AimBot: rotate camera to target
		if Settings.AimBot then
			local targetCF = CFrame.new(Camera.CFrame.Position, closest.Position)
			Camera.CFrame = targetCF
		end
		-- Silent Aim: aim tool at target
		if Settings.SilentAim then
			local tool = me:FindFirstChildWhichIsA("Tool", true)
			if tool and tool.Handle then
				tool.Handle.CFrame = CFrame.new(tool.Handle.Position, closest.Position)
			end
		end
	end

	-- ===== Trigger Bot =====
	if Settings.TriggerBot and closest then
		local tool = me:FindFirstChildWhichIsA("Tool", true)
		if tool then
			if tool.Activated then tool.Activated:Fire() end
		end
	end
end)

-- ===== Jump on spawn =====
LocalPlayer.CharacterAdded:Connect(function(c)
	c:WaitForChild("Humanoid").JumpPower = Settings.Rage_Jump and 100 or 50
end)

print("Rivals Cheat v2 Loaded")
