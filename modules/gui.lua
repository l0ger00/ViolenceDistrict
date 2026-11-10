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
panel.Size = UDim2.new(0, 190, 0, 170)
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
    
    -- Propriedade Modal ajuda a focar o input na UI
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
_G.CreateGUIToggle("FPS Boost", 160, "fpsBoost") -- <-- Novo botão (lembre de aumentar a altura do 'panel' de 170 para 200 se precisar de espaço)

-- Função para alternar o estado do painel e gerenciar o comportamento do mouse limpidamente
local function toggleMenu()
    panel.Visible = not panel.Visible
    
    if panel.Visible then
        -- Quando abre: Libera o mouse e mostra o cursor
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        -- Quando fecha: Devolve o controle total para o jogo (restaura comportamento padrão)
        UserInputService.MouseIconEnabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

-- Atalho de Tecla (M)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.MenuKey then
        toggleMenu()
    end
end)

-- Garante o travamento/comportamento correto do mouse a cada frame SE o menu estiver aberto
RunService.RenderStepped:Connect(function()
    if panel.Visible then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

print("🖥️ Módulo GUI atualizado com controle inteligente de cursor!")
