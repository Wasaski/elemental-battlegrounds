-- Config.lua
-- Game configuration settings

return {
    Game = {
        MinPlayers = 1,
        LobbyTime = 30,  -- seconds
        GameTime = 600,  -- seconds (10 minutes)
        SafeZone = {
            StartShrinkTime = 300,  -- Start shrinking after 5 minutes
            ShrinkDuration = 240,   -- 4 minutes to fully shrink
            InitialRadius = 1000,
            MinRadius = 100
        },
        RespawnTime = 5,  -- seconds
        MaxLevel = 100,
        XPPerLevel = 1000,
    },
    
    Elements = {
        Fire = {
            Color = Color3.fromRGB(255, 100, 100),
            Abilities = {
                {
                    Name = "Fireball",
                    Cooldown = 3,
                    Damage = 20,
                    Range = 100,
                    Speed = 100,
                    Cost = 10
                },
                {
                    Name = "Flame Dash",
                    Cooldown = 8,
                    Damage = 10,
                    Range = 30,
                    Speed = 50,
                    Cost = 20
                },
                {
                    Name = "Meteor Shower",
                    Cooldown = 30,
                    Damage = 50,
                    Range = 200,
                    Speed = 30,
                    Cost = 50
                }
            }
        },
        
        Water = {
            Color = Color3.fromRGB(100, 100, 255),
            Abilities = {
                {
                    Name = "Water Blast",
                    Cooldown = 4,
                    Damage = 15,
                    Range = 80,
                    Speed = 80,
                    Cost = 12
                },
                {
                    Name = "Healing Rain",
                    Cooldown = 15,
                    Damage = -30,  -- Negative damage heals
                    Range = 50,
                    Speed = 0,  -- Instant
                    Cost = 30
                },
                {
                    Name = "Tsunami",
                    Cooldown = 40,
                    Damage = 45,
                    Range = 150,
                    Speed = 40,
                    Cost = 60
                }
            }
        },
        
        -- Add more elements here
    },
    
    Maps = {
        Default = {
            Name = "Arena",
            SpawnPoints = 20,
            Size = Vector3.new(2000, 500, 2000),
            Terrain = {
                HeightScale = 50,
                WaterLevel = 0,
                Features = {
                    {Type = "Mountain", Size = 100, Position = Vector3.new(0, 0, 0)},
                    {Type = "Lake", Size = 50, Position = Vector3.new(300, 0, 300)}
                }
            }
        }
    },
    
    UI = {
        Colors = {
            Background = Color3.fromRGB(30, 30, 30),
            Text = Color3.fromRGB(255, 255, 255),
            Health = Color3.fromRGB(255, 50, 50),
            Mana = Color3.fromRGB(50, 100, 255),
            Experience = Color3.fromRGB(100, 255, 100),
            Cooldown = Color3.fromRGB(0, 150, 255)
        },
        Fonts = {
            Title = Enum.Font.SourceSansBold,
            Normal = Enum.Font.SourceSans,
            Monospace = Enum.Font.Code
        }
    },
    
    Assets = {
        Sounds = {
            Fireball = "rbxassetid://142647127",
            Explosion = "rbxassetid://142647195",
            LevelUp = "rbxassetid://142647288",
            Victory = "rbxassetid://142647367",
            Defeat = "rbxassetid://142647412"
        },
        Meshes = {
            Fireball = "rbxassetid://142647501",
            WaterOrb = "rbxassetid://142647567"
        },
        Textures = {
            FireIcon = "rbxassetid://142647623",
            WaterIcon = "rbxassetid://142647689",
            EarthIcon = "rbxassetid://142647745",
            AirIcon = "rbxassetid://142647801"
        }
    },
    
    Debug = {
        Enabled = true,
        ShowHitboxes = false,
        LogLevel = "Info",  -- Debug, Info, Warning, Error
        FPS = 60
    }
}
