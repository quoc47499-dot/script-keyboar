local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------
-- HOOK METAMETHOD: GIẢ LẬP THIẾT BỊ PC (PC SPOOFING)
---------------------------------------------------------
-- Giúp đánh lừa tất cả các Script trong Game rằng bạn đang chơi trên PC
if hookmetamethod then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and self == UserInputService then
            if key == "TouchEnabled" then
                return false -- Game nghĩ thiết bị KHÔNG CÓ màn hình cảm ứng
            elseif key == "KeyboardEnabled" then
                return true -- Game nhận diện CÓ bàn phím PC
            elseif key == "MouseEnabled" then
                return true -- Game nhận diện CÓ chuột PC
            elseif key == "GamepadEnabled" then
                return false
            end
        end
        return oldIndex(self, key)
    end)
end

-- Khởi tạo ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomVirtualControlGui_V3"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------
-- HỆ THỐNG ÂM THANH BẤM BÀN PHÍM THẬT
---------------------------------------------------------
local keySound = Instance.new("Sound")
keySound.Name = "VirtualKeyClickSound"
keySound.SoundId = "rbxassetid://9114223179" -- Âm thanh phím cơ gõ chân thực
keySound.Volume = 0.6
keySound.Parent = SoundService

local function playKeySound()
    pcall(function()
        local soundClone = keySound:Clone()
        -- Thay đổi nhẹ pitch (độ trầm bổng) ngẫu nhiên để tạo cảm giác gõ các phím khác nhau
        soundClone.PlaybackSpeed = math.random(95, 105) / 100
        soundClone.Parent = SoundService
        soundClone:Play()
        Debris:AddItem(soundClone, 0.5)
    end)
end

---------------------------------------------------------
-- BIẾN TRẠNG THÁI KHÓA / DI CHUYỂN KHUNG
---------------------------------------------------------
local isDragEnabled = true -- Mặc định ban đầu cho phép di chuyển

---------------------------------------------------------
-- HÀM HỖ TRỢ KÉO THẢ KHUNG (DRAGGABLE WITH LOCK)
---------------------------------------------------------
local function makeDraggable(dragHandle, targetFrame, ignoreLock)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if not isDragEnabled and not ignoreLock then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if not isDragEnabled and not ignoreLock then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and (isDragEnabled or ignoreLock) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

---------------------------------------------------------
-- THANH BẬT/TẮT KHÓA DI CHUYỂN (TOP CONTROL BAR)
---------------------------------------------------------
local controlBar = Instance.new("Frame")
controlBar.Name = "TopControlBar"
controlBar.Size = UDim2.new(0, 220, 0, 36)
controlBar.Position = UDim2.new(0.5, -110, 0, 10)
controlBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
controlBar.BackgroundTransparency = 0.85
controlBar.BorderSizePixel = 0
controlBar.Parent = screenGui
Instance.new("UICorner", controlBar).CornerRadius = UDim.new(0, 8)

local controlStroke = Instance.new("UIStroke")
controlStroke.Color = Color3.fromRGB(255, 255, 255)
controlStroke.Transparency = 0.9
controlStroke.Thickness = 1
controlStroke.Parent = controlBar

local unlockBtn = Instance.new("TextButton")
unlockBtn.Name = "UnlockBtn"
unlockBtn.Size = UDim2.new(0.46, 0, 0.75, 0)
unlockBtn.Position = UDim2.new(0.03, 0, 0.125, 0)
unlockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
unlockBtn.BackgroundTransparency = 0.5
unlockBtn.Text = "🔓 Di Chuyển"
unlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unlockBtn.Font = Enum.Font.SourceSansBold
unlockBtn.TextSize = 12
unlockBtn.Parent = controlBar
Instance.new("UICorner", unlockBtn).CornerRadius = UDim.new(0, 6)

local lockBtn = Instance.new("TextButton")
lockBtn.Name = "LockBtn"
lockBtn.Size = UDim2.new(0.46, 0, 0.75, 0)
lockBtn.Position = UDim2.new(0.51, 0, 0.125, 0)
lockBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
lockBtn.BackgroundTransparency = 0.85
lockBtn.Text = "🔒 Cố Định"
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.Font = Enum.Font.SourceSansBold
lockBtn.TextSize = 12
lockBtn.Parent = controlBar
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

unlockBtn.MouseButton1Click:Connect(function()
    playKeySound()
    isDragEnabled = true
    unlockBtn.BackgroundTransparency = 0.5
    lockBtn.BackgroundTransparency = 0.85
end)

lockBtn.MouseButton1Click:Connect(function()
    playKeySound()
    isDragEnabled = false
    lockBtn.BackgroundTransparency = 0.5
    unlockBtn.BackgroundTransparency = 0.85
end)

---------------------------------------------------------
-- TRẠNG THÁI PHÍM BẤM & DI CHUYỂN / CAMERA
---------------------------------------------------------
local keyState = {
    SPACE = false, SHIFT = false,
    Up = false, Down = false, Left = false, Right = false,
    W = false, A = false, S = false, D = false
}

local keyMap = {
    ["SPACE"] = Enum.KeyCode.Space,
    ["ENTER"] = Enum.KeyCode.Return,
    ["SHIFT"] = Enum.KeyCode.LeftShift,
    ["CTRL"]  = Enum.KeyCode.LeftControl,
    ["W"]     = Enum.KeyCode.W,
    ["A"]     = Enum.KeyCode.A,
    ["S"]     = Enum.KeyCode.S,
    ["D"]     = Enum.KeyCode.D,
}

-- =========================================================
-- HỆ THỐNG XOAY CAMERA KHÔNG GIẬT (STABLE EULER CAMERA ENGINE)
-- =========================================================
local CAM_PITCH_SPEED = math.rad(200)
local CAM_YAW_SPEED   = math.rad(240)
local MIN_PITCH       = math.rad(-79)
local MAX_PITCH       = math.rad(79)
local CAM_SMOOTHNESS  = 18

local targetPitchStep = 0
local targetYawStep   = 0
local currentPitchStep = 0
local currentYawStep   = 0

RunService.RenderStepped:Connect(function(dt)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local moveX = 0
    local moveZ = 0
    if keyState.W then moveZ = moveZ - 1 end
    if keyState.S then moveZ = moveZ + 1 end
    if keyState.A then moveX = moveX - 1 end
    if keyState.D then moveX = moveX + 1 end

    if moveX ~= 0 or moveZ ~= 0 then
        humanoid:Move(Vector3.new(moveX, 0, moveZ), true)
    end

    if keyState.SPACE then humanoid.Jump = true end

    local goalYaw = 0
    local goalPitch = 0

    if keyState.Left then goalYaw = goalYaw + CAM_YAW_SPEED * dt end
    if keyState.Right then goalYaw = goalYaw - CAM_YAW_SPEED * dt end
    if keyState.Up then goalPitch = goalPitch + CAM_PITCH_SPEED * dt end
    if keyState.Down then goalPitch = goalPitch - CAM_PITCH_SPEED * dt end

    targetYawStep = goalYaw
    targetPitchStep = goalPitch

    local alpha = 1 - math.exp(-CAM_SMOOTHNESS * dt)
    currentYawStep = currentYawStep + (targetYawStep - currentYawStep) * alpha
    currentPitchStep = currentPitchStep + (targetPitchStep - currentPitchStep) * alpha

    if math.abs(currentYawStep) > 0.0001 or math.abs(currentPitchStep) > 0.0001 then
        local cam = workspace.CurrentCamera
        if cam then
            local rx, ry, rz = cam.CFrame:ToOrientation()
            local newPitch = math.clamp(rx + currentPitchStep, MIN_PITCH, MAX_PITCH)
            local newYaw = ry + currentYawStep

            local focus = cam.Focus.Position
            local dist = (cam.CFrame.Position - focus).Magnitude

            if dist < 1 then
                cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.fromOrientation(newPitch, newYaw, 0)
            else
                cam.CFrame = CFrame.new(focus) 
                    * CFrame.fromOrientation(newPitch, newYaw, 0) 
                    * CFrame.new(0, 0, dist)
            end
        end
    end
end)

local function sendVirtualInput(isStart, keyName)
    if keyName == "SPACE" then keyState.SPACE = isStart
    elseif keyName == "SHIFT" then keyState.SHIFT = isStart
    elseif keyName == "W" then keyState.W = isStart
    elseif keyName == "A" then keyState.A = isStart
    elseif keyName == "S" then keyState.S = isStart
    elseif keyName == "D" then keyState.D = isStart
    elseif keyName == "▲" then keyState.Up = isStart
    elseif keyName == "▼" then keyState.Down = isStart
    elseif keyName == "◄" then keyState.Left = isStart
    elseif keyName == "►" then keyState.Right = isStart
    end

    pcall(function()
        if keyName == "LMB" then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, isStart, game, 0)
        elseif keyName == "RMB" then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, isStart, game, 0)
        else
            local code = keyMap[keyName] or Enum.KeyCode[keyName]
            if code then
                VirtualInputManager:SendKeyEvent(isStart, code, false, game)
            end
        end
    end)
end

local function bindHoldEvents(btn, keyName)
    local activeInput = nil

    local function startHold(input)
        if not activeInput then
            activeInput = input
            btn.BackgroundTransparency = 0.5
            playKeySound() -- Phát âm thanh gõ phím chân thật
            sendVirtualInput(true, keyName)
        end
    end

    local function stopHold()
        if activeInput then
            activeInput = nil
            btn.BackgroundTransparency = 0.88
            sendVirtualInput(false, keyName)
        end
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            startHold(input)
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input == activeInput then
            stopHold()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == activeInput then
            stopHold()
        end
    end)
end

---------------------------------------------------------
-- TẠO KHUNG CƠ BẢN
---------------------------------------------------------
local function createBasePanel(name, title, size, pos)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = pos
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.93
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = frame

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.92
    stroke.Thickness = 1.2
    stroke.Parent = frame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BackgroundTransparency = 0.96
    header.Active = true
    header.Parent = frame

    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = " " .. title
    titleLbl.Size = UDim2.new(1, -75, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 12
    titleLbl.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -23, 0.5, -10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BackgroundTransparency = 0.7
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 11
    closeBtn.Parent = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    closeBtn.MouseButton1Click:Connect(function() 
        playKeySound()
        frame.Visible = false 
    end)

    local zoomInBtn = Instance.new("TextButton")
    zoomInBtn.Size = UDim2.new(0, 20, 0, 20)
    zoomInBtn.Position = UDim2.new(1, -46, 0.5, -10)
    zoomInBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    zoomInBtn.BackgroundTransparency = 0.7
    zoomInBtn.Text = "+"
    zoomInBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    zoomInBtn.Font = Enum.Font.SourceSansBold
    zoomInBtn.TextSize = 13
    zoomInBtn.Parent = header
    Instance.new("UICorner", zoomInBtn).CornerRadius = UDim.new(0, 4)
    zoomInBtn.MouseButton1Click:Connect(function() 
        playKeySound()
        uiScale.Scale = math.clamp(uiScale.Scale + 0.1, 0.5, 2.0) 
    end)

    local zoomOutBtn = Instance.new("TextButton")
    zoomOutBtn.Size = UDim2.new(0, 20, 0, 20)
    zoomOutBtn.Position = UDim2.new(1, -69, 0.5, -10)
    zoomOutBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 30)
    zoomOutBtn.BackgroundTransparency = 0.7
    zoomOutBtn.Text = "-"
    zoomOutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    zo---------------------------------------------------------
-- 1. CẦN ĐIỀU KHIỂN (JOYSTICK)
---------------------------------------------------------
local moveFrame, moveBody = createBasePanel("MovePanel", "🕹 CẦN ĐIỀU KHIỂN", UDim2.new(0, 160, 0, 170), UDim2.new(0.02, 0, 0.55, 0))

local joystickBase = Instance.new("Frame")
joystickBase.Name = "JoystickBase"
joystickBase.Size = UDim2.new(0, 110, 0, 110)
joystickBase.Position = UDim2.new(0.5, -55, 0.5, -55)
joystickBase.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
joystickBase.BackgroundTransparency = 0.5
joystickBase.Parent = moveBody
Instance.new("UICorner", joystickBase).CornerRadius = UDim.new(1, 0)

local joystickBaseStroke = Instance.new("UIStroke")
joystickBaseStroke.Color = Color3.fromRGB(230, 120, 30)
joystickBaseStroke.Transparency = 0.5
joystickBaseStroke.Thickness = 2
joystickBaseStroke.Parent = joystickBase

local joystickKnob = Instance.new("Frame")
joystickKnob.Name = "JoystickKnob"
joystickKnob.Size = UDim2.new(0, 46, 0, 46)
joystickKnob.Position = UDim2.new(0.5, -23, 0.5, -23)
joystickKnob.BackgroundColor3 = Color3.fromRGB(230, 120, 30)
joystickKnob.BackgroundTransparency = 0.2
joystickKnob.Parent = joystickBase
Instance.new("UICorner", joystickKnob).CornerRadius = UDim.new(1, 0)

local knobText = Instance.new("TextLabel")
knobText.Size = UDim2.new(1, 0, 1, 0)
knobText.BackgroundTransparency = 1
knobText.Text = ""
knobText.TextColor3 = Color3.fromRGB(255, 255, 255)
knobText.Font = Enum.Font.SourceSansBold
knobText.TextSize = 13
knobText.Parent = joystickKnob

local activeJoystickInput = nil
local maxRadius = 40

local function updateJoystick(inputPosition)
    local center = joystickBase.AbsolutePosition + joystickBase.AbsoluteSize / 2
    local delta = Vector2.new(inputPosition.X - center.X, inputPosition.Y - center.Y)
    local dist = delta.Magnitude

    if dist > maxRadius then
        delta = delta.Unit * maxRadius
    end

    joystickKnob.Position = UDim2.new(0.5, delta.X - 23, 0.5, delta.Y - 23)

    local deadzone = 12
    local activeKeys = {}

    if dist > deadzone then
        local norm = delta.Unit
        if norm.Y < -0.38 then
            if not keyState.W then playKeySound() end
            keyState.W = true
            table.insert(activeKeys, "W")
        else
            keyState.W = false
        end
        if norm.Y > 0.38 then
            if not keyState.S then playKeySound() end
            keyState.S = true
            table.insert(activeKeys, "S")
        else
            keyState.S = false
        end
        if norm.X < -0.38 then
            if not keyState.A then playKeySound() end
            keyState.A = true
            table.insert(activeKeys, "A")
        else
            keyState.A = false
        end
        if norm.X > 0.38 then
            if not keyState.D then playKeySound() end
            keyState.D = true
            table.insert(activeKeys, "D")
        else
            keyState.D = false
        end
    else
        keyState.W = false
        keyState.A = false
        keyState.S = false
        keyState.D = false
    end

    knobText.Text = table.concat(activeKeys, " ")
end

local function resetJoystick()
    activeJoystickInput = nil
    joystickKnob.Position = UDim2.new(0.5, -23, 0.5, -23)
    keyState.W = false
    keyState.A = false
    keyState.S = false
    keyState.D = false
    knobText.Text = ""
end

joystickBase.InputBegan:Connect(function(input)
    if not activeJoystickInput and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        activeJoystickInput = input
        updateJoystick(input.Position)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == activeJoystickInput then
        updateJoystick(input.Position)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == activeJoystickInput then
        resetJoystick()
    end
end)

---------------------------------------------------------
-- 2. KHUNG CHUỘT
---------------------------------------------------------
local mouseFrame, mouseBody = createBasePanel("MousePanel", "🖱 CHUỘT", UDim2.new(0, 180, 0, 90), UDim2.new(0.85, 0, 0.32, 0))

local lmbBtn = Instance.new("TextButton")
lmbBtn.Size = UDim2.new(0.48, 0, 0.85, 0)
lmbBtn.Position = UDim2.new(0, 0, 0.08, 0)
lmbBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
lmbBtn.BackgroundTransparency = 0.88
lmbBtn.Text = "TRÁI (LMB)"
lmbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lmbBtn.Font = Enum.Font.SourceSansBold
lmbBtn.TextSize = 12
lmbBtn.Parent = mouseBody
Instance.new("UICorner", lmbBtn).CornerRadius = UDim.new(0, 6)
bindHoldEvents(lmbBtn, "LMB")

local rmbBtn = Instance.new("TextButton")
rmbBtn.Size = UDim2.new(0.48, 0, 0.85, 0)
rmbBtn.Position = UDim2.new(0.52, 0, 0.08, 0)
rmbBtn.BackgroundColor3 = Color3.fromRGB(215, 100, 0)
rmbBtn.BackgroundTransparency = 0.88
rmbBtn.Text = "PHẢI (RMB)"
rmbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rmbBtn.Font = Enum.Font.SourceSansBold
rmbBtn.TextSize = 12
rmbBtn.Parent = mouseBody
Instance.new("UICorner", rmbBtn).CornerRadius = UDim.new(0, 6)
bindHoldEvents(rmbBtn, "RMB")

---------------------------------------------------------
-- 3. XOAY CAMERA MƯỢT TỐI ƯU
---------------------------------------------------------
local camFrame, camBody = createBasePanel("CamPanel", "🎥 CAMERA", UDim2.new(0, 160, 0, 170), UDim2.new(0.85, 0, 0.55, 0))
local arrowBtns = {
    {Name = "▲", Pos = UDim2.new(0.35, 0, 0.05, 0), Size = UDim2.new(0.3, 0, 0.42, 0)},
    {Name = "◄", Pos = UDim2.new(0.03, 0, 0.52, 0), Size = UDim2.new(0.3, 0, 0.42, 0)},
    {Name = "▼", Pos = UDim2.new(0.35, 0, 0.52, 0), Size = UDim2.new(0.3, 0, 0.42, 0)},
    {Name = "►", Pos = UDim2.new(0.67, 0, 0.52, 0), Size = UDim2.new(0.3, 0, 0.42, 0)},
}
for _, item in ipairs(arrowBtns) do
    local btn = Instance.new("TextButton")
    btn.Size = item.Size
    btn.Position = item.Pos
    btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    btn.BackgroundTransparency = 0.88
    btn.Text = item.Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Parent = camBody
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    bindHoldEvents(btn, item.Name)
end

---------------------------------------------------------
-- 4. HÀNH ĐỘNG (SHIFT VÀ SPACE)
---------------------------------------------------------
local actionFrame, actionBody = createBasePanel("ActionPanel", "⚡ SHIFT / SPACE", UDim2.new(0, 180, 0, 90), UDim2.new(0.02, 0, 0.32, 0))

local shiftBtn = Instance.new("TextButton")
shiftBtn.Size = UDim2.new(0.48, 0, 0.85, 0)
shiftBtn.Position = UDim2.new(0, 0, 0.08, 0)
shiftBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
shiftBtn.BackgroundTransparency = 0.88
shiftBtn.Text = "SHIFT"
shiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shiftBtn.Font = Enum.Font.SourceSansBold
shiftBtn.TextSize = 13
shiftBtn.Parent = actionBody
Instance.new("UICorner", shiftBtn).CornerRadius = UDim.new(0, 6)
bindHoldEvents(shiftBtn, "SHIFT")

local spaceBtn = Instance.new("TextButton")
spaceBtn.Size = UDim2.new(0.48, 0, 0.85, 0)
spaceBtn.Position = UDim2.new(0.52, 0, 0.08, 0)
spaceBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 140)
spaceBtn.BackgroundTransparency = 0.88
spaceBtn.Text = "SPACE\n(NHẢY)"
spaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spaceBtn.Font = Enum.Font.SourceSansBold
spaceBtn.TextSize = 13
spaceBtn.Parent = actionBody
Instance.new("UICorner", spaceBtn).CornerRadius = UDim.new(0, 6)
bindHoldEvents(spaceBtn, "SPACE")

---------------------------------------------------------
-- 5. KHUNG KỸ NĂNG NHANH (E, Q, T)
---------------------------------------------------------
local skillFrame, skillBody = createBasePanel("SkillPanel", "🔥 E, Q, T", UDim2.new(0, 210, 0, 90), UDim2.new(0.68, 0, 0.32, 0))

local skillKeys = {
    {Name = "E", Desc = "T.TÁC", Color = Color3.fromRGB(210, 150, 20), Pos = UDim2.new(0, 0, 0.08, 0)},
    {Name = "Q", Desc = "LƯỚT", Color = Color3.fromRGB(40, 150, 210), Pos = UDim2.new(0.35, 0, 0.08, 0)},
    {Name = "T", Desc = "K.NĂNG", Color = Color3.fromRGB(180, 50, 210), Pos = UDim2.new(0.70, 0, 0.08, 0)},
}

for _, item in ipairs(skillKeys) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.3, 0, 0.85, 0)
    btn.Position = item.Pos
    btn.BackgroundColor3 = item.Color
    btn.BackgroundTransparency = 0.88
    btn.Text = item.Name .. "\n(" .. item.Desc .. ")"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = skillBody
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    bindHoldEvents(btn, item.Name)
end

---------------------------------------------------------
-- 6. KHUNG PHÍM SỐ ĐỘC LẬP (1 - 0)
---------------------------------------------------------
local numFrame, numBody = createBasePanel("NumPanel", "🔢 PHÍM SỐ (1-0)", UDim2.new(0, 320, 0, 90), UDim2.new(0.35, 0, 0.42, 0))

local numKeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
local totalNum = #numKeys

for i, keyName in ipairs(numKeys) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / totalNum, -3, 0.85, 0)
    btn.Position = UDim2.new((i - 1) / totalNum, 1, 0.08, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
    btn.BackgroundTransparency = 0.88
    btn.Text = keyName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = numBody
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    bindHoldEvents(btn, keyName)
end

---------------------------------------------------------
-- 7. KHUNG PHÍM I VÀ O (ZOOM CAMERA)
---------------------------------------------------------
local ioFrame, ioBody = createBasePanel("IOPanel", "🔍 PHÍM I & O", UDim2.new(0, 140, 0, 90), UDim2.new(0.52, 0, 0.32, 0))

local ioKeys = {
    {Name = "I", Desc = "ZOOM IN", Color = Color3.fromRGB(0, 160, 210), Pos = UDim2.new(0, 0, 0.08, 0)},
    {Name = "O", Desc = "ZOOM OUT", Color = Color3.fromRGB(220, 110, 20), Pos = UDim2.new(0.52, 0, 0.08, 0)},
}

for _, item in ipairs(ioKeys) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0.85, 0)
    btn.Position = item.Pos
    btn.BackgroundColor3 = item.Color
    btn.BackgroundTransparency = 0.88
    btn.Text = item.Name .. "\n(" .. item.Desc .. ")"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = ioBody
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    bindHoldEvents(btn, item.Name)
end

---------------------------------------------------------
-- 8. KHUNG PHÍM C, R, V, G, F
---------------------------------------------------------
local extraFrame, extraBody = createBasePanel("ExtraPanel", "🎯 PHÍM C, R, V, G, F", UDim2.new(0, 310, 0, 90), UDim2.new(0.2, 0, 0.32, 0))

local extraKeys = {
    {Name = "C", Color = Color3.fromRGB(120, 80, 200)},
    {Name = "R", Color = Color3.fromRGB(200, 60, 60)},
    {Name = "V", Color = Color3.fromRGB(50, 160, 90)},
    {Name = "G", Color = Color3.fromRGB(200, 150, 30)},
    {Name = "F", Color = Color3.fromRGB(180, 50, 160)},
}

local totalExtra = #extraKeys
for i, item in ipairs(extraKeys) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / totalExtra, -4, 0.85, 0)
    btn.Position = UDim2.new((i - 1) / totalExtra, 2, 0.08, 0)
    btn.BackgroundColor3 = item.Color
    btn.BackgroundTransparency = 0.88
    btn.Text = item.Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Parent = extraBody
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    bindHoldEvents(btn, item.Name)
  end
    ---------------------------------------------------------
-- 9. BÀN PHÍM CHAT CHUẨN KHÔNG DẤU
---------------------------------------------------------
local kbFrame, kbBody = createBasePanel("KBPanel", "⌨ BÀN PHÍM CHAT", UDim2.new(0, 520, 0, 230), UDim2.new(0.18, 0, 0.08, 0))
kbFrame.Visible = false

local chatHeader = Instance.new("Frame")
chatHeader.Size = UDim2.new(1, 0, 0, 32)
chatHeader.Position = UDim2.new(0, 0, 0, 0)
chatHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
chatHeader.BackgroundTransparency = 0.4
chatHeader.Parent = kbBody
Instance.new("UICorner", chatHeader).CornerRadius = UDim.new(0, 6)

local chatBox = Instance.new("TextBox")
chatBox.Size = UDim2.new(0.8, -6, 1, 0)
chatBox.Position = UDim2.new(0, 6, 0, 0)
chatBox.BackgroundTransparency = 1
chatBox.Text = ""
chatBox.PlaceholderText = "Bấm phím để nhập tin nhắn..."
chatBox.TextColor3 = Color3.fromRGB(255, 255, 255)
chatBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
chatBox.Font = Enum.Font.SourceSans
chatBox.TextSize = 14
chatBox.TextXAlignment = Enum.TextXAlignment.Left
chatBox.ClearTextOnFocus = false
chatBox.Parent = chatHeader

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0.2, -6, 0.8, 0)
sendBtn.Position = UDim2.new(0.8, 2, 0.1, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
sendBtn.Text = "GỬI 💬"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.Font = Enum.Font.SourceSansBold
sendBtn.TextSize = 12
sendBtn.Parent = chatHeader
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 5)

local function sendChatMessage(msg)
    if not msg or msg:gsub("%s+", "") == "" then return end
    
    local sent = false
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                generalChannel:SendAsync(msg)
                sent = true
            end
        end
    end)

    if not sent then
        pcall(function()
            local repStorage = game:GetService("ReplicatedStorage")
            local chatEvents = repStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(msg, "All")
            end
        end)
    end
end

local function executeSend()
    playKeySound()
    local text = chatBox.Text
    if text ~= "" then
        sendChatMessage(text)
        chatBox.Text = ""
    end
end

sendBtn.MouseButton1Click:Connect(executeSend)
chatBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        executeSend()
    end
end)

local kbKeysArea = Instance.new("Frame")
kbKeysArea.Size = UDim2.new(1, 0, 1, -38)
kbKeysArea.Position = UDim2.new(0, 0, 0, 38)
kbKeysArea.BackgroundTransparency = 1
kbKeysArea.Parent = kbBody

local isUpper = true
local kbButtonsList = {}

local kbLayout = {
    { {Key="1"}, {Key="2"}, {Key="3"}, {Key="4"}, {Key="5"}, {Key="6"}, {Key="7"}, {Key="8"}, {Key="9"}, {Key="0"} },
    { {Key="Q"}, {Key="W"}, {Key="E"}, {Key="R"}, {Key="T"}, {Key="Y"}, {Key="U"}, {Key="I"}, {Key="O"}, {Key="P"} },
    { {Key="A"}, {Key="S"}, {Key="D"}, {Key="F"}, {Key="G"}, {Key="H"}, {Key="J"}, {Key="K"}, {Key="L"} },
    { {Key="SHIFT", Weight=1.5}, {Key="Z"}, {Key="X"}, {Key="C"}, {Key="V"}, {Key="B"}, {Key="N"}, {Key="M"}, {Key="⌫", Weight=1.5} },
    { {Key=","}, {Key="?", Weight=1}, {Key="SPACE", Weight=5.5}, {Key="."}, {Key="ENTER", Weight=2} }
}

local rowCount = #kbLayout
for rIndex, row in ipairs(kbLayout) do
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1, 0, 1 / rowCount, -2)
    rowFrame.Position = UDim2.new(0, 0, (rIndex - 1) / rowCount, 1)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = kbKeysArea

    local totalWeight = 0
    for _, item in ipairs(row) do
        totalWeight = totalWeight + (item.Weight or 1)
    end

    local currentOffsetWeight = 0
    for _, item in ipairs(row) do
        local keyName = item.Key
        local weight = item.Weight or 1
        local widthFraction = weight / totalWeight

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(widthFraction, -3, 1, -3)
        btn.Position = UDim2.new(currentOffsetWeight / totalWeight, 1, 0, 1)
        
        if keyName == "ENTER" or keyName == "⌫" then
            btn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
        elseif keyName == "SHIFT" or keyName == "SPACE" then
            btn.BackgroundColor3 = Color3.fromRGB(0, 140, 180)
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end
        
        btn.BackgroundTransparency = 0.85
        btn.Text = keyName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 12
        btn.Parent = rowFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

        table.insert(kbButtonsList, {Button = btn, Key = keyName})

        btn.MouseButton1Click:Connect(function()
            playKeySound()
            if keyName == "⌫" then
                chatBox.Text = string.sub(chatBox.Text, 1, #chatBox.Text - 1)
            elseif keyName == "SPACE" then
                chatBox.Text = chatBox.Text .. " "
            elseif keyName == "ENTER" then
                executeSend()
            elseif keyName == "SHIFT" then
                isUpper = not isUpper
                for _, kData in ipairs(kbButtonsList) do
                    if #kData.Key == 1 and kData.Key:match("%a") then
                        kData.Button.Text = isUpper and kData.Key or string.lower(kData.Key)
                    end
                end
            else
                local charToAdd = (#keyName == 1 and keyName:match("%a")) and (isUpper and keyName or string.lower(keyName)) or keyName
                chatBox.Text = chatBox.Text .. charToAdd
            end
        end)

        currentOffsetWeight = currentOffsetWeight + weight
    end
end

---------------------------------------------------------
-- HỆ THỐNG LƯU & TẢI SETTINGS (ĐÃ SỬA LỖI JSONDECODE)
---------------------------------------------------------
local fileName = "VirtualControl_Settings.json"

local allPanels = {
    MovePanel = moveFrame,
    NumPanel = numFrame,
    MousePanel = mouseFrame,
    CamPanel = camFrame,
    ActionPanel = actionFrame,
    SkillPanel = skillFrame,
    IOPanel = ioFrame,
    ExtraPanel = extraFrame,
    KBPanel = kbFrame,
}

local function saveSettings()
    if not writefile then
        warn("[VirtualControl] Executor không hỗ trợ hàm writefile!")
        return false
    end

    local data = {}
    for name, frame in pairs(allPanels) do
        if frame then
            local scaleObj = frame:FindFirstChildOfClass("UIScale")
            data[name] = {
                Pos = {
                    XS = frame.Position.X.Scale, XO = frame.Position.X.Offset,
                    YS = frame.Position.Y.Scale, YO = frame.Position.Y.Offset
                },
                Scale = scaleObj and scaleObj.Scale or 1,
                Visible = frame.Visible
            }
        end
    end

    local success, err = pcall(function()
        writefile(fileName, HttpService:JSONEncode(data))
    end)

    if not success then
        warn("[VirtualControl] Lỗi khi ghi file lưu:", err)
    end
    return success
end

local function loadSettings()
    if not (readfile and isfile) then return end

    pcall(function()
        if isfile(fileName) then
            local raw = readfile(fileName)
            if raw and raw ~= "" then
                -- SỬA TẠI ĐÂY: Dùng JSONDecode để giải mã dữ liệu file sang Bảng (Table)
                local data = HttpService:JSONDecode(raw)
                if type(data) == "table" then
                    for name, config in pairs(data) do
                        local frame = allPanels[name]
                        if frame and config then
                            if config.Pos then
                                frame.Position = UDim2.new(
                                    config.Pos.XS or 0, config.Pos.XO or 0,
                                    config.Pos.YS or 0, config.Pos.YO or 0
                                )
                            end
                            local scaleObj = frame:FindFirstChildOfClass("UIScale")
                            if scaleObj and config.Scale then
                                scaleObj.Scale = config.Scale
                            end
                            if config.Visible ~= nil then
                                frame.Visible = config.Visible
                            end
                        end
                    end
                end
            end
        end
    end)
end

---------------------------------------------------------
-- 10. THANH MENU TRUNG TÂM
---------------------------------------------------------
local toolbar = Instance.new("Frame")
toolbar.Name = "Toolbar"
toolbar.Size = UDim2.new(0, 750, 0, 36)
toolbar.Position = UDim2.new(0.5, -375, 0.02, 0)
toolbar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
toolbar.BackgroundTransparency = 0.88
toolbar.Active = true
toolbar.Parent = screenGui

Instance.new("UICorner", toolbar).CornerRadius = UDim.new(0, 8)
local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(255, 255, 255)
tbStroke.Transparency = 0.92
tbStroke.Parent = toolbar
makeDraggable(toolbar, toolbar)

local menuButtons = {
    {Text = "🕹 DI CHUYỂN", Panel = moveFrame},
    {Text = "🔢 PHÍM SỐ", Panel = numFrame},
    {Text = "⚡ SHIFT/SPC", Panel = actionFrame},
    {Text = "🔥 E, Q, T", Panel = skillFrame},
    {Text = "🔍 I, O", Panel = ioFrame},
    {Text = "🎯 C,R,V,G,F", Panel = extraFrame},
    {Text = "🖱 CHUỘT", Panel = mouseFrame},
    {Text = "🎥 CAMERA", Panel = camFrame},
    {Text = "⌨ BÀN PHÍM", Panel = kbFrame},
}

local totalMenuBtns = #menuButtons + 1
for i, item in ipairs(menuButtons) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / totalMenuBtns, -3, 0.75, 0)
    btn.Position = UDim2.new((i - 1) / totalMenuBtns, 2, 0.12, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    btn.BackgroundTransparency = 0.85
    btn.Text = item.Text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 9
    btn.Parent = toolbar

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() 
        playKeySound()
        item.Panel.Visible = not item.Panel.Visible 
    end)
end

-- NÚT LƯU CÀI ĐẶT
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1 / totalMenuBtns, -3, 0.75, 0)
saveBtn.Position = UDim2.new((totalMenuBtns - 1) / totalMenuBtns, 2, 0.12, 0)
saveBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
saveBtn.BackgroundTransparency = 0.75
saveBtn.Text = "💾 LƯU"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.SourceSansBold
saveBtn.TextSize = 10
saveBtn.Parent = toolbar
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

saveBtn.MouseButton1Click:Connect(function()
    playKeySound()
    if saveSettings() then
        saveBtn.Text = "✔ ĐÃ LƯU!"
        saveBtn.BackgroundColor3 = Color3.fromRGB(30, 200, 100)
        task.wait(1.5)
        saveBtn.Text = "💾 LƯU"
        saveBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    else
        saveBtn.Text = "❌ LỖI LƯU"
        saveBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1.5)
        saveBtn.Text = "💾 LƯU"
        saveBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    end
end)

---------------------------------------------------------
-- 11. NÚT BẬT/TẮT GIAO DIỆN DẠNG BONG BÓNG (FLOATING TOGGLE BUTTON)
---------------------------------------------------------
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "FloatingToggleBtn"
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.Position = UDim2.new(0.02, 0, 0.12, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
toggleBtn.BackgroundTransparency = 0.25
toggleBtn.Text = "🎮"
toggleBtn.TextSize = 22
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Active = true
toggleBtn.Parent = screenGui

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(0, 170, 255)
toggleStroke.Thickness = 2
toggleStroke.Transparency = 0.3
toggleStroke.Parent = toggleBtn

makeDraggable(toggleBtn, toggleBtn, true)

local isMainVisible = true
toggleBtn.MouseButton1Click:Connect(function()
    playKeySound()
    isMainVisible = not isMainVisible
    toolbar.Visible = isMainVisible
    controlBar.Visible = isMainVisible

    for _, panel in pairs(allPanels) do
        if panel then
            panel.Visible = isMainVisible
        end
    end

    if isMainVisible then
        toggleStroke.Color = Color3.fromRGB(0, 170, 255)
        toggleBtn.BackgroundTransparency = 0.25
    else
        toggleStroke.Color = Color3.fromRGB(120, 120, 120)
        toggleBtn.BackgroundTransparency = 0.6
    end
end)

-- Tự động tải lại vị trí đã lưu khi chạy Script
loadSettings()
  omOutBtn.Font = Enum.Font.SourceSansBold
    zoomOutBtn.TextSize = 13
    zoomOutBtn.Parent = header
    Instance.new("UICorner", zoomOutBtn).CornerRadius = UDim.new(0, 4)
    zoomOutBtn.MouseButton1Click:Connect(function() 
        playKeySound()
        uiScale.Scale = math.clamp(uiScale.Scale - 0.1, 0.5, 2.0) 
    end)

    makeDraggable(header, frame)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -8, 1, -30)
    body.Position = UDim2.new(0, 4, 0, 26)
    body.BackgroundTransparency = 1
    body.Parent = frame

    return frame, body
end
