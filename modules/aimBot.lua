-- ============================================================================
-- MÓDULO: AIMBOT / AIM ASSIST COM PREVISÃO BALÍSTICA
-- Arquivo: modules/aimBot.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- CONFIGURAÇÕES DO AIMBOT
--------------------------------------------------------------------------------
local Cfg = {
    MaxDistance = 400,
    FovRadius = 100,
    -- Perfis de Física de Projétil (Velocidade v0, Gravidade g, Latência)
    PROF = {
        v0 = 150,
        g = 96.05,
        windup = 0.10,
        latency = 0.04,
        maxlead = 35,
        scale = 1.05
    }
}

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.aimBot = _G.FeatureState.aimBot or false

local State = { target = nil, lookVector = nil }
local velHistory = {}

--------------------------------------------------------------------------------
-- LÓGICA MATEMÁTICA E BALÍSTICA
--------------------------------------------------------------------------------
local function isSurvivor(player)
    if not player or player == LocalPlayer then return false end
    if not player.Team then return false end
    local t = player.Team.Name:lower()
    if t:find("spectator") or t:find("lobby") or t:find("killer") then return false end
    return t:find("survivor") ~= nil
end

local function solvePitch(p, d, dy)
    d = math.max(d, 0.1)
    local s2 = p.v0 * p.v0
    local root = s2 * s2 - p.g * (p.g * d * d + 2 * dy * s2)
    local outOfRange = false
    if root < 0 then
        root = 0
        outOfRange = true
    end
    local tanTheta = (s2 - math.sqrt(root)) / (p.g * d)
    local theta = math.atan(tanTheta)
    local t = d / (p.v0 * math.cos(theta))
    return theta, outOfRange, t
end

local function getCharacterVelocity(char)
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
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

--------------------------------------------------------------------------------
-- LOOP DE SELEÇÃO E CÁLCULO DE MIRA (RENDERSTEPPED)
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not _G.FeatureState.aimBot then
        State.target = nil
        State.lookVector = nil
        return
    end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local nearest = nil
    local bestDist = math.huge

    -- Busca o alvo mais próximo dentro do FOV na tela
    for _, p in ipairs(Players:GetPlayers()) do
        if isSurvivor(p) and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and targetHRP then
                local sp, onScreen = Camera:WorldToScreenPoint(targetHRP.Position)
                if onScreen then
                    local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if screenDist <= Cfg.FovRadius and screenDist < bestDist then
                        bestDist = screenDist
                        nearest = p
                    end
                end
            end
        end
    end

    -- Calcula a trajetória preditiva para acertar o alvo
    if nearest and nearest.Character then
        local targetHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            local origin = hrp.Position
            local tp = targetHRP.Position
            local dir = tp - origin
            local dist = dir.Magnitude

            if dist > 0.1 and dist <= Cfg.MaxDistance then
                local prof = Cfg.PROF
                local h0 = Vector3.new(dir.X, 0, dir.Z)
                local _, _, tFlight = solvePitch(prof, h0.Magnitude, dir.Y)

                local aimPoint = tp
                local vel = getCharacterVelocity(nearest.Character)

                if vel.Magnitude > 0.5 then
                    local delay = tFlight + prof.windup + prof.latency
                    for i = 1, 2 do
                        local lead = vel * delay * prof.scale
                        local maxLead = math.clamp(dist * 0.6, 3, prof.maxlead)
                        if lead.Magnitude > maxLead then lead = lead.Unit * maxLead end
                        aimPoint = tp + lead
                        local ad = aimPoint - origin
                        local ah = Vector3.new(ad.X, 0, ad.Z)
                        local _, _, t2 = solvePitch(prof, math.max(ah.Magnitude, 0.1), ad.Y)
                        delay = t2 + prof.windup + prof.latency
                    end
                end

                -- Suaviza e ajusta a câmera para a direção prevista
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPoint)
                State.target = nearest
            end
        end
    end
end)

print("🎯 Módulo AimBot inicializado com sucesso!")
