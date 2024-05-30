--[[pod_format="raw",created="2024-05-19 15:23:45",modified="2024-05-30 22:37:24",revision=2927]]

--#if false

include "window_install.lua" 

--[[#elseif label

local w, h = 64, 16
local l = userdata("u8", w, h)

set_draw_target(l)

cls(0)
spr(1, 0, 0)
print("PEPPER.p64", 15, 3, 9)

set_draw_target()

local s = min(480\w, 270\h)
local w2, h2 = w*s, h*s
local x = (480 - w2) \ 2
local y = (270 - h2) \ 2

function _draw()
	cls(0)
	sspr(l, 0, 0, w, h, x, y, w2, h2)
end

--#else

-- sets up .pepper to open in the code file
create_process("/system/util/default_app.lua", {argv={"pepper", "/system/apps/code.p64"}})

include "window_main.lua"

--#end]]
