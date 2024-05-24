--[[pod_format="raw",created="2024-05-19 15:23:45",modified="2024-05-24 00:45:22",revision=1267]]
-- probably load the files in the correct locations
-- use a small window

-- sets up .pepper to open in the code file
create_process("/system/util/default_app.lua", {argv={"pepper", "/system/apps/code.p64"}})

include"pepper.lua"

--[[#if t == 0

print("load program")

--#elseif t == 1

print("test successful!")

--#else]]

print("extra")

--#end

print(--#if t
--#insert t
--#else
"no t value"
--#end
)
