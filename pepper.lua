--[[pod_format="raw",created="2024-05-19 15:24:54",modified="2024-05-23 15:55:37",revision=1066]]
-- contains the code for running the command (look at other commands for examples)

-- probably put the files into /ram/pepper/


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


local function pepper_file(file, base_defs)
	local i = 1
	local defs = {} -- add from command line if needed
	local if_blocks = {} -- {{starting point, end of statement, truthy statement found, current statement truthy}, ...}
	local section_removal = {} -- {{start, end, new contents}, ...}
	
	for k,v in pairs(base_defs) do
		defs[k] = v
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
	
	
	while true do
		local a, b, c = file:find("%-%-%[*=*%[*#(%w*)", i)
		
		if(not a) break	
		
		i = b+1
		
		if c == "def" then
			local _,b,name = file:find("(%w)",i)
			i = b+2
	
			local val, e = eval_statement(file, i, defs)
			defs[name] = val
			
			add(section_removal, {a, e})
		
		elseif c == "if" then
			local val, e = eval_statement(file, i, defs)
			val = val and true or false -- turn to boolean
			
			add(if_blocks, {a, e, val, val})
	
		elseif c == "elseif" then
			local val, e = eval_statement(file, i, defs)
			local block = block_removal(e)
					
			add(if_blocks, {a, e, block[3] or val, not block[3] and val})
		
		elseif c == "else" then
			local _, e = find_statement_end(file, i)
			local block = block_removal(e)
			
			add(if_blocks, {a, e, true, not block[3]})
		
		elseif c == "end" then
			local _, e = find_statement_end(file, i)
			local block = block_removal(e)
			
			add(section_removal, {a, e})
		
		elseif c == "insert" then
			local val, e = eval_statement(file, i, defs)
			
			add(section_removal, {a, e, val})
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

-- make a copy of the current cart to work with
cp("/ram/cart/", "/ram/pepper/")

function pepper_dir(dir, ignore)
	local files = ls(dir)
	for f in all(files) do
		local _f, f = f, dir .. f
		
		-- skip files or folders from a table
		if not ignore or (count(ignore, f) == 0 and count(ignore, _f) == 0) then
			local ty = fstat(f)
						
			if ty == "file" then
				if f:ext() == "lua" then
					store(f, pepper_file(fetch(f)))
					print(f)
				end
				
			elseif ty == "folder" then
				pepper_dir(f)
			end
		end
	end
end

pepper_dir("/ram/pepper/", {"TODO.lua", "README.lua"})

-- local file = pepper_file(fetch("/ram/pepper/main.lua"))
-- store("/ram/pepper/main.lua", file)

-- new version of file
print(file)
