fx_version 'cerulean'
game 'gta5'

name 'fd_banking with DualCurrency'
author 'zThundy'
version '1.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    "libs/**/*",
    'config.lua',
}

client_scripts {
    'client/**/*',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**/*',
}

files {
    'html/**/*',
    'locales/**/*',
}

dependencies {
    'ox_lib',
    'oxmysql'
}

lua54 'yes'
