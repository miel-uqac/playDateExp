import "game_constants"

Background = {}

local Config = GameConstants
local graphics <const> = playdate.graphics

local mountainImage = nil
local foregroundCloudLayer = nil

local menuBackgroundImage = nil
local menuTitleImage = nil
local menuLeftCloudImage = nil
local menuRightCloudImage = nil

local function createParallaxLayer(config)
    local layer = {
        images = {},
        clouds = {},
        spawnAccumulator = 0,
        config = config,
        imageWidth = 0,
        imageHeight = 0,
    }
    for _, path in ipairs(config.imagePaths) do
        local loaded = graphics.image.new(path)
        if loaded then
            table.insert(layer.images, loaded:scaledImage(config.scale))
        end
    end
    if #layer.images > 0 then
        layer.imageWidth, layer.imageHeight = layer.images[1]:getSize()
    end
    return layer
end

local function cloudsOverlap(layer, x1, y1, x2, y2)
    local w = layer.imageWidth
    local h = layer.imageHeight
    local margin = layer.config.margin
    return not (
        x1 + w + margin < x2 or x2 + w + margin < x1 or
        y1 + h + margin < y2 or y2 + h + margin < y1
    )
end

local function buildLayerSlots(layer, minY, maxY)
    local slots = {}
    local stepX = layer.imageWidth + layer.config.margin * 2
    local stepY = layer.imageHeight + layer.config.margin * 2
    local yMin = minY or (-layer.imageHeight)
    local yMax = maxY or (Config.SCREEN_HEIGHT - layer.imageHeight)
    for y = yMin, yMax, stepY do
        for x = -layer.imageWidth, Config.SCREEN_WIDTH, stepX do
            slots[#slots + 1] = { x = x, y = y }
        end
    end
    for i = #slots, 2, -1 do
        local j = math.random(i)
        slots[i], slots[j] = slots[j], slots[i]
    end
    return slots
end

local function placeLayerCloud(layer, cloud, minY, maxY)
    local slots = buildLayerSlots(layer, minY, maxY)
    for _, slot in ipairs(slots) do
        local overlaps = false
        for _, other in ipairs(layer.clouds) do
            if other ~= cloud and cloudsOverlap(layer, slot.x, slot.y, other.x, other.y) then
                overlaps = true
                break
            end
        end
        if not overlaps then
            cloud.x = slot.x
            cloud.y = slot.y
            return true
        end
    end
    return false
end

local function respawnLayerCloud(layer, cloud)
    local h = layer.imageHeight
    local placed = placeLayerCloud(layer, cloud, -h * 4, -h)
    if not placed then
        cloud.x = math.random(-layer.imageWidth, Config.SCREEN_WIDTH - layer.imageWidth)
        cloud.y = math.random(-h * 4, -h)
    end
    cloud.speed = 0.7 + math.random() * 0.6
    cloud.imageIndex = math.random(#layer.images)
end

local function resetLayer(layer)
    layer.clouds = {}
    layer.spawnAccumulator = 0
    if #layer.images == 0 then return end
    local count = math.random(layer.config.countMin, layer.config.countMax)
    for i = 1, count do
        local cloud = {}
        layer.clouds[i] = cloud
        local placed = placeLayerCloud(layer, cloud)
        if not placed then
            cloud.x = math.random(-layer.imageWidth, Config.SCREEN_WIDTH - layer.imageWidth)
            cloud.y = math.random(-layer.imageHeight, Config.SCREEN_HEIGHT - layer.imageHeight)
        end
        cloud.speed = 0.7 + math.random() * 0.6
        cloud.imageIndex = math.random(#layer.images)
    end
end

local function spawnLayerCloudFromTop(layer)
    if #layer.clouds >= layer.config.hardCap then return end
    local cloud = {}
    layer.clouds[#layer.clouds + 1] = cloud
    respawnLayerCloud(layer, cloud)
end

function Background.load()
    local loadedMountain = graphics.image.new(Config.BG_MOUNTAINS_PATH)
    if loadedMountain then
        mountainImage = loadedMountain:scaledImage(Config.BG_MOUNTAINS_SCALE)
    end

    menuBackgroundImage = graphics.image.new(Config.BG_MENU_PATH)

    foregroundCloudLayer = createParallaxLayer({
        imagePaths = Config.BG_LAYER1_IMAGES,
        scale = Config.BG_LAYER1_SCALE,
        parallaxSpeed = Config.BG_LAYER1_PARALLAX_SPEED,
        margin = Config.BG_LAYER1_MARGIN,
        countMin = Config.BG_LAYER1_COUNT_MIN,
        countMax = Config.BG_LAYER1_COUNT_MAX,
        hardCap = Config.BG_LAYER1_HARD_CAP,
        spawnClimb = Config.BG_LAYER1_SPAWN_CLIMB,
    })
end

function Background.reset()
    resetLayer(foregroundCloudLayer)
end

function Background.drawMenu()
    if menuBackgroundImage then 
        menuBackgroundImage:draw(0, 0) 
    end
end

function Background.update(scrollOffset, climbDelta)
    if mountainImage then mountainImage:draw(0, 0) end

    if #foregroundCloudLayer.images == 0 then return end

    if climbDelta > 0 then
        foregroundCloudLayer.spawnAccumulator = foregroundCloudLayer.spawnAccumulator + climbDelta
        while foregroundCloudLayer.spawnAccumulator >= foregroundCloudLayer.config.spawnClimb do
            foregroundCloudLayer.spawnAccumulator = foregroundCloudLayer.spawnAccumulator - foregroundCloudLayer.config.spawnClimb
            spawnLayerCloudFromTop(foregroundCloudLayer)
        end
    end

    local h = foregroundCloudLayer.imageHeight
    for i = 1, #foregroundCloudLayer.clouds do
        local cloud = foregroundCloudLayer.clouds[i]
        if cloud.x and cloud.y and cloud.speed then
            cloud.y = cloud.y + (scrollOffset * foregroundCloudLayer.config.parallaxSpeed * cloud.speed)
            if cloud.y < -h - 20 or cloud.y > Config.SCREEN_HEIGHT + 20 then
                respawnLayerCloud(foregroundCloudLayer, cloud)
            end
            local img = foregroundCloudLayer.images[cloud.imageIndex or 1]
            if img then img:draw(cloud.x, cloud.y) end
        end
    end
end