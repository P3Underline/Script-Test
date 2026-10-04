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
            return math.cos(angle + time) * config.radius, config.height, math.sin(angle + time) * config.radius
        end
    },
    tornado = {
        name = "🌪️ Tornado",
        description = "Tornado de blocos acima",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 2
            return math.cos(angle + time) * config.radius, config.height + (i / total) * 20, math.sin(angle + time) * config.radius
        end
    },
    wings = {
        name = "🪽 Asas",
        description = "Asas de props atrás de você",
        calculate = function(i, total, time, config)
            local half = math.max(total / 2, 1)
            local side = i > half and 1 or -1
            local offset = i > half and (i - half) or i
            return side * config.radius, config.height + math.sin(time + offset) * 3, -10 - (offset / half) * 5
        end
    },
    wave = {
        name = "〰️ Onda",
        description = "Onda fluida de blocos",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 4
            return math.cos(angle + time) * config.radius, config.height + math.sin(angle + time * 2) * 5, math.sin(angle + time) * config.radius
        end
    },
    helix = {
        name = "🧬 Hélice",
        description = "DNA em volta de você",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 4
            return math.cos(angle + time) * config.radius, config.height + (i / total) * 15 + math.sin(time) * 3, math.sin(angle + time) * config.radius
        end
    },
    figure8 = {
        name = "∞ Figura 8",
        description = "Infinito em volta de você",
        calculate = function(i, total, time, config)
            local angle = (i / total) * math.pi * 2
            return math.cos(angle + time) * config.radius, config.height + math.sin(time * 2) * 3, math.sin(2 * (angle + time)) * config.radius
        end
    },
    ball = {
        name = "⚽ Esfera",
        description = "Bola de blocos",
        calculate = function(i, total, time, config)
            local angle1 = (i / total) * math.pi * 2
            local angle2 = (i / total) * math.pi
            return math.cos(angle1 + time) * math.sin(angle2) * config.radius,
                config.height + math.cos(angle2) * config.radius,
                math.sin(angle1 + time) * math.sin(angle2) * config.radius
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
        if obj:IsA("BasePart") and not obj.Anchored and not typeSet[obj.ClassName] then
            typeSet[obj.ClassName] = true
            table.insert(types, obj.ClassName)
        end
    end
    table.sort(types)
    return types
end

local function startOrbit(partList, className)
    if #partList == 0 then return end

    if activeOrbits[className] then
        activeOrbits[className] = false
        task.wait(0.1)
    end

    activeOrbits[className] = true

    for i, part in ipairs(partList) do
        if not part or not part.Parent then continue end

        part.CanCollide = false
        part.Transparency = 0.2
        part.Color = Color3.fromHSV(i / #partList, 1, 1)
        part.Size = part.Size * orbitSettings.particleSize

        task.spawn(function()
            local time = 0
            while part and part.Parent and activeOrbits[className] and orbitSettings.enabled do
                time += 0.01 * orbitSettings.speed

                local pattern = ORBIT_PATTERNS[orbitSettings.pattern]
                if pattern then
                    local x, y, z = pattern.calculate(i, #partList, time, orbitSettings)
                    if humanoidRootPart and humanoidRootPart.Parent then
                        part.Position = humanoidRootPart.Position + Vector3.new(x, y, z)
                        part.Orientation += Vector3.new(5, 10, 5)
                    end
                end
                task.wait()
            end
        end)
    end
end

local function stopOrbit(className)
    activeOrbits[className] = false
end

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PartsOrbitMenuUltimate"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.42
background.BorderSizePixel = 0
background.ZIndex = 1
background.Visible = false
background.Parent = screenGui

local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.fromScale(0.78, 0.78)
mainContainer.Position = UDim2.fromScale(0.5, 0.5)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundColor3 = Color3.fromRGB(18, 19, 25)
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 2
mainContainer.Visible = false
mainContainer.Parent = screenGui

local mainConstraint = Instance.new("UISizeConstraint")
mainConstraint.MinSize = Vector2.new(700, 520)
mainConstraint.MaxSize = Vector2.new(1050, 760)
mainConstraint.Parent = mainContainer

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainContainer

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(55, 60, 75)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainContainer

-- ===== HEADER =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = Color3.fromRGB(27, 29, 39)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = mainContainer

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 18)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -170, 1, 0)
title.Position = UDim2.new(0, 24, 0, 0)
title.BackgroundTransparency = 1
title.Text = "✨  ULTIMATE ORBIT MENU"
title.TextColor3 = Color3.fromRGB(115, 205, 255)
title.TextSize = 21
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

local closeHint = Instance.new("TextLabel")
closeHint.Size = UDim2.new(0, 130, 1, 0)
closeHint.Position = UDim2.new(1, -150, 0, 0)
closeHint.BackgroundTransparency = 1
closeHint.Text = "M  •  FECHAR"
closeHint.TextColor3 = Color3.fromRGB(145, 150, 165)
closeHint.TextSize = 12
closeHint.Font = Enum.Font.GothamMedium
closeHint.TextXAlignment = Enum.TextXAlignment.Right
closeHint.ZIndex = 4
closeHint.Parent = header

-- ===== CONTEÚDO =====
local scrollContainer = Instance.new("ScrollingFrame")
scrollContainer.Name = "ScrollContainer"
scrollContainer.Size = UDim2.new(1, -28, 1, -145)
scrollContainer.Position = UDim2.new(0, 14, 0, 76)
scrollContainer.BackgroundTransparency = 1
scrollContainer.BorderSizePixel = 0
scrollContainer.ScrollBarThickness = 5
scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 100, 125)
scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollContainer.ZIndex = 3
scrollContainer.Parent = mainContainer

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 4)
scrollPadding.PaddingRight = UDim.new(0, 8)
scrollPadding.PaddingBottom = UDim.new(0, 12)
scrollPadding.Parent = scrollContainer

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 16)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scrollContainer

local function makeSection(parent, height, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, height)
    section.BackgroundColor3 = Color3.fromRGB(23, 24, 32)
    section.BorderSizePixel = 0
    section.LayoutOrder = order
    section.ZIndex = 3
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = section

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(43, 46, 58)
    stroke.Thickness = 1
    stroke.Parent = section

    return section
end

local function makeSectionTitle(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -28, 0, 28)
    label.Position = UDim2.new(0, 14, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(150, 175, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = parent
    return label
end

-- ===== PADRÕES =====
local patternsSection = makeSection(scrollContainer, 208, 1)
makeSectionTitle(patternsSection, "🎨  TIPO DE ÓRBITA")

local patternsGrid = Instance.new("Frame")
patternsGrid.Size = UDim2.new(1, -28, 0, 154)
patternsGrid.Position = UDim2.new(0, 14, 0, 44)
patternsGrid.BackgroundTransparency = 1
patternsGrid.ZIndex = 4
patternsGrid.Parent = patternsSection

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.CellSize = UDim2.new(0.32, 0, 0, 69)
gridLayout.FillDirectionMaxCells = 3
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = patternsGrid

local selectedPatternButton

local function createPatternButton(key, patternData)
    local btn = Instance.new("TextButton")
    btn.Name = key
    btn.Text = ""
    btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    btn.Parent = patternsGrid

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(55, 58, 72)
    stroke.Thickness = 1
    stroke.Parent = btn

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -12, 1, -8)
    content.Position = UDim2.new(0, 6, 0, 4)
    content.BackgroundTransparency = 1
    content.TextColor3 = Color3.fromRGB(205, 208, 220)
    content.TextSize = 12
    content.Font = Enum.Font.GothamMedium
    content.TextWrapped = true
    content.Text = patternData.name .. "\n" .. patternData.description
    content.ZIndex = 6
    content.Parent = btn

    btn.MouseButton1Click:Connect(function()
        orbitSettings.pattern = key
        if selectedPatternButton then
            selectedPatternButton.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
            selectedPatternButton.UIStroke.Color = Color3.fromRGB(55, 58, 72)
        end
        selectedPatternButton = btn
        btn.BackgroundColor3 = Color3.fromRGB(55, 78, 112)
        stroke.Color = Color3.fromRGB(105, 180, 255)
    end)

    btn.MouseEnter:Connect(function()
        if selectedPatternButton ~= btn then
            btn.BackgroundColor3 = Color3.fromRGB(42, 45, 58)
        end
    end)

    btn.MouseLeave:Connect(function()
        if selectedPatternButton ~= btn then
            btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
        end
    end)

    if key == orbitSettings.pattern then
        selectedPatternButton = btn
        btn.BackgroundColor3 = Color3.fromRGB(55, 78, 112)
        stroke.Color = Color3.fromRGB(105, 180, 255)
    end
end

local patternOrder = {"circle", "tornado", "wings", "wave", "helix", "figure8", "ball"}
for _, key in ipairs(patternOrder) do
    createPatternButton(key, ORBIT_PATTERNS[key])
end

-- ===== PROPRIEDADES =====
local propertiesSection = makeSection(scrollContainer, 310, 2)
makeSectionTitle(propertiesSection, "⚙️  PROPRIEDADES")

local propertiesContainer = Instance.new("Frame")
propertiesContainer.Size = UDim2.new(1, -28, 0, 252)
propertiesContainer.Position = UDim2.new(0, 14, 0, 45)
propertiesContainer.BackgroundTransparency = 1
propertiesContainer.ZIndex = 4
propertiesContainer.Parent = propertiesSection

local propsLayout = Instance.new("UIListLayout")
propsLayout.Padding = UDim.new(0, 8)
propsLayout.Parent = propertiesContainer

local function createSlider(parent, label, minVal, maxVal, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 54)
    container.BackgroundTransparency = 1
    container.ZIndex = 4
    container.Parent = parent

    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -80, 0, 22)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = Color3.fromRGB(205, 208, 220)
    labelText.TextSize = 13
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Text = label .. ": " .. string.format("%.1f", defaultVal)
    labelText.ZIndex = 5
    labelText.Parent = container

    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0, 70, 0, 22)
    valueText.Position = UDim2.new(1, -70, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.TextColor3 = Color3.fromRGB(115, 205, 255)
    valueText.TextSize = 13
    valueText.Font = Enum.Font.GothamBold
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Text = string.format("%.1f", defaultVal)
    valueText.ZIndex = 5
    valueText.Parent = container

    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0, 31)
    sliderBg.Text = ""
    sliderBg.AutoButtonColor = false
    sliderBg.BackgroundColor3 = Color3.fromRGB(48, 50, 62)
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 5
    sliderBg.Parent = container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(95, 175, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 6
    sliderFill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill

    local function setFromX(x)
        local percent = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * percent
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        valueText.Text = string.format("%.1f", value)
        labelText.Text = label .. ": " .. string.format("%.1f", value)
        callback(value)
    end

    sliderBg.MouseButton1Down:Connect(function(x)
        setFromX(x)
        local moveConnection
        local releaseConnection
        moveConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                setFromX(input.Position.X)
            end
        end)
        releaseConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConnection:Disconnect()
                releaseConnection:Disconnect()
            end
        end)
    end)
end

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

-- ===== PARTS =====
local partsSection = makeSection(scrollContainer, 390, 3)
makeSectionTitle(partsSection, "📦  TIPOS DE PARTES")

local partsScroll = Instance.new("ScrollingFrame")
partsScroll.Size = UDim2.new(1, -28, 1, -58)
partsScroll.Position = UDim2.new(0, 14, 0, 48)
partsScroll.BackgroundTransparency = 1
partsScroll.BorderSizePixel = 0
partsScroll.ScrollBarThickness = 5
partsScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 100, 125)
partsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
partsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
partsScroll.ZIndex = 4
partsScroll.Parent = partsSection

local partsPadding = Instance.new("UIPadding")
partsPadding.PaddingRight = UDim.new(0, 6)
partsPadding.PaddingBottom = UDim.new(0, 8)
partsPadding.Parent = partsScroll

local partsListLayout = Instance.new("UIListLayout")
partsListLayout.Padding = UDim.new(0, 7)
partsListLayout.Parent = partsScroll

local function createPartButton(className, count)
    local btn = Instance.new("TextButton")
    btn.Name = className
    btn.Text = ""
    btn.Size = UDim2.new(1, 0, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    btn.Parent = partsScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(55, 58, 72)
    stroke.Thickness = 1
    stroke.Parent = btn

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 44, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "📦"
    icon.TextSize = 21
    icon.ZIndex = 6
    icon.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 55, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = className .. "  •  " .. count .. " partes"
    label.TextColor3 = Color3.fromRGB(205, 208, 220)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = btn

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 11, 0, 11)
    statusDot.Position = UDim2.new(1, -27, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 6
    statusDot.Parent = btn

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    local isActive = false
    btn.MouseButton1Click:Connect(function()
        isActive = not isActive
        selectedParts[className] = isActive
        if isActive then
            statusDot.BackgroundColor3 = Color3.fromRGB(100, 220, 135)
            btn.BackgroundColor3 = Color3.fromRGB(45, 66, 58)
            stroke.Color = Color3.fromRGB(100, 220, 135)
            startOrbit(getPartsByClassName(className), className)
        else
            statusDot.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
            btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
            stroke.Color = Color3.fromRGB(55, 58, 72)
            stopOrbit(className)
        end
    end)

    btn.MouseEnter:Connect(function()
        if not isActive then btn.BackgroundColor3 = Color3.fromRGB(42, 45, 58) end
    end)
    btn.MouseLeave:Connect(function()
        if not isActive then btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44) end
    end)
end

-- ===== FOOTER =====
local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 58)
footer.Position = UDim2.new(0, 0, 1, -58)
footer.BackgroundColor3 = Color3.fromRGB(27, 29, 39)
footer.BorderSizePixel = 0
footer.ZIndex = 4
footer.Parent = mainContainer

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 18)
footerCorner.Parent = footer

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Text = "🟢  ÓRBITA ON"
toggleBtn.Size = UDim2.new(0, 155, 0, 40)
toggleBtn.Position = UDim2.new(0, 14, 0.5, -20)
toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 180, 105)
toggleBtn.TextColor3 = Color3.fromRGB(8, 12, 10)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 5
toggleBtn.Parent = footer

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 9)
toggleCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    orbitSettings.enabled = not orbitSettings.enabled
    if orbitSettings.enabled then
        toggleBtn.Text = "🟢  ÓRBITA ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 180, 105)
    else
        toggleBtn.Text = "🔴  ÓRBITA OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(190, 85, 85)
    end
end)

local keybindContainer = Instance.new("Frame")
keybindContainer.Size = UDim2.new(0, 210, 0, 40)
keybindContainer.Position = UDim2.new(0, 180, 0.5, -20)
keybindContainer.BackgroundColor3 = Color3.fromRGB(42, 44, 56)
keybindContainer.BorderSizePixel = 0
keybindContainer.ZIndex = 5
keybindContainer.Parent = footer

local keybindCorner = Instance.new("UICorner")
keybindCorner.CornerRadius = UDim.new(0, 9)
keybindCorner.Parent = keybindContainer

local keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(1, -72, 1, 0)
keybindLabel.Position = UDim2.new(0, 12, 0, 0)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Text = "🎮 Bind: Z"
keybindLabel.TextColor3 = Color3.fromRGB(205, 208, 220)
keybindLabel.TextSize = 12
keybindLabel.Font = Enum.Font.GothamBold
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.ZIndex = 6
keybindLabel.Parent = keybindContainer

local keybindBtn = Instance.new("TextButton")
keybindBtn.Text = "Mudar"
keybindBtn.Size = UDim2.new(0, 64, 1, 0)
keybindBtn.Position = UDim2.new(1, -64, 0, 0)
keybindBtn.BackgroundColor3 = Color3.fromRGB(85, 145, 220)
keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindBtn.TextSize = 11
keybindBtn.Font = Enum.Font.GothamBold
keybindBtn.BorderSizePixel = 0
keybindBtn.ZIndex = 6
keybindBtn.Parent = keybindContainer

local keybindCorner2 = Instance.new("UICorner")
keybindCorner2.CornerRadius = UDim.new(0, 8)
keybindCorner2.Parent = keybindBtn

local waitingForBind = false
keybindBtn.MouseButton1Click:Connect(function()
    if waitingForBind then return end
    waitingForBind = true
    keybindBtn.Text = "Pressione..."
    keybindBtn.BackgroundColor3 = Color3.fromRGB(190, 145, 75)

    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode == Enum.KeyCode.Unknown or input.KeyCode == Enum.KeyCode.M then return end
        orbitSettings.keybind = input.KeyCode
        keybindLabel.Text = "🎮 Bind: " .. input.KeyCode.Name
        keybindBtn.Text = "Mudar"
        keybindBtn.BackgroundColor3 = Color3.fromRGB(85, 145, 220)
        waitingForBind = false
        connection:Disconnect()
    end)
end)

local stopAllBtn = Instance.new("TextButton")
stopAllBtn.Name = "StopAll"
stopAllBtn.Text = "⏹  PARAR TUDO"
stopAllBtn.Size = UDim2.new(0, 150, 0, 40)
stopAllBtn.Position = UDim2.new(1, -164, 0.5, -20)
stopAllBtn.BackgroundColor3 = Color3.fromRGB(185, 75, 80)
stopAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopAllBtn.TextSize = 12
stopAllBtn.Font = Enum.Font.GothamBold
stopAllBtn.BorderSizePixel = 0
stopAllBtn.ZIndex = 5
stopAllBtn.Parent = footer

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 9)
stopCorner.Parent = stopAllBtn

stopAllBtn.MouseButton1Click:Connect(function()
    for className in pairs(selectedParts) do
        stopOrbit(className)
        selectedParts[className] = false
    end
    for _, btn in pairs(partsScroll:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
            btn:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(90, 95, 110)
            btn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(55, 58, 72)
        end
    end
end)

-- ===== ABINHA FECHADA =====
local openTab = Instance.new("TextButton")
openTab.Name = "OpenTab"
openTab.Size = UDim2.new(0, 58, 0, 116)
openTab.Position = UDim2.new(1, -8, 0.5, -58)
openTab.AnchorPoint = Vector2.new(1, 0)
openTab.BackgroundColor3 = Color3.fromRGB(27, 29, 39)
openTab.BorderSizePixel = 0
openTab.Text = "M\n☰"
openTab.TextColor3 = Color3.fromRGB(115, 205, 255)
openTab.TextSize = 17
openTab.Font = Enum.Font.GothamBold
openTab.AutoButtonColor = false
openTab.ZIndex = 10
openTab.Parent = screenGui

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 12)
tabCorner.Parent = openTab

local tabStroke = Instance.new("UIStroke")
tabStroke.Color = Color3.fromRGB(65, 75, 95)
tabStroke.Thickness = 1
 tabStroke.Parent = openTab

openTab.MouseEnter:Connect(function()
    openTab.BackgroundColor3 = Color3.fromRGB(40, 44, 58)
end)
openTab.MouseLeave:Connect(function()
    openTab.BackgroundColor3 = Color3.fromRGB(27, 29, 39)
end)

-- ===== ABRIR / FECHAR COM M =====
local menuOpen = false
local mouseLockedBeforeMenu = true

local function setMenuOpen(state)
    menuOpen = state
    mainContainer.Visible = state
    background.Visible = state
    openTab.Visible = not state

    if state then
        mouseLockedBeforeMenu = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        if mouseLockedBeforeMenu then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = false
        end
    end
end

openTab.MouseButton1Click:Connect(function()
    setMenuOpen(true)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M then
        setMenuOpen(not menuOpen)
        return
    end

    if gameProcessed or menuOpen then return end

    if input.KeyCode == orbitSettings.keybind then
        orbitSettings.enabled = not orbitSettings.enabled
        if orbitSettings.enabled then
            toggleBtn.Text = "🟢  ÓRBITA ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 180, 105)
        else
            toggleBtn.Text = "🔴  ÓRBITA OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(190, 85, 85)
        end
    end
end)

-- ===== INICIALIZAR =====
local partTypes = getAllPartTypes()
for _, className in ipairs(partTypes) do
    createPartButton(className, #getPartsByClassName(className))
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Começa fechado e mantém o mouse travado para o jogo em primeira pessoa.
setMenuOpen(false)

print("=" .. string.rep("=", 60))
print("✨ ULTIMATE ORBIT MENU CARREGADO!")
print("Menu: M | Keybind da órbita: " .. orbitSettings.keybind.Name)
print("=" .. string.rep("=", 60))
