--[[pod_format="raw",created="2024-05-19 15:23:45",modified="2024-05-28 20:20:26",revision=2244]]

--#if false

include "window_install.lua" 

--[[#else

-- sets up .pepper to open in the code file
create_process("/system/util/default_app.lua", {argv={"pepper", "/system/apps/code.p64"}})

include "window_main.lua"

--#end]]
