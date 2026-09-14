local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ПЕРЕМЕННЫЕ СОСТОЯНИЯ
local isRunning = false
local currentWaveCFrame = nil

-- ФУНКЦИЯ ПОЛУЧЕНИЯ АКТУАЛЬНОГО HUMANOIDROOTPART
local function getRootPart()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
        return char.HumanoidRootPart
    end
    return nil
end

-- ФУНКЦИЯ ДЛЯ СДЕЛАНИЯ ЭЛЕМЕНТА ПЕРЕТАСКИВАЕМЫМ
local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- СОЗДАНИЕ ИНТЕРФЕЙСА (ScreenGui)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BreakeDoorGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- ОСНОВНОЕ ОКНО
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 180, 0, 75)
MainFrame.Position = UDim2.new(0.5, -90, 0.4, -37)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
makeDraggable(MainFrame)

-- ЗАГОЛОВОК
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -12, 0, 20)
Title.Position = UDim2.new(0, 6, 0, 2)
Title.Text = "BreakeDoor"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- СТАТУС
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 0, 16)
StatusLabel.Position = UDim2.new(0, 6, 0, 20)
StatusLabel.Text = "Статус: Выключен"
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- КНОПКА ВКЛ / ВЫКЛ
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -12, 0, 30)
ToggleBtn.Position = UDim2.new(0, 6, 0, 38)
ToggleBtn.Text = "Собирать все подарки"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

-- БЕЗОПАСНАЯ АКТИВАЦИЯ PROXIMITYPROMPT
local function safeTriggerPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end
end

-- ВОЗВРАТ НА ТОЧКУ
local function returnToStartPos()
    local root = getRootPart()
    if currentWaveCFrame and root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = currentWaveCFrame
    end
    currentWaveCFrame = nil
end

-- СБОР ПОДАРКОВ
local function collectAirdrops()
    local airdropFolder = Workspace:FindFirstChild("AirdropFolder")
    if not airdropFolder then 
        StatusLabel.Text = "Папка AirdropFolder не найдена"
        return 
    end

    local drops = airdropFolder:GetChildren()
    local root = getRootPart()

    if not root then return end

    if #drops > 0 then
        if not currentWaveCFrame then
            currentWaveCFrame = root.CFrame
        end

        for i, box in ipairs(drops) do
            root = getRootPart()
            if not isRunning or not root then
                returnToStartPos()
                return
            end

            local targetPart = box:IsA("BasePart") and box or box:FindFirstChildWhichIsA("BasePart", true)
            if targetPart and box.Parent then
                StatusLabel.Text = "Сбор: " .. i .. "/" .. #drops

                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = targetPart.CFrame + Vector3.new(0, 1.5, 0)
                
                task.wait(0.15)

                local attempts = 0
                while box.Parent and attempts < 6 and isRunning do
                    root = getRootPart()
                    if not root then break end

                    root.CFrame = targetPart.CFrame + Vector3.new(0, 1.5, 0)
                    root.AssemblyLinearVelocity = Vector3.zero
                    
                    local prompt = box:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        safeTriggerPrompt(prompt)
                    end
                    
                    attempts = attempts + 1
                    task.wait(0.1)
                end

                task.wait(0.05)
            end
        end

        returnToStartPos()
        StatusLabel.Text = "Собрано! Поиск..."
    else
        StatusLabel.Text = "Ожидание подарков..."
    end
end

-- ЦИКЛ МОНИТОРИНГА И КНОПКА
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        StatusLabel.Text = "Статус: Работает..."
        
        task.spawn(function()
            while isRunning do
                collectAirdrops()
                task.wait(0.3)
            end
        end)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        StatusLabel.Text = "Статус: Выключен"
        returnToStartPos()
    end
end)
