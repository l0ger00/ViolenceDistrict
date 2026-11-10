-- ============================================================================
-- MÓDULO OTIMIZADO: ESP PLAYER (ZERO MEMORY LEAKS)
-- Arquivo: modules/espPlayer.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local activeHighlights = {}

local function getPlayerRole(plr)
    if not plr or not plr.Team then return "" end
    return string.upper(plr.Team.Name or "")
end

local function removeESP(plr)
    if activeHighlights[plr] then
        pcall(function()
            activeHighlights[plr]:Destroy()
        end)
        activeHighlights[plr] = nil
    end
end

local function updatePlayersESP()
    local enabled = _G.FeatureState and _G.FeatureState.espPlayer

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if enabled and char and char:IsDescendantOf(workspace) then
                local h = activeHighlights[plr]
                if not h or not h.Parent then
                    h = Instance.new("Highlight")
                    h.Name = "VD_ESP_Player"
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = char
                    activeHighlights[plr] = h
                end

                local role = getPlayerRole(plr)
                local color = Color3.fromRGB(128, 128, 128)
                if role == "KILLER" then
                    color = Color3.fromRGB(255, 50, 50)
                elseif role == "SURVIVORS" then
                    color = Color3.fromRGB(50, 150, 255)
                elseif role == "SPECTATOR" then
                    color = Color3.fromRGB(255, 255, 255)
                end

                h.FillColor = color
                h.OutlineColor = color
            else
                removeESP(plr)
            end
        end
    end
end

-- Limpa referência quando o player sai do jogo
Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

-- Throttle inteligente via Heartbeat (roda a cada frame mas processa de forma leve)
RunService.Heartbeat:Connect(function()
    if _G.FeatureState and _G.FeatureState.espPlayer then
        updatePlayersESP()
    else
        for plr, _ in pairs(activeHighlights) do
            removeESP(plr)
        end
    end
end)

print("👁️ Módulo ESP Player otimizado carregado!")
