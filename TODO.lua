--[[pod_format="raw",created="2024-05-21 20:04:04",modified="2024-05-25 17:31:06",revision=564]]
--[[

read main.pepper
	unless requesting a different initial pepper file
copy files from /ram/cart/ to /ram/pepper/
run through all files of current project

turn pepper.lua contents into a function
	and abstract it a bit to allow for using it during .pepper files (without --#)

.pepper file exclusive commands
	remove <file> ...
		removes one or more files from the peppered version
	rename <file> <new name>
		rename and/or moving a file
	include <file.pepper>
		recursivly find all instances of include first to add to file
		OR
		start a new initial call with that file (and include current pepper_env)
		
	ignore <file> ...
		excludes files or directories from being altered
		can help with speeding up the build process if there's a lot of files

test include command

add infinite loop check on include
	check if file is included 3 times, then exit
	specifically 3 because there could be some small weird cases where a file could include itself for some benifit

add error messages for most possible cases
	probably surround the function call with a coroutine to capture errors

installing pepper window
	version number? (probably just replace the entire thing)
	
turn into widget for desktop2?
keybind if possible??? (like ctrl+r)

run and export commands

.pepper syntax highlighting?
	code.p64 doesn't automatically give it lua's, so it might be possible?

]]