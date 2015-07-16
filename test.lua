-- you can "require" lua libraries
require "randist"
-- comment out things in this file using:
--[[ comment in order to test how things work --]]
function testfunc()
	-- delay by 1/2 beat
	bdelay(.5)
	bv(1500) -- set beat value for this environment (2000 ms)
	-- do the following 3 times:
	for i=1, 3 do
		-- send to "bd" receiver with "list" selector
		pdsend{"bd", "list", "this", "is", "a", "bass", "drum?"}
		-- delay by a beat
		bdelay(1)
	end
end

-- define a step sequencer that prints, every 50 ms, 100 times
paul = stepseq({{"one"}, {"blah"},
		{"three"},  {"4"},
		{"5"},  {"6"}}, {{{print}}}, 50, 80)

-- define a global function
function test(loo)
	print(loo)
end

-- if a function named "predone" is in the global loadENV,
-- it will be called before exiting
-- here a sine is sent to "display" with a pulse-width mod of .25
-- (so 1/2 the cycle will finish in 1/4 of the total wavelength)

-- if possess is changed to addfnow, then "done!" will display
-- before the oscillator, not after
function predone()
	possess(oscil({{pdsend, {"display", "float"}},
		{2, 3}}, 5, "sin", 0, 0.25).addf(5005, 1, 0))

	print("done!")
end

-- main function that start() calls (entry point)
function main()
	-- print to pd console
	print("hi, in main")
	-- make an exponential line that prints every 25 milliseconds
	local aline = reline(print, 25)
	-- add testfunc
	addfnow(testfunc)
	print("jumping:")
	-- now the line will jump to 10 and call print() on 10
	aline.jump(10)
	for i=1, 4 do
		pd.post("onbeat")
		--delay by a beat
		bdelay(1)
	end
	-- add paul, have it start at step 1, and have it take over main's thread
	possess(paul.addf(1))
	-- add the line, go to 0 in 4 seconds after paul's done
	addfnow(aline.addf(0, 4000))
end