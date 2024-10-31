-- Trailmakers Minigolf Mod created by TerrorSoul
-- Constants
local PIECE_DIMENSIONS = 10
local PIECE_SCALE = 0.4
local SLOPE_HEIGHT_CHANGE = (PIECE_DIMENSIONS * PIECE_SCALE) * 0.2  -- rise/fall by half the piece height
local DISABLE_BALL_MOVEMENT_CHECK = true  -- true to disable ball movement checking
local DEBUG_FORCED_BIOME = nil -- nil is not forced

local DEFAULT_START_HEIGHT = 250
local DEFAULT_START_X = -6200
local DEFAULT_START_Z = -1350
local DEFAULT_VIEW_PLATFORM_HEIGHT = 320

local INITIAL_START_DELAY = 8 -- normal is 8

local MIN_STRAIGHT_BEFORE_TURN = 3
local MAX_STRAIGHT_BEFORE_TURN = 5
local TURN_PROBABILITY = 0.2
local CONSECUTIVE_SLOPE_PROBABILITY = 0.3
local SPAWN_LOCATION_ID = 1
local MAX_PUTT_POWER = 1.2
local MAX_CHARGE_TIME = 5
local UPDATE_INTERVAL = 0.05
local POWER_BAR_LENGTH = 10
local POWER_BAR_CHAR = "█"
local EMPTY_BAR_CHAR = "░"
local PAR = 3
local FLAG_HEIGHT_OFFSET = -0.3
local CAMERA_POSITION_SMOOTHING = 0.037
local CAMERA_ROTATION_SMOOTHING = 0.043
local CAMERA_DISTANCE = 0.8
local CAMERA_HEIGHT = 0.528
local HOLE_RADIUS = 0.28
local goalYPosition
local FALL_OFFSET = 13 -- TP offset for ball falling
local TOP_DOWN_VIEW_DURATION = 3  -- Duration in seconds for the top-down view
local styleHistory = {}
local STYLE_REPEAT_PREVENTION = 5  -- No of generations before a style can repeat

local currentDifficulty = 1  -- Start with diff lvl 1
local MAX_DIFFICULTY = 30    -- Max diff lvl
local MIN_COURSE_LENGTH = 3
local MAX_COURSE_LENGTH = 26
local COURSE_LENGTH_INCREMENT = 1
local currentCourseLength = MIN_COURSE_LENGTH
local NIGHT_TIME_THRESHOLD_LOW = 72  -- Start of night time
local NIGHT_TIME_THRESHOLD_HIGH = 30
local DEFAULT_LIGHT_HEIGHT_OFFSET = 4.4

local MIN_CHARGE_TIME = 0.3

local isRegeneratingCourse = false
local courseCompletionTimer = nil
local currentMusicName = nil
local previousStyle = nil
local initialDelayTimer = nil
local hasInitializedGame = false
local isInitialCourse = true
local currentTimeOfDay = nil

local PREVIEW_START_POSITION = tm.vector3.Create(-5500, 350, 10000)
local PREVIEW_SPACING = 4  -- Space between preview menu balls
local GOLFBALL_TEXTURES = {
    "golfball_tm",
    "golfball_trailmakers",
    "golfball_melvin",
    "golfball_runner",
    "golfball_flame",
    "golfball_void",
    "golfball_pink",
    "golfball_rainbow",
    "golfball_pumpkin",
    "golfball_spooky",
    "golfball_chirpo",
    "golfball_chirpo_green",
    "golfball_1by1",
    "golfball_stars",
    "golfball_stone",
    "golfball_pixel",
    "golfball_mud",
    "golfball_white",
    "golfball_snowflakes",
    "golfball_spark",
    "golfball_ice",
    "golfball_johannes"
}

local playerPreviewBalls = {}
local playerSelectedTextures = {}
local playerTextureIndex = {}
local playerPreviewLights = {}
tm.os.SetModTargetDeltaTime(1/60)
tm.world.SetTimeOfDay(50)
tm.audio.PlayAudioAtPosition("UI_InGameMenu_QuitToMain_click", tm.vector3.Create(0, 1000, 0), 0)
tm.audio.PlayAudioAtPosition("ExplorationCheckpoint_music_stop", tm.vector3.Create(0, 1000, 0), 0)
tm.audio.PlayAudioAtPosition("CutScene_StartIntroCinematic", tm.vector3.Create(0, 1000, 0), 0)
tm.physics.AddTexture("viewer.png", "theviewer")
tm.physics.AddTexture("thelogo.png", "logo")
tm.physics.AddTexture("theinfo.png", "info")
tm.physics.AddTexture("theflag.png", "flag")
tm.physics.AddMesh("golfball.obj", "golfball")
tm.physics.AddTexture("golfball_tm.jpg", "golfball_tm")

local globalStartPosition   
local globalStartRotation
local puttingPlayers = {}
local subtleMessageIds = {}
local playerGolfBalls = {}
local playerCameraPositions = {}
local playerCameraRotations = {}
local playerScores = {}
local holePosition
local previousBallPositions = {}
local coursePieces = {}
local golfBallRollingInfo = {}
local activePlayers = {}
local playerTopDownCameras = {}
local courseLights = {}
local detailObjects = {}
local currentStyle = nil 
local lastBallMovingMessageTime = {}

-- Style definitions
local STYLES = {
    tropical = {
        detailFile = "tropical_details",
        textureAtlas = "matlas_tropical.png",
        timeOfDay = {min = 0, max = 100},
        music = {"AMB_Forest_Birds_start","Amb_SkylandsForest_Radial_start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0} -- adds to the position the details from files (biome) spawns at
            }
        },
        details = {
            {prefab = "PFB_TropicalFlower_2", minScale = 0.0008, maxScale = 0.002, heightOffset = 0.08, density = 2, padding = 0.1},
            {prefab = "PFB_TropicalFlower_3", minScale = 0.0008, maxScale = 0.002, heightOffset = 0.08, density = 2, padding = 0.1},
            {prefab = "PFB_TropicalFlower_4", minScale = 0.0008, maxScale = 0.002, heightOffset = 0.08, density = 2, padding = 0.1},
            {prefab = "PFB_TropicalFlower_1", minScale = 0.0008, maxScale = 0.0012, heightOffset = 0.055, density = 0.7, padding = 0.15},
        },
        difficultyDetails = {
            {prefab = "PFB_SimpleStoneHighSeas", minScale = 0.08, maxScale = 0.11, heightOffset = 0.07, multiplier = 0.5, padding = 0.2},
        },
        validMaps = nil,
        maxCourseLength = 30
    },
    desert = {
        detailFile = "desert_details",
        textureAtlas = "matlas_desert.png",
        timeOfDay = {min = 45, max = 70},
        music = {"Amb_BasicWind_RaceIsland_start","Amb_Desert_Basic_Start","AI_Amb_BaseWind_Start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0}
            }
        },
        details = {
            {prefab = "PFB_Cactus_Star_Plant", minScale = 0.5, maxScale = 0.7, heightOffset = 0.08, density = 0.8, padding = 0.2},
            {prefab = "PFB_Desert_Bush_Fir", minScale = 0.1, maxScale = 0.2, heightOffset = -0.015, density = 0.3, padding = 1},
        },
        difficultyDetails = {
            {prefab = "PFB_Cactus_Bush", minScale = 0.19, maxScale = 0.22, heightOffset = -0.05, multiplier = 0.2, padding = 0.25},
            {prefab = "PFB_Cactus_Ball", minScale = 0.11, maxScale = 0.14, heightOffset = 0.055, multiplier = 0.2, padding = 0.2},
        },
        validMaps = nil,
        maxCourseLength = 28
    },
    space = {
        detailFile = "special_details",
        textureAtlas = "matlas_special.png",
        timeOfDay = {min = 68, max = 100},
        music = {"Amb_Space_Start","Amb_Space_Crystal_Notes_06_start","Amb_Space_Crystal_Notes_05_start","Amb_Space_Crystal_Notes_03_start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0}
            }
        },
        details = {
            {prefab = "PFB_PowerCoreCrate", minScale = 0.03, maxScale = 0.03, heightOffset = -0.1, density = 0.4, padding = 0.45},
        },
        difficultyDetails = {
            {prefab = "PFB_CrystalClusterBlue", minScale = 0.017, maxScale = 0.02, heightOffset = 0, multiplier = 0.25, padding = 2},
            {prefab = "PFB_CrystalClusterPink", minScale = 0.017, maxScale = 0.02, heightOffset = 0, multiplier = 0.25, padding = 2},
            {prefab = "PFB_CrystalSmall_blue", minScale = 0.1, maxScale = 0.13, heightOffset = -0, multiplier = 0.34, padding = 1},
            {prefab = "PFB_CrystalSmall_pink", minScale = 0.1, maxScale = 0.13, heightOffset = -0, multiplier = 0.34, padding = 1},
        },
        lightPrefab = "PFB_SalvageItem_Ball",
        lightHeightOffset = 4.4,
        validMaps = nil,
        maxCourseLength = 11
    },
    mushroom = {
        detailFile = "mushroom_details",
        textureAtlas = "matlas_mushroom.png",
        timeOfDay = {min = 40, max = 100},
        music = {"Amb_Marsh_Base_Start","Amb_Frogs_Radial_start", "Amb_Marsh_Crickets_Start","Amb_Animals_Marsh_Start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0}
            }
        },
        details = {
            {prefab = "PFB_Mushroom_5m_01", minScale = 0.02, maxScale = 0.03, heightOffset = 0.05, density = 1.5, padding = 0.5},
            {prefab = "PFB_Mushroom_5m_02", minScale = 0.02, maxScale = 0.03, heightOffset = 0.05, density = 1, padding = 1.3},
        },
        difficultyDetails = {
        },
        validMaps = nil,
        maxCourseLength = 28
    },
    ice = {
        detailFile = "ice_details",
        textureAtlas = "matlas_ice.png",
        timeOfDay = {min = 50, max = 50},
        music = {"Amb_HeavyWinds_Start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0}
            }
        },
        details = {
        },
        difficultyDetails = {
            {prefab = "PFB_Iceberg_01", minScale = 0.01, maxScale = 0.02, heightOffset = 0.05, multiplier = 0.22, padding = 2},
        },
        validMaps = nil,
        maxCourseLength = 32
    },
    lava = {
        detailFile = "lava_details",
        textureAtlas = "matlas_lava.png",
        timeOfDay = {min = 80, max = 100},
        music = {"Amb_Volcano_Base_Start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0}
            }
        },
        details = {
            {prefab = "PFB_CharredBush", minScale = 0.2, maxScale = 0.3, heightOffset = 0.08, density = 1.6, padding = 0.4},
        },
        difficultyDetails = {
            {prefab = "PFB_spikes01_volcano", minScale = 0.02, maxScale = 0.03, heightOffset = -0.1, multiplier = 0.26, padding = 1.8},
            {prefab = "PFB_CharredStump", minScale = 0.2, maxScale = 0.3, heightOffset = 0.1, multiplier = 0.2, padding = 2},
        },
        validMaps = nil,
        maxCourseLength = 28
    },
    underwater = {
        detailFile = "underwater_details",
        textureAtlas = "matlas_underwater.png",
        timeOfDay = {min = 50, max = 100},
        music = {"CameraUnderWater","Amb_Basicwind_start"},
        positioning = {
            WLD_Sandbox = {  
                start_height = 165,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 193,
                position_offset = {x = 0, y = 85, z = 0}
            },
            WLD_StuntIsland = {  
                start_height = 165,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 193,
                position_offset = {x = 0, y = 85, z = 0}
            }
        },
        details = {
            {prefab = "PFB_WavyBottomPlantGreenLadder", minScale = 0.2, maxScale = 0.5, heightOffset = 0, density = 1.5, padding = 1.6},
            {prefab = "PFB_WavyBottomPlantGreenBubbleWeed", minScale = 0.2, maxScale = 0.5, heightOffset = 0, density = 0.4, padding = 2.5},
            {prefab = "PFB_WavyBottomPlantGreenLeafy", minScale = 0.2, maxScale = 0.5, heightOffset = 0, density = 0.5, padding = 1.8},
        },
        difficultyDetails = {
            {prefab = "PFB_HS_ClamClosed", minScale = 0.11, maxScale = 0.13, heightOffset = 0.4, multiplier = 0.26, padding = 1.5},
        },
        validMaps = {"WLD_Sandbox", "WLD_StuntIsland"},
        maxCourseLength = 24
    },
    isle = {
        detailFile = "isle_details",
        textureAtlas = "matlas_isle.png",
        timeOfDay = {min = 0, max = 100},
        music = {"Amb_Animals_ExoticIsland_Start"},
        positioning = {
            WLD_Sandbox = {  
                start_height = 230,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 300,
                position_offset = {x = 0, y = 19, z = 0}
            },
            WLD_StuntIsland = {  
                start_height = 230,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 300,
                position_offset = {x = 0, y = 19, z = 0}
            }
        },
        details = {
            {prefab = "PFB_TropicalFlower_1", minScale = 0.0008, maxScale = 0.0012, heightOffset = 0.055, density = 0.7, padding = 0.15},
        },
        difficultyDetails = {
            {prefab = "PFB_SimpleStoneHighSeas", minScale = 0.08, maxScale = 0.11, heightOffset = 0.07, multiplier = 0.5, padding = 0.2},
        },
        validMaps = {"WLD_Sandbox", "WLD_StuntIsland"},
        maxCourseLength = 24
    },
    city = {
        detailFile = "city_details",
        textureAtlas = "matlas_city.png",
        timeOfDay = {min = 40, max = 80},
        music = {"CharacterCustomisationGarage","AI_Amb_BaseWind_Start", "Amb_RaceIsland_start"},
        positioning = {
            WLD_TestZone = {  
                start_height = 450,
                start_x = -6200,
                start_z = -1350,
                view_platform_height = 530,
                position_offset = {x = 0, y = 0, z = 0}
            }
        },
        details = {
        },
        difficultyDetails = {
        },
        validMaps = {"WLD_Sandbox", "WLD_StuntIsland", "WLD_TestZone"},
        validMaps = nil,
        maxCourseLength = 20
    },
}

-- Piece definitions
local PIECES = {
    mgoal = {excludeDetails = true},
    mupslope = {excludeDetails = true},
    mdownslope = {excludeDetails = true},
    mstart = {excludeDetails = true},
    mcornerleft = {},
    mcornerright = {},
    mstraight = {},
    mcastle = {
        minDifficulty = 2,
        chanceMuliplier = 0.02,
        excludeDetails = true
    },
    mwindmill = {
        minDifficulty = 4,
        chanceMuliplier = 0.010,
        excludeDetails = true
    },
    mhole = {
        minDifficulty = 3,
        chanceMuliplier = 0.033,
        excludeDetails = true
    },
    mvalley = {
        minDifficulty = 7,
        chanceMuliplier = 0.006,
        excludeDetails = true
    },
    mditch = {
        minDifficulty = 6,
        chanceMuliplier = 0.01,
        excludeDetails = true
    },
    mobstacle = {
        minDifficulty = 3,
        chanceMuliplier = 0.009,
        excludeDetails = true
    },
    mobstacle2 = {
        minDifficulty = 5,
        chanceMuliplier = 0.008,
        excludeDetails = true
    },
    mnarrow = {
        minDifficulty = 2,
        chanceMuliplier = 0.01,
        excludeDetails = true
    },
    mbump = {
        minDifficulty = 3,
        chanceMuliplier = 0.01,
        excludeDetails = true
    },
    mstunt = {
        minDifficulty = 2,
        chanceMuliplier = 0.01,
        excludeDetails = true
    },
    mplankcenter = {
        minDifficulty = 2,
        chanceMuliplier = 0.01,
        excludeDetails = true
    },
    mplankleft = {
        minDifficulty = 3,
        chanceMuliplier = 0.02,
        excludeDetails = true
    },
    mplankright = {
        minDifficulty = 6,
        chanceMuliplier = 0.02,
        excludeDetails = true
    },
    --mbeam = {
    --   minDifficulty = 11,
    --    chanceMuliplier = 0.007,
    --    excludeDetails = true
    --},
    mwiggle= {
        minDifficulty = 2,
        chanceMuliplier = 0.01,
        excludeDetails = true
    },
    mtunnel= {
        minDifficulty = 7,
        chanceMuliplier = 0.008,
        excludeDetails = true
    },
    mobstacleopen = {
        minDifficulty = 9,
        chanceMuliplier = 0.008,
        excludeDetails = true
    },
    mdiagopen = {
        minDifficulty = 11,
        chanceMuliplier = 0.009,
        excludeDetails = true
    }
}

local currentMap = tm.physics.GetMapName()
if currentMap == "WLD_HighSeas" or currentMap == "WLD_Exploration" or currentMap == "WLD_RaceIsland" or currentMap == "WLD_AirborneIsland" or currentMap == "WLD_TheMoon" then
    tm.playerUI.AddSubtleMessageForAllPlayers(
        "Trailmakers Minigolf",
        "Not compatible with current map",
        10,
        "info"
    )
    return  -- This will stop the rest of the code from executing
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function getPositioningValues(style)
    local currentMap = tm.physics.GetMapName()
    
    if STYLES[style] and 
       STYLES[style].positioning and 
       STYLES[style].positioning[currentMap] then
        return STYLES[style].positioning[currentMap]
    end
    
    return {
        start_height = DEFAULT_START_HEIGHT,
        start_x = DEFAULT_START_X,
        start_z = DEFAULT_START_Z,
        view_platform_height = DEFAULT_VIEW_PLATFORM_HEIGHT,
        position_offset = {x = 0, y = 0, z = 0}
    }
end

local function cleanupDetailObjects()
    if detailObjects then
        for _, object in ipairs(detailObjects) do
            if object and object.Exists() then
                object.Despawn()
            end
        end
    end
    detailObjects = {}
end

local function spawnFromEntry(spawn, style)
    if not spawn then return end
    
    local pos = getPositioningValues(style)
    local offset = pos.position_offset or {x = 0, y = 0, z = 0}
    
    local position = tm.vector3.Create(
        tonumber(spawn.L[1]) + offset.x, 
        tonumber(spawn.L[2]) + offset.y, 
        tonumber(spawn.L[3]) + offset.z
    )
    
    local rotation = tm.vector3.Create(
        tonumber(spawn.R[1]), 
        tonumber(spawn.R[2]), 
        tonumber(spawn.R[3])
    )
    
    local gameObject
    local isCustom = string.find(tostring(spawn.Name), " ")
    
    if not isCustom then
        gameObject = tm.physics.SpawnObject(position, spawn.Name)
    else
        local name = spawn.Name
        local space = string.find(name, " ")
        local meshName = string.sub(name, space + 1) .. "Obj"
        local textureName = string.sub(name, 1, space - 1) .. "Tex"
        gameObject = tm.physics.SpawnCustomObjectConcave(position, meshName, textureName)
    end
    
    gameObject.GetTransform().SetRotation(rotation)
    
    if spawn.S and spawn.S ~= 1 then
        gameObject.GetTransform().SetScale(spawn.S)
    end
    
    if type(spawn.Static) == "boolean" then
        gameObject.SetIsStatic(spawn.Static)
    end
    
    if type(spawn.CanCollide) == "boolean" then
        gameObject.SetIsTrigger(not spawn.CanCollide)
    end
    
    if type(spawn.Visible) ~= "boolean" then
        spawn.Visible = true
    end
    gameObject.SetIsVisible(spawn.Visible)
    
    return gameObject
end

local function spawnViewPlatform()
    local currentMap = tm.physics.GetMapName()
    if viewPlatform and viewPlatform.Exists() then
        viewPlatform.Despawn()
    end
    
    local platformHeight
    local style = currentStyle or "tropical"  -- Fallback tropical if currentStyle is nil
    
    if STYLES[style] and 
       STYLES[style].positioning and 
       STYLES[style].positioning[currentMap] then
        platformHeight = STYLES[style].positioning[currentMap].view_platform_height
    else
        platformHeight = DEFAULT_VIEW_PLATFORM_HEIGHT
    end
    

    local pos = getPositioningValues(style)
    
    -- Create view platform
    viewPlatform = tm.physics.SpawnObject(
        tm.vector3.Create(pos.start_x, platformHeight, pos.start_z),
        "PFB_TestCollisionTimeline"
    )
    viewPlatform.GetTransform().SetScale(50,2,50)
    viewPlatform.SetIsVisible(false)
end

-- For custom meshes in detail files
local function loadCustomAssets(style)
    local fileName = STYLES[style].detailFile
    if not fileName then return end
    
    local file = tm.os.ReadAllText_Static(fileName)
    if file == "" then return end
    
    local jsonData = json.parse(file)
    if not jsonData or not jsonData.Spawns then return end
    
    -- Track what we've already loaded to avoid duplicates
    local loadedMeshes = {}
    local loadedTextures = {}
    
    -- List of textures that use jpg
    local jpgTextures = {
        "skyscraper2",
        "skyscraper3",
        "skyscraper4",
        "skyscraper6",
        "skyscraper8",
        "skyscraper10",
        "skyscraper11",
        "skyscraper13",
        "apartment5"
    }
    
    for _, spawnData in pairs(jsonData.Spawns) do
        if spawnData.Name then
            local isCustom = string.find(tostring(spawnData.Name), " ")
            if isCustom then
                local space = string.find(spawnData.Name, " ")
                local textureName = string.sub(spawnData.Name, 1, space - 1)
                local meshName = string.sub(spawnData.Name, space + 1)
                
                -- Load mesh if not already loaded
                if not loadedMeshes[meshName] then
                    tm.physics.AddMesh(meshName .. ".obj", meshName .. "Obj")
                    loadedMeshes[meshName] = true
                end
                
                -- Load texture if not already loaded
                if not loadedTextures[textureName] then
                    -- Check if this texture should use jpg
                    local useJpg = false
                    for _, jpgName in ipairs(jpgTextures) do
                        if textureName == jpgName then
                            useJpg = true
                            break
                        end
                    end
                    
                    local extension = useJpg and ".jpg" or ".png"
                    tm.physics.AddTexture(textureName .. extension, textureName .. "Tex")
                    loadedTextures[textureName] = true
                end
            end
        end
    end
end

-- Load custom assets for all styles
for styleName, _ in pairs(STYLES) do
    loadCustomAssets(styleName)
end

local function spawnDetailsFromFile(style)
    cleanupDetailObjects()
    currentStyle = style
    local fileName = STYLES[style].detailFile
    if not fileName then 
        return 
    end
    
    local file = tm.os.ReadAllText_Static(fileName)
    if file == "" then
        return
    end
    
    local jsonData = json.parse(file)
    if not jsonData or not jsonData.Spawns then
        return
    end
    
    local pos = getPositioningValues(style)
    local offset = pos.position_offset or {x = 0, y = 0, z = 0}
    
    local heightDifference = pos.start_height - DEFAULT_START_HEIGHT
    
    for _, spawnData in pairs(jsonData.Spawns) do
        if spawnData.Name and spawnData.L and spawnData.R then
            -- Apply both height difference and position offset
            local position = tm.vector3.Create(
                tonumber(spawnData.L[1]) + offset.x,
                tonumber(spawnData.L[2]) + heightDifference + offset.y,
                tonumber(spawnData.L[3]) + offset.z
            )
            
            local rotation = tm.vector3.Create(
                tonumber(spawnData.R[1]),
                tonumber(spawnData.R[2]),
                tonumber(spawnData.R[3])
            )
            
            local gameObject
            local isCustom = string.find(tostring(spawnData.Name), " ")
            
            if not isCustom then
                gameObject = tm.physics.SpawnObject(position, spawnData.Name)
            else
                local space = string.find(spawnData.Name, " ")
                local textureName = string.sub(spawnData.Name, 1, space - 1)
                local meshName = string.sub(spawnData.Name, space + 1)
                gameObject = tm.physics.SpawnCustomObject(position, meshName .. "Obj", textureName .. "Tex")
            end
            
            if gameObject then
                gameObject.GetTransform().SetRotation(rotation)
                
                if spawnData.S and spawnData.S ~= 1 then
                    gameObject.GetTransform().SetScale(spawnData.S)
                end
                
                if type(spawnData.Static) == "boolean" then
                    gameObject.SetIsStatic(spawnData.Static)
                end
                
                if type(spawnData.CanCollide) == "boolean" then
                    gameObject.SetIsTrigger(not spawnData.CanCollide)
                end
                
                if type(spawnData.Visible) ~= "boolean" then
                    spawnData.Visible = true
                end
                gameObject.SetIsVisible(spawnData.Visible)
                
                table.insert(detailObjects, gameObject)
            end
        end
    end
end

local function setTimeOfDay(style)
    local timeOfDay = STYLES[style].timeOfDay
    local setTime
    if type(timeOfDay) == "number" then
        setTime = timeOfDay
    elseif type(timeOfDay) == "table" and timeOfDay.min and timeOfDay.max then
        setTime = math.random(timeOfDay.min, timeOfDay.max)
    else
        setTime = 50 -- Default to midday if invalid
    end
    setTime = tonumber(setTime) or 50
    currentTimeOfDay = setTime
    tm.world.SetTimeOfDay(setTime)
    return setTime
end

local function parseObjFile(filename)
    local content = tm.os.ReadAllText_Static(filename)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for line in content:gmatch("[^\r\n]+") do
        local prefix, x, y, z = line:match("^(%S+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)")
        if prefix == "v" then
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
            minX, maxX = math.min(minX, x), math.max(maxX, x)
            minY, maxY = math.min(minY, y), math.max(maxY, y)
            minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
        end
    end

    return {
        width = (maxX - minX) * PIECE_SCALE,
        height = (maxY - minY) * PIECE_SCALE,
        length = (maxZ - minZ) * PIECE_SCALE
    }
end

local PIECE_SIZES = {}
for pieceType, _ in pairs(PIECES) do
    PIECE_SIZES[pieceType] = parseObjFile(pieceType .. ".obj")
end

-- Add meshes and textures
for pieceType, pieceData in pairs(PIECES) do
    tm.physics.AddMesh(pieceType .. ".obj", pieceType)
    if pieceData.texture then
        if type(pieceData.texture) == "table" then
            for style, texture in pairs(pieceData.texture) do
                tm.physics.AddTexture(texture, pieceType .. "_texture_" .. style)
            end
        else
            tm.physics.AddTexture(pieceData.texture, pieceType .. "_texture")
        end
    end
end

-- Add textures for all styles
for styleName, styleData in pairs(STYLES) do
    tm.physics.AddTexture(styleData.textureAtlas, "matlas_" .. styleName)
end

-- Add golfball textures
for _, textureName in ipairs(GOLFBALL_TEXTURES) do
    if textureName ~= "golfball_tm" then
        tm.physics.AddTexture(textureName .. ".jpg", textureName)
    end
end

local function isBallInHole(ballPosition, holePosition)
    local dx = ballPosition.x - holePosition.x
    local dy = ballPosition.y - holePosition.y
    local dz = ballPosition.z - holePosition.z
    local distanceSquared = dx*dx + dy*dy + dz*dz
    return distanceSquared <= HOLE_RADIUS * HOLE_RADIUS
end

local function spawnLightForPiece(piece, style)
    local piecePosition = piece.GetTransform().GetPosition()
    local lightPrefab = STYLES[style].lightPrefab or "PFB_SalvageItem_Ball"
    local lightHeightOffset = STYLES[style].lightHeightOffset or DEFAULT_LIGHT_HEIGHT_OFFSET
    
    local lightPosition = tm.vector3.Create(
        piecePosition.x,
        piecePosition.y + lightHeightOffset,
        piecePosition.z
    )
    
    local light = tm.physics.SpawnObject(lightPosition, lightPrefab)
    light.GetTransform().SetRotation(tm.vector3.Create(0,0,180))
    light.SetIsStatic(true)
    light.SetIsVisible(false)
    light.SetIsTrigger(true)
    
    table.insert(courseLights, light)
end

function isNightTime(currentTime)
    local timeValue = tonumber(currentTime)
    if not timeValue then
        return false
    end
    
    -- Adjust for circular time (0 to 100 scale)
    if timeValue > 100 then
        timeValue = timeValue % 100
    end
    
    local isNight = timeValue >= NIGHT_TIME_THRESHOLD_LOW or timeValue <= NIGHT_TIME_THRESHOLD_HIGH
    return isNight
end

local function spawnPiece(pieceType, gridX, gridY, rotation, height, style, currentTimeOfDay)
    local pos = getPositioningValues(style)
    
    -- Adjust grid coordinates to center the course
    local offset = math.floor(currentCourseLength / 2)  -- Center the course based on course length
    local worldX = pos.start_x + ((gridX - offset) * PIECE_DIMENSIONS * PIECE_SCALE)
    local worldZ = pos.start_z + ((gridY - offset) * PIECE_DIMENSIONS * PIECE_SCALE)
    
    -- Simple height calculation - just used the accumulated height value for sake of mind
    local yPosition = pos.start_height + height
    
    local position = tm.vector3.Create(
        worldX,
        yPosition,
        worldZ
    )
   
    local texture = PIECES[pieceType].texture and 
        (type(PIECES[pieceType].texture) == "table" 
            and pieceType .. "_texture_" .. style 
            or pieceType .. "_texture") 
        or "matlas_" .. style
   
    local piece = tm.physics.SpawnCustomObjectConcave(position, pieceType, texture)
    piece.GetTransform().SetScale(PIECE_SCALE)
   
    local yRotation = (rotation * 90) % 360
    piece.GetTransform().SetRotation(0, yRotation, 0)
    
    table.insert(coursePieces, piece)
    
    if currentTimeOfDay and isNightTime(currentTimeOfDay) then
        spawnLightForPiece(piece, style)
    end
 
    if pieceType == "mgoal" then
        local flagPosition = tm.vector3.Create(
            position.x,
            position.y + (PIECE_DIMENSIONS * PIECE_SCALE * 0.1) + FLAG_HEIGHT_OFFSET,
            position.z
        )
        
        local flag = tm.physics.SpawnObject(flagPosition, "PFB_FlagTwin")
        flag.GetTransform().SetScale(0.09)
        flag.GetTransform().SetRotation(0, yRotation, 0)
        table.insert(coursePieces, flag)
        
        holePosition = tm.vector3.Create(
            position.x,
            position.y + (PIECE_DIMENSIONS * PIECE_SCALE * 0.05),
            position.z
        )
        
        goalYPosition = position.y
    end
   
    return piece
 end

local function spawnDetails(piecePosition, pieceRotation, difficulty, pieceType, style)
    -- Check if piece type excludes details, no rogue bushes
    if PIECES[pieceType] and PIECES[pieceType].excludeDetails then
        return
    end
 
    local styleData = STYLES[style]
    local spawnedDetails = {}
    local minDetailDistance = 0.2 * PIECE_SCALE
    
    local function isValidPosition(x, z)
        for _, detail in ipairs(spawnedDetails) do
            local dx, dz = x - detail.x, z - detail.z
            if dx*dx + dz*dz < minDetailDistance*minDetailDistance then
                return false
            end
        end
        return true
    end
 
    local function spawnDetail(detailType, isComplexity)
        local pieceWidth = PIECE_SIZES[pieceType].width
        local pieceLength = PIECE_SIZES[pieceType].length
        local padding = (detailType.padding or 0.1) * PIECE_SCALE
        local attempts = 0
        local maxAttempts = 20
 
        while attempts < maxAttempts do
            local offsetX, offsetZ
            
            if pieceType == "mstraight" then
                offsetX = ((math.random() - 0.5) * 0.6 + (math.random() - 0.5) * 0.4) * pieceWidth * (1 - 2 * padding)
                offsetZ = ((math.random() - 0.5) * 0.6 + (math.random() - 0.5) * 0.4) * pieceLength * (1 - 2 * padding)
            else
                local radius = math.min(pieceWidth, pieceLength) * (0.4 - padding)
                local angle = math.random() * math.pi / 2
                offsetX = math.cos(angle) * radius * (0.6 + math.random() * 0.4)
                offsetZ = math.sin(angle) * radius * (0.6 + math.random() * 0.4)
            end
           
            local rotatedOffsetX = offsetX * math.cos(math.rad(pieceRotation)) - offsetZ * math.sin(math.rad(pieceRotation))
            local rotatedOffsetZ = offsetX * math.sin(math.rad(pieceRotation)) + offsetZ * math.cos(math.rad(pieceRotation))
            
            if isValidPosition(rotatedOffsetX, rotatedOffsetZ) then
                local randomScale = detailType.minScale + math.random() * (detailType.maxScale - detailType.minScale)
                
                local detailPosition = tm.vector3.Create(
                    piecePosition.x + rotatedOffsetX,
                    piecePosition.y + (PIECE_SIZES.mstraight.height * PIECE_SCALE) + detailType.heightOffset,
                    piecePosition.z + rotatedOffsetZ
                )
               
                local detail = tm.physics.SpawnObject(detailPosition, detailType.prefab)
                detail.GetTransform().SetScale(randomScale)
                detail.GetTransform().SetRotation(0, math.random() * 360, 0)
                table.insert(spawnedDetails, {x = rotatedOffsetX, z = rotatedOffsetZ})
                table.insert(coursePieces, detail)
                return
            end
            
            attempts = attempts + 1
        end
    end
 
    -- Spawn standard details
    for _, detailType in ipairs(styleData.details) do
        local detailCount = math.floor(math.random() * 3 + 2) * detailType.density
        for i = 1, detailCount do
            spawnDetail(detailType, false)
        end
    end
 
    -- Spawn difficulty-based details
    for _, detailType in ipairs(styleData.difficultyDetails) do
        local detailCount = math.floor(difficulty * detailType.multiplier * (0.5 + math.random() * 0.5))
        for i = 1, detailCount do
            spawnDetail(detailType, true)
        end
    end
end

local function getMaxCourseLength(style, difficulty)
    local styleData = STYLES[style]
    local maxLength = styleData.maxCourseLength
    
    -- Calculate length based on difficulty (1-10)
    local baseLength = 3 + math.floor(difficulty * 1.5)
    baseLength = math.min(baseLength, maxLength)
    
    -- Add random variation
    local variation = math.random(-1, 1)
    
    return math.min(baseLength + variation, maxLength)
end

local function generateRandomCourse(size, difficulty, style)

    -- Get course length based on style and difficulty
    local courseLength = getMaxCourseLength(style, difficulty)
    
    -- Increase grid size to give more room
    local gridSize = courseLength * 2
    local course = {}
    local directions = {
        {0, 1},  -- North 
        {1, 0},  -- East
        {0, -1}, -- South
        {-1, 0}  -- West
    }

    -- Initialize the grid
    for y = 1, gridSize do
        course[y] = {}
        for x = 1, gridSize do
            course[y][x] = {piece = "empty", rotation = 0, height = 0}
        end
    end

    local currentX = math.floor(gridSize / 2)
    local currentY = math.floor(gridSize / 2)
    local currentDir = 2  -- Start facing East
    local currentHeight = 0
    local lastPieceWasSlope = false
    local straightCount = 0
    local visited = {}
    local turnCount = 0
    local turnsOnCurrentLevel = 0
    local lastPieceWasPlank = false
    local lastPlankDirection = nil
    local remainingPieces = courseLength
    local maxIterations = remainingPieces * 3
    local MIN_TURNS = 1 + math.floor(difficulty * 0.3)
    local slopeChance = math.min(0.2 + (difficulty * 0.1), 0.5)
    local upwardSlopeChance = math.min(0 + (difficulty * 0.1), 0.3)
    local turnChance = math.min(TURN_PROBABILITY + (difficulty * 0.08), 0.4)
    local maxTurns = math.min(2 + math.floor(difficulty * 0.5), 5)

    local straightBeforeTurn = math.random(MIN_STRAIGHT_BEFORE_TURN, MAX_STRAIGHT_BEFORE_TURN)

    local placedPieces = {}
    local function addPiece(x, y, piece, rot, height)
        table.insert(placedPieces, {
            x = x,
            y = y,
            piece = piece,
            rotation = rot,
            height = height
        })
        course[y][x] = {
            piece = piece,
            rotation = rot,
            height = height
        }
        visited[y .. "," .. x] = true
    end

    local function shouldForceTurn()
        return straightCount >= straightBeforeTurn or 
               (turnCount < MIN_TURNS and remainingPieces <= 4) or
               (math.random() < turnChance and straightCount >= MIN_STRAIGHT_BEFORE_TURN)
    end
    
    
    -- Place the start piece
    addPiece(currentX, currentY, "mstart", currentDir, currentHeight)
    currentX = currentX + directions[currentDir][1]
    currentY = currentY + directions[currentDir][2]
    remainingPieces = remainingPieces - 1

    local iterations = 0
    while remainingPieces > 0 and iterations < maxIterations do
        iterations = iterations + 1
        
        if remainingPieces <= 1 then
            addPiece(currentX, currentY, "mgoal", currentDir, currentHeight)
            break
        end
        
        local nextX = currentX + directions[currentDir][1]
        local nextY = currentY + directions[currentDir][2]
        

        local function isSpaceOccupied(x, y, course)
            return course[y][x].piece ~= "empty"
        end
        
        local function canPlacePieceAt(x, y, gridSize, course)
            -- Check bounds
            if x <= 1 or x >= gridSize or y <= 1 or y >= gridSize then
                return false
            end
            
            -- Check if space is already occupied
            if isSpaceOccupied(x, y, course) then
                return false
            end
            
            -- Check adjacent cells (including diagonals) to prevent tight squeezes
            for dy = -1, 1 do
                for dx = -1, 1 do
                    local checkX = x + dx
                    local checkY = y + dy
                    if checkX > 0 and checkX <= gridSize and 
                       checkY > 0 and checkY <= gridSize and
                       isSpaceOccupied(checkX, checkY, course) and
                       not (dx == 0 and dy == 0) then
                        -- Allow connection to previous piece but prevent other adjacencies
                        if visited[checkY .. "," .. checkX] and
                           math.abs(dx) + math.abs(dy) > 1 then
                            return false
                        end
                    end
                end
            end
            
            return true
        end
        
        local canContinue = canPlacePieceAt(nextX, nextY, gridSize, course)

        if not canContinue or shouldForceTurn() then
            local newDir, turnPiece
            
            -- Try to turn even if can continue straight
            if canContinue then
                -- Calculate potential turn directions
                local leftDir = ((currentDir - 2) % 4) + 1
                local rightDir = (currentDir % 4) + 1
                local turnOptions = {}
                
                -- Check both turn directions
                local leftX = currentX + directions[leftDir][1]
                local leftY = currentY + directions[leftDir][2]
                if leftX > 1 and leftX < gridSize and leftY > 1 and leftY < gridSize and
                   not visited[leftY .. "," .. leftX] then
                    table.insert(turnOptions, {dir = leftDir, piece = "mcornerleft"})
                end
                
                local rightX = currentX + directions[rightDir][1]
                local rightY = currentY + directions[rightDir][2]
                if rightX > 1 and rightX < gridSize and rightY > 1 and rightY < gridSize and
                   not visited[rightY .. "," .. rightX] then
                    table.insert(turnOptions, {dir = rightDir, piece = "mcornerright"})
                end
                
                if #turnOptions > 0 then
                    local selected = turnOptions[math.random(#turnOptions)]
                    newDir = selected.dir
                    turnPiece = selected.piece
                end
            end
            
            if newDir then
                addPiece(currentX, currentY, turnPiece, currentDir, currentHeight)
                turnCount = turnCount + 1
                turnsOnCurrentLevel = turnsOnCurrentLevel + 1
                currentDir = newDir
                nextX = currentX + directions[currentDir][1]
                nextY = currentY + directions[currentDir][2]
                lastPieceWasSlope = false
                lastPieceWasPlank = false
                lastPlankDirection = nil
                straightCount = 0
                straightBeforeTurn = math.random(MIN_STRAIGHT_BEFORE_TURN, MAX_STRAIGHT_BEFORE_TURN)
            else
                addPiece(currentX, currentY, "mgoal", currentDir, currentHeight)
                break
            end
        else
            if math.random() < slopeChance and (not lastPieceWasSlope or math.random() < CONSECUTIVE_SLOPE_PROBABILITY) then
                if math.random() < upwardSlopeChance then
                    addPiece(currentX, currentY, "mupslope", currentDir, currentHeight)
                    currentHeight = currentHeight + SLOPE_HEIGHT_CHANGE
                else
                    addPiece(currentX, currentY, "mdownslope", currentDir, currentHeight)
                    currentHeight = currentHeight - SLOPE_HEIGHT_CHANGE
                end
                lastPieceWasSlope = true
                lastPieceWasPlank = false
                lastPlankDirection = nil
                straightCount = 0
                turnsOnCurrentLevel = 0
            else
                local availablePieces = {"mstraight"}
                for pieceType, pieceData in pairs(PIECES) do
                    if pieceData.minDifficulty and difficulty >= pieceData.minDifficulty then
                        local chanceMultiplier = pieceData.chanceMuliplier or 1
                        if math.random() < chanceMultiplier * difficulty then
                            local canAdd = true
                            if lastPlankDirection then
                                if pieceType == "mplankleft" and lastPlankDirection ~= "left" then
                                    canAdd = false
                                elseif pieceType == "mplankright" and lastPlankDirection ~= "right" then
                                    canAdd = false
                                elseif pieceType == "mplankcenter" and lastPlankDirection ~= "center" then
                                    canAdd = false
                                end
                            end
                            if canAdd then
                                table.insert(availablePieces, pieceType)
                            end
                        end
                    end
                end
                
                local nextPiece = availablePieces[math.random(#availablePieces)]
                addPiece(currentX, currentY, nextPiece, currentDir, currentHeight)
                
                if nextPiece == "mplankleft" then
                    lastPieceWasPlank = true
                    lastPlankDirection = "left"
                elseif nextPiece == "mplankright" then
                    lastPieceWasPlank = true
                    lastPlankDirection = "right"
                elseif nextPiece == "mplankcenter" then
                    lastPieceWasPlank = true
                    lastPlankDirection = "center"
                else
                    lastPieceWasPlank = false
                    lastPlankDirection = nil
                end
                
                straightCount = straightCount + 1
                lastPieceWasSlope = false
            end
        end

        if course[currentY][currentX].piece == "empty" then
            addPiece(currentX, currentY, "mstraight", currentDir, currentHeight)
        end

        currentX = nextX
        currentY = nextY
        remainingPieces = remainingPieces - 1
    end

    if remainingPieces > 0 and course[currentY][currentX].piece == "empty" then
        addPiece(currentX, currentY, "mgoal", currentDir, currentHeight)
    end
    
    
    return course
end

local function initializePlayerScore(playerId)
    playerScores[playerId] = {
        strokes = 0,
        finished = false
    }
end

function playBackgroundMusic(style)
    -- Stop current music if playing
    if currentMusicName then
        -- Stop the music/audio
        tm.audio.PlayAudioAtPosition("UI_InGameMenu_QuitToMain_click", tm.vector3.Create(0, 1000, 0), 0)
        tm.audio.PlayAudioAtPosition("ExplorationCheckpoint_music_stop", tm.vector3.Create(0, 1000, 0), 0)
    end

    local musicList = STYLES[style].music

    -- Calculate the center of the course or use a default position
    local musicPosition
    if globalStartPosition then
        local courseCenterX = globalStartPosition.x + (currentCourseLength * PIECE_SIZES.mstraight.length) / 2
        local courseCenterZ = globalStartPosition.z + (currentCourseLength * PIECE_SIZES.mstraight.length) / 2
        musicPosition = tm.vector3.Create(
            courseCenterX,
            globalStartPosition.y,
            courseCenterZ
        )
    else
        -- Use a default position if globalStartPosition is not set
        musicPosition = tm.vector3.Create(0, 1000, 0)
    end

    -- Play all music tracks at the same time
    for _, selectedMusic in ipairs(musicList) do
        tm.audio.PlayAudioAtPosition(selectedMusic, musicPosition, 0)
    end

    -- Store the last played music to handle future stopping
    currentMusicName = musicList[#musicList]  -- Just storing the last one for reference
end

local function spawnCourse(size, difficulty, style, startX, startZ, startHeight)
    currentStyle = style
    
    local pos = getPositioningValues(style)
    START_X = startX or pos.start_x
    START_Z = startZ or pos.start_z
    START_HEIGHT = startHeight or pos.start_height

    local currentMap = tm.physics.GetMapName()

    if STYLES[style].validMaps and not table.contains(STYLES[style].validMaps, currentMap) then
        style = "tropical"
        currentStyle = style  -- Update currentStyle if we default to tropical
        pos = getPositioningValues(style)  -- Update positioning values for new style
        START_X = startX or pos.start_x
        START_Z = startZ or pos.start_z
        START_HEIGHT = startHeight or pos.start_height
    end

    local currentTimeOfDay = setTimeOfDay(style)
    
    -- Spawn the view platform first
    spawnViewPlatform()
    
    -- Generate and spawn the course
    local actualSize = size * 2 
    local courseLayout = generateRandomCourse(actualSize, difficulty, style)
    
    for y, row in ipairs(courseLayout) do
        for x, piece in ipairs(row) do
            if piece.piece ~= "empty" then
                local pieceHeight = piece.height
                local spawnedPiece = spawnPiece(piece.piece, x - 1, y - 1, piece.rotation, pieceHeight, style, currentTimeOfDay)
                --spawnedPiece.GetTransform().SetScale(5)

                if piece.piece == "mstart" then
                    globalStartPosition = spawnedPiece.GetTransform().GetPosition()
                    globalStartRotation = spawnedPiece.GetTransform().GetRotation()
                end
               
                if not PIECES[piece.piece].texture then
                    local piecePosition = spawnedPiece.GetTransform().GetPosition()
                    spawnDetails(piecePosition, piece.rotation * 90, difficulty, piece.piece, style)
                end
            end
        end
    end

    -- Spawn style-specific details
    spawnDetailsFromFile(style)

    -- Handle player setup
    for _, playerId in ipairs(activePlayers) do
        if playerGolfBalls[playerId] and playerGolfBalls[playerId].Exists() then
            playerGolfBalls[playerId].GetTransform().SetPosition(
                globalStartPosition.x,
                globalStartPosition.y + 1,
                globalStartPosition.z
            )
        end
        
        local ballPosition = playerGolfBalls[playerId].GetTransform().GetPosition()
        local cameraPosition = tm.vector3.Create(
            ballPosition.x,
            ballPosition.y + 2,
            ballPosition.z
        )
        local cameraRotation = PPointing(tm.vector3.Create(0, 0, 0))
        
        tm.players.SetCameraPosition(playerId, cameraPosition)
        tm.players.SetCameraRotation(playerId, cameraRotation)
        playerCameraPositions[playerId] = cameraPosition
        playerCameraRotations[playerId] = tm.quaternion.Create(0, 0, 0)
        initializePlayerScore(playerId)
    end
    
    -- Play course spawn sound
    tm.audio.PlayAudioAtPosition("UI_Pickup_Secret", globalStartPosition, 0)
   
    if not isInitialCourse then
        -- Show the new course message for everyone when it's not the initial course
        tm.playerUI.AddSubtleMessageForAllPlayers(
            "New Course!",
            string.format("Biome: %s, Difficulty: %d", style, difficulty),
            6,
            "logo"
        )
    else
        -- For initial course, show message only for players who have completed selection
        for _, player in ipairs(tm.players.CurrentPlayers()) do
            local playerId = player.playerId
            if table.contains(activePlayers, playerId) then
                tm.playerUI.AddSubtleMessageForPlayer(
                    playerId,
                    "Course Info",
                    string.format("Biome: %s, Difficulty: %d", style, difficulty),
                    6,
                    "logo"
                )
            end
        end
        isInitialCourse = false  -- Mark that we're past the initial course
    end
end

local function getRandomStyle()
    -- Check for debug override first
    if DEBUG_FORCED_BIOME then
        -- Verify the forced biome exists
        if STYLES[DEBUG_FORCED_BIOME] then
            local currentMap = tm.physics.GetMapName()
            -- Check if the forced biome is valid for current map
            if STYLES[DEBUG_FORCED_BIOME].validMaps == nil or
               (type(STYLES[DEBUG_FORCED_BIOME].validMaps) == "table" and
                table.contains(STYLES[DEBUG_FORCED_BIOME].validMaps, currentMap)) then
                return DEBUG_FORCED_BIOME
            end
        end
        tm.playerUI.AddSubtleMessageForAllPlayers(
            "Debug Warning",
            "Forced biome '" .. DEBUG_FORCED_BIOME .. "' is invalid, using random selection",
            5,
            "info"
        )
    end

    local availableStyles = {}
    local currentMap = tm.physics.GetMapName()
    
    for style, styleData in pairs(STYLES) do
        local recentCount = 0
        for i = 1, math.min(STYLE_REPEAT_PREVENTION, #styleHistory) do
            if styleHistory[i] == style then
                recentCount = recentCount + 1
                break
            end
        end
        
        if recentCount == 0 then
            local isValidMap = styleData.validMaps == nil or 
                             (type(styleData.validMaps) == "table" and 
                              table.contains(styleData.validMaps, currentMap))
            
            if isValidMap then
                table.insert(availableStyles, style)
            end
        end
    end
    
    if #availableStyles == 0 then
        styleHistory = {}
        return getRandomStyle()
    end
    
    local selectedStyle = availableStyles[math.random(#availableStyles)]
    
    table.insert(styleHistory, 1, selectedStyle)
    if #styleHistory > STYLE_REPEAT_PREVENTION then
        table.remove(styleHistory)
    end
    
    return selectedStyle
end

local function incrementStrokes(playerId)
    if not playerScores[playerId].finished then
        playerScores[playerId].strokes = playerScores[playerId].strokes + 1
    end
end

local function getScoreType(strokes)
    local scoreDiff = strokes - PAR
    if strokes == 1 and scoreDiff == -2 then
        return "Hole-in-One"
    elseif scoreDiff == -3 then
        return "Albatross"
    elseif scoreDiff == -2 then
        return "Eagle"
    elseif scoreDiff == -1 then
        return "Birdie"
    elseif scoreDiff == 0 then
        return "Par"
    elseif scoreDiff == 1 then
        return "Bogey"
    elseif scoreDiff == 2 then
        return "Double Bogey"
    elseif scoreDiff == 3 then
        return "Triple Bogey"
    elseif scoreDiff == 4 then
        return "Quad Bogey"
    else
        return "Melvin's Mishap"
    end
end

local function updatePuttStrengthMessage(playerId, strength, chargeTime)
    if chargeTime and chargeTime >= MIN_CHARGE_TIME then
        local filledSegments = math.floor(strength * POWER_BAR_LENGTH)
        local powerBar = string.rep(POWER_BAR_CHAR, filledSegments) .. string.rep(EMPTY_BAR_CHAR, POWER_BAR_LENGTH - filledSegments)
        local message = powerBar
        
        -- Only play tick sound if there's exactly one player
        local golfBall = playerGolfBalls[playerId]
        if golfBall and golfBall.Exists() and #activePlayers == 1 then
            -- Store previous segments for comparison
            if not puttingPlayers[playerId].lastSegments then
                puttingPlayers[playerId].lastSegments = 0
            end
            
            -- If segments increased, play sound
            if filledSegments > puttingPlayers[playerId].lastSegments then
                tm.audio.PlayAudioAtGameobject("AVI_NPC_Intercom_Typing_BasicChirpo", golfBall)
            end
            
            -- Update last segments
            puttingPlayers[playerId].lastSegments = filledSegments
        end
        
        if subtleMessageIds[playerId] then
            tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, subtleMessageIds[playerId], message)
        else
            local id = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Putting", message, 9999, "logo")
            subtleMessageIds[playerId] = id
        end
    end
end

local function removePuttStrengthMessage(playerId)
    if subtleMessageIds[playerId] then
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, subtleMessageIds[playerId])
        subtleMessageIds[playerId] = nil
    end
end

local function spawnGolfBall(playerId)
    local offsetX = (playerId % 3 - 1) * 0.5
    local offsetZ = (math.floor(playerId / 3) % 3 - 1) * 0.5
    local spawnPosition = tm.vector3.Create(
        globalStartPosition.x + offsetX,
        globalStartPosition.y + 1,
        globalStartPosition.z + offsetZ
    )
    
    local texture = playerSelectedTextures[playerId] or GOLFBALL_TEXTURES[1]
    local golfBall = tm.physics.SpawnCustomObjectRigidbody(spawnPosition, "golfball", texture, false, 0.07)
    golfBall.GetTransform().SetScale(0.12)
    
    playerGolfBalls[playerId] = golfBall
    return golfBall
end

local function updateCamera(playerId)
    local golfBall = playerGolfBalls[playerId]
    local player = tm.players.GetPlayerGameObject(playerId)
    if not (golfBall and golfBall.Exists() and player) then return end
    
    -- Cache transform access
    local ballPosition = golfBall.GetTransform().GetPosition()
    local playerTransform = player.GetTransform()
    local forward = playerTransform.Forward()
    local playerRotation = playerTransform.GetRotation()
    
    -- Single vector creation for camera position
    local desiredCameraPosition = tm.vector3.Create(
        ballPosition.x - forward.x * CAMERA_DISTANCE,
        ballPosition.y + CAMERA_HEIGHT,
        ballPosition.z - forward.z * CAMERA_DISTANCE
    )
    
    -- Early initialization
    if not playerCameraPositions[playerId] then
        playerCameraPositions[playerId] = desiredCameraPosition
        playerCameraRotations[playerId] = tm.quaternion.Create(15, playerRotation.y, 0)
        return
    end
    
    -- Single lerp calculation
    local smoothedPosition = tm.vector3.Lerp(
        playerCameraPositions[playerId],
        desiredCameraPosition,
        CAMERA_POSITION_SMOOTHING
    )
    
    -- Single quaternion creation and slerp
    local desiredRotation = tm.quaternion.Create(15, playerRotation.y, 0)
    local smoothedRotation = tm.quaternion.Slerp(
        playerCameraRotations[playerId],
        desiredRotation,
        CAMERA_ROTATION_SMOOTHING
    )
    
    -- Single update to camera
    tm.players.SetCameraPosition(playerId, smoothedPosition)
    tm.players.SetCameraRotation(playerId, PPointing(smoothedRotation.GetEuler()))
    
    -- Single update to stored values
    playerCameraPositions[playerId] = smoothedPosition
    playerCameraRotations[playerId] = smoothedRotation
end

local BALL_MOVING_THRESHOLD = 0.00008  -- Further reduced threshold for movement
local POSITION_CHECK_INTERVAL = 0.06   -- Keep checking frequently
local VELOCITY_THRESHOLD = 6

local function isBallMoving(golfBall, playerId)
    if DISABLE_BALL_MOVEMENT_CHECK then return false end  -- Always return false if checks are disabled
    
    if not (golfBall and golfBall.Exists()) then return false end
    
    local currentTime = tm.os.GetTime()
    local ballData = previousBallPositions[playerId]
    
    -- Early return if no previous data
    if not ballData then
        previousBallPositions[playerId] = {
            position = golfBall.GetTransform().GetPosition(),
            time = currentTime,
            isMoving = false
        }
        return false
    end
    
    -- Early return if not enough time has passed
    if currentTime - ballData.time < POSITION_CHECK_INTERVAL then
        return ballData.isMoving
    end
    
    local currentPosition = golfBall.GetTransform().GetPosition()
    local dx = currentPosition.x - ballData.position.x
    local dy = currentPosition.y - ballData.position.y
    local dz = currentPosition.z - ballData.position.z
    
    -- Single division for velocity calculation
    local velocity = math.sqrt(dx*dx + dy*dy + dz*dz) / (currentTime - ballData.time)
    
    -- Single table creation
    previousBallPositions[playerId] = {
        position = currentPosition,
        time = currentTime,
        isMoving = velocity > VELOCITY_THRESHOLD
    }
    
    return previousBallPositions[playerId].isMoving
end

local function calculatePlayerSpawnPosition(playerId)
    local playerCount = #tm.players.CurrentPlayers()
    local gridSize = math.ceil(math.sqrt(playerCount))
    local row = math.floor((playerId - 1) / gridSize)
    local col = (playerId - 1) % gridSize
    
    local usableSize = 8  -- Increased platform size
    local cellSize = usableSize / gridSize
    
    local viewPlatformPosition = viewPlatform.GetTransform().GetPosition()
    return tm.vector3.Create(
        viewPlatformPosition.x + (col - (gridSize-1)/2) * cellSize,
        viewPlatformPosition.y + 2,
        viewPlatformPosition.z + (row - (gridSize-1)/2) * cellSize
    )
end

local function getPlayerStructureId(playerId)
    return "player_" .. playerId .. "_structure"
end

local function createTopDownCamera(playerId)
    -- Calculate actual course boundaries
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    local totalY = 0
    local pieceCount = 0
    
    for _, piece in ipairs(coursePieces) do
        if piece and piece.Exists() then
            local piecePos = piece.GetTransform().GetPosition()
            minX = math.min(minX, piecePos.x)
            maxX = math.max(maxX, piecePos.x)
            minZ = math.min(minZ, piecePos.z)
            maxZ = math.max(maxZ, piecePos.z)
            totalY = totalY + piecePos.y
            pieceCount = pieceCount + 1
        end
    end
    
    -- Calculate true course center
    local courseCenterX = (minX + maxX) / 2
    local courseCenterZ = (minZ + maxZ) / 2
    local averageY = totalY / pieceCount
    
    -- Calculate course dimensions
    local courseWidth = maxX - minX
    local courseLength = maxZ - minZ
    local courseDiagonal = math.sqrt(courseWidth * courseWidth + courseLength * courseLength)
    
    -- Set camera height based on difficulty
    local cameraHeight
    if currentDifficulty == 1 then
        cameraHeight = (courseDiagonal * 1.4) + averageY
    elseif currentDifficulty == 2 then
        cameraHeight = (courseDiagonal * 1.06) + averageY
    else
        cameraHeight = (courseDiagonal * 1.02) + averageY
    end
    
    local cameraPosition = tm.vector3.Create(
        courseCenterX,
        cameraHeight,
        courseCenterZ
    )
    
    local cameraRotation = PPointing(tm.vector3.Create(90, 0, 0))  -- Looking straight down
    
    tm.players.RemoveCamera(playerId)
    tm.players.AddCamera(playerId, cameraPosition, cameraRotation)
    tm.players.ActivateCamera(playerId, 0)
    playerTopDownCameras[playerId] = {position = cameraPosition, rotation = cameraRotation}
end

local function checkCourseCompletion()
    if isRegeneratingCourse then return end
    if #activePlayers == 0 then return end  -- No active players yet

    local allCompleted = true
    for _, playerId in ipairs(activePlayers) do
        if playerScores[playerId] and not playerScores[playerId].finished then
            allCompleted = false
            break
        end
    end
    
    if allCompleted and not courseCompletionTimer then
        courseCompletionTimer = tm.os.GetTime()
        return
    end

    if courseCompletionTimer and tm.os.GetTime() - courseCompletionTimer >= TOP_DOWN_VIEW_DURATION then
        
        isRegeneratingCourse = true
        courseCompletionTimer = nil
        
        -- Stop the current music
        if currentMusicName then
            tm.audio.PlayAudioAtPosition("UI_InGameMenu_QuitToMain_click", tm.vector3.Create(0, 1000, 0), 0)
            tm.audio.PlayAudioAtPosition("ExplorationCheckpoint_music_stop", tm.vector3.Create(0, 1000, 0), 0)
            currentMusicName = nil
        end

        -- Clear existing course pieces and lights
        for _, piece in ipairs(coursePieces) do
            if piece and piece.Exists() then
                piece.Despawn()
            end
        end
        coursePieces = {}

        for _, light in ipairs(courseLights) do
            if light and light.Exists() then
                light.Despawn()
            end
        end
        courseLights = {}
        
        -- Reset variables
        previousBallPositions = {}
        puttingPlayers = {}
        subtleMessageIds = {}
        holePosition = nil
        goalYPosition = nil
        golfBallRollingInfo = {}

        -- Increase difficulty and course length
        currentDifficulty = math.min(currentDifficulty + 1, MAX_DIFFICULTY)
        currentCourseLength = math.min(currentCourseLength + COURSE_LENGTH_INCREMENT, MAX_COURSE_LENGTH)
        
        -- Generate new course with increased difficulty and length
        local selectedStyle = getRandomStyle()
        spawnCourse(currentCourseLength, currentDifficulty, selectedStyle)
        
        -- Respawn players' structures and move golf balls
        for _, playerId in ipairs(activePlayers) do
            -- Despawn and respawn player structure
            local structureId = getPlayerStructureId(playerId)
            local structures = tm.players.GetSpawnedStructureById(structureId)
            if structures and #structures > 0 then
                tm.players.DespawnStructure(structureId)
            end
            
            -- Calculate new spawn position and respawn structure
            local playerSpawnPosition = calculatePlayerSpawnPosition(playerId)
            local structureBlueprint = "theviewer"
            tm.players.SpawnStructure(playerId, structureBlueprint, structureId, playerSpawnPosition, PPointing(tm.vector3.Create(0, 90, 0)))
            
            -- Place player in the new structure
            tm.players.PlacePlayerInSeat(playerId, structureId)
            
            -- Move existing golf ball to new start position
            local golfBall = playerGolfBalls[playerId]
            if golfBall and golfBall.Exists() then
                golfBall.SetIsStatic(false)  -- Make ball dynamic again
                golfBall.SetIsVisible(true)  -- Make ball visible again
                golfBall.GetTransform().SetPosition(
                    globalStartPosition.x,
                    globalStartPosition.y + 1,
                    globalStartPosition.z
                )
            else
                -- If for some reason the golf ball doesn't exist, spawn a new one
                playerGolfBalls[playerId] = spawnGolfBall(playerId)
            end
            
            -- Reset player score
            initializePlayerScore(playerId)

            -- Remove top-down camera and reset to original camera
            if playerTopDownCameras[playerId] then
                tm.players.RemoveCamera(playerId)
                playerTopDownCameras[playerId] = nil
            end

            -- Recreate original camera
            local ballPosition = playerGolfBalls[playerId].GetTransform().GetPosition()
            local cameraPosition = tm.vector3.Create(
                ballPosition.x,
                ballPosition.y + 2,
                ballPosition.z
            )
            local cameraRotation = PPointing(tm.vector3.Create(0, 0, 0))
            tm.players.AddCamera(playerId, cameraPosition, cameraRotation)
            tm.players.ActivateCamera(playerId, 0)

            playerCameraPositions[playerId] = cameraPosition
            playerCameraRotations[playerId] = tm.quaternion.Create(0, 0, 0)
        end
        
        isRegeneratingCourse = false
    end
end

function update()
    -- Handle initial delay
    if not hasInitializedGame then
        local currentTime = tm.os.GetTime()
        if not initialDelayTimer then
            initialDelayTimer = currentTime
            subtleMessageIds["countdown"] = tm.playerUI.AddSubtleMessageForAllPlayers(
                "Loading...",
                "Starting in " .. INITIAL_START_DELAY .. " seconds",
                INITIAL_START_DELAY,
                "info"
            )
            return
        end
        
        local timeRemaining = INITIAL_START_DELAY - (currentTime - initialDelayTimer)
        if timeRemaining > 0 then
            if subtleMessageIds["countdown"] then
                tm.playerUI.SubtleMessageUpdateMessageForAll(
                    subtleMessageIds["countdown"],
                    "Starting in " .. math.ceil(timeRemaining) .. " seconds"
                )
            end
            return
        end
        
        if subtleMessageIds["countdown"] then
            tm.playerUI.RemoveSubtleMessageForAll(subtleMessageIds["countdown"])
            subtleMessageIds["countdown"] = nil
            hasInitializedGame = true
            spawnCourse(currentCourseLength, currentDifficulty, getRandomStyle())
            for _, player in ipairs(tm.players.CurrentPlayers()) do
                startTextureSelection(player.playerId)
            end
        end
        return
    end

    if isRegeneratingCourse then return end

    local currentTime = tm.os.GetTime()
    
    for _, playerId in ipairs(activePlayers) do
        local puttingData = puttingPlayers[playerId]
        local golfBall = playerGolfBalls[playerId]
        
        -- Update putting charge
        if puttingData and puttingData.lastUpdateTime and 
           currentTime - puttingData.lastUpdateTime >= UPDATE_INTERVAL then
            local chargeTime = currentTime - puttingData.startTime
            puttingData.lastUpdateTime = currentTime
            
            if chargeTime >= MAX_CHARGE_TIME then
                releasePutt(playerId)
            else
                updatePuttStrengthMessage(playerId, chargeTime / MAX_CHARGE_TIME, chargeTime)
            end
        end

        -- Handle ball and player updates
        if golfBall and golfBall.Exists() then
            local player = tm.players.GetPlayerGameObject(playerId)
            if player then
                local structureId = getPlayerStructureId(playerId)
                
                -- Ensure player is seated
                if not tm.players.IsPlayerInSeat(playerId) then
                    local structures = tm.players.GetSpawnedStructureById(structureId)
                    if structures and #structures > 0 then
                        tm.players.PlacePlayerInSeat(playerId, structureId)
                    end
                end

                -- Update camera if not finished
                if not playerScores[playerId].finished then
                    updateCamera(playerId)
                end
                
                -- Handle rolling behavior
                local rollingInfo = golfBallRollingInfo[playerId]
                if rollingInfo then
                    local elapsedTime = currentTime - rollingInfo.startTime
                    if elapsedTime < rollingInfo.duration then
                        local rollFactor = (1 - (elapsedTime / rollingInfo.duration))^2
                        local rollPower = rollingInfo.power * rollFactor
                        golfBall.AddForce(
                            rollingInfo.direction.x * rollPower,
                            0,
                            rollingInfo.direction.z * rollPower
                        )
                    else
                        golfBallRollingInfo[playerId] = nil
                    end
                end
                
                -- Handle hole and out of bounds checks
                if holePosition and not playerScores[playerId].finished then
                    local ballPosition = golfBall.GetTransform().GetPosition()
                    
                    if isBallInHole(ballPosition, holePosition) then
                        if puttingPlayers[playerId] then
                            removePuttStrengthMessage(playerId)
                            puttingPlayers[playerId] = nil
                        end
                        
                        golfBallRollingInfo[playerId] = nil
                        playerScores[playerId].finished = true
                        
                        -- Make ball static and invisible when in hole
                        golfBall.SetIsStatic(true)
                        golfBall.SetIsVisible(false)
                        
                        local score = playerScores[playerId].strokes
                        local scoreType = getScoreType(score)
                        
                        -- Play different sounds based on score type

                        if scoreType == "Hole-in-One" then
                            tm.audio.PlayAudioAtPosition("LvlObj_ConfettiCelebration", holePosition, 5)
                            tm.playerUI.AddSubtleMessageForAllPlayers(
                                tm.players.GetPlayerName(playerId) .. " got " .. scoreType .. "!",
                                "",
                                10,
                                "flag"
                            )
                        else
                            tm.audio.PlayAudioAtPosition("UI_CookBook_stepComplete", holePosition, 5)
                            tm.playerUI.AddSubtleMessageForAllPlayers(
                                tm.players.GetPlayerName(playerId) .. " scored " .. score,
                                "",
                                10,
                                "flag"
                            )    
                        end

                        --if scoreType == "Melvin's Mishap" then
                          --  tm.audio.PlayAudioAtPosition("AVI_NPC_Intercom_Chirpo_Civillian_Default", holePosition, 5)
                        --elseif scoreType == "Hole-in-One" then
                        --    tm.audio.PlayAudioAtPosition("LvlObj_ConfettiCelebration", holePosition, 5)
                        --else
                         --   tm.audio.PlayAudioAtPosition("UI_CookBook_stepComplete", holePosition, 5)
                       -- end
                    
                        createTopDownCamera(playerId)
                        tm.players.ActivateCamera(playerId, 1)
                        
                    elseif ballPosition.y < goalYPosition - FALL_OFFSET then
                        if puttingPlayers[playerId] then
                            removePuttStrengthMessage(playerId)
                            puttingPlayers[playerId] = nil
                        end
                        
                        golfBallRollingInfo[playerId] = nil
                        golfBall.SetIsStatic(true)
                        golfBall.GetTransform().SetPosition(
                            globalStartPosition.x,
                            globalStartPosition.y + 1,
                            globalStartPosition.z
                        )
                        golfBall.SetIsStatic(false)
                        
                        incrementStrokes(playerId)
                        tm.audio.PlayAudioAtGameobject("LvlObj_TeleportStation_disable", golfBall)

                        local structures = tm.players.GetSpawnedStructureById(structureId)
                        if structures and #structures > 0 then
                            tm.players.DespawnStructure(structureId)
                        end
                        
                        local playerSpawnPosition = calculatePlayerSpawnPosition(playerId)
                        tm.players.SpawnStructure(playerId, "theviewer", structureId, 
                            playerSpawnPosition, PPointing(tm.vector3.Create(0, 90, 0)))
                        tm.players.PlacePlayerInSeat(playerId, structureId)
                        
                        tm.playerUI.AddSubtleMessageForPlayer(
                            playerId,
                            "Out of Bounds",
                            "+1 stroke!",
                            3,
                            "info"
                        )
                    end
                end
            end
        end
    end

    if not isRegeneratingCourse then
        checkCourseCompletion()
    end
end

function handleMouseClick(playerId)
    if not table.contains(activePlayers, playerId) or 
       (playerScores[playerId] and playerScores[playerId].finished) then
        return
    end
    local golfBall = playerGolfBalls[playerId]
    if not isBallMoving(golfBall, playerId) then
        if not puttingPlayers[playerId] then
            chargePutt(playerId)
        else
            releasePutt(playerId)
        end
    else
        tm.playerUI.AddSubtleMessageForPlayer(
            playerId,
            "Ball Moving",
            "Wait, your ball's still moving!",
            0.3,
            "info"
        )
    end
end

function chargePutt(playerId)
    local golfBall = playerGolfBalls[playerId]
    if not playerScores[playerId].finished then
        if not isBallMoving(golfBall, playerId) then
            -- Remove any existing putting message
            removePuttStrengthMessage(playerId)
            
            puttingPlayers[playerId] = {
                startTime = tm.os.GetTime(),
                lastUpdateTime = tm.os.GetTime(),
                mouseInitiated = true,
                lastSegments = 0  -- Initialize lastSegments
            }
            
        else
            local currentTime = tm.os.GetTime()
            if not lastBallMovingMessageTime[playerId] or currentTime - lastBallMovingMessageTime[playerId] >= 1 then
                tm.playerUI.AddSubtleMessageForPlayer(
                    playerId,
                    "Ball Moving",
                    "Wait, your ball's still moving!",
                    0.5,
                    "info"
                )
                lastBallMovingMessageTime[playerId] = currentTime
            end
        end
    end
end

function releasePutt(playerId)
    if puttingPlayers[playerId] and not playerScores[playerId].finished then
        local chargeTime = tm.os.GetTime() - puttingPlayers[playerId].startTime
        
        -- Check if minimum charge time has been met
        if chargeTime < MIN_CHARGE_TIME then
            -- If released too quickly, just clear putting state without executing the putt
            removePuttStrengthMessage(playerId)
            if puttingPlayers[playerId] then
                puttingPlayers[playerId].lastSegments = nil
            end
            puttingPlayers[playerId] = nil
            return
        end
        
        -- Continue with normal putt logic
        chargeTime = math.min(chargeTime, MAX_CHARGE_TIME)
        local power = (chargeTime / MAX_CHARGE_TIME) * MAX_PUTT_POWER
        local golfBall = playerGolfBalls[playerId]
        local player = tm.players.GetPlayerGameObject(playerId)
        
        if golfBall and golfBall.Exists() and player then
            local playerTransform = player.GetTransform()
            local playerForward = playerTransform.Forward()
            
            -- Normalize the forward vector for consistent direction
            local magnitude = math.sqrt(playerForward.x * playerForward.x + playerForward.z * playerForward.z)
            playerForward = tm.vector3.Create(
                playerForward.x / magnitude,
                0,
                playerForward.z / magnitude
            )
            
            -- Apply main force
            local forceVector = tm.vector3.Create(playerForward.x * power, 0, playerForward.z * power)
            golfBall.AddForceImpulse(forceVector.x, forceVector.y, forceVector.z)
            
            -- Apply slight upward force
            local upForce = power * 0.25
            golfBall.AddForceImpulse(0, upForce, 0)

            -- Play putt sound
            tm.audio.PlayAudioAtGameobject("LvlObj_Landmine_reset", golfBall)

            -- Start rolling behavior
            golfBallRollingInfo[playerId] = {
                direction = playerForward,
                power = power * 1.1,
                startTime = tm.os.GetTime(),
                duration = 3.1
            }
            
            incrementStrokes(playerId)
        end
        
        removePuttStrengthMessage(playerId)
        if puttingPlayers[playerId] then
            puttingPlayers[playerId].lastSegments = nil
        end
        puttingPlayers[playerId] = nil
    end
end

local function spawnPreviewBall(playerId)
   -- Use player's current position as base
   local player = tm.players.GetPlayerGameObject(playerId)
   local playerPos = player.GetTransform().GetPosition()
  
   -- Position the ball slightly in front and above the player
   local position = tm.vector3.Create(
       playerPos.x,
       playerPos.y + 30,  -- Lift ball above player
       playerPos.z
   )
  
   -- Spawn the preview ball
   local previewBall = tm.physics.SpawnCustomObjectRigidbody(position, "golfball", GOLFBALL_TEXTURES[1], true, 0.07)
   previewBall.GetTransform().SetRotation(tm.vector3.Create(180, 90, 0))
   previewBall.GetTransform().SetScale(0.18)
   previewBall.SetIsStatic(true)
  
   -- Get time from the current style
   local timeToUse = currentTimeOfDay or 50  -- Use stored time or default to 50
   
   local shouldSpawnLight = isNightTime(timeToUse)

   if shouldSpawnLight then
       local ballPosition = previewBall.GetTransform().GetPosition()
       local lightPosition = tm.vector3.Create(
           ballPosition.x,
           ballPosition.y + 1,
           ballPosition.z - 3.5
       )
       local thelight = tm.physics.SpawnObject(lightPosition, "PFB_PowerCoreCrate")
       thelight.GetTransform().SetRotation(tm.vector3.Create(0, 0, 180))
       thelight.GetTransform().SetScale(1)
       thelight.SetIsStatic(true)
       thelight.SetIsVisible(false)
       playerPreviewLights[playerId] = thelight
   end
  
   playerPreviewBalls[playerId] = previewBall
   playerTextureIndex[playerId] = 1
  
   return previewBall
end

local function cycleTexture(playerId, direction)
    local currentIndex = playerTextureIndex[playerId]
    local newIndex = currentIndex + direction
    if newIndex < 1 then
        newIndex = #GOLFBALL_TEXTURES
    elseif newIndex > #GOLFBALL_TEXTURES then
        newIndex = 1
    end
    playerTextureIndex[playerId] = newIndex
    
    local previewBall = playerPreviewBalls[playerId]
    if previewBall and previewBall.Exists() then
        previewBall.SetTexture(GOLFBALL_TEXTURES[newIndex])
    end
end

function cycleTextureLeft(playerId)
    cycleTexture(playerId, -1)
end

function cycleTextureRight(playerId)
    cycleTexture(playerId, 1)
end

function selectTexture(playerId)
    local selectedIndex = playerTextureIndex[playerId]
    playerSelectedTextures[playerId] = GOLFBALL_TEXTURES[selectedIndex]
    
    -- Remove preview ball and light
    local previewBall = playerPreviewBalls[playerId]
    if previewBall and previewBall.Exists() then
        previewBall.Despawn()
    end
    playerPreviewBalls[playerId] = nil

    local previewLight = playerPreviewLights[playerId]
    if previewLight and previewLight.Exists() then
        previewLight.Despawn()
    end
    playerPreviewLights[playerId] = nil
    -- Remove both messages
    if subtleMessageIds[playerId] then
        if subtleMessageIds[playerId].controls then
            tm.playerUI.RemoveSubtleMessageForPlayer(playerId, subtleMessageIds[playerId].controls)
        end
        if subtleMessageIds[playerId].selection then
            tm.playerUI.RemoveSubtleMessageForPlayer(playerId, subtleMessageIds[playerId].selection)
        end
        subtleMessageIds[playerId] = nil
    end

    -- Start the game for this player
    setupPlayerForGame(playerId)
end

function resetPlayer(playerId)
    -- Check if player is active and hasn't finished the hole
    if not table.contains(activePlayers, playerId) or 
       (playerScores[playerId] and playerScores[playerId].finished) then
        return
    end

    local golfBall = playerGolfBalls[playerId]
    if golfBall and golfBall.Exists() then
        -- Reset ball position
        golfBall.SetIsStatic(true)
        golfBall.GetTransform().SetPosition(
            globalStartPosition.x,
            globalStartPosition.y + 1,
            globalStartPosition.z
        )
        golfBall.SetIsStatic(false)
        
        -- Reset any putting state
        if puttingPlayers[playerId] then
            removePuttStrengthMessage(playerId)
            puttingPlayers[playerId] = nil
        end
        
        -- Reset rolling info
        golfBallRollingInfo[playerId] = nil
        
        -- Reset score
        playerScores[playerId].strokes = 0
        
        -- Reset camera
        local ballPosition = golfBall.GetTransform().GetPosition()
        local cameraPosition = tm.vector3.Create(
            ballPosition.x,
            ballPosition.y + 2,
            ballPosition.z
        )
        local cameraRotation = PPointing(tm.vector3.Create(0, 0, 0))
        
        tm.players.SetCameraPosition(playerId, cameraPosition)
        tm.players.SetCameraRotation(playerId, cameraRotation)
        playerCameraPositions[playerId] = cameraPosition
        playerCameraRotations[playerId] = tm.quaternion.Create(0, 0, 0)
        
        -- Show reset message
        tm.playerUI.AddSubtleMessageForPlayer(
            playerId,
            "Ball Reset",
            "Ball and putt count reset!",
            3,
            "info"
        )
    end
end

function setupPlayerForGame(playerId)
    if not hasInitializedGame then
        return  -- Don't set up player until game has initialized
    end
    
    if isRegeneratingCourse then
        -- Wait for the course to finish regenerating
        local waitTime = 0
        while isRegeneratingCourse and waitTime < 5 do  -- 5 second timeout
            waitTime = waitTime + 0.1
        end
    end

    local playerSpawnPosition = calculatePlayerSpawnPosition(playerId)

    if playerId == 0 then
        tm.audio.PlayAudioAtPosition("UI_InGameMenu_QuitToMain_click", tm.vector3.Create(0, 1000, 0), 0)
        playBackgroundMusic(currentStyle)
    end
    
    tm.players.SetSpawnPoint(playerId, SPAWN_LOCATION_ID, playerSpawnPosition, tm.vector3.Create(0, 0, 0))
    tm.players.SetPlayerSpawnLocation(playerId, SPAWN_LOCATION_ID)

    local structureId = getPlayerStructureId(playerId)
    local structureBlueprint = "theviewer"
    tm.players.SpawnStructure(playerId, structureBlueprint, structureId, playerSpawnPosition, PPointing(tm.vector3.Create(0, 90, 0)))
    
    tm.players.PlacePlayerInSeat(playerId, structureId)

    local golfBall = spawnGolfBall(playerId)
    
    local ballPosition = golfBall.GetTransform().GetPosition()
    local cameraPosition = tm.vector3.Create(
        ballPosition.x,
        ballPosition.y + 2,
        ballPosition.z
    )
    local cameraRotation = PPointing(tm.vector3.Create(0, 0, 0))
    
    -- Remove any existing cameras
    tm.players.RemoveCamera(playerId)
    
    -- Add and activate the new camera
    tm.players.AddCamera(playerId, cameraPosition, cameraRotation)
    tm.players.ActivateCamera(playerId, 0)

    playerCameraPositions[playerId] = cameraPosition
    playerCameraRotations[playerId] = tm.quaternion.Create(0, 0, 0)
    
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "chargePutt", "space")
    tm.input.RegisterFunctionToKeyUpCallback(playerId, "releasePutt", "space")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "resetPlayer", "`")

    initializePlayerScore(playerId)
    
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, "Select Golfball")
    tm.playerUI.AddSubtleMessageForPlayer(
        playerId,
        "",
        "Hold Space to putt, Mouse to aim",
        5,
        "info"
    )

    -- Add initial course info message if this is still the first course
    if isInitialCourse then
        tm.playerUI.AddSubtleMessageForPlayer(
            playerId,
            "Course Info",
            string.format("Biome: %s, Difficulty: %d", currentStyle, currentDifficulty),
            6,
            "logo"
        )
    end

    -- Add this player to the active players list
    table.insert(activePlayers, playerId)
end

function handleSpaceKeyPress(playerId)
    if not table.contains(activePlayers, playerId) then
        selectTexture(playerId)
    else
        if not puttingPlayers[playerId] then
            chargePutt(playerId)
        else
            releasePutt(playerId)
        end
    end
end

function startTextureSelection(playerId)
    -- First seat the player
    local structureId = getPlayerStructureId(playerId)
    local structureBlueprint = "theviewer"
    local playerSpawnPosition = calculatePlayerSpawnPosition(playerId)
    
    -- Spawn and seat player first
    tm.players.SpawnStructure(playerId, structureBlueprint, structureId, playerSpawnPosition, PPointing(tm.vector3.Create(0, 90, 0)))
    tm.players.PlacePlayerInSeat(playerId, structureId)
    
    -- Now spawn the preview ball
    local previewBall = spawnPreviewBall(playerId)
   
    local ballPosition = previewBall.GetTransform().GetPosition()
    -- Position camera to look at the ball
    local cameraPosition = tm.vector3.Create(
        ballPosition.x,
        ballPosition.y + 0.4,
        ballPosition.z - 1.2
    )
    
    local cameraRotation = PPointing(tm.vector3.Create(20, 0, 0))
    tm.players.AddCamera(playerId, cameraPosition, cameraRotation)
    tm.players.ActivateCamera(playerId, 0)
   
    -- Register input controls
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "cycleTextureLeft", "left")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "cycleTextureRight", "right")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "handleSpaceKeyPress", "space")
    tm.playerUI.RegisterMouseDownPositionCallback(playerId, function(position)
        handleMouseClick(playerId)
    end)

    -- Initialize message storage
    if not subtleMessageIds[playerId] then
        subtleMessageIds[playerId] = {}
    end
    
    local controlsMessageId = tm.playerUI.AddSubtleMessageForPlayer(
        playerId,
        "Space to select",
        "Use left/right arrow to cycle",
        9999,
        "info"
    )
    subtleMessageIds[playerId].controls = controlsMessageId

    -- Add selection header message, prompt the player to select the ball in the preview
    local selectionMessageId = tm.playerUI.AddSubtleMessageForPlayer(
        playerId,
        "Pick Your Golf Ball!",
        "",
        9999,
        "info"
    )
    subtleMessageIds[playerId].selection = selectionMessageId

    -- Add welcome message
    tm.playerUI.AddSubtleMessageForPlayer(
        playerId,
        "Trailmakers Minigolf",
        "Have fun!, Mod by TerrorSoul",
        6,
        "logo"
    )
end

tm.players.OnPlayerJoined.add(function(player)
    local playerId = player.playerId
    tm.players.SetBuilderEnabled(playerId, false)
    tm.players.SetRepairEnabled(playerId, false)
    if player.playerId ~= 0 then
        tm.playerUI.AddSubtleMessageForAllPlayers(
            "",
            tm.players.GetPlayerName(playerId) .. " joined",
            3,
            "info"
        )
    end
    if hasInitializedGame then
        startTextureSelection(playerId)
    end
end)

tm.players.OnPlayerLeft.add(function(player)
    local playerId = player.playerId
    
    -- Clean up player's golf ball
    if playerGolfBalls[playerId] and playerGolfBalls[playerId].Exists() then
        playerGolfBalls[playerId].Despawn()
    end
    
    -- Clean up player's preview ball
    if playerPreviewBalls[playerId] and playerPreviewBalls[playerId].Exists() then
        playerPreviewBalls[playerId].Despawn()
    end

    -- Clean up player's preview light
    if playerPreviewLights[playerId] and playerPreviewLights[playerId].Exists() then
        playerPreviewLights[playerId].Despawn()
    end
    
    -- Clean up player's structure
    local structureId = getPlayerStructureId(playerId)
    local structures = tm.players.GetSpawnedStructureById(structureId)
    if structures and #structures > 0 then
        tm.players.DespawnStructure(structureId)
    end
    
    -- Remove from active players
    for i, pid in ipairs(activePlayers) do
        if pid == playerId then
            table.remove(activePlayers, i)
            break
        end
    end
    
    -- Clear player data
    playerGolfBalls[playerId] = nil
    playerPreviewBalls[playerId] = nil
    playerPreviewLights[playerId] = nil
    playerSelectedTextures[playerId] = nil
    playerTextureIndex[playerId] = nil
    playerScores[playerId] = nil
    playerCameraPositions[playerId] = nil
    playerCameraRotations[playerId] = nil
    previousBallPositions[playerId] = nil
    puttingPlayers[playerId] = nil
    golfBallRollingInfo[playerId] = nil
    playerTopDownCameras[playerId] = nil
    lastBallMovingMessageTime[playerId] = nil
end)

-- Pointing function to convert Euler angles to a rotation vector (Thanks again to Jess for this function :))
function PPointing(rotation)
    local RotXRad = math.rad(rotation.x)
    local RotYRad = math.rad(rotation.y)
    local VectorX = math.sin(RotYRad) * math.cos(RotXRad)
    local VectorY = math.sin(RotXRad) * -1
    local VectorZ = math.cos(RotYRad) * math.cos(RotXRad)
    return tm.vector3.Create(VectorX, VectorY, VectorZ)
end