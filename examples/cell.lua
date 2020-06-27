predone = nil

cellob = pnotef(
	function(bargs)
		pdsend{"midio", "list", bargs, 127}
	end,
	function(bargs)
		pdsend{"midio", "list", bargs, 0}
	end, 0, 0, 500)
cel = cellob.play

function main()
	temp(90)
	local times = false
	while true do
		if(comp.odds(0.35)) then
			bfdelay({cel, 40}, 1.5)
		else
			bfdelay({cel, 38}, 0.5)
			bfdelay({cel, 40}, 1)
		end
		bfdelay({cel, 40}, 0.5)
		bfdelay({cel, 40}, 1)
		bfdelay({cel, 52}, 1)
		bfdelay({cel, 50}, 1.5)
		bfdelay({cel, (comp.odds(0.2) and 45 or 43)}, 0.5)
		if not times then
			if (comp.odds(0.5)) then
				cel((comp.odds(0.35) and 45 or 43))
			end
			bdelay(0.5)
			bfdelay({cel, (comp.odds(0.5) and 45 or 43)}, 0.5)
	
			bfdelay({cel, (comp.odds(0.8) and 45 or 43)}, 0.25)
			if (comp.odds(0.5)) then
				for i, v in ipairs {(comp.odds(0.5) and 45 or 43),
					45, 47} do
					bfdelay({cel, v}, 0.25)
				end
			else
				bfdelay({cel, 47}, 0.75)
			end
		else
			for i, v in ipairs {55, 54, 52, 50} do
				bfdelay({cel, v}, 0.5)
			end
		end
		times = not times
	end
end