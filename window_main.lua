--[[pod_format="raw",created="2024-05-25 22:10:24",modified="2025-07-07 07:22:03",revision=2005]]
function _init()
	wind = window{
		width = 200,
		height = 108,
		title = "Pepper"
	}
	
-- copies over pepper file for console use
	cp("pepper.lua", "/system/util/pepper.lua")

--[[
-- currently limited to the active window
	menuitem{
		id = "test",
		label = "Test",
		shortcut = "CTRL-P",
		action = function()
			notify"test"
		end
	}
--]]

	run_modes = {}
	
	init_gui()
	
end

function _draw()
	cls(6)
	spr(1,1,1)
	
	if #run_modes > 0 then
		rectfill(1, 16, window_width - 2, 16, 0xd)
	end

	gui:draw_all()
	spr(2,16,2)
end

function _update()
	gui:update_all()
end

function next_button(label, click, x, y)
	last_b = gui:attach_button{
		x = x or last_b and (last_b.x + last_b.width + 1) or 1, 
		y = y or last_b and last_b.y or 1,
		label = label,
		bgcol = 0x070d,
		click = click
	}	
	return last_b
end

function init_gui()
	gui = create_gui()
	
	local pep = gui:attach_button{
		x = 1, y = 1, width = 15, height = 15, cursor="grab"
	}
	function pep:draw() end
	function pep:click() send_message(3, {event="grab"}) end

	last_b = {
		x = 14,
		y = 1,
		width = 0,
	}
	
	--local b = next_button("Refresh",
	local b = next_button("  ",
		function()
			run_modes = {"None"}
			-- just in case
			cp("pepper.lua", "/system/util/pepper.lua")

			for f in all(ls("/ram/cart/")) do
				
				if f:ext() == "pepper" then
					add(run_modes, split(f, ".", false)[1])
				end
			end
			
			init_gui()
		end)
	b.width = 14
		
	if #run_modes > 0 then
		next_button("Run", pepper_run)	
		next_button("Export", pepper_export)
	end	
	
	local top_width = last_b.x + last_b.width
	local top_height = last_b.y + last_b.height + 1

	last_b = {
		x = 0,
		y = last_b.y + last_b.height+3,
		width = 0,
	}
	
	current_mode = "None"
	mode_buttons = {}		
	
	-- make a button for each pepper file
	for m in all(run_modes) do
		local b = next_button(m,
			function()
				current_mode = m	
				
				for b in all(mode_buttons) do
					if b.mode == m then
						b.bgcol = 0x0101
						b.fgcol = 0x0707
					else
						b.bgcol = 0x070d
						b.fgcol = nil
					end
				end
			end)
			
		b.mode = m
		add(mode_buttons, b)
	end
	
	if #mode_buttons > 0 then
		mode_buttons[1].click()
	end 
	
	-- change window size based on the contents
	window_width = max(max(top_width, last_b.x + last_b.width), 75) + 1
	window{
		width = window_width,
		height = #mode_buttons > 0 and (last_b.y + last_b.height + 1) or top_height,
		title = "Pepper"
	}
	
--maybe add for the refresh button
--[[pod_type="gfx"]]unpod("b64:bHo0ACoAAAAoAAAA8BlweHUAQyALCwTwCidgByAHQAdABzAHIAcABwAHEAcwJzAHMAdQJ-AK")

end

function pepper_run()
	create_process(pwd() .. "/pepper.lua", {argv = {"run", current_mode}})
end

function pepper_export()
	create_process(pwd() .. "/pepper.lua", {argv = {"export", current_mode}})
end

on_event("export_done", function(msg)
	create_process("/system/apps/filenav.p64", 
				{path="/", intention="save_file_as", use_ext = "p64", window_attribs={workspace = "current", autoclose=true}})
end)

on_event("save_file_as", function(msg)
	local fn = msg.filename
	if(not fn:ext()) fn ..= ".p64"
	
	cp("/ram/pepper/", fn)			
	notify("saved as ".. fn) -- show message even if cart file
end)