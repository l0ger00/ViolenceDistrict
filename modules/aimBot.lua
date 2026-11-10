-- ============================================================================
-- MÓDULO: AIMBOT / AIM ASSIST (VERSÃO SIMPLIFICADA)
-- Arquivo: modules/aimBot.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- CONFIGURAÇÕES DO AIMBOT
--------------------------------------------------------------------------------
local Cfg = {
    MaxDistance = 500,
    FovRadius = 250,
}

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.aimBot = _G.FeatureState.aimBot or false

_G.Keybinds = _G.Keybinds or {
    AimAssist = Enum.KeyCode.E
}

--------------------------------------------------------------------------------
-- LISTENER DE TECLA DE ATALHO (KEYBIND)
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == _G.Keybinds.AimAssist then
        _G.FeatureState.aimBot = not _G.FeatureState.aimBot
        
        if _G.SyncGUIToggle then
            _G.SyncGUIToggle("aimBot")
        end
        
        if _G.ShowNotify then
            local state = _G.FeatureState.aimBot
            _G.ShowNotify("Aim Assist: " .. (state and "ATIVADO 🟢" or "DESATIVADO 🔴"), state)
        end
        print("🎯 [AimBot] Estado alterado para:", _G.FeatureState.aimBot)
    end
end)

--------------------------------------------------------------------------------
-- LÓGICA DE DETECÇÃO DE ALVO
--------------------------------------------------------------------------------
local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character then return false end
    
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 or not hrp then return false end
    
    if player.Team then
        local t = player.Team.Name:lower()
        if t:find("spectator") or t:find("lobby") then 
            return false 
        end
    end
    
    return true
end

--------------------------------------------------------------------------------
-- LOOP DE MIRA DIRETA (RENDERSTEPPED)
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not _G.FeatureState.aimBot then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local nearestHRP = nil
    local bestDist = math.huge

    -- Busca o alvo mais próximo do centro da tela (dentro do FOV e alcance)
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local targetHRP = p.Character.HumanoidRootPart
            local distWorld = (targetHRP.Position - hrp.Position).Magnitude
            
            if distWorld <= Cfg.MaxDistance then
                local sp, onScreen = Camera:WorldToScreenPoint(targetHRP.Position)
                if onScreen then
                    local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if screenDist <= Cfg.FovRadius and screenDist < bestDist then
                        bestDist = screenDist
                        nearestHRP = targetHRP
                    end
                end
            end
        end
    end

    -- Aponta a câmera diretamente para o HumanoidRootPart do alvo
    if nearestHRP then
        Camera.CFrame = Cframe.new(Camera.CFrame.Position, nearestHRP.Position)
    end
end)

print("🎯 Módulo AimBot (Simplificado) carregado!")
