-- ============================================================================
-- MÓDULO: VEIL MODE (MAGIC SPEAR AIM ASSIST) - CORRIGIDO E LIMPO
-- Arquivo: modules/veilMode.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

_G.FeatureState = _G.FeatureState or {}
_G.FeatureState.veilMode = _G.FeatureState.veilMode or false

_G.Keybinds = _G.Keybinds or {
    VeilModeKey = Enum.KeyCode.V
}

local Cfg = {
    MaxDistance = 500,
    FovRadius = 90,
    PROF = {
        aura = {
            v0 = 165, g = 96.5,
            windup = 0.10, latency = 0.04,
            maxlead = 25, scale = 1.00,
        },
        normal = {
            v0 = 143, g = 96.05,
            windup = 0.10, latency = 0.04,
            maxlead = 45, scale = 1.10,
        },
    },
}

local State = { target = nil, lookVector = nil }
local velHistory = {}

-- Busca segura do RemoteEvent do Veil Spearthrow com feedback no console
local Veil_Spearthrow = nil
local successRemote, errRemote = pcall(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    local killers = remotes and remotes:WaitForChild("Killers", 5)
    local veil = killers and killers:WaitForChild("Veil", 5)
    Veil_Spearthrow = veil and veil:WaitForChild("Spearthrow", 5)
end)

if not Veil_Spearthrow then
    warn("⚠️ [Veil Mode] Remote 'Spearthrow' não encontrado automaticamente. Verifique se o caminho no jogo mudou.")
else
    print("🎯 [Veil Mode] Remote 'Spearthrow' mapeado com sucesso!")
end

-- Cache de Ping
local cachedPing = 0.08
task.spawn(function()
    while true do
        pcall(function()
            local p = LP and LP:GetNetworkPing()
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
-- FUNÇÕES AUXILIARES
--------------------------------------------------------------------------------
local function isSurvivor(player)
    if not player or player == LP then return false end
    if not player.Team then return false end
    local success, t = pcall(function() return player.Team.Name:lower() end)
    if not success or not t then return false end
    if t:find("spectator") or t:find("lobby") or t:find("killer") then return false end
    return t:find("survivor") ~= nil
end

local function isKnockedOrHooked(c)
    if not c then return false end
    return c:GetAttribute("Knocked") == true or c:GetAttribute("HookProgressDepleting") == true
end

local function getTargetPosition(character)
    if not character then return nil end
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if torso and torso:IsA("BasePart") then return torso.Position end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head.Position end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp.Position end
    return nil
end

local function worldToScreen(pos)
    if typeof(pos) ~= "Vector3" then return Vector2.zero, false end
    local cam = workspace.CurrentCamera
    if not cam then return Vector2.zero, false end
    local sp, on = cam:WorldToScreenPoint(pos)
    if sp.Z <= 0 then return Vector2.new(sp.X, sp.Y), false end
    return Vector2.new(sp.X, sp.Y), on
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
    if not char then return Vector3.zero end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root or not root:IsA("BasePart") then return Vector3.zero end
    local now = os.clock()
    local last = velHistory[char]
    local measured = Vector3.zero
    if last and now - last.t > 0.02 then
        measured = (root.Position - last.pos) / (now - last.t)
        if measured.Magnitude > 150 then
            measured = last.smooth or Vector3.zero
        end
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
-- LOOP PRINCIPAL DE CÁLCULO
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not (_G.FeatureState and _G.FeatureState.veilMode) then
        State.target = nil
        State.lookVector = nil
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end
    local char = LP and LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local nearest = nil
    local bestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if isSurvivor(p) then
            local pc = p.Character
            if pc and pc:IsDescendantOf(workspace) and not isKnockedOrHooked(pc) then
                local hum = pc:FindFirstChildOfClass("Humanoid")
                local pos = getTargetPosition(pc)
                if hum and hum.Health > 0 and typeof(pos) == "Vector3" then
                    local sp, on = worldToScreen(pos)
                    if on then
                        local sd = (sp - center).Magnitude
                        if sd <= Cfg.FovRadius and sd < bestDist then
                            bestDist = sd
                            nearest = p
                        end
                    end
                end
            end
        end
    end

    if nearest and nearest.Character then
        local tp = getTargetPosition(nearest.Character)
        if typeof(tp) == "Vector3" then
            local hand = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
            local origin = (hand and hand:IsA("BasePart")) and hand.Position or hrp.Position
            local dir = tp - origin
            local dist = dir.Magnitude

            if dist > 0.1 and dist <= Cfg.MaxDistance then
                local auraActive = char:GetAttribute("special") == true
                local prof = auraActive and Cfg.PROF.aura or Cfg.PROF.normal

                local h0 = Vector3.new(dir.X, 0, dir.Z)
                local _, _, tFlight = solvePitch(prof, h0.Magnitude, dir.Y)

                local aimPoint = tp
                local vel = getCharacterVelocity(nearest.Character)
                if vel.Magnitude > 0.5 then
                    local delay = tFlight + prof.windup + cachedPing + prof.latency
                    for i = 1, 2 do
                        local lead = vel * delay * prof.scale
                        local maxLead = math.clamp(dist * 0.6, 3, prof.maxlead)
                        if lead.Magnitude > maxLead then
                            lead = lead.Unit * maxLead
                        end
                        aimPoint = tp + lead
                        local ad = aimPoint - origin
                        local ah = Vector3.new(ad.X, 0, ad.Z)
                        local _, _, t2 = solvePitch(prof, math.max(ah.Magnitude, 0.1), ad.Y)
                        delay = t2 + prof.windup + cachedPing + prof.latency
                    end
                end

                local adir = aimPoint - origin
                local ah = Vector3.new(adir.X, 0, adir.Z)
                local ahDist = ah.Magnitude
                local pitch = solvePitch(prof, ahDist, adir.Y)
                if ahDist > 0.001 then
                    State.lookVector = ah.Unit * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
                else
                    State.lookVector = adir.Unit
                end
                State.target = nearest
            end
        end
    else
        State.target = nil
        State.lookVector = nil
    end
end)

--------------------------------------------------------------------------------
-- NAMECALL HOOK SEGURO
--------------------------------------------------------------------------------
if Veil_Spearthrow and hookmetamethod and getnamecallmethod then
    pcall(function()
        local originalNamecall
        originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer"
                and rawequal(self, Veil_Spearthrow)
                and (_G.FeatureState and _G.FeatureState.veilMode)
                and typeof(State.lookVector) == "Vector3"
            then
                local args = table.pack(...)
                if args.n >= 1 and typeof(args[1]) == "Vector3" then
                    args[1] = State.lookVector
                end
                return originalNamecall(self, table.unpack(args, 1, args.n))
            end
            return originalNamecall(self, ...)
        end)
        print("🪄 [Veil Mode] Hook de Namecall instalado com segurança máxima!")
    end)
end

print("🔮 Módulo Veil Mode carregado com sucesso!")
