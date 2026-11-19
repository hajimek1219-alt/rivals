-- Rivals Cheat | ESP + Skin Changer + Auto Kill (Rage) | Real Executor Compatible
-- Lightweight version. Load in Real executor.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- ===== Settings =====
local Settings = {
	ESP = true,
	ESP_Color = Color3.fromRGB(255, 60, 60),
	ESP_Dist = true,
	ESP_Box = true,

	Skin = true,
	Skin_Part = "Body",
	Skin_Color = Color3.fromRGB(0, 170, 255),

	Rage = true,
	Rage_Distance = 20,
	Rage_Speed = 50,
	Rage_Jump = true,
	Rage_Auto = true,
}

-- ===== UI (lightweight) =====
local UI = Instance.new("ScreenGui")
UI.Name = "RivalsUI"
UI.ResetOnSpawn = false
UI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 260)
frame.Position = UDim2.new(0, 20, 0.5, -130)
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
local function toggle(text, state, fn)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.BackgroundColor3 = state and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(30, 30, 38)
	btn.Text = "  " .. text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.BackgroundColor3 = state and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(30, 30, 38)
		fn(state)
	end)
	return btn
end

-- build buttons
local y = 35
local function makeBtn(text, val, fn)
	local b = toggle(text, val, fn)
	b.Position = UDim2.new(0, 5, 0, y); y = y + 34
end
makeBtn("ESP", Settings.ESP, function(v) Settings.ESP = v end)
makeBtn("ESP Distance", Settings.ESP_Dist, function(v) Settings.ESP_Dist = v end)
makeBtn("Skin Changer", Settings.Skin, function(v) Settings.Skin = v end)
makeBtn("Auto Kill (Rage)", Settings.Rage_Auto, function(v) Settings.Rage_Auto = v end)
makeBtn("High Jump", Settings.Rage_Jump, function(v)
	Settings.Rage_Jump = v
	if LocalPlayer.Character then
		local h = LocalPlayer.Character:FindFirstChild("Humanoid")
		if h then h.JumpPower = v and 100 or 50 end
	end
end)

-- ===== ESP =====
local ESP = {}
local function addESP(p)
	if p == LocalPlayer then return end
	local bf = Instance.new("BillboardGui")
	bf.AlwaysOnTop = true
	bf.Size = UDim2.new(0, 100, 0, 100)
	bf.StudsOffset = Vector3.new(0, 3, 0)
	bf.Parent = p:WaitForChild("Head")
	local sl = Instance.new("ScrollingFrame")
	sl.BackgroundTransparency = 1
	sl.Size = UDim2.new(1, 0, 1, 0)
	sl.CanvasSize = UDim2.new(0, 0, 0, 0)
	sl.ScrollBarThickness = 0
	sl.Parent = bf
	ESP[p] = {gui = bf, frame = sl}
end
for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
Players.PlayerAdded:Connect(addESP)

-- ===== Render loop =====
RunService.RenderStepped:Connect(function()
	local me = LocalPlayer.Character
	if not me then return end
	local hp = me:FindFirstChild("Humanoid")
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			local dist = math.floor((me.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude)

			-- ESP
			if Settings.ESP and ESP[p] then
				local f = ESP[p].frame
				f:ClearAllChildren()
				local t = Instance.new("TextLabel")
				t.BackgroundTransparency = 1
				t.TextColor3 = Settings.ESP_Color
				t.TextSize = 12
				t.Size = UDim2.new(1, 0, 0, 16)
				t.Position = UDim2.new(0, 0, 0, 0)
				local txt = p.Name
				if Settings.ESP_Dist then txt = txt .. " [" .. dist .. "m]" end
				t.Text = txt
				t.Parent = f
				if hum and hum.Health <= 0 then
					local d = Instance.new("TextLabel")
					d.BackgroundTransparency = 1
					d.Text = "DEAD"
					d.TextColor3 = Color3.fromRGB(150, 150, 150)
					d.TextSize = 11
					d.Parent = f
				end
			end

			-- Rage auto-kill
			if Settings.Rage and Settings.Rage_Auto and hum and hum.Health > 0 then
				if dist <= Settings.Rage_Distance then
					local tool = me:FindFirstChildWhichIsA("Tool", true)
					if tool then
						if not tool.Activated then tool.Activated:Fire() end
					end
				end
			end
		end
	end

	-- Skin changer
	if Settings.Skin and me then
		local body = me:FindFirstChild("Body") or me:FindFirstChild("Torso")
		if body then
			local col = Settings.Skin_Color
			for _, part in ipairs(me:GetDescendants()) do
				if part:IsA("Part") and (part.Name == "Head" or part.Name == "Torso" or part.Name == "UpperArm" or part.Name == "UpperLeg") then
					part.Color = col
				end
			end
		end
	end
end)

-- ===== Rage jump / speed on key =====
LocalPlayer.CharacterAdded:Connect(function(c)
	c:WaitForChild("Humanoid").JumpPower = Settings.Rage_Jump and 100 or 50
end)

print("Rivals Cheat Loaded | Press to toggle UI via script")
