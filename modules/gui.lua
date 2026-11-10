-- ============================================================================
-- MÓDULO: INTERFACE GRÁFICA (GUI) E INPUTS (ORGANIZADO AUTOMATICAMENTE)
-- Arquivo: modules/gui.lua
-- ============================================================================

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

_G.FeatureState = _G.FeatureState or {
    espPlayer = true,
    espGenerator = true,
    generatorProgress = true,
    aimBot = false,
    fpsBoost = false,
    veilMode = false,
}

-- Configuração de Teclas Globais
_G.Keybinds = _G.Keybinds or {
    AimAssist = Enum.KeyCode.E,
    VeilModeKey = Enum.KeyCode.V
}

local Config = {
    MenuKey = Enum.KeyCode.M
}

local guiParent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "ViolenceDistrict_GUI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 99999
sg.Parent = guiParent

local panel = Instance.new("Frame", sg)
panel.Name = "MainPanel"
-- Ajustamos a largura para 210 para dar mais conforto aos textos longos
panel.Size = UDim2.new(0, 210, 0, 315) 
panel.Position = UDim2.new(0.05, 0, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(80, 70, 140)
stroke.Thickness = 1.2

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "  VD · MENU CENTRAL [M]"
title.TextColor3 = Color3.fromRGB(230, 230, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left

-- Usamos UIListLayout para organizar os elementos internos em ordem perfeita sem sobreposição
local listLayout = Instance.new("UIListLayout", panel)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Padding interno para afastar das bordas do painel
local padding = Instance.new("UIPadding", panel)
padding.PaddingTop = UDim.new(0, 32) -- Deixa espaço limpo para o título fixo no topo
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)

-- Tabela para guardar atualizadores visuais de botões
local toggleUpdaters = {}

-- Helper global para criar botões na UI ordenados por LayoutOrder
_G.CreateGUIToggle = function(name, orderIndex, stateKey, callback)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Modal = true 
    btn.LayoutOrder = orderIndex

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local function updateVisual(state)
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(50, 160, 90)
            btn.Text = name .. ": LIGADO"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            btn.Text = name .. ": DESLIGADO"
            btn.TextColor3 = Color3.fromRGB(160, 160, 180)
        end
    end

    updateVisual(_G.FeatureState[stateKey] or false)
    toggleUpdaters[stateKey] = updateVisual

    btn.MouseButton1Click:Connect(function()
        _G.FeatureState[stateKey] = not _G.FeatureState[stateKey]
        updateVisual(_G.FeatureState[stateKey])
        if callback then callback(_G.FeatureState[stateKey]) end
    end)
end

-- Sincronizador visual externo
_G.SyncGUIToggle = function(stateKey)
    if toggleUpdaters[stateKey] then
        toggleUpdaters[stateKey](_G.FeatureState[stateKey])
    end
end

-- Criação dos botões ordenados com segurança (sem conflito de pixels)
_G.CreateGUIToggle("ESP Player", 1, "espPlayer")
_G.CreateGUIToggle("ESP Generator", 2, "espGenerator")
_G.CreateGUIToggle("Progresso Gen (%)", 3, "generatorProgress")
_G.CreateGUIToggle("Aim Assist", 4, "aimBot")
_G.CreateGUIToggle("FPS Boost", 5, "fpsBoost")
_G.CreateGUIToggle("Veil Mode", 6, "veilMode")

-- Botão especial para a Keybind do Aim Assist (organizado automaticamente no final)
local bindBtn = Instance.new("TextButton", panel)
bindBtn.Size = UDim2.new(1, 0, 0, 22)
bindBtn.Font = Enum.Font.Gotham
bindBtn.TextSize = 9
bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
bindBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
bindBtn.Text = "Aim Assist Key: [ " .. _G.Keybinds.AimAssist.Name .. " ]"
bindBtn.AutoButtonColor = false
bindBtn.Modal = true
bindBtn.LayoutOrder = 7
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

local waitingForKey = false
bindBtn.MouseButton1Click:Connect(function()
    if waitingForKey then return end
    waitingForKey = true
    bindBtn.Text = "Pressione qualquer tecla..."
    bindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            _G.Keybinds.AimAssist = input.KeyCode
            bindBtn.Text = "Aim Assist Key: [ " .. input.KeyCode.Name .. " ]"
            bindBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
            waitingForKey = false
            connection:Disconnect()
        end
    end)
end)

-- Notificação na Tela (Toast Notification)
local notifyLabel = Instance.new("TextLabel", sg)
notifyLabel.Size = UDim2.new(0, 220, 0, 25)
notifyLabel.Position = UDim2.new(0.5, -110, 0.08, 0)
notifyLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
notifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifyLabel.Font = Enum.Font.GothamBold
notifyLabel.TextSize = 11
notifyLabel.Visible = false
notifyLabel.BorderSizePixel = 0
Instance.new("UICorner", notifyLabel).CornerRadius = UDim.new(0, 6)

_G.ShowNotify = function(msg, isSuccess)
    notifyLabel.Text = msg
    notifyLabel.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    notifyLabel.Visible = true
    task.spawn(function()
        task.wait(1.5)
        notifyLabel.Visible = false
    end)
end

-- Toggle do Menu via Tecla M
local function toggleMenu()
    panel.Visible = not panel.Visible
    if panel.Visible then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        UserInputService.MouseIconEnabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.MenuKey then
        toggleMenu()
    end
end)

RunService.RenderStepped:Connect(function()
    if panel.Visible then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

print("🖥️ Módulo GUI redesenhado e organizado com sucesso!")
