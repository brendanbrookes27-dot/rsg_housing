fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'RSG Housing System - Advanced Property Management for RedM'
version '2.0.0'
author 'RSG Framework'

shared_scripts {
    '@rsg-core/shared/locale.lua',
    'locales/en.lua',
    'config/config.lua',
    'config/properties.lua'
}

client_scripts {
    'client/main.lua',
    'client/markers.lua',
    'client/blips.lua',
    'client/interactions.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/properties.lua',
    'server/callbacks.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js'
}

dependencies {
    'rsg-core',
    'rsg-menu',
    'rsg-input',
    'oxmysql'
}

lua54 'yes'