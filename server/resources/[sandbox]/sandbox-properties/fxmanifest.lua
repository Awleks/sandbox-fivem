fx_version("cerulean")
client_script("@sandbox-base/exports/cl_error.lua")
client_script("@sandbox-pwnzor/client/check.lua")

game("gta5")
lua54("yes")

client_scripts({
	"interiors/**/*.lua",
	"client/**/*.lua",
})

server_scripts({
	"interiors/**/*.lua",
	"sv_config.lua",
	"server/**/*.lua",
})

shared_scripts({
	"shared/**/*.lua",
})
