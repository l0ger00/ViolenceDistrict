-- ============================================================================
-- MÓDULO OTIMIZADO: ESP GENERATOR (CACHE + THROTTLE)
-- Arquivo: modules/espGene.lua
-- ============================================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local espGenObjects = {}
local generatorsCache = {}
local lastCacheUpdate = 0

local function getGeneratorProgress(gen)
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, v in pairs(gen:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local name = v.Name:lower()
                if name:find("progress") or name:find("repair") or name:find("percent") then
                    progress = v.Value
                    break
                end
            end
        end
    end
    progress = (progress > 1) and (progress / 100) or progress
    return math.clamp(progress, 0, 1)
end

local function removeGenESP(obj)
    if espGenObjects[obj] then
        pcall(function()
            if espGenObjects[obj].highlight then espGenObjects[obj].highlight:Destroy() end
            if espGenObjects[obj].billboard then espGenObjects[obj].billboard:Destroy() end
        end)
        espGenObjects[obj] = nil
    end
end

-- Cache de geradores para evitar varredura pesada constante no workspace
local function getGenerators()
    local now = tick()
    if now - lastCacheUpdate > 1 then
        generatorsCache = {}
        local map = Workspace:FindFirstChild("Map") or Workspace
        for _, v in pairs(map:GetDescendants()) do
            if v.Name == "Generator" then
                table.insert(generatorsCache, v)
            end
        end
        lastCacheUpdate = now
    end
    return generatorsCache
end

local function clearAllGenESP()
    for obj, _ in pairs(espGenObjects) do
        removeGenESP(obj)
    end
end

RunService.Heartbeat:Connect(function()
    local enabled = _G.FeatureState and _G.FeatureState.espGenerator
    local progressEnabled = _G.FeatureState and _G.FeatureState.generatorProgress

    if not enabled then
        clearAllGenESP()
        return
    end

    local gens = getGenerators()
    for _, gen in ipairs(gens) do
        if gen and gen.Parent then
            local progress = getGeneratorProgress(gen)
            local percent = math.floor(progress * 100)
            local color = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(0, 255, 0), progress)

            local data = espGenObjects[gen]
            if not data then
                local h = Instance.new("Highlight")
                h.Name = "VD_ESP_Gen"
                h.FillTransparency = 0.6
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = gen

                local bill = Instance.new("BillboardGui")
                bill.Name = "VD_Bill_Gen"
                bill.Size = UDim2.new(0, 80, 0, 30)
                bill.AlwaysOnTop = true
                bill.StudsOffset = Vector3.new(0, 3, 0)
                bill.Parent = gen

                local label = Instance.new("TextLabel", bill)
                label.Name = "PercentLabel"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamBold
                label.TextSize = 13
                label.TextStrokeTransparency = 0
                label.Parent = bill

                data = { highlight = h, billboard = bill, label = label }
                espGenObjects[gen] = data
            end

            data.highlight.FillColor = color
            data.highlight.OutlineColor = color

            if progressEnabled then
                data.label.Text = percent .. "%"
                data.label.TextColor3 = color
            else
                data.label.Text = "GEN"
                data.label.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        else
            removeGenESP(gen)
        end
    end
end)

print("⚡ Módulo ESP Generator otimizado (com Cache) carregado!")
