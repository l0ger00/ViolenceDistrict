-- ============================================================================
-- MÓDULO: ESP GENERATOR
-- Arquivo: modules/espGene.lua
-- ============================================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

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

local function clearGenESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" then
            local h = obj:FindFirstChild("GenESP")
            if h then h:Destroy() end
            local b = obj:FindFirstChild("GenBill")
            if b then b:Destroy() end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not (_G.FeatureState and _G.FeatureState.espGenerator) then
        clearGenESP()
        return
    end

    local map = Workspace:FindFirstChild("Map") or Workspace
    for _, obj in ipairs(map:GetDescendants()) do
        if obj.Name == "Generator" then
            local highlight = obj:FindFirstChild("GenESP")
            local billboard = obj:FindFirstChild("GenBill")
            local progress = getGeneratorProgress(obj)
            local percent = math.floor(progress * 100)
            local color = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(0, 255, 0), progress)

            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "GenESP"
                highlight.FillTransparency = 0.6
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = obj
            end

            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "GenBill"
                billboard.Size = UDim2.new(0, 80, 0, 30)
                billboard.AlwaysOnTop = true
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.Parent = obj

                local label = Instance.new("TextLabel", billboard)
                label.Name = "PercentLabel"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamBold
                label.TextSize = 13
                label.TextStrokeTransparency = 0
            end

            highlight.FillColor = color
            highlight.OutlineColor = color

            local lbl = billboard:FindFirstChild("PercentLabel")
            if lbl then
                if _G.FeatureState.generatorProgress then
                    lbl.Text = percent .. "%"
                    lbl.TextColor3 = color
                else
                    lbl.Text = "GEN"
                    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end)

print("⚡ Módulo ESP Generator inicializado!")
