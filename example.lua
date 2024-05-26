--[[pod_format="raw",created="2024-05-26 02:04:45",modified="2024-05-26 03:09:57",revision=61]]

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