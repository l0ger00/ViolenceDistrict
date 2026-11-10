-- ============================================================================
-- MÓDULO: INTERFACE GRÁFICA (GUI) E INPUTS
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
}

-- Configuração de Teclas Globais
_G.Keybinds = _G.Keybinds or {
    AimAssist = Enum.KeyCode.E -- Tecla padrão para ligar/desligar o Aim Assist rapidamente
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
panel.Size = UDim2.new(0, 190, 0, 210) -- Altura ajustada para caber os botões
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
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "  VD · MENU CENTRAL [M]"
title.TextColor3 = Color3.fromRGB(230, 230, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left

-- Helper global para criar botões na UI
_G.CreateGUIToggle = function(name, posY, stateKey, callback)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1, -16, 0, 26)
    btn.Position = UDim2.new(0, 8, 0, posY)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Modal = true 

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

    btn.MouseButton1Click:Connect(function()
        _G.FeatureState[stateKey] = not _G.FeatureState[stateKey]
        updateVisual(_G.FeatureState[stateKey])
        if callback then callback(_G.FeatureState[stateKey]) end
    end)
end

-- Botões Padrão
_G.CreateGUIToggle("ESP Player", 32, "espPlayer")
_G.CreateGUIToggle("ESP Generator", 64, "espGenerator")
_G.CreateGUIToggle("Progresso Gen (%)", 96, "generatorProgress")
_G.CreateGUIToggle("Aim Assist", 128, "aimBot")
_G.CreateGUIToggle("FPS Boost", 160, "fpsBoost")
_G.CreateGUIToggle("Veil Mode", 192, "veilMode") -- <-- Novo botão Veil Mode

-- Botão especial para mostrar a Keybind do Aim Assist
local bindBtn = Instance.new("TextButton", panel)
bindBtn.Size = UDim2.new(1, -16, 0, 20)
bindBtn.Position = UDim2.new(0, 8, 0, 188)
bindBtn.Font = Enum.Font.Gotham
bindBtn.TextSize = 9
bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
bindBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
bindBtn.Text = "Aim Assist Key: [ " .. _G.Keybinds.AimAssist.Name .. " ]"
bindBtn.AutoButtonColor = false
bindBtn.Modal = true
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

-- Sistema simples para remapear a tecla clicando no botão (pressionando a próxima tecla)
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

print("🖥️ Módulo GUI com Keybind customizável inicializado!")
