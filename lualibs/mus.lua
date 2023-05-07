local comp = require "comp"

--scales
--major
local Mscale = {0, 2, 4, 5, 7, 9, 11, 12}

--harmonic minor
local hmscale = {0, 2, 3, 5, 7, 8, 11, 12}

--melodic minor
local mmscale = {0, 2, 3, 5, 7, 9, 10, 12}

--k is mode:
-- 0 is Ionian, then dorian, phrygian, etc.
-- i is number to look up in the scale (0-based)
local function mode(i, k, table)
	table = table or Mscale
	k = k or 0
	local size = table[#table]
    -- subtract 1 for modulo (e.g. we want 0 - 6, not 1- 7)
	k = math.floor(k) % (#table-1)
	i = math.floor(i+0.5)
	return ((table[((i + k) % (#table - 1)) + 1] - table[k + 1]) % size)
		+ math.floor(i/(#table-1))*size
end

--makes a function to output a certain scale.
local function makemode(k, table)
	return function(i)
		return mode(i, k, table)
	end
end

--make general scales
local function makescale(table)
	return function(i)
		return(table[math.floor(i % (#table - 1)) + 1]) +
			math.floor(i/(#table-1))*table[#table]
	end
end

--fix scale to be 0-based, flattened and sorted
local function fixscale(input)
	--trying to modify input destructively
	local other = comp.flatten(input)
	table.sort(other)
	local diff = other[1]
	--other must be longer because input was flattened
	for i=1, #other do
		other[i] = other[i] - diff
	end
	--return input for convenience
	return other
end

local m = makemode(-2)
local M = makemode()
local hm = makemode(0, hmscale)
local mm = makemode(0, mmscale)

--just do this kinda like in Common Music, but no enharmonics
local name = {{"c"}, {"df", "cs"}, {"d"}, {"ef", "ds"},
	{"e"}, {"f"}, {"gf", "fs"}, {"g"}, {"af", "gs"}, {"a"},
	{"bf", "as"}, {"b"}, c=0, d=2, e=4, f=5,
	g=7, a=9, b=11}

--mapping ratios to cents and steps
--ratio to desired note from current note
local function tors(ratio)
	return 17.31234049066756088865182139358012136653997004032135009765625*math.log(ratio)
end

local function tosr(step)
	return 2^(step/12)
end

local function ratiostep(list)
	return comp.rmap(list, tors)
end

local function stepratio(list)
	return comp.rmap(list, tosr)
end

-- the following are inspired by Common Music
-- translates keynum to notes:
local function tonote(inkey)
	local octave = math.floor(inkey/12) - 1
	inkey = inkey % 12
	local frac
	local inflect = ""
	inkey, frac = math.modf(inkey)
	if frac > 0.333333 then
		inkey = (inkey + 1) % 12
		if frac < 0.666666 then
			inflect = "<"
		end
	end
	local octaves = tostring(octave)
	return(name[inkey + 1][1] .. inflect .. octaves)
end

-- translates a note or hertz to a keynum
local function tokey(insym)
	local typein = type(insym)
	if typein == "number" then
		return ratiostep(insym/440) + 69
	elseif typein == "string" then
        local keyr
		local pos, _, str = string.find(insym, "(%a)")
		if not pos then return
		else keyr = name[str] end
		pos = pos + 1
		pos, _, str = string.find(insym, "([fs])", pos)
		if pos then
			if str == "f" then keyr = keyr - 1
			else keyr = keyr + 1 end
			pos = pos + 1
		end
		str = string.match(insym, "([<>])", pos)
		if str then
			if str == "<" then keyr = keyr - .5
			else keyr = keyr + .5 end
		end
        local octave
		pos, _, str = string.find(insym, "([+-]?%d)", pos)
		if pos then octave = tonumber(str) end
		octave = octave or 4
		return ((octave + 1)*12) + keyr, octave
	end
end

--translate notes or keynums to hz
local function tohz(ref, octave)
	if type(ref) == "string" then
		local keyn
		local pos, _, str = string.find(ref, "(%a)")
		if not pos then return
		else keyn = name[str] end
		pos = pos + 1
		pos, _, str = string.find(ref, "([fs])", pos)
		if pos then
			if str == "f" then keyn = keyn - 1
			else keyn = keyn + 1 end
			pos = pos + 1
		end
		str = string.match(ref, "([<>])", pos)
		if str then
			if str == "<" then keyn = keyn - .5
			else keyn = keyn + .5 end
		end
		pos, _, str = string.find(ref, "([+-]?%d)", pos)
		if pos then octave = tonumber(str) end
		octave = octave or 4
		ref = ((octave + 1)*12) + keyn
	end
	return 440*2^((ref - 69)/12), octave
end

local function note(list)
	return comp.rmap(list, tonote)
end

local function keynum(list)
	if comp.istable(list) then
		local lt = {}
		for index,value in pairs(list) do
			lt[index] = keynum(value)
		end
		return lt
	else return tokey(list) end
end

local function hertz(list, octave)
	if comp.istable(list) then
		local lt = {}
		for index,value in pairs(list) do
			lt[index], octave = hertz(value, octave)
		end
		return lt
	else return tohz(list, octave) end
end

local function isrest(ref)
	return ref == -1 or ref == "r"
end

--get pitch class of ref
local function topc(insym)
	local typein = type(insym)
	if typein == "number" then
		return math.floor((insym % 12) * 2) / 2
	elseif typein == "string" then
		local keyn
		local pos, _, str = string.find(insym, "(%a)")
		if not pos then return
		else keyn = name[str] end
		pos = pos + 1
		pos, _, str = string.find(insym, "([fs])", pos)
		if pos then
			if str == "f" then keyn = keyn - 1
			else keyn = keyn + 1 end
			pos = pos + 1
		end
		str = string.match(insym, "([<>])", pos)
		if str then
			if str == "<" then keyn = keyn - .5
			else keyn = keyn + .5 end
		end
		return math.floor((keyn % 12) * 2) / 2
	end
end

local function pclass(list)
	return comp.rmap(list, topc)
end

--if ref and amount are pitch classes, transposes to modn space.
--otherwise, ref is note or key list
local function transpose(ref, amount)
	if comp.istable(ref) then
		if comp.isstring(ref[1]) then
			ref = keynum(ref)
			ref = comp.rmap(ref, function(value)
				return value + amount end)
			return note(ref)
		else
			ref = comp.rmap(ref, function(value)
				return value + amount end)
			return ref
		end
	else
		if comp.isstring(ref) then
			ref = tokey(ref)
			ref = ref + amount
			return tonote(ref)
		elseif ref < 12 then return ref + amount % 12
		else return ref + amount end
	end
end

--loadscala takes a string and
--parses it into a scale table (array) of semitones
--local function loadscala(instring)

local mus = {
	mode = mode,
	makemode = makemode,
	scale = makescale,
	fixscale = fixscale,
	name = name,
    tonote = tonote,
	note = note,
	keynum = keynum,
	hertz = hertz,
	isrest = isrest,
	pclass = pclass,
	transpose = transpose,
	ratiostep = ratiostep,
	stepratio = stepratio,
    tors = tors,
    tosr = tosr,
    topc = topc,
    tokey = tokey,
    tohz = tohz,
	m = m,
	M = M,
	hm = hm,
	mm = mm
}

return mus
