--[[
This file contains a pattern for oscillators:
each has an interval, and each time "next" is called on the pattern
the interval will be incremented modulo 1 and the given (math) function
will be evaluated, returning values from -1 to 1
--]]

-- sine for convenience of phase
local function sin(phase)
	return math.sin(math.pi*phase*2)
end

local function saw(phase)
	return ((phase*2 + 1) % 2) - 1
end

local function tri(phase)
	return 1 - math.abs(2 - ((phase*4 + 1) % 4))
end

local function sqr(phase)
	if phase < .5 then return 1
	else return -1 end
end

local map = {sin=sin, saw=saw, tri=tri, sqr=sqr}

local function addrdr(array, name)
	map[name] = function(phase)
		return array[math.floor(phase*#array)]
	end
end

-- part is the number of times next() should be called in a cycle
-- osctype is either "sin", "saw", "tri", or "sqr"
-- phase is 0 to 1, so is pwm
local function new(osctype, part, phase, pwm)
	local obj = {
		patt = true,
		type = "oscpat",
		phase = phase or 0
	}
    local incrpart
    local incrper
	obj.part = function(inpart)
		if inpart then
			incrpart = inpart
			if incrpart == 0 then incrper = 0
			else incrper = 1/incrpart end
		end
		return incrpart
	end
	obj.part(part or 0)
	obj.per = function(inper)
		if inper then
			incrper = inper
			if incrper == 0 then incrpart = 0
			else incrpart = 1/incrper end
		end
		return incrper
	end
	local func
	obj.osctype = function(intype)
		if intype then
			osctype = intype
			func = map[osctype]
		end
		return osctype
	end
	obj.osctype(osctype or "sin")
	obj.pwm = function(mod)
		pwm = mod % 1
		if pwm == 0 then pwm = 0.999999999 end
	end
	obj.pwm(pwm or 0.5)
	obj.next = function()
		local ret = func(obj.phase)
		local modper
		if obj.phase < 0.5 then modper = incrper*.5/pwm
		else modper = incrper*.5/(1 - pwm) end
		obj.phase = (obj.phase + modper) % 1
		return ret
	end
	return obj
end

local oscpat = {
	map = map,
	addrdr = addrdr,
	new = new
}

return oscpat
