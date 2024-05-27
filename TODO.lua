--[[pod_format="raw",created="2024-05-21 20:04:04",modified="2024-05-27 03:24:13",revision=585]]
--[[

add none option?

test include command

add infinite loop check on include
	check if file is included 3 times, then exit
	specifically 3 because there could be some small weird cases where a file could include itself for some benifit

add error messages for most possible cases
	probably surround the function call with a coroutine to capture errors
	somehow figure out line (probably count \n up to a certain point)

	error message to "report_error"
		like in startup.lua
		send_message(3, {event="report_error", content = "** system version mismatch **"})

improve ui
	
run and export commands

remove .pepper files on export

add option to remove startup


--probably not possible yet--

keybind if possible??? (like ctrl+r)

.pepper syntax highlighting?
	code.p64 doesn't automatically give it lua's, so it might be possible?

]]