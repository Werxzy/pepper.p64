--[[pod_format="raw",created="2024-05-25 22:10:24",modified="2024-05-28 20:20:26",revision=436]]
function _init()
	wind = window{
		width = 200,
		height = 108,
		title = "Pepper"
	}
	
	run_modes = {}
	
	init_gui()
end

function _draw()
	cls(6)
	
	gui:draw_all()
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
	last_b = nil
	
	next_button("Refresh",
		function()
			run_modes = {}
			
			for f in all(ls("/ram/cart/")) do
				if f:ext() == "pepper" then
					add(run_modes, split(f, ".", false)[1])
				end
			end
			
			init_gui()
		end)
		
	if #run_modes > 0 then
		next_button("Run", pepper_run)	
		next_button("Export", pepper_export)
	end	
	
	local top_width = last_b.x + last_b.width
	local top_height = last_b.y + last_b.height

	last_b = {
		x = 0,
		y = last_b.y + last_b.height,
		width = 0,
	}
	
	current_mode = nil
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
	
	-- change window size based on the contents
	wind = window{
		width = max(max(top_width, last_b.x + last_b.width), 75) + 1,
		height = #mode_buttons > 0 and (last_b.y + last_b.height) or top_height,
		title = "Pepper"
	}
	
--maybe add for the refresh button
--[[pod_type="gfx"]]unpod("b64:bHo0ACoAAAAoAAAA8BlweHUAQyALCwTwCidgByAHQAdABzAHIAcABwAHEAcwJzAHMAdQJ-AK")

end

function pepper_run()
	create_process(pwd() .. "/pepper.lua", {argv = {"run", current_mode}})
	--include"pepper.lua"
end

function pepper_export()
	-- maybe present an export location
end