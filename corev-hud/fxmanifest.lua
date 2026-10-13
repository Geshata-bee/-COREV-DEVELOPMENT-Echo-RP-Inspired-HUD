--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                CoreV HUD - FX Manifest                   ║
    ╚══════════════════════════════════════════════════════════╝
]]

fx_version 'cerulean'
lua54      'yes'

games { 'gta5', 'rdr3' }

ui_page 'web/build/index.html'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

server_script 'server/**/*'

client_scripts {
    'client/utils.lua',
    'client/harness.lua',
    'client/stress.lua',
    'client/client.lua',
}

files {
    'web/build/index.html',
    'web/build/**/*',
}
