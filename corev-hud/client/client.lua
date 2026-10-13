local plyPed = cache.ped
local plyVeh = cache.vehicle
local plyId  = PlayerId()

lib.onCache('ped',     function(value) plyPed = value end)
lib.onCache('vehicle', function(value) plyVeh = value end)

local InventoryBridge = (function()
    local inv = Config.Inventory

    if inv == 'ox_inventory' then
        return {
            itemIdFromHash = function(weaponHash)
                local w = exports.ox_inventory:getCurrentWeapon()
                if w and w.hash == weaponHash then return w.name end
                return false
            end,
            itemImage = function(itemId)
                return ('nui://ox_inventory/web/images/%s.png'):format(itemId)
            end,
            hasEnoughOfItem = function(itemName, amount)
                return (exports.ox_inventory:Search('count', itemName) or 0) >= amount
            end,
        }

    elseif inv == 'qb-inventory' then
        return {
            itemIdFromHash = function(weaponHash)
                local items = exports['qb-inventory']:getUserInventory()
                if not items then return false end
                for _, item in pairs(items) do
                    if item.info and item.info.hash == weaponHash then return item.name end
                end
                return false
            end,
            itemImage = function(itemId)
                return ('nui://qb-inventory/html/images/%s.png'):format(itemId)
            end,
            hasEnoughOfItem = function(itemName, amount)
                return exports['qb-inventory']:HasItem(itemName, amount)
            end,
        }

    elseif inv == 'qs-inventory' then
        return {
            itemIdFromHash = function(weaponHash)
                return exports['qs-inventory']:getItemFromWeapon(weaponHash)
            end,
            itemImage = function(itemId)
                return ('nui://qs-inventory/html/images/%s.png'):format(itemId)
            end,
            hasEnoughOfItem = function(itemName, amount)
                return (exports['qs-inventory']:getItemCount(itemName) or 0) >= amount
            end,
        }

    elseif inv == 'corev_inventory' then
        return {
            itemIdFromHash = function(weaponHash)
                return exports.corev_inventory:itemIdFromHash(weaponHash)
            end,
            itemImage = function(itemId)
                return exports.corev_inventory:itemImage(itemId)
            end,
            hasEnoughOfItem = function(itemName, amount)
                return exports.corev_inventory:hasEnoughOfItem(itemName, amount)
            end,
        }

    elseif inv == 'custom' then
        return Config.CustomInventoryBridge

    else
        print(('[corev_hud] WARNING: Unknown Config.Inventory "%s". Weapon HUD disabled.'):format(inv))
        return {
            itemIdFromHash  = function() return false end,
            itemImage       = function() return ""    end,
            hasEnoughOfItem = function() return false end,
        }
    end
end)()

local ambulanceResourceActive = false

if Config.AmbulanceJobResource then
    ambulanceResourceActive = GetResourceState(Config.AmbulanceJobResource) == 'started'
    AddEventHandler('onResourceStart', function(r)
        if r == Config.AmbulanceJobResource then ambulanceResourceActive = true end
    end)
    AddEventHandler('onResourceStop', function(r)
        if r == Config.AmbulanceJobResource then ambulanceResourceActive = false end
    end)
end

local function IsAmbulanceActive()
    if not Config.AmbulanceJobResource then return true end
    return ambulanceResourceActive
end

local function GetNitrousLevel(veh)
    if not Config.Nitrous then return 0 end
    return exports[Config.Nitrous]:getNitrousLevel(veh) or 0
end

local DisplayAmmoThisFrame             = DisplayAmmoThisFrame
local DisableControlAction             = DisableControlAction
local DisplayRadar                     = DisplayRadar
local DrawRect                         = DrawRect
local GetAmmoInPedWeapon               = GetAmmoInPedWeapon
local GetAmmoInClip                    = GetAmmoInClip
local GetActiveScreenResolution        = GetActiveScreenResolution
local GetAspectRatio                   = GetAspectRatio
local GetEntityHealth                  = GetEntityHealth
local GetEntityHeading                 = GetEntityHeading
local GetEntitySpeed                   = GetEntitySpeed
local GetEntityCoords                  = GetEntityCoords
local GetLabelText                     = GetLabelText
local GetPedArmour                     = GetPedArmour
local GetPlayerUnderwaterTimeRemaining = GetPlayerUnderwaterTimeRemaining
local GetStreetNameAtCoord             = GetStreetNameAtCoord
local GetStreetNameFromHashKey         = GetStreetNameFromHashKey
local GetNameOfZone                    = GetNameOfZone
local GetVehicleCurrentRpm             = GetVehicleCurrentRpm
local GetVehicleEngineHealth           = GetVehicleEngineHealth
local GetIsVehicleEngineRunning        = GetIsVehicleEngineRunning
local GetVehicleFuelLevel              = GetVehicleFuelLevel
local GetVehicleCurrentGear            = GetVehicleCurrentGear
local HideHudComponentThisFrame        = HideHudComponentThisFrame
local IsBigmapActive                   = IsBigmapActive
local IsPauseMenuActive                = IsPauseMenuActive
local IsScreenFadedOut                 = IsScreenFadedOut
local IsScreenFadingOut                = IsScreenFadingOut
local NetworkIsActivitySpectator       = NetworkIsActivitySpectator
local NetworkIsPlayerTalking           = NetworkIsPlayerTalking
local ResetScriptGfxAlign              = ResetScriptGfxAlign
local SetVehicleCurrentRpm             = SetVehicleCurrentRpm

local string_byte = string.byte
local math_abs    = math.abs
local math_ceil   = math.ceil

local HUD = {

    isOpen          = false,
    carHud          = false,
    seatBelt        = false,
    fuelAlarm       = false,
    radioActive     = false,
    inventoryActive = true,
    blackbars       = false,
    compassActive   = false,
    carControls     = false,
    sniper          = false,
    carhudPos       = Config.DefaultCarHudPosition or 'right',
    HarnessVehicles = {},

    ToggleNui = function(self, open)
        self.isOpen = open
        SendReactMessage('setVisible', open)
        DisplayRadar(open)
    end,

    GetMinimapPosition = function(self)
        local minimap = {}
        local resX, resY  = GetActiveScreenResolution()
        local aspectRatio = GetAspectRatio()
        local scaleX      = 1 / resX
        local scaleY      = 1 / resY
        local minimapRawX, minimapRawY

        SetScriptGfxAlign(string_byte('L'), string_byte('B'))

        if IsBigmapActive() then
            minimapRawX, minimapRawY = GetScriptGfxPosition(-0.003975, 0.022 + (-0.460416666))
            minimap.width  = scaleX * (resX / (2.52 * aspectRatio))
            minimap.height = scaleY * (resY / 2.3374)
        else
            minimapRawX, minimapRawY = GetScriptGfxPosition(-0.0045, 0.002 + (-0.188888))
            minimap.width  = scaleX * (resX / (4 * aspectRatio))
            minimap.height = scaleY * (resY / 5.674)
        end

        ResetScriptGfxAlign()

        minimap.rightX  = minimapRawX + minimap.width
        minimap.bottomY = minimapRawY + minimap.height

        return minimap
    end,

    InfoThread = function(self)
        while true do
            Wait(1000)
            local hidden = IsPauseMenuActive()
                        or IsScreenFadedOut()
                        or IsScreenFadingOut()
                        or self.blackbars
            SendReactMessage('setPauseMenu', hidden)
        end
    end,

    UnarmedHash = `WEAPON_UNARMED`,

    StatusThread = function(self)
        while true do
            Wait(250)

            if self.carHud or self.compassActive then
                SendReactMessage('setLocation', self:GetLocation())
            end

            local armed         = self.inventoryActive and GetSelectedPedWeapon(plyPed) or self.UnarmedHash
            local itemId        = armed ~= self.UnarmedHash and InventoryBridge.itemIdFromHash(armed) or false
            local weaponImage   = itemId and InventoryBridge.itemImage(itemId) or ""
            local pedWeapon     = weaponImage ~= "" and GetSelectedPedWeapon(plyPed) or false
            local weaponMaxAmmo = pedWeapon and GetAmmoInPedWeapon(plyPed, pedWeapon) or 0
            local _, weaponClipAmmo = GetAmmoInClip(plyPed, pedWeapon)

            local map     = self:GetMinimapPosition()
            local rightX  = map.rightX  * 100
            local bottomY = map.bottomY * 100

            local localState = LocalPlayer.state
            local hunger = localState[Config.StateBagHunger] or 100
            local thirst = localState[Config.StateBagThirst] or 100
            local stress = localState[Config.StateBagStress] or 0

            local isAmb      = IsAmbulanceActive()
            local isBleeding = isAmb and (localState.bloodLevel or 0) > 0 or false
            local isLimp     = isAmb and (localState.isLimp or false) or false

            SendReactMessage('setStatusData', {
                isTalking     = NetworkIsPlayerTalking(plyId),
                voiceLevel    = localState.proximity and localState.proximity.index or 1,
                radioActive   = self.radioActive,
                hunger        = math_ceil(hunger),
                thirst        = math_ceil(thirst),
                stress        = math_ceil(stress),
                health        = GetEntityHealth(plyPed) - 100,
                armor         = GetPedArmour(plyPed),
                isBleeding    = isBleeding,
                isCaffeinated = localState.caffeinated,
                isLimp        = isLimp,
                weapon        = self.MovingHud and 'advancedrifle.png' or weaponImage,
                maxAmmo       = weaponMaxAmmo - weaponClipAmmo,
                clipAmmo      = weaponClipAmmo,
                rightX        = rightX,
                bottomY       = bottomY,
                oxygen        = GetPlayerUnderwaterTimeRemaining(plyId) * 10,
            })
        end
    end,

    ToggleCarHud = function(self)
        SendReactMessage('setCarHud', self.carHud)
    end,

    CarFuelAlarm = function(self)
        CreateThread(function()
            if self.fuelAlarm then return end
            self.fuelAlarm = true
            NotifyBridge.SendAlert('error', 'Low Fuel', 2500)
            for _ = 0, 4 do
                PlaySound(-1, "5_SEC_WARNING", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
                Wait(250)
            end
            Wait(60000)
            self.fuelAlarm = false
        end)
    end,

    ToggleBelt = function(self)
        local plyVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if not DoesEntityExist(plyVehicle) or plyVehicle == 0 then return end

        local speed = (GetPedInVehicleSeat(plyVehicle, -1) == PlayerPedId())
                      and GetEntitySpeed(plyVehicle) * 2.236936 or 0

        if speed > Config.SeatbeltMaxSpeed then
            NotifyBridge.SendAlert('inform', 'Too high speed to toggle seatbelt')
            return
        end

        if self.HarnessVehicles[VehToNet(plyVehicle)] then
            NotifyBridge.SendAlert('inform', 'You have a harness on')
            return
        end

        self.seatBelt = not self.seatBelt

        NotifyBridge.SendAlert(
            self.seatBelt and 'success' or 'error',
            self.seatBelt and 'Seat Belt Enabled' or 'Seat Belt Disabled'
        )
    end,

    Directions = {
        [0]   = 'N',  [45]  = 'NW', [90]  = 'W',  [135] = 'SW',
        [180] = 'S',  [225] = 'SE', [270] = 'E',  [315] = 'NE',
        [360] = 'N',
    },

    GetLocation = function(self)
        local plyPos = GetEntityCoords(plyPed)
        local x, y, z = plyPos.x, plyPos.y, plyPos.z

        local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(x, y, z)
        local currentStreetName   = GetStreetNameFromHashKey(currentStreetHash)
        local intersectStreetName = GetStreetNameFromHashKey(intersectStreetHash)

        local zone = tostring(GetNameOfZone(x, y, z)) or 'UNKNOWN'
        local area = GetLabelText(zone)
        local playerLocation = area

        if intersectStreetName and intersectStreetName ~= '' then
            playerLocation = currentStreetName .. ' | ' .. intersectStreetName .. ' | [ ' .. area .. ' ]'
        elseif currentStreetName and currentStreetName ~= '' then
            playerLocation = currentStreetName .. ' | [ ' .. area .. ' ]'
        end

        local direction = ''
        local heading   = GetEntityHeading(plyPed)

        for k, v in pairs(self.Directions) do
            if math_abs(heading - k) < 22.5 then
                direction = v
                break
            end
        end

        return '[' .. direction .. '] ' .. playerLocation
    end,

    CarThread = function(self)
        self.carhudPos = GetResourceKvpString('carhudpos') or Config.DefaultCarHudPosition or 'right'

        while true do
            local showRadar = (plyVeh and not self.blackbars and self.isOpen)
                           or NetworkIsActivitySpectator()

            DisplayRadar(showRadar)

            if not plyVeh then
                if self.carHud then
                    self.carHud = false
                    self:ToggleCarHud()
                end
                if self.seatBelt then self.seatBelt = false end
            else
                if not self.carHud then
                    self.carHud = true
                    self:ToggleCarHud()
                end

                local rpm = GetVehicleCurrentRpm(plyVeh)
                if rpm < 0.2 then rpm = 0.2 end

                if rpm > 0.2 and not GetIsVehicleEngineRunning(plyVeh) then
                    SetVehicleCurrentRpm(plyVeh, 0.0)
                end

                local currentRpm = (((rpm * 270 - 160.2)) / 80) * 100
                local fuel = GetVehicleFuelLevel(plyVeh)

                if fuel < Config.FuelLowThreshold then self:CarFuelAlarm() end

                SendReactMessage('setVehicleData', {
                    speed       = math_ceil(GetEntitySpeed(plyVeh) * 2.236936),
                    gear        = GetVehicleCurrentGear(plyVeh),
                    rpm         = currentRpm,
                    fuel        = fuel,
                    engineAlert = GetVehicleEngineHealth(plyVeh) <= 500,
                    seatBelt    = self.seatBelt,
                    nitrous     = GetNitrousLevel(plyVeh),
                    position    = self.carhudPos,
                    visible     = not (self.carhudPos == 'center' and self.carControls),
                })

                if self.seatBelt then
                    DisableControlAction(0, 75, true)
                end
            end

            Wait(self.carHud and 30 or 500)
        end
    end,

    IdleCam = function()
        while true do
            Wait(Config.IdleCamInterval or 15000)
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()
        end
    end,

    HideAmmo = function(self)
        while true do
            Wait(0)
            if not self.sniper then HideHudComponentThisFrame(14) end
            DisplayAmmoThisFrame(false)
            if self.blackbars then
                DrawRect(0.0, 0.0, 2.0, 0.13, 0, 0, 0, 255)
                DrawRect(0.0, 1.0, 2.0, 0.13, 0, 0, 0, 255)
            end
        end
    end,

    UpdateHarnessVehicles = function(self, data)
        self.HarnessVehicles = data
    end,

    Compass = function(self, toggle)
        self.compassActive = (toggle ~= nil) and toggle or (not self.compassActive)
        SendReactMessage('setCompass', self.compassActive)
    end,

    MoveCarHud = function(self, position)
        local newState = position == 'center' and 'center' or 'right'
        SetResourceKvp('carhudpos', newState)
        self.carhudPos = newState
    end,

    MovingHud = false,

    MoveHud = function(self, state)
        local newState = (state ~= nil) and state or (not self.MovingHud)

        SetNuiFocus(newState, newState)
        SendReactMessage('setMovingHud', newState)
        self.MovingHud = newState

        if not newState then
            NotifyBridge.SendAlert('success', 'HUD location saved', 5000)
            return
        end

        NotifyBridge.SendAlert('inform', 'Drag around the HUD to move it, hit ESC to save. Use /resethud to reset position.', 5000)
    end,

    CompassReadability = function(self, size)
        local newSize = size and tonumber(size) or 18
        SendReactMessage('setCompassSize', newSize)
        NotifyBridge.SendAlert('success', 'Compass text size adjusted', 4000)
    end,
}

RegisterNUICallback('stopMovingHud', function(_, cb)
    HUD:MoveHud(false)
    cb('ok')
end)

CreateThread(function()
    Wait(100)
    HUD:ToggleNui(true)
end)

CreateThread(function() Wait(500) HUD:InfoThread() end)
CreateThread(function() Wait(500) HUD:CarThread() end)
CreateThread(function() Wait(500) HUD:StatusThread() end)
CreateThread(function() HUD:IdleCam() end)
CreateThread(function() HUD:HideAmmo() end)

RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', 'B')
RegisterCommand('-seatbelt', function() end, false)
RegisterCommand('seatbelt',  function() HUD:ToggleBelt() end, false)

RegisterCommand('togglehud', function()
    HUD:ToggleNui(not HUD.isOpen)
end, false)

RegisterCommand('blackbars', function()
    HUD.blackbars = not HUD.blackbars
    TriggerEvent('chat:toggleChat', HUD.blackbars)
end, false)

RegisterCommand('carhud', function(_, args)
    HUD:MoveCarHud(args[1])
end, false)

RegisterCommand('movehud', function(_, args)
    HUD:MoveHud(args[1])
end, false)

RegisterCommand('compassreadability', function(_, args)
    HUD:CompassReadability(args[1])
end, false)

RegisterCommand('resethud', function()
    SendReactMessage('setHudPosition', { x = 0, y = 0 })
end, false)

TriggerEvent('chat:addSuggestion', '/carhud', 'Move the Car HUD to center or right.', {
    { name = 'center/right', help = 'Target position for the Car HUD.' },
})
TriggerEvent('chat:addSuggestion', '/compassreadability', 'Set the compass text size.', {
    { name = 'Size', help = 'Size in pixels, e.g. 16' },
})
TriggerEvent('chat:addSuggestion', '/togglehud', 'Show or hide the HUD.')
TriggerEvent('chat:addSuggestion', '/blackbars', 'Toggle cinematic black bars (also hides chat).')

exports('toggleNui', function(...) return HUD:ToggleNui(...) end)
exports('IsHarness', function(targetVeh) return HUD.HarnessVehicles[VehToNet(targetVeh)] or false end)
exports('seatBeltActive', function() return HUD.seatBelt end)

AddEventHandler('harness', function(toggle)
    local plyVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not plyVehicle or plyVehicle == 0 or not toggle then return end
    TriggerServerEvent('harness', VehToNet(plyVehicle))
end)

RegisterNetEvent('newHarness', function(newData) HUD:UpdateHarnessVehicles(newData) end)

RegisterNetEvent('pma-voice:radioActive', function(talking)
    HUD.radioActive = talking
end)

if Config.CarControlsEvent then
    AddEventHandler(Config.CarControlsEvent, function(toggle) HUD.carControls = toggle end)
end

if Config.ProgressBarEvent then
    AddEventHandler(Config.ProgressBarEvent, function(toggle) HUD.carControls = toggle end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == Config.Inventory then HUD.inventoryActive = true end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == Config.Inventory then HUD.inventoryActive = false end
end)

AddEventHandler('corev_hud:toggleLandHud', function(sentToggle) HUD:Compass(sentToggle) end)
AddEventHandler('corev_hud:togglesniper',  function(sniper) HUD.sniper = sniper end)
