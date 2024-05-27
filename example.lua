--[[pod_format="raw",created="2024-05-26 02:04:45",modified="2024-05-26 13:49:59",revision=129]]

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