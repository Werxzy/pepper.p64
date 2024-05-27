--[[pod_format="raw",created="2024-05-19 15:24:54",modified="2024-05-27 03:24:13",revision=2372]]
-- contains the code for running the command (look at other commands for examples)

-- probably put the files into /ram/pepper/

local argv = env().argv or {}

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

local function eval_statement(file, start_i, env)
	local a, a2 = find_statement_end(file, start_i)
	local statement = sub(file, start_i, a)

	-- insert into function
	local f, err = load("_val = " .. statement, nil, "t", env)
	
	-- invalid line
	if(not f) error("invalid statement: " .. statement, 0)

	f()
	return env._val, a2
end


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

	function block_removal(e)
		local block = deli(if_blocks)
	
		-- invalid block
		if(not block) error("unclosed if/else block", 2)
		
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
			local _,b,name = file:find("(%w)",i)
			i = b+2
			
			local val, e = eval_statement(file, i, defs)
			
			if block_is_true() then
				defs[name] = val
			end
			
			add(section_removal, {a, e})
			i = e+1
		
		elseif c == "if" then
			local val, e = eval_statement(file, i, defs)
			val = val and true or false -- turn to boolean
			
			add(if_blocks, {a, e, val, val})
			i = e+1
	
		elseif c == "elseif" then
			local val, e = eval_statement(file, i, defs)
			local block = block_removal(e)
					
			add(if_blocks, {a, e, block[3] or val, not block[3] and val})
			i = e+1
		
		elseif c == "else" then
			local _, e = find_statement_end(file, i)
			local block = block_removal(e)
			
			add(if_blocks, {a, e, true, not block[3]})
			i = e+1
		
		elseif c == "end" then
			local _, e = find_statement_end(file, i)
			local block = block_removal(e)
			
			add(section_removal, {a, e})
			i = e+1
		
		elseif c == "insert" and not init_pepper then
			local val, e = eval_statement(file, i, defs)
			
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
					local _, d = pepper_file(fetch("/ram/pepper/" .. param[1]), true, defs)
					defs = d
			
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
local j = "/ram/cart/"
for i = 1, #argv-1 do
	if argv[i] == "-f" then
		j = argv[i + 1]
	end
end

-- make a copy of the current cart to work with
cp(j, "/ram/pepper/")

function pepper_dir(dir, ignore, defs)
	local files = ls(dir)
	for f in all(files) do
		local _f, f = f, dir .. f
		
		-- skip files or folders from a table
		if not ignore or (count(ignore, f) == 0 and count(ignore, _f) == 0) then
			local ty = fstat(f)
						
			if ty == "file" then
				if f:ext() == "lua" then
					-- pepper lua file
					local file = pepper_file(fetch(f), false, defs)
					store(f, file)
					print(f)
				end
				
			elseif ty == "folder" then
				-- check files and folders in this folder.
				pepper_dir(f)
			end
		end
	end
end

-- todo, change what the starting .pepper file is based on argv.
local file, defs = fetch("/ram/pepper/" .. (argv[2] or "main") .. ".pepper"), {}

if file then
	file, defs = pepper_file(file, true)
end

pepper_dir("/ram/pepper/", defs._pepper_ignore, defs)

if argv[1] == "run" then
	create_process("/ram/pepper/main.lua")
	
elseif argv[1] == "export" then
	local j = nil
	for i = 1,#argv-1 do
		if argv[i] == "-t" then
			j = argv[i + 1]
		end
	end

	if j then
		cp("/ram/pepper/", j)
	else
		notify"no export location provided"
		-- probably have a default location
	end

end


-- local file = pepper_file(fetch("/ram/pepper/main.lua"))
-- store("/ram/pepper/main.lua", file)
