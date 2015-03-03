-- comment out things in this file using:
--[[ comment in order to test how things work --]]

function testfunc()
	bv(2000) -- set beat value for this envelope
	bdelay(.5)
	for i=1, 4 do
		pdsend{"bd", "list", "this", "is", "a", "bass", "drum?"}
		bdelay(1)
	end
end

-- step sequencer that prints, every 50 ms, 100 times
paul = stepseq({{{print, "one"}}, {{print, "blah"}},
		{{print, "three"}},  {{print, "4"}},
		{{print, "5"}},  {{print, "6"}}}, 50, 100)

function test(loo)
	print(loo)
end

function main()
	pd.post("hi, in main")
	-- add a line that prints every 250 milliseconds
	local aline = line(print, 250)
	-- add paul, have it start at step 1
	addfnow(paul.addf(1))
	addfnow(testfunc)
	print("jumping:")
	aline.jump(10)
	for i=1, 4 do
		pd.post("onbeat")
		bdelay(1)
	end
	addfnow(aline.addf(0, 10000))
end