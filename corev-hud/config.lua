--[[
    ╔══════════════════════════════════════════════════════════╗
    ║              CoreV HUD - Configuration File              ║
    ║                                                          ║
    ║  Edit the values below to match your server setup.       ║
    ║  No other files need to be touched for basic config.     ║
    ╚══════════════════════════════════════════════════════════╝
]]

Config = {}

-- ─────────────────────────────────────────────────────────────
--  INVENTORY BRIDGE
--  Supported values:
--    'ox_inventory'     → ox_inventory (overextended)
--    'qb-inventory'     → QBCore inventory
--    'qs-inventory'     → Quasar inventory
--    'corev_inventory'  → CoreV inventory
--    'custom'           → Use the custom bridge below
-- ─────────────────────────────────────────────────────────────
Config.Inventory = 'ox_inventory'

-- ─────────────────────────────────────────────────────────────
--  NOTIFICATIONS
--  Supported values:
--    'ox_lib'            → ox_lib notify (lib.notify)
--    'corev_notify'      → CoreV notifications
--    'custom'            → Use the custom handler below
-- ─────────────────────────────────────────────────────────────
Config.Notifications = 'ox_lib'

-- ─────────────────────────────────────────────────────────────
--  NITROUS BRIDGE
--  Resource that exposes getNitrousLevel(vehicle).
--  Set to false to disable the nitrous bar on the car HUD.
-- ─────────────────────────────────────────────────────────────
Config.Nitrous = false

-- ─────────────────────────────────────────────────────────────
--  AMBULANCE JOB RESOURCE
--  The name of the ambulance job resource running on your server.
--  The HUD uses this to show bleeding / injury status icons
--  only when relevant (the resource must be running).
--
--  Supported values:
--    'qbx_ambulancejob'   → QBox ambulance job
--    'qb-ambulancejob'    → QBCore ambulance job
--    'esx_ambulancejob'   → ESX ambulance job
--    'corev_ambulancejob' → CoreV ambulance job
--    false                → Always show medical status icons
-- ─────────────────────────────────────────────────────────────
Config.AmbulanceJobResource = 'qbx_ambulancejob'

-- ─────────────────────────────────────────────────────────────
--  CAR CONTROLS / PROGRESSBAR
--  Events that signal when car controls or a progress bar are
--  active so the center car HUD can be hidden automatically.
--  Set to false to skip.
-- ─────────────────────────────────────────────────────────────
Config.CarControlsEvent = 'corev_carcontrols:toggle'
Config.ProgressBarEvent = 'corev_progressbar:visible'

-- ─────────────────────────────────────────────────────────────
--  HUNGER / THIRST / STRESS STATEBAG KEYS
--  The statebag keys your framework sets on LocalPlayer.state.
--  Values are expected in the range 0-100.
--
--  qbx_core  → 'hunger', 'thirst', 'stress'
--  qb-core   → 'hunger', 'thirst', 'stress'
-- ─────────────────────────────────────────────────────────────
Config.StateBagHunger = 'hunger'
Config.StateBagThirst = 'thirst'
Config.StateBagStress = 'stress'
Config.FuelLowThreshold = 12

-- ─────────────────────────────────────────────────────────────
--  SEATBELT SPEED LIMIT
--  Maximum speed in MPH at which a player may toggle seatbelt.
-- ─────────────────────────────────────────────────────────────
Config.SeatbeltMaxSpeed = 50

-- ─────────────────────────────────────────────────────────────
--  DEFAULT CAR HUD POSITION
--  Supported values: 'right' | 'center'
-- ─────────────────────────────────────────────────────────────
Config.DefaultCarHudPosition = 'right'

-- ─────────────────────────────────────────────────────────────
--  IDLE CAM INTERVAL (milliseconds)
--  How often to invalidate the idle camera.
-- ─────────────────────────────────────────────────────────────
Config.IdleCamInterval = 15000

-- ─────────────────────────────────────────────────────────────
--  CUSTOM INVENTORY BRIDGE
--  Only used when Config.Inventory = 'custom'.
-- ─────────────────────────────────────────────────────────────
Config.CustomInventoryBridge = {

    itemIdFromHash = function(weaponHash)
        return false
    end,

    itemImage = function(itemId)
        return ""
    end,

    hasEnoughOfItem = function(itemName, amount)
        return false
    end,

}

-- ─────────────────────────────────────────────────────────────
--  CUSTOM NOTIFICATION BRIDGE
--  Only used when Config.Notifications = 'custom'.
--  type values: 'success' | 'error' | 'inform'
-- ─────────────────────────────────────────────────────────────
Config.CustomNotificationBridge = {

    SendAlert = function(notifType, message, duration)
        print(('[corev_hud] Notify [%s]: %s'):format(notifType, message))
    end,

}
