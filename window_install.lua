--[[pod_format="raw",created="2024-05-25 22:13:23",modified="2024-05-26 03:09:57",revision=278]]
function _init()
	wind = window{
		width = 200,
		height = 90,
		title = "Pepper Installer"
	}
		
	init_gui()
end

function _draw()
	cls(6)
	
	gui:draw_all()
end

function _update()
	gui:update_all()
end

function init_gui()
	gui = create_gui()
	
	gui:attach_button{
		x = 20, y = 60,
		label = "Install",
		bgcol = 0x070d,
		click = install_pepper
	}	
	
	gui:attach_button{
		x = 66, y = 60,
		label = "Uninstall",
		bgcol = 0x070d,
		click = uninstall_pepper
	}	
	
	gui:attach_button{
		x = 155, y = 60,
		label = "Run",
		bgcol = 0x070d,
		click = run_pepper_once
	}	
end

function install_pepper()
	create_process(pwd() .. "/pepper.lua", {argv = split"export main -f " .. pwd() .. " -t /appdata/system/desktop2/pepper.p64"}})
end

function uninstall_pepper()

end

function run_pepper_once()
	include "window_main.lua"
	_init()
end