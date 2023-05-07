-- general utility functions:
-- exponential table lookup:
-- goes from 0 to 1, 1002 entries. 0 is scaled to be .001 in the real e^-x 
--function
-- should be read going from 2 to 1001 (for cubic interpolation)
local exptab = {}
for i=1, 1002 do
	exptab[i] = (math.exp((i-1001)*0.00691466994893) - 0.001)/0.999
end

--clip input between low and high
local function clip(input, low, high)
	input = input or 0
	return math.min(math.max(input, low), high)
end

-- reads interpolated index in array that starts at 1
-- (cubic lagrange)
local function lagrange(index, tab)
	local max = #tab - 1
	if index >= max then return tab[max]
	elseif index <= 2 then return tab[2] end
	local iindex = math.floor(index)
	index = index - iindex
	local a = tab[iindex - 1]
	local b = tab[iindex]
	local c = tab[iindex + 1] - b
	local d = tab[iindex + 2]
	return b + index*(c - 0.166666667*(1 - index)*(
		(d - a - 3*c)*index + (d + 2*a - 3*b)))
end

-- exponentially map range 0-1 (clipped). uses lagrange interpolation
local function unexp(input)
	input = input * 999 + 2
	--close enough
	if input <= 2 then return 0 end
	return lagrange(input, exptab)
end

--scale a range from (0, 1) to (add, add+scale)
local function sfrom(input, scale, add)
	scale = scale or 1
	add = add or 0
	return input*scale + add
end

--scale input with range of lower, upper or 0, upper if no 3rd arg
--to be in the range (0, 1)
--if lower = upper, resolves to fractional part of input
local function sto(input, lower, upper)
	if not lower then return 1
	elseif not upper then
		upper = lower
		lower = 0
	end
	if upper < lower then
		upper, lower = lower, upper
	elseif upper == lower then
		return input % 1
	end
	return (input - lower)/(upper - lower)
end

--scale number from range a, b to range 0, 1
local function scaletou(input, a, b)
    return (input - a)/(b - a)
end

--scale number from range 0, 1 to range a, b
local function scalefromu(input, a, b)
    return input*(b-a) + a
end

--scale from range a, b to range c, d
local function scalef(input, a, b, c, d)
	return (input-a)*(d - c)/(b - a) + c
end

--[[
--random number between 2 values at a certain interval, inclusive
-- interval defaults to 1
local function randinter(a, b, inter)
	inter = inter or 1
	if not b then
		b = a
		a = 0
	end
	local num = math.floor((a - b)/inter)
	num = math.random(num + 1)
	return num*(inter - 1) + a
end
]]--

--reflect value in range(low, high)
local function reflect(val, low, high)
	if not low then error("reflect: must pass 2nd argument") end
	if not high then
		low, high = 0, low
	end
	if low > high then low, high = high, low end
	local range = high - low
	val = range - ((val - low) % (range*2))
	return high - math.abs(val)
end

--wrap value in range(low, high)
local function frange(val, low, high)
	if not low then error("wrap: must pass 2nd argument") end
	if not high then
		low, high = 0, low
	end
	if low > high then low, high = high, low end
	return ((val - low) % (high - low)) + low
end

local function ltype(obj)
	local thistype = type(obj)
	if thistype == 'table' then
		return obj.type or thistype
	else return thistype end
end

--from Moses:
--- Maps function `f(key, value)` on all key-value pairs. Collects
-- and returns the results as a table.
local function map(t, f, ...)
  local lt = {}
  for index,value in pairs(t) do
    lt[index] = f(index,value,...)
  end
  return lt
end

local function log2(exp)
	return math.log(exp)/math.log(2)
end

--turn a function into a thunk (1-arg function)
-- args must be a table
local function promise(f, args)
	args = args or {}
	return function()
		return f(unpack(args))
	end
end

--returns tr if input > random value between 0 and 1
--else returns fa
local function odds(input, tr, fa)
	tr = tr or true
	fa = fa or false
	if input > math.random() then
		return tr
	else return fa end
end

--pick a random member of a table of integer indices
local function pick(table)
	return(table[math.random(#table)])
end


-------- from moses library---------------------------------
-- http://yonaba.github.io/Moses/
local function isstring(obj)
  return type(obj) == 'string'
end

local function isfunction(obj)
   return type(obj) == 'function'
end

local function isnil(obj)
  return obj==nil
end

local function isnumber(obj)
  return type(obj) == 'number'
end

local function istable(t)
	return type(t) == 'table'
end

-- recursive map on f(value, ...)
-- by S. Shader, needed to put after istable()
local function rmap(table, f, ...)
	-- need to pass varargs here because upvalue doesn't work
	if istable(table) then return map(table, function(_, value, ...)
			return rmap(value, f, ...)
		end)
	else return f(table, ...) end
end

--- Checks if the given argument is an array. Assumes `obj` is an array
-- if is a table with integer numbers starting at 1.
-- @name isArray
-- @tparam table obj an object
-- @treturn boolean `true` or `false`
local function isarray(obj)
  if not istable(obj) then return false end
  -- Thanks @Wojak and @Enrique García Cota for suggesting this
  -- See : http://love2d.org/forums/viewtopic.php?f=3&t=77255&start=40#p163624
  local i = 0
  for _ in pairs(obj) do
     i = i + 1
     if isnil(obj[i]) then return false end
  end
  return true
end

local function isnot(value) return not value end

local function isboolean(obj)
  return type(obj) == 'boolean'
end

local function isinteger(obj)
  return isnumber(obj) and math.floor(obj)==obj
end

local function countt(t)  -- raw count of items in an map-table
  local i = 0
    for _,_ in pairs(t) do i = i + 1 end
  return i
end

--- Counts the number of values in a collection. If being passed more than one args
-- it will return the count of all passed-in args.
local function size(...)
  local args = {...}
  local arg1 = args[1]
  if isnil(arg1) then
    return 0
  elseif istable(arg1) then
    return countt(args[1])
  else
    return countt(args)
  end
end

--- Performs a deep comparison test between two objects. Can compare strings, functions 
-- (by reference), nil, booleans. Compares tables by reference or by values. If `useMt` 
-- is passed, the equality operator `==` will be used if one of the given objects has a 
-- metatable implementing `__eq`.
local function isequal(objA, objB, useMt)
  local typeObjA = type(objA)
  local typeObjB = type(objB)

  if typeObjA~=typeObjB then return false end
  if typeObjA~='table' then return (objA==objB) end

  local mtA = getmetatable(objA)
  local mtB = getmetatable(objB)

  if useMt then
    if (mtA or mtB) and (mtA.__eq or mtB.__eq) then
      return mtA.__eq(objA, objB) or mtB.__eq(objB, objA) or (objA==objB)
    end
  end

  if size(objA)~=size(objB) then return false end

  for i,v1 in pairs(objA) do
    local v2 = objB[i]
    if isnil(v2) or not isequal(v1,v2,useMt) then return false end
  end

  for i,_ in pairs(objB) do
    local v2 = objA[i]
    if isnil(v2) then return false end
  end

  return true
end

-- calls f(key, value) for each member in t
local function each(t, f, ...)
  for index,value in pairs(t) do
    f(index,value,...)
  end
end

--- Counts occurrences of a given value in a table. Uses @{isEqual} to compare values.
-- @name count
-- @tparam table t a table
-- @tparam[opt] value value a value to be searched in the table. If not given, the @{size} of the table will be returned
-- @treturn number the count of occurrences of `value`
local function countn(t, value)
  if isnil(value) then return #t end
  local count = 0
  each(t, function(_,v)
    if isequal(v, value) then count = count + 1 end
  end)
  return count
end

--shuffle table, from Moses
local function shuffle(t, seed)
  if seed then math.randomseed(seed) end
  local shuffled = {}
  each(t, function(index,value)
    local randPos = math.floor(math.random()*index)+1
	shuffled[index] = shuffled[randPos]
    shuffled[randPos] = value
  end)
  return shuffled
end

--Reduces a table, left-to-right. Folds the table from the first element to the last element
-- to into a single value, with respect to a given iterator and an initial state.
-- The given function takes a state and a value and returns a new state.
local function reduce(t, f, state)
  for _,value in pairs(t) do
    if state == nil then state = value
    else state = f(state,value)
    end
  end
  return state
end

local function detect(t, value)
  local iter = isfunction(value) and value or isequal
  for key,arg in pairs(t) do
    if iter(arg,value) then return key end
  end
end

local function f_max(a,b) return a>b end
local function f_min(a,b) return a<b end

local function identity(value) return value end

local function extract(list,comp,transform,...) -- extracts value from a list
  local ans
  transform = transform or identity
  for _,value in pairs(list) do
    if not ans then ans = transform(value,...)
    else
      value = transform(value,...)
      ans = comp(ans,value) and ans or value
    end
  end
  return ans
end

--- Clones a table while dropping values passing an iterator test.
-- <br/><em>Aliased as `discard`</em>
-- @name reject
-- @tparam table t a table
-- @tparam function f an iterator function, prototyped as `f(key, value, ...)`
-- @tparam[opt] vararg ... Optional extra-args to be passed to function `f`
-- @treturn table the remaining values
local function reject(t, f, ...)
  local mapped = map(t,f,...)
  local lt = {}
  for index,value in pairs (mapped) do
    if not value then lt[#lt+1] = t[index] end
  end
  return lt
end

local function lselect(t, f, ...)
  local mapped = map(t, f, ...)
  local lt = {}
  for index,value in pairs(mapped) do
    if value then lt[#lt+1] = t[index] end
  end
  return lt
end

--- Extracts property-values from a table of values.
-- @name pluck
-- @tparam table t a table
-- @tparam string a property, will be used to index in each value: `value[property]`
-- @treturn table an array of values for the specified property
local function pluck(t, property)
  return reject(map(t,function(_,value)
      return value[property]
    end), isnot)
end

--- Returns the max/min value in a collection. If an transformation function is passed, it will
-- be used to extract the value by which all objects will be sorted.
-- @tparam[opt] function transform an transformation function, prototyped as `transform(value,...)`, defaults to @{identity}
-- @tparam[optchain] vararg ... Optional extra-args to be passed to function `transform`
local function max(t, transform, ...)
  return extract(t, f_max, transform, ...)
end

local function min(t, transform, ...)
  return extract(t, f_min, transform, ...)
end

--- Chunks together consecutive values. Values are chunked on the basis of the return
-- value of a provided predicate `f(key, value, ...)`. Consecutive elements which return 
-- the same value are chunked together. Leaves the first argument untouched if it is not an array.
-- @name chunk
-- @tparam table array an array
-- @tparam function f an iterator function prototyped as `f(key, value, ...)`
-- @tparam[opt] vararg ... Optional extra-args to be passed to function `f`
-- @treturn table a table of chunks (arrays)
local function chunk(array, f, ...)
  if not isarray(array) then return array end
  local ch, ck, prev = {}, 0, nil
  local mask = map(array, f,...)
  each(mask, function(k,v)
    prev = (prev==nil) and v or prev
    ck = ((v~=prev) and (ck+1) or ck)
    if not ch[ck] then
      ch[ck] = {array[k]}
    else
      ch[ck][#ch[ck]+1] = array[k]
    end
    prev = v
  end)
  return ch
end

--- Slices values indexed within `[start, finish]` range.
-- @name slice
-- @tparam table array an array
-- @tparam[opt] number start the lower bound index, defaults to the first index in the array.
-- @tparam[optchain] number finish the upper bound index, defaults to the array length.
-- @treturn table a new array
local function slice(array, start, finish)
  return lselect(array, function(index)
      return (index >= (start or next(array)) and index <= (finish or #array))
    end)
end

--- Returns the first N values in an array.
-- @tparam table array an array
-- @tparam[opt] number n the number of values to be collected, defaults to 1.
-- @treturn table a new array
local function first(array, n)
  n = n or 1
  return slice(array,1, min(n,#array))
end

--- Returns the last N values in an array.
-- @name last
-- @tparam table array an array
-- @tparam[opt] number n the number of values to be collected, defaults to the array length.
-- @treturn table a new array
local function last(array,n)
  if n and n <= 0 then return end
  return slice(array,n and #array-min(n-1,#array-1) or 2,#array)
end

--- Flattens a nested array. Passing `shallow` will only flatten at the first level.
-- @name flatten
-- @tparam table array an array
-- @tparam[opt] boolean shallow specifies the flattening depth
-- @treturn table a new array, flattened
local function flatten(array, shallow)
  shallow = shallow or false
  local new_flattened
  local flat = {}
  for _,value in pairs(array) do
    if istable(value) then
      new_flattened = shallow and value or flatten (value)
      each(new_flattened, function(_,item) flat[#flat+1] = item end)
    else flat[#flat+1] = value
    end
  end
  return flat
end

--- Merges values of each of the passed-in arrays in subsets.
-- Only values indexed with the same key in the given arrays are merged in the same subset.
-- @name zip
-- @tparam vararg ... a variable number of array arguments
-- @treturn table a new array
local function zip(...)
  local arg = {...}
  local len = max(map(arg,function(_,v)
      return #v
    end))
  local ans = {}
  for i = 1,len do
    ans[i] = pluck(arg,i)
  end
  return ans
end

--- Clones `array` and appends `other` values.
-- @name append
-- @tparam table array an array
-- @tparam table other an array
-- @treturn table a new array
local function append(array, other)
  local t = {}
  for i,v in ipairs(array) do t[i] = v end
  for _,v in ipairs(other) do t[#t+1] = v end
  return t
end

--- Interleaves arrays. It returns a single array made of values from all
-- passed in arrays in their given order, interleaved.
-- @name interleave
-- @tparam vararg ... a variable list of arrays
-- @treturn table a new array
-- @see interpose
local function interleave(...) return flatten(zip(...)) end

--- Produce a flexible list of numbers. If one positive value is passed, will count from 0 to that value,
-- with a default step of 1. If two values are passed, will count from the first one to the second one, with the
-- same default step of 1. A third passed value will be considered a step value.
-- @name range
-- @tparam[opt] number from the initial value of the range
-- @tparam[optchain] number to the final value of the range
-- @tparam[optchain] number step the count step value
-- @treturn table a new array of numbers
local function range(...)
  local arg = {...}
  local start, stop, step
  if #arg==0 then return {}
  elseif #arg==1 then stop,start, step = arg[1],0,1
  elseif #arg==2 then start,stop,step = arg[1],arg[2],1
  elseif #arg == 3 then start,stop,step = arg[1],arg[2],arg[3]
  end
  if (step and step==0) then return {} end
  local ranged = {}
  local steps = math.max(math.floor((stop-start)/step),0)
  for i=1,steps do ranged[#ranged+1] = start+step*i end
  if #ranged>0 then table.insert(ranged,1,start) end
  return ranged
end

--- Creates an array list of `n` values, repeated.
-- @name rep
-- @tparam value value a value to be repeated
-- @tparam number n the number of repetitions of the given `value`.
-- @treturn table a new array of `n` values
local function rep(value, n)
  local ret = {}
  for _ = 1, n do ret[#ret+1] = value end
  return ret
end

--- Reverses values in a given array. The passed-in array should not be sparse.
-- @name reverse
-- @tparam table array an array
-- @treturn table a copy of the given array, reversed
local function reverse(array)
  local larray = {}
  for i = #array,1,-1 do
    larray[#larray+1] = array[i]
  end
  return larray
end

-- binary search of sorted array,
-- get should get numerical items to compare
-- from the table. val is already "got"ten
-- returns negative number of last index to the right if unfound,
-- and index if found
-- from Sedgewick
local function bsearch(tbl, val, get)
	get = get or identity
	local l = 1
	local r = #tbl
	local index
	-- get real value
	repeat
		index = math.floor((l + r)/2)
		if val == get(tbl[index]) then return index
		elseif val < get(tbl[index]) then r = index - 1
		else l = index + 1 end
	until r < l
	return -r - 1
end

-- one time weighting of table in format:
-- {{item1, weight1}, {item2, weight2}, etc}
-- where weights are positive numbers, defaulting to 1 if absent
local function wonce(intable)
	local sums = {}
	local sum = 0.0
	local add
	for i=1, #intable do
		add = intable[i][2] or 1
		sum = sum + math.abs(add)
		sums[i] = sum
	end
	sum = math.random()*sum
	sum = math.abs(bsearch(sums, sum))
	return intable[sum][1]
end

--- Composes functions. Each passed-in function consumes the return value of the function that follows.
-- In math terms, composing the functions `f`, `g`, and `h` produces the function `f(g(h(...)))`.
-- @name compose
-- @tparam vararg ... a variable number of functions
-- @treturn function a new function
-- @see pipe
local function compose(...)
  local f = reverse {...}
  return function (...)
      local temp
      for _, func in ipairs(f) do
        temp = temp and func(temp) or func(...)
      end
      return temp
    end
end

--- Pipes a value through a series of functions. In math terms, 
-- given some functions `f`, `g`, and `h` in that order, it returns `f(g(h(value)))`.
-- @name pipe
-- @tparam value value a value
-- @tparam vararg ... a variable number of functions
-- @treturn value the result of the composition of function calls.
-- @see compose
local function pipe(value, ...)
  return compose(...)(value)
end

--- Wraps `f` inside of the `wrapper` function. It passes `f` as the first argument to `wrapper`.
-- This allows the wrapper to execute code before and after `f` runs,
-- adjust the arguments, and execute it conditionally.
-- @name wrap
-- @tparam function f a function to be wrapped, prototyped as `f(...)`
-- @tparam function wrapper a wrapper function, prototyped as `wrapper(f,...)`
-- @treturn function a new function
local function wrap(f, wrapper)
  return function (...) return  wrapper(f,...) end
end

--- Binds `v` to be the first argument to function `f`. As a result,
-- calling `f(...)` will result to `f(v, ...)`.
-- @name bind
-- @tparam function f a function
-- @tparam value v a value
-- @treturn function a function
-- @see bindn
local function bind(f, v)
  return function (...)
      return f(v,...)
    end
end

--- Binds `...` to be the N-first arguments to function `f`. As a result,
-- calling `f(a1, a2, ..., aN)` will result to `f(..., a1, a2, ...,aN)`.
-- @name bindn
-- @tparam function f a function
-- @tparam vararg ... a variable number of arguments
-- @treturn function a function
-- @see bind
local function bindn(f, ...)
  local iarg = {...}
  return function (...)
      return f(unpack(append(iarg,{...})))
    end
end

---------------------------- from abclua:
-- return the greatest common divisor of a and b
local function gcd(a, b)
  while a ~= 0 do
    a,b = (b%a),a
  end
  return b
end

local function copyar(orig)
    -- copy an array (only integer keys are copied)
    local copy = {}
    for i=1,#orig do
        copy[i] = orig[i]
    end
    return copy
end

local function copytab(orig)
    -- shallow copy a table (does not copy the contents)
    local copy = {}
    for i,v in pairs(orig) do
        copy[i] = v
    end
    return copy
end


-- copy a table completely (excluding metatables)
-- don't copy keys, just values
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[orig_key] = deepcopy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--function to do something many times
local function domult (times, f, ...)
	for _=1, (times - 1) do
		f(...)
	end
	return f(...)
end

-- takes an array representation of a function call and calls it:
-- {function, arg1, arg2, etc...}
local function fcall(intable)
	local f = intable[1]
	return f(unpack(intable, 2))
end

-- arg is a table, if arg[1] is a function then calls it with fcall
-- else, does arg[1][arg[3]] = arg[2]
-- if addarg and switch are provided, the arg is inserted
-- in the switchth spot. switch can be an array, in which case
-- arrays are traversed by index: for instance, a switch value of
-- {4, 2, 3} would insert addarg into intable[4][2][3]
-- default {2}
local function route(intable, addarg, switch)
	if addarg then
		switch = switch or 2
		if type(switch) == "number" then
			switch = {switch}
		end
		local trav = intable
		local ltable
		local lindex
		for _, v in ipairs(switch) do
			-- if an index doesn't exist, create it
			if type(trav) ~= "table" then
				trav = {}
				table.insert(ltable, lindex, trav)
			end
			ltable = trav
			lindex = v
			trav = ltable[lindex]
		end
		table.insert(ltable, lindex, addarg)
	end
	if isfunction(intable[1]) then
		return fcall(intable)
	else intable[1][intable[3]] = intable[2] end
end

--call all promises or structures for route in a table
local function callall (intable)
	for _, v in pairs(intable) do
		if isfunction(v) then v()
		elseif istable(v) then route(v) end
	end
end

--[[uses fcall on args, but also stores array
returns an object with members:
call(): call args with fcall
setcall(item, index): set an arg at index and call
--]]
local function storargs(intable)
	local obj = {type = "stargs", args = intable}
	obj.call = function()
		fcall(obj.args)
	end
	obj.setcall = function(item, index)
		obj.args[index] = item
		obj.call()
	end
	return obj
end

-- cyclic counter maker
local function ccount(limit)
	local idx = 1
	return function()
		local ret = idx
		idx = idx + 1
		if idx > limit then idx = 1 end
		return ret
	end
end

-- http://lua-users.org/wiki/SplitJoin
local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

local comp = {
	log2 = log2,
	clip = clip,
	lagrange = lagrange,
	unexp = unexp,
	sto = sto,
	sfrom = sfrom,
	reflect = reflect,
	frange = frange,
	scalef = scalef,
	each = each,
	map = map,
	rmap = rmap,
	identity = identity,
	reduce = reduce,
	count = countn,
	size = size,
	reject = reject,
	select = lselect,
	pluck = pluck,
	chunk = chunk,
	slice = slice,
	first = first,
	last = last,
	flatten = flatten,
	zip = zip,
	append = append,
	interleave = interleave,
	range = range,
	rep = rep,
	reverse = reverse,
	bsearch = bsearch,
	compose = compose,
	pipe = pipe,
	wrap = wrap,
	bind = bind,
	bindn = bindn,
	isequal = isequal,
	detect = detect,
	max = max,
	min = min,
	isnot = isnot,
	isstring = isstring,
	isfunction = isfunction,
	isnil = isnil,
	isnumber = isnumber,
	isboolean = isboolean,
	isinteger = isinteger,
	istable = istable,
	type = ltype,
	gcd = gcd,
	copyar = copyar,
	copytab = copytab,
	deepcopy = deepcopy,
	domult = domult,
	promise = promise,
	odds = odds,
	route = route,
	pick = pick,
	shuffle = shuffle,
	wonce = wonce,
	fcall = fcall,
	stargs = storargs,
	callall = callall,
	ccount = ccount,
    countt = countt,
	split = split,
    scaletou = scaletou,
    scalefromu = scalefromu
}

return comp
