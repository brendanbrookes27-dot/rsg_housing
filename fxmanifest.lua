fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

name 'rsg_housing'
description 'Advanced Housing System for RSG Framework'
author 'RSG Development Team'
version '2.0.0'

shared_scripts {
    '@rsg-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/furniture.lua',
    'client/storage.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/furniture.lua',
    'server/storage.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/*.png',
    'html/images/*.jpg'
}

dependencies {
    'rsg-core',
    'oxmysql'
}

lua54 'yes'