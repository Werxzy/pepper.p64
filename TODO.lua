--[[pod_format="raw",created="2024-05-21 20:04:04",modified="2024-05-28 20:20:26",revision=916]]
--[[

add none option?

test include command

add infinite loop check on include
	check if file is included 3 times, then exit
	specifically 3 because there could be some small weird cases where a file could include itself for some benifit

fix file path on error messages?
	currently mentions /ram/pepper/... which isn't useful to the user
	also could do proper linking on click
		look at infobar for more info on "report_error" event

improve ui
	
remove .pepper files on export

add option to remove startup


--probably not possible yet--

keybind if possible??? (like ctrl+r)

.pepper syntax highlighting?
	code.p64 doesn't automatically give it lua's, so it might be possible?

]]