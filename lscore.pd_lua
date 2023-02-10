local lscore = pd.Class:new():register("lscore")

local function settpath()
	local path = lscore._loadpath
	if (pd._iswindows) then
		package.path = path .. "lualibs\\?;" .. path .. "lualibs\\?.lua;" .. package.path
		package.cpath = path .. "lualibs\\?.dll;" .. package.cpath
	else
		package.path = path .. "lualibs/?;" .. path .. "lualibs/?.lua;" .. package.path
		package.cpath = path .. "lualibs/?.so;" .. package.cpath
	end
end

settpath()

require "Score"
require "comp"

pd._clearrequirepath()

Score.ENV.print = function(inthing) pd.post(tostring(inthing)) end
--send to a receiver in format: {receiver, sel, arg1, arg2, etc}
Score.ENV.pdsend = function(atable)
	local cop = Comp.copytab(atable)
	local rec = table.remove(cop, 1)
	local sel = table.remove(cop, 1)
	pd.send(rec, sel, cop)
end

function lscore:initialize(_, atoms)
	self.inlets = 1
	self.outlets = 1
	self.score = Score:new()
	--current delay time
	self.time = 0
	--whether we are paused
	self.paused = false
    local path = self._canvaspath
	--simple wrapper for load
	self.score.ENV.dofiles = function(...)
		local args = {...}
		for i = 1, #args do
			local chunk = loadfile(path .. args[i] .. ".lua")
			setfenv(chunk, self.score.loadENV)
			chunk()
		end
	end
	self.score.ENV.dofiles(unpack(atoms))
	return true
end

function lscore:postinitialize()
	self.clock = pd.Clock:new():register(self, "trigger")

	local obj = self
	function self.score:clock_callback(time)
		obj.clock:delay(time)
		obj.time = time
	end
	function self.score:done()
		obj:outlet(1, "bang", {}) end
    self.score.ENV.pdopath = self._canvaspath
end

function lscore:in_1_load(atoms)
	local chunk = loadfile(self._canvaspath .. table.concat(atoms, " "))
	setfenv(chunk, self.score.loadENV)
	settpath()
	chunk()
	pd._clearrequirepath()
end

function lscore:in_1_clear()
	self.score:clear()
end

function lscore:in_1_start(atoms)
	self.score:start(atoms[1], unpack(atoms, 2))
end

--later write an interface to get system time
function lscore:in_1_pause()
	self.paused = true
	self.clock:unset()
end

function lscore:in_1_resume()
	self.paused = false
	self:trigger()
end

function lscore:in_1_stop()
	self.score:stop()
end

--add a function to the queue
function lscore:in_1_add(atoms)
	local f = atoms[1]
	local time = atoms[2]
	self.score:startfrom(self.score.loadENV[f], time, false, unpack(atoms, 3))
end

--set a key-value pair in score.loadENV
function lscore:in_1_set(atoms)
	local first = table.remove(atoms, 1)
	self.score.loadENV[first] = atoms
end

--call a function in loadENV
function lscore:in_1_call(atoms)
	local name = atoms[1]
	name = Comp.split(name, "%.")
	local t = self.score.loadENV
	for i=1, #name do
		if type(t[name[i]]) == "table" then
			t = t[name[i]]
		else
		 	name = name[i]
			break
		end
	end
	t[name](unpack(atoms, 2))
end

function lscore:finalize()
	self.clock:destruct()
end

function lscore:trigger()
	self.score:callback(self.time)
end
