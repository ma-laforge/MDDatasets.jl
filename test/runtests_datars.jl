#Test DataRS manipulations
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:

println("\nTest constructors:")

data = fill(DataRS, PSweep("tbit", [1, 3, 9] * 1e-9)) do tbit
	fill(DataRS, PSweep("VDD", 0.9 * [0.9, 1, 1.1])) do vdd
		fill(DataRS{DataFloat}, PSweep("trise", [0.1, 0.15, 0.2] * tbit)) do trise
			return rand() #Return value
		end
	end
end

@show data

println("\nTest broadcast operations on DataRS:")


:Test_Complete
