-- ============================================================================
-- MÓDULO: GET ROLE (IDENTIFICADOR DE PAPEL/EQUIPE)
-- Arquivo: modules/getRole.lua
-- ============================================================================

if _G.RoleData then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Tabela global de dados de Role que outros scripts vão consultar
_G.RoleData = {
    TeamName = "",
    IsLobby = false
}

-- Evento Bindable para avisar os outros módulos quando o role mudar
local UpdateEvent = Instance.new("BindableEvent")
_G.RoleUpdate = UpdateEvent.Event

local function getTeamName(plr)
    if plr.Team then
        return plr.Team.Name:lower()
    end
    return ""
end

local lastStatus = nil
local lastTeam = nil
local lastUpdateTime = 0
local UPDATE_DEBOUNCE = 0.1  -- Limite máximo de 10x por segundo para evitar spam

RunService.Heartbeat:Connect(function()
    local now = tick()
    local team = getTeamName(LocalPlayer)
    local lobby = (team == "spectator" or team == "")

    _G.RoleData.TeamName = team
    _G.RoleData.IsLobby = lobby

    -- Só dispara o evento se o time/papel realmente mudou (com debounce)
    if now - lastUpdateTime > UPDATE_DEBOUNCE and (lastStatus ~= lobby or lastTeam ~= team) then
        lastStatus = lobby
        lastTeam = team
        lastUpdateTime = now
        UpdateEvent:Fire()
    end
end)

print("👥 Módulo GetRole inicializado!")
