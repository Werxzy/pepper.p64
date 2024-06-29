--[[pod_format="raw",created="2024-05-25 22:13:23",modified="2024-06-29 22:06:20",revision=1902]]
function _init()
	wind = window{
		width = 200,
		height = 100,
		title = "Pepper v1.1 Installer"
	}
		
	init_gui()
end

function _draw()
	cls(6)
--	cls(key"ctrl" and key"p" and 7 or 6) -- should work unfocused

	spr(1, 10, 15)
	
	print([[
After installing, reboot to have
pepper appear in the tooltray,
or use the pepper command in
the terminal for more info.]], 30, 15, 1)
	
	gui:draw_all()
end

function _update()
	gui:update_all()
end

function init_gui()
	gui = create_gui()
	
	gui:attach_button{
		x = 20, y = 70,
		label = "Install",
		bgcol = 0x070d,
		click = install_pepper
	}	
	
	gui:attach_button{
		x = 66, y = 70,
		label = "Uninstall",
		bgcol = 0x070d,
		click = uninstall_pepper
	}	
	
	gui:attach_button{
		x = 155, y = 70,
		label = "Run",
		bgcol = 0x070d,
		click = run_pepper_once
	}	
end

function install_pepper()
	mode = "install"
	mkdir"/appdata/system/tooltray"
	create_process(pwd() .. "/pepper.lua", {argv = split("export main -f " .. pwd() .. "/ -t /appdata/system/tooltray/pepper.p64", " ", false)})
	modify_startup(true)
	notify"Pepper Installed at /appdata/system/tooltray/"
end

function uninstall_pepper()
	-- removes the .p64 file and the process creation
	if fstat("/appdata/system/tooltray/pepper.p64") then
		rm("/appdata/system/tooltray/pepper.p64")
	end
	if fstat("/system/util/pepper.lua") then
		rm("/system/util/pepper.lua")
	end
	modify_startup()
	notify"Pepper Uninstalled"
end

function run_pepper_once()
	mode = "once"
	create_process(pwd() .. "/pepper.lua", {argv = split("export main -f " .. pwd() .. "/ -t /ram/compost/pepper.p64", " ", false)})
end

function modify_startup(process)
	local file = fetch("/appdata/system/startup.lua")
	if not file then
		file = ""
	end
	
	-- just in case it needs to update
	file = remove_pepper_process(file)
	
	if process then
		file ..= [[
		
--PEPPER_PROCESS-- 
-- do not add anything extra between the comments
-- that you don't want removed along with pepper.p64
create_process("/appdata/system/tooltray/pepper.p64", {window_attribs = {workspace = "tooltray", x=2, y=2}})
-- so other programs may use pepper
cp("/appdata/system/tooltray/pepper.p64/pepper.lua", "/system/util/pepper.lua")
--PEPPER_END--
]]	
	end

	store("/appdata/system/startup.lua", file)
end

function remove_pepper_process(file)
	local a, b = file:find("%-%-PEPPER_PROCESS%-%-.-%-%-PEPPER_END%-%-\n?")
	
	if(not a) return file, false
	
	local file2 = ""
	if a > 1 then
		file2 ..= sub(file, 1, a-1)
	end
	if b < #file then
		file2 ..= sub(file, b+1)
	end
	
	return file2, true
end

on_event("export_done", function(msg)
	if mode == "install" then
		cp("/appdata/system/tooltray/pepper.p64/pepper.lua", "/system/util/pepper.lua")
	elseif mode == "once" then
		create_process("/ram/compost/pepper.p64")
	end
end)