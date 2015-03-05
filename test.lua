-- comment out things in this file using:
--[[ comment in order to test how things work --]]

function testfunc()
	bv(2000) -- set beat value for this environment (2000 ms)
	-- delay by 1/2 beat
	bdelay(.5)
	-- do the following 4 times:
	for i=1, 4 do
		-- send to "bd" receiver with "list" selector
		pdsend{"bd", "list", "this", "is", "a", "bass", "drum?"}
		-- delay by a beat
		bdelay(1)
	end
end

-- define a step sequencer that prints, every 50 ms, 100 times
paul = stepseq({{{print, "one"}}, {{print, "blah"}},
		{{print, "three"}},  {{print, "4"}},
		{{print, "5"}},  {{print, "6"}}}, 50, 100)

-- define a global function
function test(loo)
	print(loo)
end

-- main function that start() calls (entry point)
function main()
	-- print to pd console
	print("hi, in main")
	-- make an exponential line that prints every 25 milliseconds
	local aline = reline(print, 25)
	-- add paul, have it start at step 1
	addfnow(paul.addf(1))
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
	-- add the line, go to 0 in 10 seconds
	addfnow(aline.addf(0, 10000))
end