--[[pod_format="raw",created="2024-07-01 19:34:37",modified="2025-07-07 06:52:09",revision=157]]


--#if false
if not get_param then
	notify"wrong"
end
--#end

local s = ""
for k in all(get_param()) do
	s ..= k .. " "
end
--notify(s)
