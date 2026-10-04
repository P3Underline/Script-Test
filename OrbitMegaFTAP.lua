-- MENU ULTIMATE DE PARTS ORBIT COM PADRÕES E BIND
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ===== ESTADO =====
local activeOrbits = {}
local selectedParts = {}
local orbitSettings = {
    pattern = "circle",
    speed = 2,
    radius = 20,
    height = 10,
    particleSize = 1,
    enabled = true,
    keybind = Enum.KeyCode.Z
}

-- ===== PADRÕES DE ÓRBITA =====
local ORBIT_PATTERNS = {
    circle = {
        name = "⭕ Círculo",
        description = "Gira em volta tranquilo",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 2
            local x = math.cos(angle + time) * config.radius
            local z = math.sin(angle + time) * config.radius
            local y = config.height
            return x, y, z
        end
    },
    
    tornado = {
        name = "🌪️ Tornado",
        description = "Tornado de blocos acima",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 2
            local x = math.cos(angle + time) * config.radius
            local z = math.sin(angle + time) * config.radius
            local y = config.height + (i / total) * 20
            return x, y, z
        end
    },
    
    wings = {
        name = "🪽 Asas",
        description = "Asas de props atrás de você",
        calculate = function(i, total, time, config)
            local half = total / 2
            local side = i > half and 1 or -1
            local offset = i > half and (i - half) or i
            
            local x = side * config.radius
            local z = -10 - (offset / half) * 5
            local y = config.height + math.sin(time + offset) * 3
            return x, y, z
        end
    },
    
    wave = {
        name = "〰️ Onda",
        description = "Onda fluida de blocos",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 4
            local x = math.cos(angle + time) * config.radius
            local z = math.sin(angle + time) * config.radius
            local y = config.height + math.sin(angle + time * 2) * 5
            return x, y, z
        end
    },
    
    helix = {
        name = "🧬 Hélice",
        description = "DNA em volta de você",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 4
            local x = math.cos(angle + time) * config.radius
            local z = math.sin(angle + time) * config.radius
            local y = config.height + (i / total) * 15 + math.sin(time) * 3
            return x, y, z
        end
    },
    
    figure8 = {
        name = "∞ Figura 8",
        description = "Infinito em volta de você",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 2
            local x = math.cos(angle + time) * config.radius
            local z = math.sin(2 * (angle + time)) * config.radius
            local y = config.height + math.sin(time * 2) * 3
            return x, y, z
        end
    },
    
    ball = {
        name = "⚽ Esfera",
        description = "Bola de blocos",
        calculate = function(i, total, time, config)
            local angle1 = (i / total) * math.pi * 2
            local angle2 = (i / total) * math.pi
            local x = math.cos(angle1 + time) * math.sin(angle2) * config.radius
            local z = math.sin(angle1 + time) * math.sin(angle2) * config.radius
            local y = config.height + math.cos(angle2) * config.radius
            return x, y, z
        end
    }
}

-- ===== FUNÇÕES CORE =====
local function getPartsByClassName(className)
    local foundParts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and obj.ClassName == className then
            table.insert(foundParts, obj)
        end
    end
    return foundParts
end

local function getAllPartTypes()
    local types = {}
    local typeSet = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            if not typeSet[obj.ClassName] then
                typeSet[obj.ClassName] = true
                table.insert(types, obj.ClassName)
            end
        end
    end
    
    table.sort(types)
    return types
end

local function startOrbit(partList, className)
    if activeOrbits[className] then
        activeOrbits[className] = false
        task.wait(0.1)
    end
    
    activeOrbits[className] = true
    
    for i, part in ipairs(partList) do
        part.CanCollide = false
        part.Transparency = 0.2
        
        if part:IsA("BasePart") then
            part.Color = Color3.fromHSV((i / #partList), 1, 1)
            part.Size = part.Size * orbitSettings.particleSize
        end
        
        task.spawn(function()
            local time = 0
            
            while part and part.Parent and activeOrbits[className] and orbitSettings.enabled do
                time = time + 0.01 * orbitSettings.speed
                
                local pattern = ORBIT_PATTERNS[orbitSettings.pattern]
                local x, y, z = pattern.calculate(i, #partList, time, orbitSettings)
                
                part.Position = humanoidRootPart.Position + Vector3.new(x, y, z)
                part.Orientation = part.Orientation + Vector3.new(5, 10, 5)
                
                task.wait()
            end
        end)
    end
end

local function stopOrbit(className)
    activeOrbits[className] = false
end

-- ===== CRIAR GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PartsOrbitMenuUltimate"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.3
background.ZIndex = 1
background.Parent = screenGui

-- Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 500, 0, 900)
mainContainer.Position = UDim2.new(0.5, -250, 0.5, -450)
mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 2
mainContainer.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainContainer

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 70)
stroke.Thickness = 1
stroke.Parent = mainContainer

-- ===== HEADER =====
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.Parent = mainContainer

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "✨ ULTIMATE ORBIT MENU"
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- ===== SCROLL CONTAINER =====
local scrollContainer = Instance.new("ScrollingFrame")
scrollContainer.Name = "ScrollContainer"
scrollContainer.Size = UDim2.new(1, -10, 1, -140)
scrollContainer.Position = UDim2.new(0, 5, 0, 70)
scrollContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
scrollContainer.BorderSizePixel = 0
scrollContainer.ScrollBarThickness = 6
scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollContainer.Parent = mainContainer

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.Parent = scrollContainer

-- ===== SEÇÃO DE PADRÕES =====
local patternsSection = Instance.new("Frame")
patternsSection.Name = "PatternsSection"
patternsSection.Size = UDim2.new(1, -20, 0, 0)
patternsSection.BackgroundTransparency = 1
patternsSection.Parent = scrollContainer

local patternsSizeConstraint = Instance.new("UISizeConstraint")
patternsSizeConstraint.MaxSize = Vector2.new(math.huge, 200)
patternsSizeConstraint.Parent = patternsSection

local patternsLabel = Instance.new("TextLabel")
patternsLabel.Name = "Label"
patternsLabel.Text = "🎨 TIPO DE ÓRBITA"
patternsLabel.Size = UDim2.new(1, 0, 0, 30)
patternsLabel.BackgroundTransparency = 1
patternsLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
patternsLabel.TextSize = 14
patternsLabel.Font = Enum.Font.GothamBold
patternsLabel.TextXAlignment = Enum.TextXAlignment.Left
patternsLabel.Parent = patternsSection

local patternsGrid = Instance.new("Frame")
patternsGrid.Name = "Grid"
patternsGrid.Size = UDim2.new(1, 0, 0, 150)
patternsGrid.Position = UDim2.new(0, 0, 0, 30)
patternsGrid.BackgroundTransparency = 1
patternsGrid.Parent = patternsSection

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
gridLayout.CellSize = UDim2.new(0.45, 0, 0, 65)
gridLayout.Parent = patternsGrid

local function createPatternButton(key, patternData)
    local btn = Instance.new("TextButton")
    btn.Name = key
    btn.Text = ""
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.BorderSizePixel = 0
    btn.Parent = patternsGrid
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(60, 60, 70)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
    
    local content = Instance.new("TextLabel")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.TextScaled = true
    content.TextColor3 = Color3.fromRGB(180, 180, 200)
    content.Font = Enum.Font.GothamBold
    content.Text = patternData.name .. "\n" .. patternData.description
    content.Parent = btn
    
    local isSelected = false
    
    btn.MouseButton1Click:Connect(function()
        isSelected = not isSelected
        orbitSettings.pattern = key
        
        if isSelected then
            btn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            btnStroke.Color = Color3.fromRGB(150, 200, 255)
            
            -- Desseleciona outros
            for _, other in pairs(patternsGrid:GetChildren()) do
                if other ~= btn and other:IsA("TextButton") then
                    other.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                    other:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(60, 60, 70)
                end
            end
        end
    end)
    
    btn.MouseEnter:Connect(function()
        if not isSelected then
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if not isSelected then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
    end)
end

for key, pattern in pairs(ORBIT_PATTERNS) do
    createPatternButton(key, pattern)
end

-- ===== SEÇÃO DE PROPRIEDADES =====
local propertiesSection = Instance.new("Frame")
propertiesSection.Name = "PropertiesSection"
propertiesSection.Size = UDim2.new(1, -20, 0, 0)
propertiesSection.BackgroundTransparency = 1
propertiesSection.Parent = scrollContainer

local propertiesSizeConstraint = Instance.new("UISizeConstraint")
propertiesSizeConstraint.MaxSize = Vector2.new(math.huge, 300)
propertiesSizeConstraint.Parent = propertiesSection

local propertiesLabel = Instance.new("TextLabel")
propertiesLabel.Name = "Label"
propertiesLabel.Text = "⚙️ PROPRIEDADES"
propertiesLabel.Size = UDim2.new(1, 0, 0, 30)
propertiesLabel.BackgroundTransparency = 1
propertiesLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
propertiesLabel.TextSize = 14
propertiesLabel.Font = Enum.Font.GothamBold
propertiesLabel.TextXAlignment = Enum.TextXAlignment.Left
propertiesLabel.Parent = propertiesSection

-- Função para criar slider
local function createSlider(parent, label, minVal, maxVal, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Name = label
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Text = label .. ": " .. tostring(math.floor(defaultVal * 10) / 10)
    labelText.Size = UDim2.new(1, 0, 0, 20)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelText.TextSize = 12
    labelText.Font = Enum.Font.Gotham
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "SliderBg"
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    sliderBg.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            while UserInputService:IsMouseButtonPressed(Enum.UserInputButton.Left) do
                local mouse = player:GetMouse()
                local pos = mouse.X - sliderBg.AbsolutePosition.X
                local size = sliderBg.AbsoluteSize.X
                local percent = math.clamp(pos / size, 0, 1)
                local value = minVal + (maxVal - minVal) * percent
                
                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                labelText.Text = label .. ": " .. tostring(math.floor(value * 10) / 10)
                
                callback(value)
                task.wait()
            end
        end
    end)
end

local propertiesContainer = Instance.new("Frame")
propertiesContainer.Name = "Container"
propertiesContainer.Size = UDim2.new(1, 0, 0, 0)
propertiesContainer.Position = UDim2.new(0, 0, 0, 30)
propertiesContainer.BackgroundTransparency = 1
propertiesContainer.Parent = propertiesSection

local propsLayout = Instance.new("UIListLayout")
propsLayout.Padding = UDim.new(0, 5)
propsLayout.Parent = propertiesContainer

createSlider(propertiesContainer, "Velocidade", 0.1, 10, orbitSettings.speed, function(value)
    orbitSettings.speed = value
end)

createSlider(propertiesContainer, "Raio", 5, 50, orbitSettings.radius, function(value)
    orbitSettings.radius = value
end)

createSlider(propertiesContainer, "Altura", 0, 30, orbitSettings.height, function(value)
    orbitSettings.height = value
end)

createSlider(propertiesContainer, "Tamanho das Partes", 0.1, 5, orbitSettings.particleSize, function(value)
    orbitSettings.particleSize = value
end)

-- ===== SEÇÃO DE PARTS =====
local partsSection = Instance.new("Frame")
partsSection.Name = "PartsSection"
partsSection.Size = UDim2.new(1, -20, 0, 0)
partsSection.BackgroundTransparency = 1
partsSection.Parent = scrollContainer

local partsSizeConstraint = Instance.new("UISizeConstraint")
partsSizeConstraint.MaxSize = Vector2.new(math.huge, 400)
partsSizeConstraint.Parent = partsSection

local partsLabel = Instance.new("TextLabel")
partsLabel.Name = "Label"
partsLabel.Text = "📦 TIPOS DE PARTES"
partsLabel.Size = UDim2.new(1, 0, 0, 30)
partsLabel.BackgroundTransparency = 1
partsLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
partsLabel.TextSize = 14
partsLabel.Font = Enum.Font.GothamBold
partsLabel.TextXAlignment = Enum.TextXAlignment.Left
partsLabel.Parent = partsSection

local partsList = Instance.new("Frame")
partsList.Name = "List"
partsList.Size = UDim2.new(1, 0, 0, 350)
partsList.Position = UDim2.new(0, 0, 0, 30)
partsList.BackgroundTransparency = 1
partsList.Parent = partsSection

local partsScroll = Instance.new("ScrollingFrame")
partsScroll.Size = UDim2.new(1, 0, 1, 0)
partsScroll.BackgroundTransparency = 1
partsScroll.BorderSizePixel = 0
partsScroll.ScrollBarThickness = 4
partsScroll.Parent = partsList

local partsListLayout = Instance.new("UIListLayout")
partsListLayout.Padding = UDim.new(0, 5)
partsListLayout.Parent = partsScroll

local function createPartButton(className, count)
    local btn = Instance.new("TextButton")
    btn.Name = className
    btn.Text = ""
    btn.Size = UDim2.new(1, -20, 0, 50)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.BorderSizePixel = 0
    btn.Parent = partsScroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = btn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(60, 60, 70)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
    
    local icon = Instance.new("TextLabel")
    icon.Text = "📦"
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.BackgroundTransparency = 1
    icon.TextSize = 24
    icon.Font = Enum.Font.GothamBold
    icon.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Text = className .. " (" .. count .. ")"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 50, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn
    
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 10, 0, 10)
    statusDot.Position = UDim2.new(1, -20, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = btn
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot
    
    local isActive = false
    
    btn.MouseButton1Click:Connect(function()
        isActive = not isActive
        selectedParts[className] = isActive
        
        if isActive then
            statusDot.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            btn.BackgroundColor3 = Color3.fromRGB(50, 70, 90)
            btnStroke.Color = Color3.fromRGB(100, 200, 100)
            
            local parts = getPartsByClassName(className)
            startOrbit(parts, className)
        else
            statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            btnStroke.Color = Color3.fromRGB(60, 60, 70)
            
            stopOrbit(className)
        end
    end)
    
    btn.MouseEnter:Connect(function()
        if not isActive then
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            btnStroke.Color = Color3.fromRGB(100, 120, 140)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if not isActive then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            btnStroke.Color = Color3.fromRGB(60, 60, 70)
        end
    end)
end

-- ===== FOOTER =====
local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 65)
footer.Position = UDim2.new(0, 0, 1, -65)
footer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
footer.BorderSizePixel = 0
footer.Parent = mainContainer

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 16)
footerCorner.Parent = footer

-- Toggle Orbit
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Text = "🟢 ÓRBITA ON"
toggleBtn.Size = UDim2.new(0, 150, 0, 45)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -22)
toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = footer

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    orbitSettings.enabled = not orbitSettings.enabled
    
    if orbitSettings.enabled then
        toggleBtn.Text = "🟢 ÓRBITA ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    else
        toggleBtn.Text = "🔴 ÓRBITA OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    end
end)

-- Keybind selector
local keybindContainer = Instance.new("Frame")
keybindContainer.Name = "KeybindContainer"
keybindContainer.Size = UDim2.new(0, 170, 0, 45)
keybindContainer.Position = UDim2.new(0, 170, 0.5, -22)
keybindContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
keybindContainer.BorderSizePixel = 0
keybindContainer.Parent = footer

local keybindCorner = Instance.new("UICorner")
keybindCorner.CornerRadius = UDim.new(0, 8)
keybindCorner.Parent = keybindContainer

local keybindLabel = Instance.new("TextLabel")
keybindLabel.Text = "🎮 Bind: E"
keybindLabel.Size = UDim2.new(1, 0, 1, 0)
keybindLabel.BackgroundTransparency = 1
keybindLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
keybindLabel.TextSize = 12
keybindLabel.Font = Enum.Font.GothamBold
keybindLabel.Parent = keybindContainer

local keybindBtn = Instance.new("TextButton")
keybindBtn.Name = "SetKeybind"
keybindBtn.Text = "Mudar"
keybindBtn.Size = UDim2.new(0, 60, 0, 45)
keybindBtn.Position = UDim2.new(1, -70, 0, 0)
keybindBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
keybindBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
keybindBtn.TextSize = 10
keybindBtn.Font = Enum.Font.GothamBold
keybindBtn.BorderSizePixel = 0
keybindBtn.Parent = keybindContainer

local keybindCorner2 = Instance.new("UICorner")
keybindCorner2.CornerRadius = UDim.new(0, 6)
keybindCorner2.Parent = keybindBtn

local waitingForBind = false

keybindBtn.MouseButton1Click:Connect(function()
    if not waitingForBind then
        waitingForBind = true
        keybindBtn.Text = "Aguarde..."
        keybindBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
        
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            orbitSettings.keybind = input.KeyCode
            keybindLabel.Text = "🎮 Bind: " .. tostring(orbitSettings.keybind):split(".")[3]:sub(1, -2)
            
            keybindBtn.Text = "Mudar"
            keybindBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            
            waitingForBind = false
            connection:Disconnect()
        end)
    end
end)

-- Stop All button
local stopAllBtn = Instance.new("TextButton")
stopAllBtn.Name = "StopAll"
stopAllBtn.Text = "⏹ PARAR TUDO"
stopAllBtn.Size = UDim2.new(0, 140, 0, 45)
stopAllBtn.Position = UDim2.new(1, -150, 0.5, -22)
stopAllBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
stopAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopAllBtn.TextSize = 12
stopAllBtn.Font = Enum.Font.GothamBold
stopAllBtn.BorderSizePixel = 0
stopAllBtn.Parent = footer

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopAllBtn

stopAllBtn.MouseButton1Click:Connect(function()
    for className, _ in pairs(selectedParts) do
        stopOrbit(className)
        selectedParts[className] = false
    end
    
    for _, btn in pairs(partsScroll:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            btn:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            btn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(60, 60, 70)
        end
    end
end)

-- ===== INICIALIZAR =====
local partTypes = getAllPartTypes()

for _, className in pairs(partTypes) do
    local count = #getPartsByClassName(className)
    createPartButton(className, count)
end

partsScroll.CanvasSize = UDim2.new(0, 0, 0, (#partTypes * 55))

-- Atualizar canvas sizes
scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 200 + 300 + 30 + (#partTypes * 55) + 50)

-- ===== KEYBIND HANDLER =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == orbitSettings.keybind then
        orbitSettings.enabled = not orbitSettings.enabled
        
        if orbitSettings.enabled then
            toggleBtn.Text = "🟢 ÓRBITA ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        else
            toggleBtn.Text = "🔴 ÓRBITA OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        end
    end
end)

-- ===== EVENTOS =====
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

print("=" .. string.rep("=", 60))
print("✨ ULTIMATE ORBIT MENU CARREGADO!")
print("Keybind: " .. tostring(orbitSettings.keybind):split(".")[3]:sub(1, -2))
print("=" .. string.rep("=", 60))
