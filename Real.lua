--[[
    Real - Universal Roblox Cheat
    機能: ESP / エイムボット / サイレントエイム / 自動射撃
    対応: 汎用エグゼキューター (Universal)
    注意: 学習・研究目的。使用は自己責任で。
]]

-- ============================================================
-- [1] 設定 (Settings)
-- ============================================================
local Settings = {
    -- ESP設定
    ESP = {
        Enabled       = false,
        Boxes         = true,   -- ボックス表示
        Names         = true,   -- 名前表示
        Distance      = true,   -- 距離表示
        HealthBar     = true,   -- HPバー
        Skeleton      = false,  -- 骨格表示
        TeamColor     = true,   -- チーム色
        MaxDistance   = 1000,   -- 表示する最大距離
        BoxThickness  = 2,      -- ボックスの太さ
        FontSize      = 14,     -- 文字サイズ
    },

    -- エイムボット設定
    Aimbot = {
        Enabled        = false,
        Key            = Enum.KeyCode.F,      -- トグルキー
        FOV            = 120,                   -- 視野角 (ピクセル)
        Smoothness     = 0.15,                  -- 滑らかさ (0=瞬時, 1=遅い)
        TargetPart     = "Head",               -- 狙うパーツ (Head / HumanoidRootPart)
        OnlyVisible    = true,                  -- 見えるターゲットのみ
        OnlyTeamCheck  = true,                  -- チームチェック
        ClosestTarget  = true,                  -- 最も近いターゲットを狙う
    },

    -- サイレントエイム設定
    SilentAim = {
        Enabled        = false,
        FOV            = 150,                   -- 有効範囲
        Correction     = 0.85,                  -- 補正強度 (0.85 = 85%)
        OnlyVisible    = true,
        HitChance      = true,                  -- 当たる確率を優先
    },

    -- 自動射撃設定
    AutoFire = {
        Enabled        = false,
        Key            = Enum.KeyCode.V,        -- トグルキー
        AutoShoot      = true,
        ShootDelay     = 0.1,                   -- 射撃間隔 (秒)
        MaxRange       = 500,                   -- 自動射撃の最大距離
    },
}

-- ============================================================
-- [2] 基本サービス取得
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- [3] グローバル変数
-- ============================================================
local AimbotActive      = false
local SilentAimActive   = false
local AutoFireActive    = false
local AimTarget         = nil
local AimTargetPos      = nil
local ESPObjects        = {}      -- ESP要素を保存するテーブル
local PlayersESP        = {}      -- プレイヤーごとのESPデータ

-- ============================================================
-- [4] ユーティリティ関数
-- ============================================================

-- 2D画面座標に変換
local function WorldToScreen(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- 2点間の2D距離
local function Distance2D(pos1, pos2)
    return math.abs(pos1.X - pos2.X) + math.abs(pos1.Y - pos2.Y)
end

-- プレイヤーがローカルプレイヤーかどうか
local function IsLocalPlayer(plr)
    return plr == LocalPlayer
end

-- チームチェック
local function SameTeam(plr1, plr2)
    if not Settings.ESP.TeamColor then return false end
    if plr1.Team and plr2.Team then
        return plr1.Team == plr2.Team
    end
    return false
end

-- プレイヤーのRootPartを取得
local function GetRootPart(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- プレイヤーのHeadを取得
local function GetHeadPart(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild("Head")
end

-- プレイヤーのHumanoidを取得
local function GetHumanoid(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild("Humanoid")
end

-- ============================================================
-- [5] ESPシステム
-- ============================================================

-- ESP用のフレームワーク (ScreenGui)
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "RealESP"
ESPGui.ResetOnSpawn = false
ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- プレイヤーごとのESP要素を作成
local function CreateESP(plr)
    if IsLocalPlayer(plr) then return end

    local espData = {
        Box       = nil,
        NameLabel = nil,
        DistLabel = nil,
        HPBar     = nil,
        Skeleton  = {},
    }

    -- ボックス (Adornesを使う)
    if Settings.ESP.Boxes then
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "RealBox"
        box.Adornee = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        box.Size = Vector3.new(4, 6, 4)
        box.Color = Color3.fromRGB(255, 0, 0)
        box.Transparency = 0.3
        box.LineThickness = Settings.ESP.BoxThickness
        box.Parent = plr.Character or plr.CharacterAdded:Wait()
        espData.Box = box
    end

    -- 名前・距離ラベル (BillboardGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RealBillboard"
    billboard.Adornee = plr.Character and plr.Character:FindFirstChild("Head")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = plr.Character or plr.CharacterAdded:Wait()

    if Settings.ESP.Names then
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "RealName"
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 0, 20)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = Settings.ESP.FontSize
        nameLabel.Parent = billboard
        espData.NameLabel = nameLabel
    end

    if Settings.ESP.Distance then
        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "RealDist"
        distLabel.BackgroundTransparency = 1
        distLabel.Size = UDim2.new(1, 0, 0, 20)
        distLabel.Position = UDim2.new(0, 0, 0, 20)
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextSize = Settings.ESP.FontSize - 2
        distLabel.Parent = billboard
        espData.DistLabel = distLabel
    end

    if Settings.ESP.HealthBar then
        local hpBar = Instance.new("Frame")
        hpBar.Name = "RealHP"
        hpBar.BackgroundTransparency = 0.5
        hpBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        hpBar.Size = UDim2.new(0, 4, 1, 0)
        hpBar.Position = UDim2.new(0, -6, 0, 0)
        hpBar.Parent = billboard
        espData.HPBar = hpBar
    end

    PlayersESP[plr] = espData
end

-- ESP更新ループ
local function UpdateESP()
    if not Settings.ESP.Enabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsLocalPlayer(plr) then return end

        local char = plr.Character
        local root = GetRootPart(plr)
        if not char or not root then return end

        local head = GetHeadPart(plr)
        local humanoid = GetHumanoid(plr)

        -- 距離計算
        local localRoot = GetRootPart(LocalPlayer)
        local distance = 0
        if localRoot then
            distance = math.round((root.Position - localRoot.Position).Magnitude)
        end

        -- 表示距離チェック
        if distance <= Settings.ESP.MaxDistance then
            local espData = PlayersESP[plr]
            if espData then
                -- 名前更新
                if espData.NameLabel then
                    espData.NameLabel.Text = plr.Name
                end

                -- 距離更新
                if espData.DistLabel then
                    espData.DistLabel.Text = distance .. "m"
                end

                -- HPバー更新
                if espData.HPBar and humanoid then
                    local hpPercent = humanoid.Health / humanoid.MaxHealth
                    espData.HPBar.Size = UDim2.new(0, 4, hpPercent, 0)
                    -- HPに応じて色変更
                    if hpPercent > 0.6 then
                        espData.HPBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    elseif hpPercent > 0.3 then
                        espData.HPBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        espData.HPBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    end
                end

                -- ボックスの色更新 (チームチェック)
                if espData.Box then
                    if SameTeam(LocalPlayer, plr) then
                        espData.Box.Color = Color3.fromRGB(0, 170, 255)  -- 味方: 青
                    else
                        espData.Box.Color = Color3.fromRGB(255, 0, 0)    -- 敵: 赤
                    end
                end
            end
        end
    end
end

-- ESPループ開始
task.spawn(function()
    while true do
        if Settings.ESP.Enabled then
            UpdateESP()
        end
        task.wait(0.05)  -- 20FPS相当
    end
end)

-- ============================================================
-- [6] エイムボットシステム
-- ============================================================

-- 最も近いターゲットを探す
local function FindClosestTarget()
    local localRoot = GetRootPart(LocalPlayer)
    if not localRoot then return nil end

    local closestPlr = nil
    local closestDist = Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsLocalPlayer(plr) then return end
        if SameTeam(LocalPlayer, plr) and Settings.Aimbot.OnlyTeamCheck then return end

        local char = plr.Character
        if char then
            local targetPart = char:FindFirstChild(Settings.Aimbot.TargetPart)
            if targetPart then
                local targetScreen, onScreen = WorldToScreen(targetPart.Position)
                if onScreen then
                    local dist = Distance2D(mousePos, targetScreen)
                    if dist < closestDist then
                        closestDist = dist
                        closestPlr = plr
                    end
                end
            end
        end
    end

    return closestPlr
end

-- ターゲットの画面座標を取得
local function GetTargetScreenPos(plr)
    local char = plr.Character
    if not char then return nil end

    local targetPart = char:FindFirstChild(Settings.Aimbot.TargetPart)
    if not targetPart then return nil end

    local screenPos, onScreen = WorldToScreen(targetPart.Position)
    if onScreen then
        return screenPos
    end
    return nil
end

-- マウスをターゲットに移動
local function MoveMouseTo(targetPos)
    local mousePos = UserInputService:GetMouseLocation()
    local delta = targetPos - mousePos

    -- 滑らかに移動
    local smoothDelta = delta * Settings.Aimbot.Smoothness
    UserInputService.MouseDelta = Vector2.new(
        smoothDelta.X,
        smoothDelta.Y
    )
end

-- エイムボットメインループ
task.spawn(function()
    while true do
        if AimbotActive then
            local target = FindClosestTarget()
            if target then
                AimTarget = target
                local screenPos = GetTargetScreenPos(target)
                if screenPos then
                    MoveMouseTo(screenPos)
                end
            end
        end
        task.wait(0.01)  -- 100FPS相当
    end
end)

-- ============================================================
-- [7] サイレントエイムシステム
-- ============================================================

-- 最も近いターゲットを探す (エイムボットと共通)
-- FindClosestTarget() を再利用

-- サイレントエイム: カメラのロケーションをターゲットに補正
local function ApplySilentAim()
    if not SilentAimActive then return end

    local target = FindClosestTarget()
    if not target then return end

    local char = target.Character
    if not char then return end

    local targetPart = char:FindFirstChild(Settings.SilentAim.TargetPart or "Head")
    if not targetPart then return end

    -- カメラの現在のロケーション
    local currentCFrame = Camera.CFrame

    -- ターゲットの位置
    local targetPos = targetPart.Position

    -- カメラからターゲットへの方向
    local direction = (targetPos - Camera.CFrame.Position).Unit

    -- サイレントエイムの補正を適用
    local correctedCFrame = CFrame.new(Camera.CFrame.Position, targetPos)

    -- 補正強度を適用 (1.0 = 完全補正)
    local correctionStrength = Settings.SilentAim.Correction
    local finalCFrame = currentCFrame:Lerp(correctedCFrame, correctionStrength)

    -- カメラのCFrameを更新
    Camera.CFrame = finalCFrame
end

-- サイレントエイムループ
task.spawn(function()
    while true do
        if SilentAimActive then
            ApplySilentAim()
        end
        task.wait(0.01)
    end
end)

-- ============================================================
-- [8] 自動射撃システム
-- ============================================================

local lastShootTime = 0

-- 最も近いターゲットを探す (エイムボットと共通)
-- FindClosestTarget() を再利用

-- 自動射撃: ターゲットが画面内にある時に自動で射撃
local function AutoShoot()
    if not AutoFireActive then return end

    local target = FindClosestTarget()
    if not target then return end

    local char = target.Character
    if not char then return end

    -- ターゲットの距離チェック
    local localRoot = GetRootPart(LocalPlayer)
    local targetRoot = GetRootPart(target)
    if localRoot and targetRoot then
        local distance = (targetRoot.Position - localRoot.Position).Magnitude
        if distance > Settings.AutoFire.MaxRange then return end
    end

    -- 射撃間隔チェック
    local currentTime = tick()
    if currentTime - lastShootTime >= Settings.AutoFire.ShootDelay then
        -- マウス左クリックをシミュレート (射撃)
        UserInputService:InputBegan(
            Input.new(Enum.UserInputType.MouseButton1, nil),
            true
        )
        lastShootTime = currentTime

        -- クリックアップ (短時間後に)
        task.delay(0.05, function()
            UserInputService:InputEnded(
                Input.new(Enum.UserInputType.MouseButton1, nil),
                true
            )
        end)
    end
end

-- 自動射撃ループ
task.spawn(function()
    while true do
        if AutoFireActive then
            AutoShoot()
        end
        task.wait(0.01)
    end
end)

-- ============================================================
-- [9] GUIメニューUI
-- ============================================================

-- メインのScreenGui
local MenuGui = Instance.new("ScreenGui")
MenuGui.Name = "RealMenu"
MenuGui.ResetOnSpawn = false
MenuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MenuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- メニューフレーム
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Size = UDim2.new(0, 300, 0, 400)
MenuFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MenuFrame.BackgroundTransparency = 0.2
MenuFrame.Parent = MenuGui

-- ドラッグ可能にするためのタイトルバー
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleBar.Parent = MenuFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Real Cheat"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = TitleBar

-- ボタン生成関数
local function CreateToggleButton(parent, name, text, defaultState, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, 0)
    button.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.Gotham
    button.Parent = parent

    button.MouseButton1Click:Connect(function()
        defaultState = not defaultState
        callback(defaultState)
        button.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        button.Text = (defaultState and "[ON] " or "[OFF] ") .. text
    end)

    return button
end

-- ESPセクション
local ESPFrame = Instance.new("Frame")
ESPFrame.Name = "ESPFrame"
ESPFrame.Size = UDim2.new(1, -20, 0, 120)
ESPFrame.Position = UDim2.new(0, 10, 0, 40)
ESPFrame.BackgroundTransparency = 1
ESPFrame.Parent = MenuFrame

CreateToggleButton(ESPFrame, "ESPBtn", "ESP", Settings.ESP.Enabled, function(state)
    Settings.ESP.Enabled = state
end)

-- ESPボタンを縦に配置するための小さな修正
-- (実際には各ボタンを順番に配置する必要あり)

-- エイムボットセクション
local AimbotFrame = Instance.new("Frame")
AimbotFrame.Name = "AimbotFrame"
AimbotFrame.Size = UDim2.new(1, -20, 0, 120)
AimbotFrame.Position = UDim2.new(0, 10, 0, 170)
AimbotFrame.BackgroundTransparency = 1
AimbotFrame.Parent = MenuFrame

CreateToggleButton(AimbotFrame, "AimbotBtn", "Aimbot", Settings.Aimbot.Enabled, function(state)
    AimbotActive = state
end)

-- サイレントエイムセクション
local SilentAimFrame = Instance.new("Frame")
SilentAimFrame.Name = "SilentAimFrame"
SilentAimFrame.Size = UDim2.new(1, -20, 0, 120)
SilentAimFrame.Position = UDim2.new(0, 10, 0, 300)
SilentAimFrame.BackgroundTransparency = 1
SilentAimFrame.Parent = MenuFrame

CreateToggleButton(SilentAimFrame, "SilentAimBtn", "Silent Aim", Settings.SilentAim.Enabled, function(state)
    SilentAimActive = state
end)

-- 自動射撃セクション
local AutoFireFrame = Instance.new("Frame")
AutoFireFrame.Name = "AutoFireFrame"
AutoFireFrame.Size = UDim2.new(1, -20, 0, 120)
AutoFireFrame.Position = UDim2.new(0, 10, 0, 430)
AutoFireFrame.BackgroundTransparency = 1
AutoFireFrame.Parent = MenuFrame

CreateToggleButton(AutoFireFrame, "AutoFireBtn", "Auto Fire", Settings.AutoFire.Enabled, function(state)
    AutoFireActive = state
end)

-- キーボードホットキー設定
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Fキー: エイムボットトグル
    if input.KeyCode == Enum.KeyCode.F then
        AimbotActive = not AimbotActive
        print("[Real] Aimbot: " .. (AimbotActive and "ON" or "OFF"))
    end

    -- Vキー: 自動射撃トグル
    if input.KeyCode == Enum.KeyCode.V then
        AutoFireActive = not AutoFireActive
        print("[Real] AutoFire: " .. (AutoFireActive and "ON" or "OFF"))
    end

    -- Rキー: ESPトグル
    if input.KeyCode == Enum.KeyCode.R then
        Settings.ESP.Enabled = not Settings.ESP.Enabled
        print("[Real] ESP: " .. (Settings.ESP.Enabled and "ON" or "OFF"))
    end

    -- Gキー: サイレントエイムトグル
    if input.KeyCode == Enum.KeyCode.G then
        SilentAimActive = not SilentAimActive
        print("[Real] SilentAim: " .. (SilentAimActive and "ON" or "OFF"))
    end
end)

-- ============================================================
-- [10] プレイヤー接続処理
-- ============================================================

-- 既存のプレイヤーにESPを設定
for _, plr in ipairs(Players:GetPlayers()) do
    if not IsLocalPlayer(plr) then
        task.wait(0.1)
        CreateESP(plr)
    end
end

-- 新しいプレイヤーが参加した時にESPを設定
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        CreateESP(plr)
    end)
end)

-- プレイヤーが退出した時にESPを削除
Players.PlayerRemoving:Connect(function(plr)
    local espData = PlayersESP[plr]
    if espData then
        if espData.Box then espData.Box:Destroy() end
        if espData.NameLabel then espData.NameLabel:Destroy() end
        if espData.DistLabel then espData.DistLabel:Destroy() end
        if espData.HPBar then espData.HPBar:Destroy() end
        PlayersESP[plr] = nil
    end
end)

-- キャラクターがリスポーンした時にESPを更新
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    Camera = workspace.CurrentCamera
end)

print("========================================")
print("[Real] チートが完全にロードされました!")
print("[Real] ホットキー:")
print("[Real]   F = エイムボット ON/OFF")
print("[Real]   V = 自動射撃 ON/OFF")
print("[Real]   R = ESP ON/OFF")
print("[Real]   G = サイレントエイム ON/OFF")
print("========================================")
