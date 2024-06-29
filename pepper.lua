--[[pod_format="raw",created="2024-05-19 15:24:54",modified="2024-06-29 22:06:20",revision=4131]]
-- contains the code for running the command (look at other commands for examples)

-- probably put the files into /ram/pepper/

local version = "v1.1"

local argv = env().argv or {}

if argv[1] == "help" then
	helps = {syntax = [===[

== base syntax ==

	Instructions are only recognized after --#
	Multi-line comments are allowed.
	
	Warning, this will track all instances of --# in .lua files.

--#WORD

--[[#WORD	
]]

--[=[#WORD	
]=]
]===],

	def = [===[

== define values ==

	Using def, the second parameter denotes the name
	while anything afterwords on the same is ran in lua.
	
	Defined values only exist within the file they're defined in.

--#def debug true
--#def length 2 * 3
--#def area length * 4
]===],

	["if"] = [===[	

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
]===],

	insert = [===[
	
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
]===],
	
	build = [===[
	
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
]===]}

	print(helps[argv[2]] or [[
pepper help [topic]
	syntax
	def
	if
	insert
	build
]])
	exit()
	return
end


if argv[1] ~= "run" and argv[1] ~= "export" then	
	print([[
ProjEct PreProcEssor ]] ..version .. [[


pepper run [.pepper] [-f | -k | -s]
	builds the current project and runs
	[.pepper]		starting pepper parameter file
					if no (or an invalid) file is provided, no initial pepper will be ran
	-f <path>		changes the base directory from /ram/cart/
	-k				keeps .pepper files after build
	-s				skip the copy directory step
	
pepper export [.pepper] [-f | -t | -k | -s]
	build the current project and copies it to a given location, if provided
	-t <path>		target location for the project
	
pepper help
	provides extra documentation
]])
	exit()
	return
end

-- creates a new error
-- (this probably could have been simplified with coroutines)
local function new_error(i, file, message)
	return {
		is_error = true, 
		i = i, 
		file = file, 
		message = message
	}
end

-- checks if a value is an error report
local function is_error(e)
	return type(e) == "table" and e.is_error
end

-- path needs to be updated separately due to where it's known.
local function add_error_path(e, path)
	e.path = e.path or path
end

-- displays the error using the infobar
local function display_error(e, base_path)
	assert(e.file)
	local i, line_number, line_text = 1, 1
	while true do
		_, i, line_text = e.file:find("([^\n]*)\n", i)
		if i >= e.i then
			break
		end
		i += 1
		line_number += 1
	end

	send_message(3, {event="report_error", content = "Pepper build error : " .. e.message})
	send_message(3, {event="report_error", content = base_path .. sub(e.path, 13) .. " : line " .. line_number})
	send_message(3, {event="report_error", content = line_text})
end

-- sorts a table of tables using a key
local function quicksort(tab, key)
	local function qs(a, lo, hi)
	    if lo >= hi or lo < 1 then
	        return
	    end
	    
	    -- find pivot
	    local lo2, hi2 = lo, hi
	    local pivot, p = a[hi2][key], lo2-1
	    for j = lo2,hi2-1 do
	        if a[j][key] <= pivot then
	            p += 1
	            a[j], a[p] = a[p], a[j]
	        end
	    end
	    p += 1
	    a[hi2], a[p] = a[p], a[hi2]
	    
	    -- quicksort next step
	    qs(a, lo, p-1)
	    qs(a, p+1, hi)
	end
    qs(tab, 1, #tab)
end

-- finds the next end of statement either being a new line, end of a multiline comment, or the end of file
local function find_statement_end(file, start_i)
	-- either cut off at ]] or the end of the line
	local a, a2 = file:find("\n", start_i)
	local b, b2 = file:find("]=*]", start_i)
		-- if reaches end of file
	if a then
		a -= 1
	else
		a = #file
		a2 = a
	end
	if b then
		b -= 1
	else
		b = #file
		b2 = b
	end
	
	if b < a then
		a, a2 = b, b2
	end
	
	return a, a2
end

-- evaluates section of code
local function eval_statement(file, start_i, env)
	local a, a2 = find_statement_end(file, start_i)
	local statement = sub(file, start_i, a)

	-- insert into function
	local f = load("_val = " .. statement, nil, "t", env)
	
	-- usually syntax error
	if(not f) return new_error(start_i, file, "Invalid statement: " .. statement)
	
	-- uses a coroutine to capture any errors caused by the statement
	local ok, err = coresume(cocreate(f))
	if not ok then
		return new_error(start_i, file, sub(err, 5)) -- always starts with ":1: "
	end
	
	return env._val, a2
end


local include_files = {}
-- applies pepper preprocessing on a file
-- init_pepper determines if it will search for "--#"
-- base_defs contains env variables for pepper statements
local function pepper_file(file, init_pepper, base_defs)
	local i = 1
	local defs = {} -- add from command line if needed
	local if_blocks = {} -- {{starting point, end of statement, truthy statement found, current statement truthy}, ...}
	local section_removal = {} -- {{start, end, new contents}, ...}
	
	if base_defs then
		for k,v in pairs(base_defs) do
			defs[k] = v
		end
	end

	local function block_removal(e)
		local block = deli(if_blocks)
	
		-- invalid block
		--if(not block) error("unclosed if/else block", 2)
		if(not block) return new_error(i, file, "Missing if statement.")
		
		if block[4] then -- keep block contents
			add(section_removal, {block[1], block[2]})
	
		else -- remove block contents
			add(section_removal, {block[1], e}) -- also remove end statement
		end
		
		return block
	end
	
	local function block_is_true()
		for b in all(if_blocks) do
			if not b[4] then
				return false
			end
		end
		return true
	end
	
	local command_search = init_pepper and "([%w]+)" or "%-%-%[*=*%[*#([%w]+)"
	
	while true do
		local a, b, c = file:find(command_search, i)

		if(not a) break	
				
		i = b+1
		
		if c == "def" then
			local _,b,name = file:find("(%w+)",i)
			i = b+2
			
			local val, e = eval_statement(file, i, defs)
			if(is_error(val)) return val
			
			if block_is_true() then
				defs[name] = val
			end
			
			add(section_removal, {a, e})
			i = e+1
		
		elseif c == "if" then
			local val, e = eval_statement(file, i, defs)
			if(is_error(val)) return val
			val = val and true or false -- turn to boolean
			
			add(if_blocks, {a, e, val, val})
			i = e+1
	
		elseif c == "elseif" then
			local val, e = eval_statement(file, i, defs)
			if(is_error(val)) return val
			local block = block_removal(e)
			if(is_error(block)) return block
					
			add(if_blocks, {a, e, block[3] or val, not block[3] and val})
			i = e+1
		
		elseif c == "else" then
			local _, e = find_statement_end(file, i)
			local block = block_removal(e)
			if(is_error(block)) return block
			
			add(if_blocks, {a, e, true, not block[3]})
			i = e+1
		
		elseif c == "end" then
			local _, e = find_statement_end(file, i)
			local block = block_removal(e)
			if(is_error(block)) return block
			
			add(section_removal, {a, e})
			i = e+1
		
		elseif c == "insert" and not init_pepper then
			local val, e = eval_statement(file, i, defs)
			if(is_error(val)) return val
			
			add(section_removal, {a, e, val})
			i = e+1
		
		-- .pepper file exclusive instructions
		elseif #c > 2 and init_pepper then
			i += 1
			local a, a2 = find_statement_end(file, i)
			local par = sub(file, i, a)
			i = a2+1
			
			-- only apply instructions if they are within a block that will run
			if block_is_true() then
			
				-- get each parameter separated by whitespace
				local param, j = {}, 1
				while true do
					local a,j2,s = par:find("([%w._%-\\/]+)", j)
					
					if a then
						add(param, s)
						j = j2+1
					else
						break
					end
				end
				
				if c == "remove" then
					for s in all(param) do
						if #s > 1 then
							rm("/ram/pepper/" .. s)
						end
					end	
								
				elseif c == "rename" then
					local from = "/ram/pepper/" .. param[1]
					local to = "/ram/pepper/" .. param[2]
					
					cp(from, to)
					rm(from)
								
				elseif c == "include" then
					local path = "/ram/pepper/" .. param[1]
					if count(include_files, path) > 3 then
						return new_error(a, file, "infinite loop detected")
					end
					
					local new_file = fetch(path)
					if(not new_file) return new_error(a, file, "missing file : " .. path)
					
					add(include_files, path)
					local err, d = pepper_file(new_file, true, defs)
					if is_error(err) then
						add_error_path(err, path)
						return err
					end
					defs = d
					del(include_files, path)
			
				elseif c == "ignore" then
					if not defs._pepper_ignore then
						defs._pepper_ignore = {}
					end
					
					for s in all(param) do
						add(defs._pepper_ignore, s)
					end	
				
				end
			end
		end
	end
	
	if #if_blocks > 0 then
		return new_error(#file, file, "Unclosed if/else block.")
	end
	
	-- merge overlapping sections
	quicksort(section_removal, 1)
	local i = 1
	while i < #section_removal do
		local a, b = section_removal[i], section_removal[i+1]
		if a[2] >= b[1] then
			a[2] = max(b[2], a[2])
			deli(section_removal, i+1)
		else
			i += 1
		end
	end
	
	-- remove or replace sections
	while section_removal[1] do
		local r = deli(section_removal)
		file = sub(file, 0, r[1]-1) ..(r[3] and tostr(r[3]) or "") .. sub(file, r[2]+1)
	end
	
	return file, defs
end

-- get from position from the parameter after -f
local base_path = "/ram/cart/"
for i = 1, #argv-1 do
	if argv[i] == "-f" then
		base_path = argv[i + 1]
	end
end

if base_path[#base_path] ~= "/" then
	base_path ..= "/"
end

-- make a copy of the current cart to work with
if count(argv, "-s") == 0 then
	cp(base_path, "/ram/pepper/")
else
	base_path = "/"
end

local keep_pepper = count(argv, "-k") > 0

-- applies pepper function do whole directory
local function pepper_dir(dir, ignore, defs)
	local files = ls(dir)
	for f in all(files) do
		local _f, f = f, dir .. "/" .. f

		-- skip files or folders from a table
		if not ignore or (count(ignore, f) == 0 and count(ignore, _f) == 0) then
			local ty = fstat(f)

			if ty == "file" then
				if f:ext() == "lua" then
					-- pepper lua file
					local file = pepper_file(fetch(f), false, defs)
					
					if is_error(file) then
						add_error_path(file, f)
						return file
					end
					
					store(f, file)
					print(f)
				
				elseif not keep_pepper and f:ext() == "pepper" then
					rm(f)
				end
				
			elseif ty == "folder" then
				-- check files and folders in this folder.
				pepper_dir(f)
			end
		end
	end
end

local path = "/ram/pepper/" .. (argv[2] or "main") .. ".pepper"
local file, defs = fetch(path), {}

if file then
	local f, d = pepper_file(file, true)
	
	if is_error(f) then
		add_error_path(f, path)
		display_error(f, base_path)
		return
	end
	
	file, defs = f, d
end

local err = pepper_dir("/ram/pepper", defs._pepper_ignore, defs)

if is_error(err) then
	display_error(err, base_path)
	
elseif argv[1] == "run" then
	-- copied from wm.lua (may need to update if there are changes)
	local id = create_process("/system/apps/terminal.lua",{
		corun_program = "/ram/pepper/main.lua",       -- program to run // terminal.lua observes this and is also used to set pwd
		window_attribs = {
			pwc_output = true,                      -- replace existing pwc_output process			
			show_in_workspace = true,               -- immediately show running process
		}
	})
	
	send_message(3, {event="set_haltable_proc_id", haltable_proc_id = id})
	
elseif argv[1] == "export" then
	local j = nil
	for i = 1,#argv-1 do
		if argv[i] == "-t" then
			j = argv[i + 1]
		end
	end
	
	if j then
		cp("/ram/pepper/", j)
	end
	
	send_message(env().parent_pid, -- env().parent_pid, 
		{event="export_done"})
end
