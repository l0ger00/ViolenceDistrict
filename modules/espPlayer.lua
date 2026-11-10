
-- ============================================================================
-- MÓDULO: ESP PLAYER
-- Arquivo: modules/espPlayer.lua
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getPlayerRole(plr)
    if not plr or not plr.Team then return "" end
    return string.upper(plr.Team.Name or "")
end

local function setupPlayerESP(char)
    if not char or char:FindFirstChild("ESP") then return end

    local h = Instance.new("Highlight")
    h.Name = "ESP"
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
end

local function clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local h = plr.Character:FindFirstChild("ESP")
            if h then h:Destroy() end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not (_G.FeatureState and _G.FeatureState.espPlayer) then
        clearESP()
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            setupPlayerESP(plr.Character)
            local h = plr.Character:FindFirstChild("ESP")
            if h then
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
            end
        end
    end
end)

print("👁️ Módulo ESP Player inicializado!")
