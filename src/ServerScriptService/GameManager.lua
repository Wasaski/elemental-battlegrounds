-- GameManager.lua
-- Main game controller for Elemental Battlegrounds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Game settings
local MIN_PLAYERS = 1
local LOBBY_TIME = 30
local GAME_TIME = 600 -- 10 minutes
local SAFE_ZONE_SHRINK_START = 300 -- Start shrinking after 5 minutes
local SAFE_ZONE_SHRINK_DURATION = 240 -- 4 minutes to fully shrink

-- Game state
local gameState = "waiting" -- waiting, counting, in_progress, ended
local playersAlive = 0
local gameTime = 0
local safeZone = {
    radius = 1000,
    minRadius = 100,
    center = Vector3.new(0, 0, 0),
    currentRadius = 1000
}

-- Create remote events
local events = {
    updateGameState = Instance.new("RemoteEvent"),
    updateTimer = Instance.new("RemoteEvent"),
    updatePlayersAlive = Instance.new("RemoteEvent"),
    updateSafeZone = Instance.new("RemoteEvent"),
    playerDied = Instance.new("RemoteEvent"),
    abilityUsed = Instance.new("RemoteEvent"),
    playerJoined = Instance.new("RemoteEvent")
}

-- Initialize remote events
for name, event in pairs(events) do
    event.Name = name
    event.Parent = ReplicatedStorage
end

-- Element definitions
local elements = {
    Fire = {
        color = Color3.fromRGB(255, 100, 100),
        abilities = {
            {name = "Fireball", cooldown = 3, damage = 20},
            {name = "Flame Dash", cooldown = 8, damage = 10},
            {name = "Meteor Shower", cooldown = 30, damage = 50}
        }
    },
    Water = {
        color = Color3.fromRGB(100, 100, 255),
        abilities = {
            {name = "Water Blast", cooldown = 4, damage = 15},
            {name = "Healing Rain", cooldown = 15, damage = -30}, -- Negative damage heals
            {name = "Tsunami", cooldown = 40, damage = 45}
        }
    },
    -- Add more elements here
}

-- Function to create a player's character
local function setupPlayerCharacter(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Set player stats
    local stats = Instance.new("Folder")
    stats.Name = "PlayerStats"
    
    local element = Instance.new("StringValue")
    element.Name = "Element"
    element.Value = "Fire" -- Default element
    element.Parent = stats
    
    local health = Instance.new("IntValue")
    health.Name = "Health"
    health.Value = 100
    health.Parent = stats
    
    local maxHealth = Instance.new("IntValue")
    maxHealth.Name = "MaxHealth"
    maxHealth.Value = 100
    maxHealth.Parent = stats
    
    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = 1
    level.Parent = stats
    
    local xp = Instance.new("IntValue")
    xp.Name = "XP"
    xp.Value = 0
    xp.Parent = stats
    
    stats.Parent = player
    
    -- Set up character appearance based on element
    local elementData = elements[element.Value]
    if elementData then
        -- Change character appearance based on element
        local shirt = character:FindFirstChild("Shirt") or Instance.new("Shirt")
        shirt.Parent = character
        shirt.ShirtTemplate = "rbxassetid://142647019" -- Default shirt, replace with element-specific
        
        local pants = character:FindFirstChild("Pants") or Instance.new("Pants")
        pants.Parent = character
        pants.PantsTemplate = "rbxassetid://142647067" -- Default pants, replace with element-specific
    end
    
    -- Set up death handling
    humanoid.Died:Connect(function()
        playersAlive = playersAlive - 1
        events.playerDied:FireClient(player, player)
        events.updatePlayersAlive:FireAllClients(playersAlive)
        
        -- Respawn after delay
        wait(5)
        if player and player.Parent then
            player:LoadCharacter()
        end
    end)
end

-- Function to start the game
local function startGame()
    gameState = "in_progress"
    gameTime = GAME_TIME
    playersAlive = #Players:GetPlayers()
    
    -- Teleport players to random spawn points
    local spawnPoints = workspace:FindFirstChild("SpawnPoints"):GetChildren()
    
    for _, player in ipairs(Players:GetPlayers()) do
        local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
        player:LoadCharacter()
        player.Character:SetPrimaryPartCFrame(spawnPoint.CFrame + Vector3.new(0, 5, 0))
        
        -- Set up player stats and abilities
        setupPlayerCharacter(player)
    end
    
    -- Start game loop
    while gameTime > 0 and gameState == "in_progress" do
        gameTime = gameTime - 1
        events.updateTimer:FireAllClients(gameTime)
        
        -- Update safe zone
        if gameTime <= SAFE_ZONE_SHRINK_START and gameTime > (SAFE_ZONE_SHRINK_START - SAFE_ZONE_SHRINK_DURATION) then
            local shrinkProgress = 1 - ((gameTime - (SAFE_ZONE_SHRINK_START - SAFE_ZONE_SHRINK_DURATION)) / SAFE_ZONE_SHRINK_DURATION)
            safeZone.currentRadius = safeZone.radius - ((safeZone.radius - safeZone.minRadius) * shrinkProgress)
            events.updateSafeZone:FireAllClients(safeZone.center, safeZone.currentRadius)
        end
        
        -- Check win condition
        if playersAlive <= 1 then
            gameState = "ended"
            break
        end
        
        wait(1)
    end
    
    -- Game over logic
    if gameState == "ended" then
        -- Find the winner
        local winner = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                winner = player
                break
            end
        end
        
        -- Announce winner
        if winner then
            events.updateGameState:FireAllClients("game_over", {winner = winner.Name})
        else
            events.updateGameState:FireAllClients("game_over", {winner = "No one"})
        end
        
        -- Reset game after delay
        wait(10)
        gameState = "waiting"
        events.updateGameState:FireAllClients("waiting")
    end
end

-- Player joining
Players.PlayerAdded:Connect(function(player)
    -- Set up character when player spawns
    player.CharacterAdded:Connect(function()
        setupPlayerCharacter(player)
    end)
    
    -- Notify client they've joined
    events.playerJoined:FireClient(player, {
        elements = elements
    })
    
    -- Start game if enough players
    if gameState == "waiting" and #Players:GetPlayers() >= MIN_PLAYERS then
        gameState = "counting"
        events.updateGameState:FireAllClients("counting", {time = LOBBY_TIME})
        
        -- Start countdown
        local countdown = LOBBY_TIME
        while countdown > 0 and gameState == "counting" do
            wait(1)
            countdown = countdown - 1
            events.updateGameState:FireAllClients("counting", {time = countdown})
        end
        
        if gameState == "counting" then  -- Make sure we didn't cancel the countdown
            startGame()
        end
    end
end)

-- Player leaving
Players.PlayerRemoving:Connect(function()
    if gameState == "in_progress" then
        playersAlive = playersAlive - 1
        events.updatePlayersAlive:FireAllClients(playersAlive)
    end
end)

-- Handle ability usage
local function onAbilityUsed(player, abilityIndex)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local playerStats = player:FindFirstChild("PlayerStats")
    if not playerStats then return end
    
    local element = playerStats:FindFirstChild("Element")
    if not element or not elements[element.Value] then return end
    
    local ability = elements[element.Value].abilities[abilityIndex]
    if not ability then return end
    
    -- Check cooldown (implement cooldown system here)
    
    -- Use ability
    events.abilityUsed:FireAllClients(player, {
        element = element.Value,
        abilityIndex = abilityIndex,
        position = character:GetPivot().Position
    })
    
    -- Handle ability effects
    if ability.name == "Fireball" then
        -- Create fireball projectile
        local fireball = Instance.new("Part")
        fireball.Shape = Enum.PartType.Ball
        fireball.Size = Vector3.new(2, 2, 2)
        fireball.Position = character.Head.Position + character.Head.CFrame.LookVector * 2
        fireball.Velocity = character.Head.CFrame.LookVector * 100
        fireball.BrickColor = BrickColor.new("Bright red")
        fireball.Material = Enum.Material.Neon
        fireball.CanCollide = false
        
        -- Add fire effect
        local fire = Instance.new("Fire")
        fire.Heat = 25
        fire.Size = 4
        fire.Parent = fireball
        
        -- Handle collision
        fireball.Touched:Connect(function(hit)
            local hitCharacter = hit:FindFirstAncestorOfClass("Model")
            if hitCharacter and hitCharacter ~= character then
                local humanoid = hitCharacter:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:TakeDamage(ability.damage)
                end
                fireball:Destroy()
            end
        end)
        
        fireball.Parent = workspace
        game.Debris:AddItem(fireball, 5)
    end
    -- Add other ability implementations here
end

events.abilityUsed.OnServerEvent:Connect(onAbilityUsed)

-- Initialize game
local function init()
    -- Create spawn points if they don't exist
    if not workspace:FindFirstChild("SpawnPoints") then
        local spawnFolder = Instance.new("Folder")
        spawnFolder.Name = "SpawnPoints"
        spawnFolder.Parent = workspace
        
        for i = 1, 20 do
            local spawnPoint = Instance.new("Part")
            spawnPoint.Name = "SpawnPoint" .. i
            spawnPoint.Size = Vector3.new(6, 1, 6)
            spawnPoint.Position = Vector3.new(
                math.random(-400, 400),
                5,
                math.random(-400, 400)
            )
            spawnPoint.Anchored = true
            spawnPoint.Transparency = 1
            spawnPoint.CanCollide = false
            spawnPoint.Parent = spawnFolder
        end
    end
    
    -- Set up lighting
    local lighting = game:GetService("Lighting")
    lighting.Ambient = Color3.fromRGB(100, 100, 100)
    lighting.Brightness = 2
    lighting.GeographicLatitude = 41.7
    lighting.TimeOfDay = "14:00:00"
    
    -- Create safe zone visual
    local safeZonePart = Instance.new("Part")
    safeZonePart.Name = "SafeZone"
    safeZonePart.Shape = Enum.PartType.Cylinder
    safeZonePart.Size = Vector3.new(1, safeZone.radius * 2, safeZone.radius * 2)
    safeZonePart.Position = safeZone.center + Vector3.new(0, -500, 0)
    safeZonePart.Orientation = Vector3.new(0, 0, 90)
    safeZonePart.Anchored = true
    safeZonePart.CanCollide = false
    safeZonePart.Transparency = 0.8
    safeZonePart.BrickColor = BrickColor.new("Lime green")
    safeZonePart.Material = Enum.Material.Neon
    safeZonePart.Parent = workspace
end

init()
