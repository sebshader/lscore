require "Heap"
require "comp"
require "mus"
require "musenv"
require "compat"
require "oscpat"

--the user of Score defines clock_callback
Score = {}
Score.clock_callback=function(self, time)
			error([[define clock_callback as object:clock_callback
				(time). after time this callback function should call
				self:callback(). varargs from delay(time, ...) 
				are in the table self.pqueue[1][5]. In addition
				self.time should be incremented by the delay amount]])
			return nil
end
		-- the user can add a function to call once a score completes
Score.done=function(self) end,
		[[--add common score functions to this(e.g. 
		function Score.ENV.makemarkov() blah blah end
		these should not need access to the Score object dataspace--]]
Score.ENV = {}

Score.ENV.__index = Score.ENV
setmetatable(Score.ENV, {__index = _G})

local function makepqmbr(f, time, DYN, args)
	local time = time or 0
	local DYN = DYN or {}
	local args = args or {}
	return {time, coroutine.create(f), f, DYN, args}
end

function Score:new()
	local object = {}
	--inherit both the class and score functions
	setmetatable(object, self)
	self.__index = self
	
	object.pqueue = Heap:new(function(a, b) return a[1] > b[1] end)
	-- per-instance "globals"
	--load functions into here
	object.loadENV = {}
	object.loadENV.__index = object.loadENV
	--current "running" environment
	object.curENV = nil
	object.time = 0
	object.ENV = {
		-- user has full control
		this=object,
		addbase = function(f, time, bool, ...)
			local dynamic = self.base.envadd(bool)
			dynamic.fms(time)
			local member = makepqmbr(f, time, dynamic, {...})
			self.pqueue:insert(member)
		end,
		--add new coroutine function
		add = function(f, time, bool, ...)
		-- create dynamically scoped globals for each new coroutine
			local dynamic
			if object.curENV then
				dynamic = object.curENV:envadd(bool)
				dynamic.fms(time)
			else return end
			object.pqueue:insert(makepqmbr(
				f, time + object.time, dynamic,
					{...}))
			return dynamic
		end,
		-- get how many ms beats is
		inbeats = function(beats) return beats*object.curENV.bv() end,
		--same but with beat value for time
		badd = function(f, beats, bool, ...)
			object.ENV.add(f, beats*object.curENV.bv(), bool, ...)
		end,
		-- add function with no delay, inheriting beat+measure info
		addfnow = function(f, ...)
			object.ENV.add(f, 0, false, ...)
		end,
		gettime = function() return object.time end,
		--play a note with noteoff (call beginf and endf with variable args)
		pnotef=function(name, beginf, nendf)
			object.loadENV[name] = function(dur, bargs, eargs)
				beginf(unpack(bargs))
				object.ENV.badd(nendf, dur, false, unpack(eargs))
			end
		end,
		--regular delay
		delay = function(time, ...)
			local cpy = object.pqueue[1]
			cpy[1] = time + object.time
			cpy[4].fms(time)
			cpy[5] = {...}
			object.pqueue:insert(cpy)
			--if for some reason you want to pass stuff from another part of 
			--the score
			return coroutine.yield()
		end,
		--call a function with fcall and then delay
		--(f is an array for fcall)
		fdelay = function(f, deltime, ...)
			local res = comp.fcall(f)
			obj.ENV.delay(deltime, ...)
			return res
		end,
		bfdelay = function(f, beats, ...)
			return fdelay(f, obj.ENV.inbeats(beats), ...)
		end,
		--delay based in beats number of beatval
		bdelay = function(beats, ...)
			object.ENV.delay(object.ENV.inbeats(beats), ...)
		end,
		-- this makes a certain function take over the current coroutine 
		-- the function runs until over, then the parent coroutine resumes
		-- like add, but in "series" rather than "parallel"
		possess = function(f, ...)
			local res = object.pqueue[1][3]
			object.pqueue[1][3] = f
			setfenv(f, object.pqueue[1][4])
			f(...)
			object.pqueue[1][3] = res
		end
	}
	--still want global vars
	object.ENV.setg = function(key, value) object.loadENV[key] = value end
	object.ENV.getg = function(key) return object.loadENV[key] end
	setmetatable(object.loadENV, object.ENV)
	object.base = musenv.make(nil, object.loadENV)
	object.ENV.__index = object.ENV
	setmetatable(object.ENV, Score.ENV)
	return object
end

-- keeps track if predone has been entered yet
local predone

--basically interface to self.ENV.add, from the base environment
function Score:startfrom(f, time, bool, ...)
	-- reset predone (un-entered)
	predone = true
	if not self.curENV then
		self.time = 0
	end
	if f then
		local dynamic = self.base.envadd(bool)
		dynamic.fms(time)
		local member = makepqmbr(f, time, dynamic, {...})
		self.curENV = member[4]
		self.pqueue:insert(member)
		self:clock_callback(self.pqueue[1][1])
	else error("Score: no function")
	end
end

function Score:start(time, ...)
	self.pqueue:clear()
	self:startfrom(self.loadENV.main, time, true, ...)
end

function Score:stop()
	self.pqueue:clear()
	self.curENV = nil
end

function Score:clear()
	for k in next, self.loadENV do self.loadENV[k] = nil end
end

-- callback receives the amount of time to increment the clock, and
-- also sends it to clock_callback
function Score:callback(time)
	self.time = self.time + time
	local current = self.pqueue[1]
	--perhaps Score:clear() was called
	if not current then
		return end
	-- set env to the right function
	setfenv(current[3], current[4])
	coroutine.resume(current[2], unpack(current[5]))
	self.pqueue:remove()
	if self.pqueue[1] then 
		self.curENV = self.pqueue[1][4]
		self:clock_callback(self.pqueue[1][1] - self.time)
	else
		if self.loadENV.predone and predone then
			predone = false
			local dynamic = self.base.envadd()
			local member = makepqmbr(self.loadENV.predone, 0, dynamic)
			self.curENV = member[4]
			self.pqueue:insert(member)
			setfenv(member[3], member[4])
			coroutine.resume(member[2])
			self.pqueue:remove()
			if self.pqueue[1] then
				self.curENV = self.pqueue[1][4]
				self:clock_callback(self.pqueue[1][1] - self.time)
				return
			end
		end
		self.curENV = nil
		self:done()
	end
end

-- an object to play a pattern in the scheduler.
-- time can be a default pattern or value to delay.
-- if pattern returns a value, that value is used as delay time
-- else the default time is used
-- mult is the number of times to play the pattern:
-- if true then the pattern will continue forever
-- stop stops the pattern in the clock.
-- pplayer can only spawn 1 thread
-- create threads with add(pplayerobj.addf(), etc.)
--to stop: current=false
function Score.ENV.pplayer(pattern, time, mult)
	local obj = {type = "patplayer"}
	-- make time into a pattern if it isn't one
	local count
	local objcount
	local current = false
	obj.time = function(intime)
		if intime then
			if not compat.ispatt(intime) then
			time = compat.const(intime)
			else time = intime end
		end
		if time.type ==  "constpat" then return time.val end
	end
	if time then obj.time(time) end
	obj.c = pattern
	obj.mult = mult or 1
	obj.stop = function() current = false end
	obj.addf = function()
		if type(current) ~= "number"
			then current = 1
		else current = current + 1 end
		local mycount = current
		
		return function ()
			-- check if this was the last thing added
			if mycount ~= current then return
			else current = this.curENV end
			if comp.isnumber(obj.mult) then count = obj.mult
			else count = nil end
			repeat
				del = obj.c.next() or time.next()
				if count then 
					count = count - 1
					if count <= 0 then
						current = nil
						return
					end
				end
				delay(del)				
			until current ~= this.curENV
		end
	end
	return obj
end

function Score.ENV.stepseq(inseq, mtx, time, mul)
	local obj = {type = "seq"}
	if not inseq then
		inseq = {}
		for i=1, 16 do
			inseq[i] = {}
		end
	end
	obj.walker = compat.walker(inseq)
	obj.player = Score.ENV.pplayer(compat.route(obj.walker, mtx), 
		time, mul)
	-- set a step + lane value
	obj.set = function(step, lane, value)
		obj.walker.arr[step][lane] = value
	end
	obj.rem = function(step, lane)
		obj.walker.arr[step][lane] = nil
	end
	--delete lane
	obj.delane = function(lane)
		for i=1, #obj.walker.arr do
			obj.walker.arr[i][lane] = nil
		end
		obj.player.c.mtx[lane] = nil
	end
	obj.destep = obj.walker.rem
	obj.addstep = obj.walker.add
	obj.addf = function(step, mul)
		if step then obj.walker.walk.getset(step) end
		if mul then obj.player.mult = mul end
		return obj.player.addf()
	end
	return obj
end

-- 1st arg: {destination, index} to be used by comp.route
function Score.ENV.line(f, tincr, value)
	tincr = tincr or 10
	value = value or 0
	local inter = {type = "line"}
	inter.player = Score.ENV.pplayer(compat.route(compat.walk{lmode = "limit"}), 
		tincr)
	-- set, don't output value
	inter.set = function(v)
		value = v or values
		inter.player.stop()
		return value
	end
	-- do output value
	inter.jump = function(v)
		value = v or value
		local tab = {}
		local router = inter.player.c.mtx[1]
		tab[1] = router[1][1]
		tab[2] = value
		for i=2, #router do
			tab[i+1] = router[1][i]
		end
		inter.player.stop()
		comp.route(tab, router[2])
	end
	-- what to do with the value?
	-- infunc is in the form {{array arg arg la} position}
	-- if it is a single function the function will be called
	-- with the value
	inter.setf = function(infunc)
		if type(infunc) ~= "table" then
			--assume function with 1 arg
			local dum = {{}}
			dum[1][1] = infunc
			infunc = dum
		--use entire table as first arg
		elseif type(infunc[1]) ~= "table" then
			infunc = {infunc}
		end
		inter.player.c.mtx[1] = infunc
	end
	inter.setf(f)
	-- set time grain
	inter.time = function(incr)
		tincr = incr or tincr
		return tincr
	end
	-- the function to: add(lineobj.addf, time, bool, goto, time)
	inter.addf = function(goto, time)
		-- store local increment
		if tincr ~= inter.player.time() then inter.player.time(tincr) end
		local times = math.floor(time/tincr)
		local diffval = (goto - value)/times
		inter.player.c.c.setrange(value, goto)
		inter.player.c.c.getset(value)
		inter.player.c.c.step(diffval)
		inter.player.mult = times + 1
		return inter.player.addf()
	end
	-- stop where you are
	inter.stop = function()
		inter.player.stop()
	end
	return inter
end

-- like line, but exponential envelope
function Score.ENV.reline(f, tincr, value)
	tincr = tincr or 10
	value = value or 0
	local gotodif
	
	local inter = {type = "reline"}
	inter.player = Score.ENV.pplayer(compat.route(compat.pipe(
		compat.walk{lmode = "limit", low = 0, high = 1}, 
			{function(val)
				return (1 - comp.unexp(val))*gotodif + value
			end}, 
			true)), 
		tincr)
	-- set, don't output value
	inter.set = function(v)
		value = v or values
		inter.player.stop()
		return value
	end
	-- do output value
	inter.jump = function(v)
		value = v or value
		local tab = {}
		local router = inter.player.c.mtx[1]
		tab[1] = router[1][1]
		tab[2] = value
		for i=2, #router do
			tab[i+1] = router[1][i]
		end
		inter.player.stop()
		comp.route(tab, router[2])
	end
	-- what to do with the value?
	-- infunc is in the form {{array arg arg la} position}
	-- if it is a single function the function will be called
	-- with the value
	inter.setf = function(infunc)
		if type(infunc) ~= "table" then
			--assume function with 1 arg
			local dum = {{}}
			dum[1][1] = infunc
			infunc = dum
		--use entire table as first arg
		elseif type(infunc[1]) ~= "table" then
			infunc = {infunc}
		end
		inter.player.c.mtx[1] = infunc
	end
	inter.setf(f)
	-- set time grain
	inter.time = function(incr)
		tincr = incr or tincr
		return tincr
	end
	-- the function to: add(lineobj.addf, time, bool, goto, time)
	inter.addf = function(goto, time)
		-- store local increment
		if tincr ~= inter.player.time() then inter.player.time(tincr) end
		local times = math.floor(time/tincr)
		local diffval
		if times ~= 0 then diffval = -1/times
		else diffval = -1 end
		inter.player.c.c.c.getset(1)
		inter.player.c.c.c.step(diffval)
		inter.player.mult = times + 1
		gotodif = goto - value
		return inter.player.addf()
	end
	-- stop where you are
	inter.stop = function()
		inter.player.stop()
	end
	return inter
end

-- like line, but exponential envelope
function Score.ENV.eline(f, tincr, value)
	tincr = tincr or 10
	value = value or 0
	local gotodif
	
	local inter = {type = "eline"}
	inter.player = Score.ENV.pplayer(compat.route(compat.pipe(
		compat.walk{lmode = "limit", low = 0, high = 1}, 
			{function(val)
				return comp.unexp(val)*gotodif + value
			end}, 
			true)), 
		tincr)
	-- set, don't output value
	inter.set = function(v)
		value = v or values
		inter.player.stop()
		return value
	end
	-- do output value
	inter.jump = function(v)
		value = v or value
		local tab = {}
		local router = inter.player.c.mtx[1]
		tab[1] = router[1][1]
		tab[2] = value
		for i=2, #router do
			tab[i+1] = router[1][i]
		end
		inter.player.stop()
		comp.route(tab, router[2])
	end
	-- what to do with the value?
	-- infunc is in the form {{array arg arg la} position}
	-- if it is a single function the function will be called
	-- with the value
	inter.setf = function(infunc)
		if type(infunc) ~= "table" then
			--assume function with 1 arg
			local dum = {{}}
			dum[1][1] = infunc
			infunc = dum
		--use entire table as first arg
		elseif type(infunc[1]) ~= "table" then
			infunc = {infunc}
		end
		inter.player.c.mtx[1] = infunc
	end
	inter.setf(f)
	-- set time grain
	inter.time = function(incr)
		tincr = incr or tincr
		return tincr
	end
	-- the function to: add(lineobj.addf, time, bool, goto, time)
	inter.addf = function(goto, time)
		-- store local increment
		if tincr ~= inter.player.time() then inter.player.time(tincr) end
		local times = math.floor(time/tincr)
		local diffval
		if times ~= 0 then diffval = 1/times
		else diffval = 1 end
		inter.player.c.c.c.getset(0)
		inter.player.c.c.c.step(diffval)
		inter.player.mult = times + 1
		gotodif = goto - value
		return inter.player.addf()
	end
	-- stop where you are
	inter.stop = function()
		inter.player.stop()
	end
	return inter
end

function Score.ENV.oscil(f, sp, osctype, freq, pwm)
	local inter = {type = "oscillator"}
	freq = freq or 0
	inter.player = Score.ENV.pplayer(compat.route(oscpat.new(osctype)))
	inter.setf = function(infunc)
		if type(infunc) ~= "table" then
			--assume function with 1 arg
			local dum = {{}}
			dum[1][1] = infunc
			infunc = dum
		--use entire table as first arg
		elseif type(infunc[1]) ~= "table" then
			infunc = {infunc}
		end
		inter.player.c.mtx[1] = infunc
	end
	inter.setf(f)
	inter.freq = function(infreq)
		freq = infreq
		inter.player.c.c.per(freq*sp)
	end
	inter.sp = function(insp)
		sp = insp/1000
		inter.player.time(insp)
		inter.freq(freq)
	end
	inter.phase = function(inphase)
		inter.player.c.c.phase = inphase
	end
	inter.sp(sp or 10)
	inter.pwm = function(inpwm)
		inter.player.c.c.pwm(inpwm)
	end
	if pwm then inter.pwm(pwm) end
	inter.addf = function(length, infreq, phase)
		if type(length) == "number" then
			inter.player.mult = length/(sp*1000)
		else inter.player.mult = length end
		if infreq then inter.freq(infreq) end
		inter.phase(phase or 0)
		return inter.player.addf()
	end
	return inter
end
	
return Score