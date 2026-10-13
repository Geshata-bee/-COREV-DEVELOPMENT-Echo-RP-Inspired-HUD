local harnessAttached = false
local harnessProp     = nil

local harnessModels = {
    `prop_seatbelt_01`,
}

local function AttachHarnessProp(ped)
    if harnessProp and DoesEntityExist(harnessProp) then
        DeleteEntity(harnessProp)
        harnessProp = nil
    end

    local model = harnessModels[1]

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    harnessProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)

    AttachEntityToEntity(
        harnessProp, ped,
        GetPedBoneIndex(ped, 24818),
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(model)
end

local function DetachHarnessProp()
    if harnessProp and DoesEntityExist(harnessProp) then
        DeleteEntity(harnessProp)
        harnessProp = nil
    end
end

local harnessVehicles = {}

RegisterNetEvent('newHarness', function(newData)
    harnessVehicles = newData
end)

local function HasHarness(vehicle)
    return harnessVehicles[VehToNet(vehicle)] == true
end

CreateThread(function()
    while true do
        Wait(500)

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            if harnessAttached then
                harnessAttached = false
                DetachHarnessProp()
            end
        else
            local hasHarness = HasHarness(vehicle)

            if hasHarness and not harnessAttached then
                harnessAttached = true
                AttachHarnessProp(ped)
            elseif not hasHarness and harnessAttached then
                harnessAttached = false
                DetachHarnessProp()
            end

            if harnessAttached then
                DisableControlAction(0, 75, true)
            end
        end
    end
end)
