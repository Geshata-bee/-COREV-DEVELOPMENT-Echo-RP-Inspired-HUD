local plyPed = cache.ped
local plyVeh = cache.vehicle
local plyId  = PlayerId()

local plyWep = nil

lib.onCache('ped',     function(v) plyPed = v end)
lib.onCache('vehicle', function(v) plyVeh = v end)

AddEventHandler('ox_inventory:currentWeapon', function(data)
    plyWep = data and data.hash or nil
end)

local math_random = math.random
local math_ceil   = math.ceil
local math_max    = math.max
local math_min    = math.min

local GetEntityCoords                 = GetEntityCoords
local GetEntityModel                  = GetEntityModel
local GetEntitySpeed                  = GetEntitySpeed
local GetWeapontypeGroup              = GetWeapontypeGroup
local GetPlayerSprintStaminaRemaining = GetPlayerSprintStaminaRemaining
local IsPedShooting                   = IsPedShooting
local IsPedInMeleeCombat              = IsPedInMeleeCombat
local IsPedInCombat                   = IsPedInCombat
local IsPedRunning                    = IsPedRunning
local IsPedWalking                    = IsPedWalking
local IsPedStill                      = IsPedStill
local IsThisModelAPlane               = IsThisModelAPlane
local IsThisModelAHeli                = IsThisModelAHeli
local IsShockingEventInSphere         = IsShockingEventInSphere
local IsEntityInWater                 = IsEntityInWater

local gsrGroups = {
    [416676503]  = true,
    [-957766203] = true,
    [860033945]  = true,
    [970310034]  = true,
    [1159398588] = true,
    [3082541095] = true,
    [2725924767] = true,
}

local gsrIgnored = {
    [`WEAPON_STUNGUN`]  = true,
    [`WEAPON_FLAREGUN`] = true,
}

local function getStress()
    return LocalPlayer.state[Config.StateBagStress] or 0
end

local function setStress(val)
    LocalPlayer.state:set(Config.StateBagStress, math_max(0, math_min(100, val)), true)
end

local function addStress(amount, silent)
    if not amount or amount == 0 then return end
    local state = LocalPlayer.state
    if state.serenity or state.virtual then return end
    setStress((state[Config.StateBagStress] or 0) + amount)
    if not silent then
        NotifyBridge.SendAlert('inform', amount > 0 and 'Stress Gained' or 'Stress Relieved', 4000)
    end
end

local function getHunger()
    return LocalPlayer.state[Config.StateBagHunger] or 100
end

local function setHunger(val)
    LocalPlayer.state:set(Config.StateBagHunger, math_max(0, math_min(100, val)), true)
end

local function getThirst()
    return LocalPlayer.state[Config.StateBagThirst] or 100
end

local function setThirst(val)
    LocalPlayer.state:set(Config.StateBagThirst, math_max(0, math_min(100, val)), true)
end

local function IsPlayerPilot()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) or veh == 0 then return false end
    return GetPedInVehicleSeat(veh, -1) == ped
end

local function GetPedInFront()
    local pos    = GetEntityCoords(plyPed, false)
    local offset = GetOffsetFromEntityInWorldCoords(plyPed, 0.0, 1.3, 0.0)
    local ray    = StartShapeTestCapsule(pos.x, pos.y, pos.z, offset.x, offset.y, offset.z, 1.0, 12, plyPed, 7)
    local _, _, _, _, ped = GetShapeTestResult(ray)
    return ped
end

CreateThread(function()
    while true do
        Wait(2750)

        local stress = getStress()

        if stress >= 75 then
            if math_random(1, 10) == math_random(3, 8) then
                if math_random(1, 3) == 1 then
                    AnimpostfxPlay('DrugsTrevorClownsFightIn', 0, false)  Wait(2500)
                    AnimpostfxStop('DrugsTrevorClownsFightIn')
                    AnimpostfxPlay('DrugsTrevorClownsFight', 0, false)    Wait(5000)
                    AnimpostfxStop('DrugsTrevorClownsFight')
                    AnimpostfxPlay('DrugsTrevorClownsFightOut', 0, false) Wait(2500)
                    AnimpostfxStop('DrugsTrevorClownsFightOut')
                elseif math_random(1, 3) == 2 then
                    AnimpostfxPlay('DrugsMichaelAliensFightIn', 0, false)  Wait(2500)
                    AnimpostfxStop('DrugsMichaelAliensFightIn')
                    AnimpostfxPlay('DrugsMichaelAliensFight', 0, false)    Wait(5000)
                    AnimpostfxStop('DrugsMichaelAliensFight')
                    AnimpostfxPlay('DrugsMichaelAliensFightOut', 0, false) Wait(2500)
                    AnimpostfxStop('DrugsMichaelAliensFightOut')
                else
                    Wait(1000)
                end
            else
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.11)
            end
        elseif stress >= 55 then
            if math_random(1, 10) == 5 then
                AnimpostfxPlay('Rampage', 0, false)    Wait(5000)
                AnimpostfxStop('Rampage')
                AnimpostfxPlay('RampageOut', 0, false) Wait(5000)
                AnimpostfxStop('RampageOut')
            elseif math_random(1, 5) == 3 then
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
            else
                Wait(1000)
            end
        elseif stress >= 35 then
            if math_random(1, 10) == math_random(1, 15) then
                SetCamEffect(1) Wait(10000) SetCamEffect(0)
            else
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
            end
        elseif stress >= 15 then
            if math_random(1, 10) == math_random(1, 15) then
                TriggerScreenblurFadeIn(500)
                Wait(math_random(1500, 2000))
                TriggerScreenblurFadeOut(500)
            else
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.01)
            end
        end

        if stress < 10 then Wait(10000 - 2750)
        elseif stress < 15 then Wait(5000 - 2750) end
    end
end)

CreateThread(function()
    Wait(500)

    local increaseShootingS = false
    local increaseShootingO = false
    local increaseMeleeS    = false
    local increaseMeleeO    = false
    local increaseWalkingS  = false
    local increaseStillS    = false
    local increaseStillO    = false
    local increaseRunningO  = false
    local bodySweat         = 0

    while true do
        Wait(0)

        local isShooting = plyWep ~= nil and IsPedShooting(plyPed) or false

        if plyWep and isShooting and not increaseShootingO and math_random(100) >= 95 and not gsrIgnored[plyWep] then
            local group = GetWeapontypeGroup(plyWep)
            if gsrGroups[group] then
                CreateThread(function() increaseShootingO = true Wait(math_random(7500, 12500)) increaseShootingO = false end)
                bodySweat = bodySweat + 300
            end
        end

        local inCombat = IsPedInMeleeCombat(plyPed)

        if inCombat and not increaseMeleeO and math_random(100) >= 95 then
            local front = GetPedInFront()
            if front and front > 0 and IsPedInCombat(front, plyPed) == 1 then
                CreateThread(function() increaseMeleeO = true Wait(math_random(10000, 15000)) increaseMeleeO = false end)
                bodySweat = bodySweat + 300
            end
        end

        local running = IsPedRunning(plyPed)

        if running and not increaseRunningO and math_random(100) >= 95 then
            CreateThread(function() increaseRunningO = true Wait(math_random(10000, 15000)) increaseRunningO = false end)
            bodySweat = bodySweat + (20 + math_ceil(GetEntitySpeed(plyPed) * 5))
        end

        local isStill = IsPedStill(plyPed)

        if not increaseStillO and isStill and math_random(100) > 85 and not plyWep then
            CreateThread(function() increaseStillO = true Wait(30000) increaseStillO = false end)
            bodySweat = bodySweat - 30
        end

        if bodySweat < 0 then bodySweat = 0 end

        if plyWep and isShooting and not increaseShootingS and math_random(1, 100) >= 85 then
            CreateThread(function() increaseShootingS = true Wait(math_random(17500, 25000)) increaseShootingS = false end)
            addStress(math_random(3, 4))
        elseif not increaseMeleeS and inCombat and math_random(1, 100) >= 65 then
            local front = GetPedInFront()
            if front and front > 0 and IsPedInCombat(front, plyPed) == 1 then
                CreateThread(function() increaseMeleeS = true Wait(math_random(10000, 15000)) increaseMeleeS = false end)
                addStress(3)
            end
        elseif not increaseWalkingS and IsPedWalking(plyPed) and not plyWep and math_random(1, 100) >= 55 then
            CreateThread(function() increaseWalkingS = true Wait(math_random(10000, 15000)) increaseWalkingS = false end)
            addStress(-1, true)
        elseif not increaseStillS and isStill and math_random(100) > 75 and not plyWep then
            CreateThread(function() increaseStillS = true Wait(30000) increaseStillS = false end)
            addStress(-1, true)
        end
    end
end)

CreateThread(function()
    Wait(500)

    local justShockedS   = false
    local justWet        = false
    local justIncreased  = false
    local isPilot        = false
    local lastVeh        = nil

    while true do
        Wait(1000)

        local pos = GetEntityCoords(plyPed)

        if IsShockingEventInSphere(88, pos.x, pos.y, pos.z, 2.5) and not justShockedS and math_random(100) >= 95 then
            CreateThread(function() justShockedS = true Wait(math_random(50000, 75000)) justShockedS = false end)
            addStress(math_random(13, 20))
        end

        if not justWet and math_random(100) >= 85 and IsEntityInWater(plyPed) then
            CreateThread(function() justWet = true Wait(math_random(275000, 300000)) justWet = false end)
        end

        local veh = plyVeh
        if veh and DoesEntityExist(veh) and veh ~= 0 then
            local model    = GetEntityModel(veh)
            local aircraft = IsThisModelAPlane(model) == 1 or IsThisModelAHeli(model) == 1

            if aircraft then
                if veh ~= lastVeh then
                    lastVeh = veh
                    isPilot = IsPlayerPilot()
                end

                if not isPilot then
                    local currSpeed = GetEntitySpeed(veh) * 2.236963

                    if currSpeed >= 165 and not justIncreased and math_random(1, 100) >= 97 then
                        CreateThread(function() justIncreased = true Wait(math_random(17500, 25000)) justIncreased = false end)
                        addStress(math_random(4, 5))
                    elseif currSpeed >= 120 and not justIncreased and math_random(1, 100) >= 97 then
                        CreateThread(function() justIncreased = true Wait(math_random(17500, 25000)) justIncreased = false end)
                        addStress(math_random(2, 3))
                    elseif currSpeed >= 90 and not justIncreased and math_random(1, 100) >= 97 then
                        CreateThread(function() justIncreased = true Wait(math_random(17500, 25000)) justIncreased = false end)
                        addStress(math_random(1, 2))
                    end
                end
            else
                if veh ~= lastVeh then
                    lastVeh  = veh
                    isPilot  = false
                    justIncreased = false
                end
            end
        else
            lastVeh = nil
            isPilot = false
        end
    end
end)

CreateThread(function()
    Wait(500)
    while true do
        Wait(2000)

        if math_random(10) >= 4 then setThirst(getThirst() - (math_random(1, 2) / 100)) end
        if math_random(10) >= 4 then setHunger(getHunger() - (math_random(1, 2) / 100)) end

        if IsPedRunning(plyPed) and math_random(100) >= 90 and GetPlayerSprintStaminaRemaining(plyId) > 90 then
            setThirst(getThirst() - (math_random(10, 15) / 100))
        end

        local hunger = getHunger()
        local thirst = getThirst()

        if thirst <= 0 then
            local chance = math_random(1, 100)
            if chance >= 85 then
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.02)
            elseif chance >= 76 then
                SetPedToRagdoll(plyPed, 5511, 5511, 0, 0, 0, 0)
            elseif chance >= 73 then
                DoScreenFadeOut(1000) Wait(1250) DoScreenFadeIn(1000)
            else
                SetEntityHealth(plyPed, GetEntityHealth(plyPed) - 1)
            end
        elseif hunger <= 0 then
            local chance = math_random(1, 100)
            if chance >= 75 then
                addStress(math_random(2, 3), true)
            elseif chance >= 69 then
                AnimpostfxPlay('FocusIn', 2000, false)  Wait(2000)
                AnimpostfxPlay('FocusOut', 2000, false) Wait(2000)
                AnimpostfxStop('FocusIn')
                AnimpostfxStop('FocusOut')
            elseif chance >= 65 then
                AnimpostfxPlay('ChopVision', 0, false) Wait(5000)
                AnimpostfxStop('ChopVision')
            else
                SetEntityHealth(plyPed, GetEntityHealth(plyPed) - 2)
            end
        end
    end
end)

RegisterNetEvent('updatestress', function(amount, silent)
    if not amount or amount == 0 then return end
    addStress(amount / 100, silent)
end)

RegisterNetEvent('updatestatus', function(type, amount)
    if not amount or amount == 0 then return end
    if type == 'hunger' then
        setHunger(getHunger() + (amount / 100))
    elseif type == 'thirst' then
        setThirst(getThirst() + (amount / 100))
    end
end)

RegisterNetEvent('erp-status:set', function(name, val)
    if name == 'hunger' then setHunger(val / 100)
    elseif name == 'thirst' then setThirst(val / 100) end
end)

RegisterNetEvent('erp-status:add', function(name, val)
    if name == 'hunger' then setHunger(getHunger() + (val / 100))
    elseif name == 'thirst' then setThirst(getThirst() + (val / 100)) end
end)

RegisterNetEvent('erp-status:remove', function(name, val)
    if name == 'hunger' then setHunger(getHunger() - (val / 100))
    elseif name == 'thirst' then setThirst(getThirst() - (val / 100)) end
end)

RegisterNetEvent('corev_hud:setStress', function(val)
    setStress(val)
end)

RegisterNetEvent('corev_hud:addStress', function(amount, silent)
    addStress(amount, silent)
end)

RegisterNetEvent('corev_hud:setHunger', function(val)
    setHunger(val)
end)

RegisterNetEvent('corev_hud:setThirst', function(val)
    setThirst(val)
end)

RegisterNetEvent('corev_hud:healPlayer', function()
    setHunger(100)
    setThirst(100)
    setStress(0)
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)

AddEventHandler('corev_hud:stress:set', function(amount) setStress(amount) end)
AddEventHandler('corev_hud:stress:add', function(amount, silent) addStress(amount, silent) end)
AddEventHandler('corev_hud:hunger:set', function(val) setHunger(val) end)
AddEventHandler('corev_hud:thirst:set', function(val) setThirst(val) end)

RegisterCommand('setstress', function(_, args)
    local val = tonumber(args[1])
    if not val then return end
    setStress(val)
    print(('[corev_hud] stress set to %d (statebag=%s)'):format(val, tostring(LocalPlayer.state[Config.StateBagStress])))
end, false)

RegisterCommand('checkstats', function()
    print(('[corev_hud] hunger=%s thirst=%s stress=%s'):format(
        tostring(LocalPlayer.state[Config.StateBagHunger]),
        tostring(LocalPlayer.state[Config.StateBagThirst]),
        tostring(LocalPlayer.state[Config.StateBagStress])
    ))
end, false)
