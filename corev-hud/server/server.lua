local harnessVehicles = {}

RegisterNetEvent('harness', function(netVeh)
    if not harnessVehicles[netVeh] then
        harnessVehicles[netVeh] = true
    else
        harnessVehicles[netVeh] = nil
    end
    TriggerClientEvent('newHarness', -1, harnessVehicles)
end)
