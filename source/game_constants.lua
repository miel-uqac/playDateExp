GameConstants = {
    STATE_MENU = 0,
    STATE_PLAYING = 1,
    STATE_GAMEOVER = 2,

    SCREEN_WIDTH = 400,
    SCREEN_HEIGHT = 240,

    PLAYER_SCALE = 0.05,
    PLAYER_IMAGE_PATH = "assets/Fleur",
    PLAYER_HITBOX_RADIUS = 10,

    SAW_IMAGE_PATH = "assets/Scie",
    SAW_ROTATION_SPEED = 180,
    SAW_SIZE_MIN = 0.5,
    SAW_SIZE_MAX = 1,

    POT_IMAGE_PATH = "assets/PotDeFleur",
    POT_DEFAULT_SIZE = 24,
    POT_WARNING_DURATION_MS = 1500,
    POT_FALL_SPEED = 180,
    POT_WARNING_BOX_SIZE = 25,
    POT_WARNING_BOX_Y = 10,

    -- Fréquence et difficulté des obstacles
    OBSTACLE_SPAWN_INTERVAL_START = 5000,
    OBSTACLE_SPAWN_INTERVAL_MIN = 3500,
    OBSTACLE_DIFFICULTY_STEP = 1000,
    OBSTACLE_DIFFICULTY_REDUCTION = 250,
    OBSTACLE_SAW_SPAWN_CHANCE = 0.7,

    -- Fond et menu
    BG_MENU_PATH = "assets/Background/MontagneMainMenu",
    BG_MOUNTAINS_PATH = "assets/Background/MontagneInGame",
    BG_MOUNTAINS_SCALE = 1,
    MENU_CLOUD_LEFT_Y = 12,
    MENU_CLOUD_RIGHT_Y = 95,

    BG_LAYER1_IMAGES = {
        "assets/Background/BigCloud2",
        "assets/Background/MoyenCloud2",
        "assets/Background/LittleCloud",
    },
    BG_LAYER1_SCALE = 1,
    BG_LAYER1_PARALLAX_SPEED = 0.08,
    BG_LAYER1_MARGIN = 20,
    BG_LAYER1_COUNT_MIN = 2,
    BG_LAYER1_COUNT_MAX = 4,
    BG_LAYER1_HARD_CAP = 60,
    BG_LAYER1_SPAWN_CLIMB = 800,

    BONUS_SIZE = 35,
    BONUS_SPAWN_INTERVAL = 1000,
    BONUS_SCORE_MULTIPLIER = 2,
    BONUS_DURATION_SECONDS = 6.0,

    -- Musiques et sons
    MUSIC_MENU_PATH = "assets/audio/music_menu",
    MUSIC_GAME_PATH = "assets/audio/music_game",
    SOUND_GAMEOVER_PATH = "assets/audio/gameover",

    SPEED = 60,
    TURN_RATE = 0.02,
    SMOOTH_DIR = 0.18,
    SCROLL_SPEED = 28,
    MIN_STEP_DISTANCE = 3,
    MAX_STEM_POINTS = 260,
    PATH_SMOOTH = 0.25,
    STEM_RADIUS = 2,
    
    LEAF_IMAGE_PATHS = {
        "assets/Feuille",
        "assets/Feuille2"
    },
    LEAF_SPAWN_CHANCE = 50,

    HEAD_CLAMP_X_MARGIN = 5,
    HEAD_CLAMP_TOP = 10,
    HEAD_CLAMP_BOTTOM_PADDING = 100,

    WATER_HEIGHT = 20,
}