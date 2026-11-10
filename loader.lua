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

local modulesToLoad = {
    "modules/getRole.lua",
    "modules/gui.lua",
    "modules/espPlayer.lua",
    "modules/espGene.lua",
    "modules/aimBot.lua"
}

local function formatName(path)
    return path:match("([^/]+)%.lua$") or path
end

print("🔄 Carregando módulos do Violence District...")

for _, modulePath in ipairs(modulesToLoad) do
    local success, err = pcall(function()
        loadstring(game:HttpGet(baseUrl .. modulePath))()
    end)

    if success then
        print("  ✅ Carregado: " .. formatName(modulePath))
    else
        warn("  ❌ Erro em " .. formatName(modulePath) .. ": " .. tostring(err))
    end
    task.wait(0.2)
end

print("🚀 Todos os módulos foram processados!")
