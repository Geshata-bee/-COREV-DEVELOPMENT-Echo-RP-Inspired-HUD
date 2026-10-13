function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data   = data,
    })
end

local currentResourceName = GetCurrentResourceName()
local debugIsEnabled = GetConvarInt(('%s-debugMode'):format(currentResourceName), 0) == 1

function debugPrint(...)
    if not debugIsEnabled then return end
    local args = { ... }
    local appendStr = ''
    for _, v in ipairs(args) do
        appendStr = appendStr .. ' ' .. tostring(v)
    end
    print(('^3[%s]^0%s'):format(currentResourceName, appendStr))
end

NotifyBridge = (function()
    local n = Config.Notifications

    if n == 'ox_lib' then
        return {
            SendAlert = function(notifType, message, duration)
                lib.notify({
                    title    = message,
                    type     = notifType == 'inform' and 'info' or notifType,
                    duration = duration or 3000,
                })
            end,
        }

    elseif n == 'corev_notify' then
        return {
            SendAlert = function(notifType, message, duration)
                exports.corev_notify:SendAlert(notifType, message, duration or 3000)
            end,
        }

    elseif n == 'custom' then
        return Config.CustomNotificationBridge

    else
        return {
            SendAlert = function(notifType, message, _duration)
                print(('[corev_hud] Notify [%s]: %s'):format(notifType, message))
            end,
        }
    end
end)()
