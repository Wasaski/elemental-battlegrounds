-- GameUI.lua
-- Client-side UI for Elemental Battlegrounds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remote events
local events = {
    updateGameState = ReplicatedStorage:WaitForChild("updateGameState"),
    updateTimer = ReplicatedStorage:WaitForChild("updateTimer"),
    updatePlayersAlive = ReplicatedStorage:WaitForChild("updatePlayersAlive"),
    updateSafeZone = ReplicatedStorage:WaitForChild("updateSafeZone"),
    playerDied = ReplicatedStorage:WaitForChild("playerDied"),
    abilityUsed = ReplicatedStorage:WaitForChild("abilityUsed"),
    playerJoined = ReplicatedStorage:WaitForChild("playerJoined")
}

-- UI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ElementalBattlegroundsUI"
screenGui.ResetOnSpawn = false

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Game status frame
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0.3, 0, 0.15, 0)
statusFrame.Position = UDim2.new(0.35, 0, 0.02, 0)
statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusFrame.BackgroundTransparency = 0.5
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame

-- Timer label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.new(1, 0, 0.5, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "00:00"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextScaled = true
font = Enum.Font.SourceSansBold
timerLabel.Parent = statusFrame

-- Players alive label
local playersLabel = Instance.new("TextLabel")
playersLabel.Name = "PlayersAlive"
playersLabel.Size = UDim2.new(1, 0, 0.5, 0)
playersLabel.Position = UDim2.new(0, 0, 0.5, 0)
playersLabel.BackgroundTransparency = 1
playersLabel.Text = "Players: 0"
playersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playersLabel.TextScaled = true
playersLabel.Font = Enum.Font.SourceSansBold
playersLabel.Parent = statusFrame

-- Health bar
local healthBar = Instance.new("Frame")
healthBar.Name = "HealthBar"
healthBar.Size = UDim2.new(0.2, 0, 0.03, 0)
healthBar.Position = UDim2.new(0.02, 0, 0.95, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBar.BorderSizePixel = 2
healthBar.BorderColor3 = Color3.fromRGB(100, 100, 100)
healthBar.Parent = mainFrame

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBar

local healthText = Instance.new("TextLabel")
healthText.Name = "HealthText"
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100/100"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.TextScaled = true
healthText.Font = Enum.Font.SourceSansBold
healthText.Parent = healthBar

-- Ability bar
local abilityBar = Instance.new("Frame")
abilityBar.Name = "AbilityBar"
abilityBar.Size = UDim2.new(0.6, 0, 0.08, 0)
abilityBar.Position = UDim2.new(0.2, 0, 0.9, 0)
abilityBar.BackgroundTransparency = 1
abilityBar.Parent = mainFrame

-- Create ability slots
local abilitySlots = {}
for i = 1, 3 do
    local slot = Instance.new("ImageButton")
    slot.Name = "Ability" .. i
    slot.Size = UDim2.new(0.3, 0, 1, 0)
    slot.Position = UDim2.new(0.23 * (i-1), 0, 0, 0)
    slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slot.BorderSizePixel = 0
    slot.Parent = abilityBar
    
    local cooldown = Instance.new("Frame")
    cooldown.Name = "Cooldown"
    cooldown.Size = UDim2.new(1, 0, 0, 0)
    cooldown.Position = UDim2.new(0, 0, 1, 0)
    cooldown.AnchorPoint = Vector2.new(0, 1)
    cooldown.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    cooldown.BorderSizePixel = 0
    cooldown.ZIndex = 2
    cooldown.Parent = slot
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "Key"
    keyLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
    keyLabel.Position = UDim2.new(0.7, 0, 0.7, 0)
    keyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    keyLabel.Text = tostring(i)
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.SourceSansBold
    keyLabel.Parent = slot
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.3, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Ability " .. i
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = slot
    
    table.insert(abilitySlots, slot)
end

-- Game state UI
local gameStateFrame = Instance.new("Frame")
gameStateFrame.Name = "GameStateFrame"
gameStateFrame.Size = UDim2.new(1, 0, 1, 0)
gameStateFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
gameStateFrame.BackgroundTransparency = 0.7
gameStateFrame.Visible = false
gameStateFrame.Parent = mainFrame

local gameStateText = Instance.new("TextLabel")
gameStateText.Name = "GameStateText"
gameStateText.Size = UDim2.new(1, 0, 0.5, 0)
gameStateText.Position = UDim2.new(0, 0, 0.25, 0)
gameStateText.BackgroundTransparency = 1
gameStateText.Text = ""
gameStateText.TextColor3 = Color3.fromRGB(255, 255, 255)
gameStateText.TextScaled = true
gameStateText.Font = Enum.Font.SourceSansBold
gameStateText.Parent = gameStateFrame

-- Element selection UI
local elementSelection = Instance.new("Frame")
elementSelection.Name = "ElementSelection"
elementSelection.Size = UDim2.new(0.8, 0, 0.8, 0)
elementSelection.Position = UDim2.new(0.1, 0, 0.1, 0)
elementSelection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
elementSelection.Visible = false
elementSelection.Parent = mainFrame

local elementTitle = Instance.new("TextLabel")
elementTitle.Name = "Title"
elementTitle.Size = UDim2.new(1, 0, 0.1, 0)
elementTitle.BackgroundTransparency = 1
elementTitle.Text = "Choose Your Element"
elementTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
elementTitle.TextScaled = true
elementTitle.Font = Enum.Font.SourceSansBold
elementTitle.Parent = elementSelection

local elementsContainer = Instance.new("Frame")
elementsContainer.Name = "ElementsContainer"
elementsContainer.Size = UDim2.new(1, 0, 0.9, 0)
elementsContainer.Position = UDim2.new(0, 0, 0.1, 0)
elementsContainer.BackgroundTransparency = 1
elementsContainer.Parent = elementSelection

-- Function to create element buttons
local function createElementButton(elementName, elementData, position)
    local button = Instance.new("TextButton")
    button.Name = elementName .. "Button"
    button.Size = UDim2.new(0.3, 0, 0.8, 0)
    button.Position = position
    button.BackgroundColor3 = elementData.color
    button.Text = elementName
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Parent = elementsContainer
    
    -- Add ability descriptions
    local abilitiesFrame = Instance.new("Frame")
    abilitiesFrame.Name = "Abilities"
    abilitiesFrame.Size = UDim2.new(1, 0, 0.6, 0)
    abilitiesFrame.Position = UDim2.new(0, 0, 1, 0)
    abilitiesFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    abilitiesFrame.Visible = false
    abilitiesFrame.Parent = button
    
    for i, ability in ipairs(elementData.abilities) do
        local abilityLabel = Instance.new("TextLabel")
        abilityLabel.Name = "Ability" .. i
        abilityLabel.Size = UDim2.new(1, 0, 0.3, 0)
        abilityLabel.Position = UDim2.new(0, 0, 0.3 * (i-1), 0)
        abilityLabel.BackgroundTransparency = 1
        abilityLabel.Text = ability.name .. " (" .. ability.cooldown .. "s)"
        abilityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        abilityLabel.TextScaled = true
        abilityLabel.TextXAlignment = Enum.TextXAlignment.Left
        abilityLabel.Padding.Left = UDim.new(0.05, 0)
        abilityLabel.Parent = abilitiesFrame
    end
    
    button.MouseEnter:Connect(function()
        abilitiesFrame.Visible = true
    end)
    
    button.MouseLeave:Connect(function()
        abilitiesFrame.Visible = false
    end)
    
    button.MouseButton1Click:Connect(function()
        -- Select this element
        -- (In a real game, you would send this to the server)
        game.ReplicatedStorage.ChangeElement:FireServer(elementName)
        elementSelection.Visible = false
    end)
end

-- Initialize UI
local function init()
    -- Set up ability keybinds
    for i = 1, 3 do
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode[i == 1 and "One" or i == 2 and "Two" or "Three"] then
                -- Use ability
                game.ReplicatedStorage.UseAbility:FireServer(i)
            end
        end)
    end
    
    -- Update health display when character spawns
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Update health display
        local function updateHealth()
            healthFill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
            healthText.Text = math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth
        end
        
        humanoid.HealthChanged:Connect(updateHealth)
        updateHealth()
    end)
    
    -- Show element selection when joining
    elementSelection.Visible = true
end

-- Game state events
events.updateGameState.OnClientEvent:Connect(function(state, data)
    if state == "waiting" then
        gameStateFrame.Visible = false
        elementSelection.Visible = true
    elseif state == "counting" then
        gameStateFrame.Visible = true
        elementSelection.Visible = false
        gameStateText.Text = "Game starting in " .. (data and data.time or 0) .. " seconds!"
    elseif state == "in_progress" then
        gameStateFrame.Visible = false
        elementSelection.Visible = false
    elseif state == "game_over" then
        gameStateFrame.Visible = true
        gameStateText.Text = "Game Over!\nWinner: " .. (data and data.winner or "No one") .. "!"
    end
end)

events.updateTimer.OnClientEvent:Connect(function(time)
    local minutes = math.floor(time / 60)
    local seconds = time % 60
    timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
end)

events.updatePlayersAlive.OnClientEvent:Connect(function(count)
    playersLabel.Text = "Players Alive: " .. count
end)

events.playerJoined.OnClientEvent:Connect(function(data)
    -- Create element selection UI
    for elementName, elementData in pairs(data.elements) do
        local position = UDim2.new(0.1 + (#elementsContainer:GetChildren() * 0.3), 0, 0.1, 0)
        createElementButton(elementName, elementData, position)
    end
end)

-- Initialize the UI
init()

-- Add UI to player's GUI
screenGui.Parent = playerGui
