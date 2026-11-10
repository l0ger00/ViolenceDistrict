-- ============================================================================
-- VIOLENCE DISTRICT - LOADER CENTRAL MODULAR (COM RETRY SEGURO)
-- Repositório: https://github.com/l0ger00/ViolenceDistrict
-- ============================================================================

if _G.__VD_LOADER_ACTIVE then
    print("⚠️ O Loader do Violence District já está rodando!")
    return
end
_G.__VD_LOADER_ACTIVE = true

local baseUrl = "https://raw.githubusercontent.com/l0ger00/ViolenceDistrict/main/"

local modulesToLoad = {
    "modules/getRole.lua",
    "modules/gui.lua",
    "modules/espPlayer.lua",
    "modules/espGene.lua",
    "modules/aimBot.lua",
    "modules/fpsBoost.lua"
}

local function formatName(path)
    return path:match("([^/]+)%.lua$") or path
end

print("🔄 Carregando módulos do Violence District...")

for _, modulePath in ipairs(modulesToLoad) do
    local success = false
    local err = nil
    
    -- Tenta até 3 vezes caso falhe por instabilidade de rede
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return game:HttpGet(baseUrl .. modulePath .. "?t=" .. tick()) -- Evita cache HTTP preso
        end)
        
        if ok and result then
            local runOk, runErr = pcall(function()
                loadstring(result)()
            end)
            if runOk then
                success = true
                break
            else
                err = runErr
            end
        else
            err = result
        end
        task.wait(0.5)
    end

    if success then
        print("  ✅ Carregado: " .. formatName(modulePath))
    else
        warn("  ❌ Falha ao carregar " .. formatName(modulePath) .. " após 3 tentativas: " .. tostring(err))
    end
    task.wait(0.2)
end

print("🚀 Inicialização concluída com sucesso!")
