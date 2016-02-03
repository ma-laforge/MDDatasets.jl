#Test DataRS manipulations
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:


#==Input data
===============================================================================#
sepline = "---------------------------------------------------------------------"

get_ydata(t, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd
t = DataF1((1:2)*1e-9)


#==Tests
===============================================================================#

println("\nTest constructors:")
#-------------------------------------------------------------------------------
println(sepline)

data = fill(DataRS, PSweep("tbit", [1, 3] * 1e-9)) do tbit
	fill(DataRS{DataF1}, PSweep("VDD", 0.9 * [0.9, 1])) do vdd
		trise = 0.1*tbit
		return get_ydata(t, tbit, vdd, trise)
	end
end


@show parameter(data, "tbit")
@show data

println("\nTest broadcast operations on DataRS:")
#-------------------------------------------------------------------------------
println(sepline)

v = 0*data+5 #Same dimensionality as data
@show shifted = data + v

@show m = maximum(data)
@show data - m
@show m = maximum(m)
@show m = maximum(m)



:Test_Complete
