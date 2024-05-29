--[[pod_format="raw",created="2024-05-21 12:00:12",modified="2024-05-29 23:44:07",revision=1195]]
--[===[


pepper.p64 allows for preprocessing a picotron project

After installing, you can use the "pepper" command to get some more details.


== base syntax ==

	Instructions are only recognized after --#
	Multi-line comments are allowed.
	
	Warning, this will track all instances of --# in .lua files.

--#WORD

--[[#WORD	
]]

--[=[#WORD	
]=]


== define values ==

	Using def, the second parameter denotes the name
	while anything afterwords on the same is ran in lua.
	
	Defined values only exist within the file they're defined in.

--#def debug true
--#def length 2 * 3
--#def area length * 4


== if/else blocks ==

	if/else blocks denote sections of code that are to be removed
	when building with pepper, before running or exporting.

--[[#if debug
print("Only run if debug is true")
--#end]]

--#if not area or area == 0
print("Run even without pepper")
print("Or run if the above statement is true")

--[[#else
print("Multi-line comments prevent statement from being run")
print("")

--#end]]

--#if false
--[[#elseif debug
--#else
--#end]]

--[[#if debug
--#elseif false]]
print("While this is also valid")
print("it's recommended to have the first block always be the default")
--[[#else
--#end]]


== insert ==

	Insert defined values into code.
	(This probably needs some work)

value = 
--#if area
--#insert area
--#else
	3
--#end

	or?

--#if not area
value = 3
--[[#else
value = --#insert area
--#end]]

	
==== .pepper files only ====
	
	Add .pepper files to the base directory to define starting
	parameters of the build.
	.pepper files do not require --# before every instruction.

== remove ==

	Remove one or more files or folders before building.
	Similar to the command rm.
	Paths are relative to the provided base directory.

remove todo.lua sfx/

== rename ==

	Renames or moves a file or folder before building.
	similar to the command cp.
	Paths are relative to the provided base directory.
	
rename demo/0.map map/0.map

== include ==
	
	Include another .pepper file to share instructions between.

include default.pepper

== ignore ==

	Skips specified one or more files or folders in the build process.
	Can help with build times if there are a lot of files.
	Skipped files are still included in the final build.
	
ignore gfx/ sfx/ map/ src/ gui.lua
]===]