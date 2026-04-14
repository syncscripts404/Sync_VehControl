version '1.0.0'
author 'Sync Scripts'
description 'VehControl for Fivem ESX and QBCore CFX.re made by Sync Scripts!'

dependency 'ox_lib'

fx_version "cerulean"
game "gta5"

shared_scripts {
    '@ox_lib/init.lua',
    "configs/main.lua"
}

client_scripts {
    "client/functions.lua",
    "client/main.lua"
}

files({
    "html/index.html",
    "html/assets/*.js",
    "html/assets/*.css"
})

ui_page("html/index.html")

shared_scripts({
    "configs/main.lua"
})
