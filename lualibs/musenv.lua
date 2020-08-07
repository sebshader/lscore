require "mus"
local floor = math.floor

--note: every child must be explicitly cleaned up

-- make an environment for music-making
local function makebase(intable, parent)
	intable = intable or {}
	-- reserved functions - user cannot redefine these
	local reserved = {}
	-- top dataspace. Each new env inherits from creating dataspace
	local resenv = {}
	-- top env
	--local top = {}
	--resenv.__index = resenv
	-- top user interface. user interface also inherits from the creating
	-- one
	local obj = {}
	local current
	
	--set resenv's parent
	obj.meta = parent

	obj.envadd = function(bool)
		current = resenv
		return reserved.envadd(bool)
	end
	obj.type = "environment"
	obj.__index = function(table, key)
		current = resenv
		if reserved[key] then
			return reserved[key]
		end
	end
	obj.__newindex = {}
	setmetatable(obj, obj)
	setmetatable(resenv, obj.meta)
	
	-- chromatic by default
	resenv.scale = intable.f or intable[1] or function(i) return i end
	resenv.root = intable.root or intable[2] or 0
	resenv.octave = floor(intable.octave or intable[3] or 4)
	resenv.octavec = 12*(resenv.octave + 1)
	resenv.tempo = intable.tempo or intable[4]
	resenv.beatval = intable.beatval
	--beats in a measure
	resenv.mbeats = intable.sig or intable[5]
	if not resenv.mbeats or resenv.mbeats <= 0 then resenv.mbeats = 4 end
	-- measures & beats transpired
	resenv.beatn = 0.0
	resenv.measn = 0.0
	--remainder ms
	if resenv.tempo and resenv.tempo > 0 then
		resenv.beatval = 60000/resenv.tempo
	else
		if resenv.beatval and resenv.beatval > 0 then
			resenv.tempo = 60000/resenv.beatval
		else
			resenv.tempo = 60
			resenv.beatval = 1000
		end
	end
	
	--set/get beatval
	reserved.bv = function(bv)
		if bv and bv > 0 then
			current.beatval = bv
			current.tempo = 60000/bv
		end
		return current.beatval
	end
	
	--set/get tempo
	reserved.temp = function(temp)
		if temp and temp > 0 then
			current.tempo = temp
			current.beatval = 60000/temp
		end
		return current.tempo
	end
	
	reserved.setrt = function(i)
		i = i or 0
		current.root = i % 12
	end
	
	-- set scale
	reserved.setsc = function(func)
		if func then current.scale = func end
	end
	
	-- set octave
	reserved.seto = function(ino)
		current.octave = ino
		current.octavec = 12*(ino + 1)
	end
	
	-- set number of beats in a measure (need not be an integer)
	reserved.setmb = function(beats, reset)
		if beats and beats > 0 then
			if current.mbeats > beats and reset then
				current.beatn = 0
			else
				current.beatn = current.beatn % current.mbeats
			end
			current.mbeats = beats
		end
	end
	
	-- set timestamp
	reserved.loc = function(measures, beats)
		if measures or beats then
			measures = measures or current.measn
			beats = beats or 0
			current.measn = floor(measures)
			current.beatn = beats % current.mbeats
		end
		return current.measn, current.beatn
	end
	
	--general get function
	reserved.get = function(key)
		return current[key]
	end
	
	--take context forward ms amount
	reserved.fms = function(ms)
		if not ms then 
			error("fms: no ms specified")
			return
		end
		local beat = current.beatn + (ms/current.beatval)
		current.measn = current.measn + floor(beat/current.mbeats)
		current.beatn = beat % current.mbeats
	end
	
	--get note # in current environment
	reserved.penv = function(i, ioctave, add)
		add = add or 0
		if ioctave then reserved.seto(ioctave) end
		return current.octavec + current.root + current.scale(i) + add
	end

	-- add new child environment with the same vars,
	-- if bool is true then measure/beats reset. if not then inherits from
	-- parent environment
	reserved.envadd = function(parent, bool)
		local private = {}
		local newobj = {}
		if bool then
			newobj.beatn = 0.0
			newobj.measn = 0.0
		end
		--newenv.__index = newenv
		--newobj.oparent = parent
		newobj.parent = parent or current
		--setmetatable(newenv, current)
		setmetatable(newobj, private) 
		
		private.__index = function(table, key)
			current = newobj
			if reserved[key] then
				return reserved[key]
			else
				local v
				repeat
					v = rawget(table, key)
         			if v ~= nil then return v end
         			--table = lenv.oparent
         			table = table.parent
				until table == resenv
				return resenv[key]
			end
		end
		private.__newindex = function(table, key, value)
			current = newobj
			if reserved[key] then
				return
			else rawset(table, key, value) end
		end
		return newobj
	end
	
	return obj
end

musenv = {
	make = makebase
}

return musenv