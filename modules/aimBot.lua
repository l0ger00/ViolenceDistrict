-- ============================================================================
-- MÓDULO OTIMIZADO: AIMBOT / AIM ASSIST (BLINDADO CONTRA NIL)
-- Arquivo: modules/aimBot.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Cfg = {
    MaxDistance = 500,
    FovRadius = 250,
}

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.aimBot = _G.FeatureState.aimBot or false

_G.Keybinds = _G.Keybinds or {
    AimAssist = Enum.KeyCode.E
}

-- Keybind Listener Seguro
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == _G.Keybinds.AimAssist then
        _G.FeatureState.aimBot = not _G.FeatureState.aimBot
        if _G.SyncGUIToggle then _G.SyncGUIToggle("aimBot") end
        if _G.ShowNotify then
            local state = _G.FeatureState.aimBot
            _G.ShowNotify("Aim Assist: " .. (state and "ATIVADO 🟢" or "DESATIVADO 🔴"), state)
        end
    end
end)

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not hrp then return false end
    
    if player.Team then
        local success, teamName = pcall(function() return player.Team.Name:lower() end)
        if success and teamName and (teamName:find("spectator") or teamName:find("lobby")) then 
            return false 
        end
    end
    
    return true
end

RunService.RenderStepped:Connect(function()
    if not _G.FeatureState.aimBot then return end

    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not Camera then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local nearestHRP = nil
    local bestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local targetChar = p.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            
            if targetHRP then
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
    end

    if nearestHRP and Camera then
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearestHRP.Position)
        end)
    end
end)

print("🎯 Módulo AimBot (Blindado) carregado com sucesso!")
