require "comp"

-- obj responds to pattern interface:
-- anything that has an internal state and responds to .next()
-- .next() should return the next item in the pattern
local function ispatt(obj)
	if type(obj) == "table" then
		return obj.patt or false
	else return false end
end

-- intermediary between stored functions, patterns, and raw values
-- keeps "count" the same if pattern counter isn't over, else
-- spits out next count, given as 3rd arg
-- pattern counter is in the form of a member being {pattern, times}
local handler = function(input, count, nextcount)
	if ispatt(input) then input = input.next()
	elseif comp.isfunction(input) then input = input()
	elseif type(input) == "table" then
		if ispatt(input[1]) and type(input[2]) == "number" then
			if input[3] then input[3] = input[3] - 1
			else input[3] = input[2] - 1 end
			if input[3] <= 0 then
				input[3] = nil
				return input[1].next(), nextcount
			else return input[1].next(), count end
		end
	end
	return input, nextcount
end

-- make rhythm distribution: args: # of possibilities, # of outcomes
-- # of outcomes is # of possibilities by default
-- returns difference of 2 numbers from 0 inclusive to 1 exclusive
-- if rep is true, at the end the pattern will output the difference between
-- 1 and the last number, and reset the pattern (create a new one)
local function makerhy(pos, out, rep)
	pos = pos or 4
	out = out or pos
	if out > pos then
		out = pos
	end
	local rhy
	local last
	local count
	local obj = { patt = true, type = "rhypat", rep = rep or true}
	obj.reset = function(inpos, inout)
		pos = inpos or pos
		out = inout or out
		rhy = {}
		local urn = comrand.makeurn(pos)
		for i=1, out do rhy[i] = (urn.next() - 1)/pos end
		table.sort(rhy)
		last = 0
		count = 1
	end
	obj.count = function(num)
		count = num or count
		return count
	end
	obj.next = function()
		if count > #rhy then
			if obj.rep then
				rhy = {}
				local urn = comrand.makeurn(pos)
				for i=1, out do rhy[i] = (urn.next() - 1)/pos end
				table.sort(rhy)
				local ret = rhy[1] + 1 - last
				last = rhy[1]
				count = 2
				return ret
			else return nil end
		else
			local ret = rhy[count] - last
			last = rhy[count]
			count = count + 1
			return ret
		end
	end
	obj.reset(pos, out)
	return obj
end

-- urn class: random selection without repetitions.
-- fbar 2007
-- urn interface:

function makeurn(size)
	local obj = {}
	local arr
	-- chosen values
	local index
	local last
	obj.patt = true
	obj.type = "urnpat"
	obj.reset = function()
		last = size
		index = {}
		for i=1,size do
			arr[i] = i
			index[i] = i
		end
	end
	-- take out specific numbers from remaining pool
	-- returns true if successful, else nil if doesn't exist
	obj.rem = function(input)
		-- location of thing to be removed
		local out = index[input]
		if out then
			local keep = arr[last]
			local res = arr[out]
			arr[out] = keep
			index[keep] = out
			index[input] = false
			last = last - 1
			return true
		else return nil end
	end
	-- if bool is true then reset
    obj.size = function(insize, bool)
    	assert(insize >= 1, "Error: size of urn must be greater than 0")
    	size = math.floor(insize)
    	last = size
		arr = {}
		local newindex = {}
		for i=1, size do
			arr[i] = i
			newindex[i] = i
		end
		if not bool then
			-- remove all already chosen occurences
			for i=1, math.min(size, #index) do
				if not index[i] then
					local keep = arr[last]
					arr[newindex[i]] = keep
					newindex[keep] = i
					newindex[i] = false
					last = last - 1
				end
			end
		end
		index = newindex
	end
	obj.next = function()
		if last > 0 then
			local i = math.random(last)
			local res = arr[i]
			arr[i] = arr[last]
			index[arr[last]] = i
			index[res] = false
			last = last - 1
			return res
		else
			return nil
		end
	end
	obj.size(size or 12, true)
	return obj
end

--random walk integers
--args:low, high, walk mode (drunk or not), limit mode (what to do at limits),
-- step size, initial state

--local table for lookups
local walklmode = {["reflect"]=1, ["limit"]=2, ["avg"]=3, ["jump"]=4, 
	["stop"]=5}

local function makewalk(inargs)
	local obj = {}
	inargs = inargs or {}
	local low = inargs.low or inargs[1] or 1
	local high = inargs.high or inargs[2] 
	local mode = inargs.mode or inargs[3]
	local lmode = inargs.lmode or inargs[4]
	local state = inargs.state or inargs[6] or 0
	local step = math.floor(math.abs(inargs.step or inargs[5] or 1))
	obj.patt = true
	obj.type = "walkpat"
	--switch statements
	local highsets = {
		-- "reset"
		[0] = function() state = low end,
		-- "reflect"
		function() 
			state = comp.reflect(state, low, high)
			if mode == 0 then step = -step end
		end,
		-- "limit"
		function() state = high end,
		-- "avg"
		function() state = math.floor((low + high)/2) end,
		-- "jump"
		function() state = math.random(low, high) end
	}
	local lowsets = {
		[0] = highsets[2],
		highsets[1],
		highsets[0],
		highsets[3],
		highsets[4]
	}
	obj.setrange = function(inlow, inhigh)
		inlow = math.floor(inlow or 0)
		if not inhigh then
			inhigh, inlow = inlow, 0
		else inhigh = math.floor(inhigh) end
		if inlow > inhigh then
			inlow, inhigh = inhigh, inlow end
		low, high = inlow, inhigh
		obj.getset(state)
	end
	obj.lmode = function(inmode)
		if not inmode then lmode = 0
		-- no case statement :^(
		elseif type(inmode) == "string" then
			lmode = walklmode[inmode]
			-- jump to opposite end (default)
			lmode = lmode or 0 -- "reset"
		else lmode = math.floor(inmode) % 6 end
	end
	obj.mode = function(inmode)
		if not inmode then mode = 0
		elseif type(inmode) == "string" then
			if inmode == "drunk" then mode = 1
			else mode = 0 end -- "count"
		else mode = math.floor(inmode) % 1 end
	end
	obj.step = function(instep)
		step = instep
	end
	obj.getset = function (inval)
		if inval then
			state = inval
			if state > high then
				local runfunc = highsets[lmode]
				if runfunc then runfunc()
				else state = high return false end
			elseif state < low then
				local runfunc = lowsets[lmode]
				if runfunc then runfunc()
				else state = low return false end
			end
		end
		return state
	end
	obj.next = function(stepin)
		if stepin then step = stepin end
		local old = obj.getset()
		if mode == 0 then obj.getset(state + step)
		else obj.getset(state + ((math.random(0, 1)*2) - 1)*step) end
		return old
	end
	obj.setrange(low, high)
	if not state then
		if lmode == 4 then state = math.random(low, high)
		else
			if mode == 1 then state = math.floor((low + high) / 2)
			else state = low end
		end
	end
	obj.mode(mode)
	obj.lmode(lmode)
	return obj
end

-- combines an array with a walkpat
local function makewalker(intable, walkargs)
	local obj = {}
	walkargs = walkargs or {}
	if not walkargs.low or walkargs[1] then walkargs.low = 1 end
	if not walkargs.state or walkargs[6] then walkargs.state = 1 end
	if intable then
		obj.arr = intable
		if not walkargs.high or walkargs[2] then walkargs.high = #obj.arr end
	end
	obj.patt = true
	obj.type = "walkerpat"
	obj.walk = makewalk(walkargs)
	obj.set = function(ind, val)
		if type(ind) == "table" then
			obj.arr = ind
			-- in this case val decides to not set the range to the length
			if not val then obj.walk.setrange(1, #ind) end
		else
			ind = math.floor((ind - 1) % #obj.arr) + 1
			obj.arr[ind] = val
		end
	end
	-- bool in these next two also decides to not set the range
	obj.add = function(item, pos, bool) 
		if pos then 
			pos = math.floor((pos - 1) % (#obj.arr + 1)) + 1
			table.insert(obj.arr, pos, item)
		else table.insert(obj.arr, item) end
		if not bool then obj.walk.setrange(1, #obj.arr) end
	end
	obj.rem = function(pos, bool)
		table.remove(obj.arr, pos)
		if not bool then obj.walk.setrange(1, #obj.arr) end
	end
	obj.next = function(step)
		local ret
		local bool
		-- current maximum counter (to reset to when pattern finishes)
		ret, bool = handler(obj.arr[obj.walk.getset()], false, 
			true)
		if bool then obj.walk.next(step) end
		return ret
	end
	obj.reset = function() 
		obj.walk.getset(1)
	end
	obj.get = function(i) return obj.arr[i] end
	obj.len = function() return #obj.arr end
	return obj
end

-- make weighting object
-- possibly make weights table a weak table
local function makeweight(intable)
	local weights = {}
	local obj = {}
	local sum = 0.0
	obj.last = false
	obj.patt = true
	obj.type = "weightpat"
	obj.new = function(item, weight)
		weight = weight or 1
		weight = math.abs(weight)
		sum = sum + weight
		if weights[item] then
			sum = sum - weights[item]
		end
		weights[item] = weight
	end
	obj.mod = function(item, weight)
		if not weights[item] then obj.new(item, weight)
		else
			local realweight = weights[item]
			weights[item] = math.max(realweight + weight, 0)
			sum = sum + weights[item] - realweight
		end
		return weights[item]
	end
	obj.rem = function(item)
		local ret = weights[item]
		sum = sum - weights[item]
		weights[item] = nil
		return ret
	end
	obj.clear = function()
		weights = {}
		sum = 0.0
		obj.last = false
	end
	obj.next = function()
		local ret
		if obj.last then
			ret, obj.last = handler(obj.last, obj.last, false)
			return ret
		else
			local randval = sum*math.random()
			for i, v in pairs(weights) do
				randval = randval - v
				if randval <= 0.0 then
					ret, obj.last = handler(i, i, false)
					return ret
				end
			end
		end
		error("could not get item in weight pairs")
	end
	obj.get = function(item)
		return weights[item]
	end
	if intable then
		for i, v in pairs(intable) do
			if not weights[i] then
				if type(i) == "string" then
					v = math.abs(v)
					weights[i] = v
					sum = sum + v
				else
					if type(v) == "table" then
						local weight = v[2] or 1
						weight = math.abs(weight)
						weights[v[1]] = weight
						sum = sum + weight
					else
						weights[v] = 1
						sum = sum+1
					end
				end
			end
		end
	end
	return obj
end

-- keeps an array of patterns, has interface similar to walker
-- at each next() call, calls handler on each item in the array and returns
-- as a parallel array. repeats are repeats in ultimate array.
local function makepar(inarray)
	local obj = {patt = true, type = "parpat"}
	obj.set = function(ind, val)
		if type(ind) == "table" then
			inarray = ind
		else
			ind = math.floor((ind - 1) % #inarray) + 1
			inarray[ind] = val
		end
	end
	-- bool in these next two also decides to not set the range
	obj.add = function(item, pos) 
		if pos then 
			pos = math.floor((pos - 1) % (#inarray + 1)) + 1
			table.insert(inarray, pos, item)
		else table.insert(inarray, item) end
	end
	obj.rem = function(pos)
		table.remove(inarray, pos)
	end
	obj.next = function()
		local result = {}
		local j = 1
		local i = 1
		while i <= #inarray do
			result[j], i = handler(inarray[i], i, i + 1)
			j = j + 1
		end
		return result
	end
	return obj
end

-- make constant data a pattern, so it can be repeated and stuff
local function makeconst(stuff)
	local obj = {patt = true, type = "constpat", val = stuff}
	obj.next = function()
		if type(obj.val) == "function" then
			return obj.val() end
		return obj.val
	end
	return obj
end

--[[ takes a single pattern as it's 1st argument that returns a table. or single 
item, in which case the item is assigned to a new table in place [1][1]
the second argument is a table of tables:
[input] = {{destination}, optional-index}. input is the location in the 
incoming array (so they are "parallel"
destination is a function call, without the added value in it
to take the value from, destination can be either an array or function
in the style of comp.route (e.g.). {table, index} to assign to an array

the pattern value is placed into the 2nd member of this array, unless
there is a 2nd optional-index value, in which case the value is placed into
this value + 1
the special destination "ret" designates the value to be returned (if any)
if "ret" has an index then it collects it's output in an array, else
it just outputs a value --]]
local function makeroute(inpat, routetable)
	local obj = {patt = true, type = "routepat"}
	obj.mtx = routetable or {}
	obj.c = inpat
	obj.next = function()		
		local member = obj.c.next()
		--pd.post(tostring(member))
		if type(member) ~= "table" then
			local dum = member
			member = {dum}
		end
		local ret
		for i, v in pairs(obj.mtx) do
			if member[i] then
				if v[1] == "ret" then
					if v[2] then
						if not ret then ret = {} end
						ret[v[2]] = member[i]
					else ret = member[i] end
				else
					local args = comp.copytab(v[1])
					local pos = v[2] or 2
					table.insert(args, pos, member[i])
					comp.route(args)
				end
			end
		end
		if ret then return ret end
	end
	return obj
end

-- calls comp.route with f (which should be a table), and switch
-- (works similarly to the route pattern)
-- next() returns the result
-- note that anything that calls handler with a function will provide the result
-- of that function upon next()
-- if bool is true then returns, else not
local function makepipe(inpat, f, bool, switch)
	local obj = {patt = true, type = "pipepat"}
	obj.c = inpat
	obj.f = f
	obj.switch = switch
	obj.ret = bool
	obj.next = function()
		local ret = obj.c.next()
		local arg = comp.copytab(obj.f)
		table.insert(arg, 2, ret)
		ret = comp.route(arg, obj.switch)
		if obj.ret then return ret end
	end
	return obj
end
	
compat = {
	handler = handler,
	ispatt = ispatt,
	walk = makewalk,
	urn = makeurn,
	par = makepar,
	const = makeconst,
	route = makeroute,
	pipe = makepipe,
	rhydist = makerhy,
	walker = makewalker,
	weight = makeweight
}