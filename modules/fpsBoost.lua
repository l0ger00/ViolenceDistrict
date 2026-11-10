-- ============================================================================
-- MÓDULO OTIMIZADO: FPS BOOST + FULL BRIGHT + NO FOG
-- Arquivo: modules/fpsBoost.lua
-- ============================================================================

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.fpsBoost = _G.FeatureState.fpsBoost or false

local wasEnabled = false

-- Salva o estado original da Lighting para restaurar caso desative o boost
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd
}

-- Função para aplicar o Boost, Full Bright e No Fog
local function applyBoost()
    print("⚡ [FPS Boost] Aplicando otimizações, Full Bright e No Fog...")

    -- 1. Full Bright & No Fog (Iluminação máxima e remoção de neblina)
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14 -- Trava o sol ao meio-dia para luz constante
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.FogEnd = 100000 -- Joga a neblina para infinitamente longe

        -- Desativa efeitos pesados de pós-processamento, atmosfera e skybox escura
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
                child.Enabled = false
            end
        end
    end)

    -- 2. Otimizar Texturas, Materiais e Partículas no Workspace
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end
    end)
end

-- Função para restaurar o estado padrão da iluminação caso desative
local function removeBoost()
    print("⚡ [FPS Boost] Desativando otimizações (restaurando padrões)...")
    pcall(function()
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.FogEnd = originalLighting.FogEnd

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

print("🚀 Módulo FPS Boost (com Full Bright & No Fog) carregado!")
