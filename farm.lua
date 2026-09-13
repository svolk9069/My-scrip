-- ========================================
-- FARM SCRIPT v3 — финальная версия
-- ========================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
print("[Farm] Загружен!")

-- ============ СКРЫТИЕ PROMPT'ОВ ============
-- Убираем все визуальные ProximityPrompt'ы (круг с рукой)
local function hideAllPrompts()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            v.Enabled = false                -- отключаем отображение
            v.MaxActivationDistance = math.huge -- но fireproximityprompt всё равно работает
        end
    end
end

-- Скрываем и те, что появятся потом
local hideCon = workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then
        task.wait(0.1)
        obj.Enabled = false
        obj.MaxActivationDistance = math.huge
    end
end)

-- Запускаем сразу
hideAllPrompts()

-- ============ GUI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmGui_" .. math.random(1,99999)
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function() screenGui.Parent = CoreGui end)
if not ok or not screenGui.Parent then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 190, 0, 175)
mainFrame.Position = UDim2.new(0, 20, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,12); mc.Parent = mainFrame
local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(80,200,255); ms.Thickness = 1.5; ms.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,28)
title.BackgroundColor3 = Color3.fromRGB(40,40,50)
title.BackgroundTransparency = 0.3
title.Text = "☰ Farm Menu"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,12); tc.Parent = title

local function makeBtn(text, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-20,0,34)
    b.Position = UDim2.new(0,10,0,y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = text
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = mainFrame
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
    return b
end

local giftBtn   = makeBtn("TP к подарку",   36, Color3.fromRGB(35,90,160))
local repairBtn = makeBtn("Авто-ремонт: ВЫКЛ", 74, Color3.fromRGB(50,50,60))
local promptBtn = makeBtn("Скрыть Prompt: ВКЛ", 112, Color3.fromRGB(30,130,50))

local notify = Instance.new("TextLabel")
notify.Size = UDim2.new(0,340,0,50)
notify.Position = UDim2.new(0.5,-170,0,15)
notify.BackgroundColor3 = Color3.fromRGB(200,40,40)
notify.BackgroundTransparency = 0.1
notify.TextColor3 = Color3.fromRGB(255,255,255)
notify.Text = ""
notify.TextSize = 18
notify.Font = Enum.Font.GothamBold
notify.Visible = false
notify.BorderSizePixel = 0
notify.Parent = screenGui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0,10); nc.Parent = notify

local function showNotify(text, dur)
    notify.Text = text
    notify.Visible = true
    task.delay(dur or 2, function() notify.Visible = false end)
end

-- Перетаскивание
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ============ ФУНКЦИИ ============
local function getChar()
    local c = player.Character or player.CharacterAdded:Wait()
    c:WaitForChild("HumanoidRootPart", 5)
    return c
end

local function getRoot(char)
    return char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
end

local function findNearestGift()
    local char = getChar()
    if not char then return nil end
    local hrp = getRoot(char)
    if not hrp then return nil end

    local folder = workspace:FindFirstChild("AirdropFolder")
    if not folder then return nil end

    local nearest, nearestDist = nil, math.huge
    for _, gift in ipairs(folder:GetChildren()) do
        local part
        if gift:IsA("Model") then
            part = gift.PrimaryPart or gift:FindFirstChildWhichIsA("BasePart")
        elseif gift:IsA("BasePart") then
            part = gift
        end
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < nearestDist then
                nearestDist = d
                nearest = gift
            end
        end
    end
    return nearest
end

-- Сбор: Prompt, ClickDetector, Touch
local function collectGift(gift)
    if not gift then return false end

    -- 1. ProximityPrompt (даже если Enabled = false, fireproximityprompt работает)
    local prompt
    if gift:IsA("Model") then
        prompt = gift:FindFirstChildOfClass("ProximityPrompt", true)
    elseif gift:IsA("BasePart") then
        prompt = gift:FindFirstChildOfClass("ProximityPrompt")
    end
    if prompt and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
    end

    -- 2. ClickDetector
    local clickDet
    if gift:IsA("Model") then
        clickDet = gift:FindFirstChildOfClass("ClickDetector", true)
    elseif gift:IsA("BasePart") then
        clickDet = gift:FindFirstChildOfClass("ClickDetector")
    end
    if clickDet and fireclickdetector then
        pcall(function() fireclickdetector(clickDet) end)
    end

    -- 3. TouchTransmitter (как в IY touchinterests)
    local part = gift:IsA("Model") and (gift.PrimaryPart or gift:FindFirstChildWhichIsA("BasePart")) or gift
    if part then
        local char = getChar()
        local root = getRoot(char)
        if firetouchinterest and root then
            pcall(function()
                firetouchinterest(part, root, 0)
                task.wait(0.05)
                firetouchinterest(part, root, 1)
            end)
        end
    end

    return true
end

local function teleportToGift()
    local gift = findNearestGift()
    if not gift then
        showNotify("Нету подарков", 2)
        return
    end

    local char = getChar()
    local hrp = getRoot(char)
    if not hrp then return end

    local targetPart
    if gift:IsA("Model") then
        targetPart = gift.PrimaryPart or gift:FindFirstChildWhichIsA("BasePart")
    else
        targetPart = gift
    end
    if not targetPart then return end

    hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 3, 0))
    task.wait(0.2)
    collectGift(gift)
end

-- ============ АВТО-РЕМОНТ ============
local function findStartRepair()
    local ok1, result = pcall(function()
        return ReplicatedStorage.CommonComponents.Packages.Knit.Services.PlotService.RF.StartRepair
    end)
    if ok1 and result then return result end
    return nil
end

local autoRepair = false

task.spawn(function()
    while true do
        if autoRepair then
            if not findStartRepair() then
                autoRepair = false
                repairBtn.Text = "Авто-ремонт: ВЫКЛ"
                repairBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
                showNotify("Кнопка StartRepair не найдена", 3)
            else
                local rf = findStartRepair()
                pcall(function() rf:InvokeServer() end)
            end
        end
        task.wait(1)
    end
end)

-- ============ ОБРАБОТЧИКИ ============
giftBtn.MouseButton1Click:Connect(function()
    pcall(teleportToGift)
end)

repairBtn.MouseButton1Click:Connect(function()
    autoRepair = not autoRepair
    if autoRepair then
        if not findStartRepair() then
            autoRepair = false
            showNotify("Кнопка StartRepair не найдена", 3)
            return
        end
        repairBtn.Text = "Авто-ремонт: ВКЛ"
        repairBtn.BackgroundColor3 = Color3.fromRGB(30,130,50)
    else
        repairBtn.Text = "Авто-ремонт: ВЫКЛ"
        repairBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
    end
end)

-- Кнопка Скрыть/Показать Prompt
local promptsHidden = true
local savedPrompts = {}

promptBtn.MouseButton1Click:Connect(function()
    promptsHidden = not promptsHidden
    if promptsHidden then
        -- Скрываем
        savedPrompts = {}
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                table.insert(savedPrompts, {prompt = v, enabled = v.Enabled})
                v.Enabled = false
            end
        end
        promptBtn.Text = "Скрыть Prompt: ВКЛ"
        promptBtn.BackgroundColor3 = Color3.fromRGB(30,130,50)
        showNotify("Prompt'ы скрыты", 1.5)
    else
        -- Показываем обратно
        for _, data in ipairs(savedPrompts) do
            if data.prompt and data.prompt.Parent then
                data.prompt.Enabled = data.enabled
            end
        end
        savedPrompts = {}
        promptBtn.Text = "Скрыть Prompt: ВЫКЛ"
        promptBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
        showNotify("Prompt'ы показаны", 1.5)
    end
end)

-- ============ СКРЫТИЕ ПРИ ЗАПУСКЕ ============
-- По умолчанию скрываем все prompt'ы сразу
savedPrompts = {}
for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("ProximityPrompt") then
        table.insert(savedPrompts, {prompt = v, enabled = v.Enabled})
        v.Enabled = false
    end
end

print("[Farm] Готово! Prompt'ы скрыты.")
