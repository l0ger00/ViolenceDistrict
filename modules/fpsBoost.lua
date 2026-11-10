-- ============================================================================
-- MÓDULO: FPS BOOST (OTIMIZAÇÃO E REMOÇÃO DE TEXTURAS)
-- Arquivo: modules/fpsBoost.lua
-- ============================================================================

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.fpsBoost = _G.FeatureState.fpsBoost or false

local wasEnabled = false

-- Função para aplicar as otimizações visuais e remoção de texturas
local function applyBoost()
    print("⚡ [FPS Boost] Aplicando otimizações visuais...")

    -- 1. Otimizar Iluminação (Remove efeitos pesados de pós-processamento)
    pcall(function()
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
                child.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        Lighting.Brightness = 2
    end)

    -- 2. Otimizar Texturas e Materiais no Workspace
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                -- Transforma materiais complexos em SmoothPlastic para poupar renderização
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                -- Desativa texturas coladas em paredes/objetos
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
                -- Desativa partículas pesadas
                obj.Enabled = false
            end
        end
    end)
end

-- Função para restaurar o estado padrão caso desative
local function removeBoost()
    print("⚡ [FPS Boost] Desativando otimizações (restaurando padrões)...")
    pcall(function()
        Lighting.GlobalShadows = true
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
                child.Enabled = true
            end
        end
    end)
end

-- Loop de verificação de estado conectado ao FeatureState da GUI
RunService.Heartbeat:Connect(function()
    local currentEnabled = _G.FeatureState.fpsBoost

    if currentEnabled and not wasEnabled then
        wasEnabled = true
        applyBoost()
    elseif not currentEnabled and wasEnabled then
        wasEnabled = false
        removeBoost()
    end
end)

print("🚀 Módulo FPS Boost inicializado!")
