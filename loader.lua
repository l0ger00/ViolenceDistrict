-- ============================================================================
-- VIOLENCE DISTRICT - LOADER CENTRAL MODULAR
-- Repositório: https://github.com/l0ger00/ViolenceDistrict
-- ============================================================================

if _G.__VD_LOADER_ACTIVE then
    print("⚠️ O Loader do Violence District já está rodando!")
    return
end
_G.__VD_LOADER_ACTIVE = true

local baseUrl = "https://raw.githubusercontent.com/l0ger00/ViolenceDistrict/main/"

-- Lista de módulos que serão carregados em ordem
local modulesToLoad = {
    "modules/getRole.lua",
    "modules/espPlayer.lua",
    "modules/espGene.lua",
    "modules/aimBot.lua"
}

local function formatName(path)
    local name = path:match("([^/]+)%.lua$") or path
    return name
end

print("🔄 Iniciando carregamento dos módulos do Violence District...")

-- Loop para baixar e executar cada módulo com tratamento de erros (pcall)
for _, modulePath in ipairs(modulesToLoad) do
    local success, err = pcall(function()
        loadstring(game:HttpGet(baseUrl .. modulePath))()
    end)

    if success then
        print("  ✅ Módulo carregado: " .. formatName(modulePath))
    else
        warn("  ❌ Erro ao carregar módulo " .. formatName(modulePath) .. ": " .. tostring(err))
    end
    task.wait(0.2)
end

print("🚀 Todos os módulos foram processados!")
