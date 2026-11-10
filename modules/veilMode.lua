-- ============================================================================
-- MÓDULO: VEIL MODE (AIM ASSIST COM BALÍSTICA AVANÇADA)
-- Arquivo: modules/veilMode.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.veilMode = _G.FeatureState.veilMode or false

_G.Keybinds = _G.Keybinds or {
    VeilModeKey = Enum.KeyCode.V -- Tecla dedicada para ativar/desativar o Veil Mode
}

local Cfg = {
    MaxDistance = 500,
    FovRadius = 120,
    PROF = {
        aura = { v0 = 165, g = 96.5, windup = 0.10, latency = 0.04, maxlead = 25, scale = 1.00 },
        normal = { v0 = 143, g = 96.05, windup = 0.10, latency = 0.04, maxlead = 45, scale = 1.10 },
    }
}

local velHistory = {}
local cachedPing = 0.08

-- Cache de Ping leve para precisão balística
task.spawn(function()
    while true do
        pcall(function()
            local p = LocalPlayer and LocalPlayer:GetNetworkPing()
            if typeof(p) == "number" then
                cachedPing = math.clamp(p, 0, 0.35)
            end
        end)
        task.wait(1.5)
    end
end)

--------------------------------------------------------------------------------
-- LISTENER DE TECLA DE ATALHO (KEYBIND)
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == _G.Keybinds.VeilModeKey then
        _G.FeatureState.veilMode = not _G.FeatureState.veilMode
        
        if _G.SyncGUIToggle then
            _G.SyncGUIToggle("veilMode")
        end
        
        if _G.ShowNotify then
            local state = _G.FeatureState.veilMode
            _G.ShowNotify("Veil Mode: " .. (state and "ATIVADO 🟢" or "DESATIVADO 🔴"), state)
        end
        print("🔮 [Veil Mode] Estado alterado para:", _G.FeatureState.veilMode)
    end
end)

--------------------------------------------------------------------------------
-- FUNÇÕES DE VALIDAÇÃO E BALÍSTICA
--------------------------------------------------------------------------------
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

local function solvePitch(p, d, dy)
    d = math.max(d, 0.1)
    local s2 = p.v0 * p.v0
    local root = s2 * s2 - p.g * (p.g * d * d + 2 * dy * s2)
    if root < 0 then root = 0 end
    local tanTheta = (s2 - math.sqrt(root)) / (p.g * d)
    local theta = math.atan(tanTheta)
    local t = d / (p.v0 * math.cos(theta))
    return theta, false, t
end

local function getCharacterVelocity(char)
    if not char then return Vector3.zero end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root or not root:IsA("BasePart") then return Vector3.zero end
    local now = os.clock()
    local last = velHistory[char]
    local measured = Vector3.zero

    if last and now - last.t > 0.02 then
        measured = (root.Position - last.pos) / (now - last.t)
        if measured.Magnitude > 150 then measured = last.smooth or Vector3.zero end
    end

    local smooth = last and last.smooth or measured
    smooth = smooth:Lerp(measured, 0.65)
    velHistory[char] = { pos = root.Position, t = now, smooth = smooth }

    if smooth.Magnitude < 1 then return Vector3.zero end
    return Vector3.new(smooth.X, 0, smooth.Z)
end

Players.PlayerRemoving:Connect(function(p)
    if p and p.Character then velHistory[p.Character] = nil end
end)

--------------------------------------------------------------------------------
-- LOOP DE MIRA COM BALÍSTICA E PREVISÃO (RENDERSTEPPED)
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not (_G.FeatureState and _G.FeatureState.veilMode) then return end

    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not Camera then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local nearestTargetHRP = nil
    local bestDist = math.huge

    -- 1. Encontra o sobrevivente mais próximo dentro do FOV
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
                            nearestTargetHRP = targetHRP
                        end
                    end
                end
            end
        end
    end

    -- 2. Aplica o cálculo balístico avançado de lançamento e move a câmera perfeitamente
    if nearestTargetHRP then
        pcall(function()
            local origin = hrp.Position
            local tp = nearestTargetHRP.Position
            local dir = tp - origin
            local dist = dir.Magnitude

            if dist > 0.1 and dist <= Cfg.MaxDistance then
                local auraActive = char:GetAttribute("special") == true
                local prof = auraActive and Cfg.PROF.aura or Cfg.PROF.normal

                local h0 = Vector3.new(dir.X, 0, dir.Z)
                local _, _, tFlight = solvePitch(prof, h0.Magnitude, dir.Y)

                local aimPoint = tp
                local targetChar = nearestTargetHRP.Parent
                local vel = getCharacterVelocity(targetChar)

                if vel.Magnitude > 0.5 then
                    local delay = tFlight + prof.windup + cachedPing + prof.latency
                    for i = 1, 2 do
                        local lead = vel * delay * prof.scale
                        local maxLead = math.clamp(dist * 0.6, 3, prof.maxlead)
                        if lead.Magnitude > maxLead then lead = lead.Unit * maxLead end
                        aimPoint = tp + lead
                        local ad = aimPoint - origin
                        local ah = Vector3.new(ad.X, 0, ad.Z)
                        local _, _, t2 = solvePitch(prof, math.max(ah.Magnitude, 0.1), ad.Y)
                        delay = t2 + prof.windup + cachedPing + prof.latency
                    end
                end

                -- Posiciona a mira da câmera diretamente no ponto balístico calculado
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPoint)
            end
        end)
    end
end)

print("🔮 Módulo Veil Mode (Balístico Direto) carregado com sucesso!")
