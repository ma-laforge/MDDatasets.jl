#Test DataHR manipulations
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:


#==Input data
===============================================================================#
sepline = "---------------------------------------------------------------------"


#==Tests
===============================================================================#

println("\nTest constructors:")
#-------------------------------------------------------------------------------
println(sepline)
@show d1 = DataF1([1,2,3], [4,5,6])
sweeplist = PSweep[
	PSweep("v1", [1,2])
	PSweep("v2", [4,5])
]
sweeplist2 = PSweep[
	PSweep("v1", [1,2])
	PSweep("v4", [4,5])
]
sweeplist3 = PSweep[
	PSweep("v1", [1,2])
	PSweep("v2", [3,4])
]
@show dhr = DataHR(sweeplist,DataF1[d1 d1; d1 d1])
dhr2 = DataHR(sweeplist2,DataF1[d1 d1; d1 d1])
dhr3 = DataHR(sweeplist3,DataF1[d1 d1; d1 d1])

println("\nTest broadcast operations on DataHR:")
#-------------------------------------------------------------------------------
println(sepline)
dhr+dhr
try; dhr+dhr2; warn("Failed")
catch e; info("Fail successful: ", e.msg); end

try; dhr+dhr3; warn("Failed")
catch e; info("Fail successful: ", e.msg); end


println("\nTest conversion to DataRS:")
#-------------------------------------------------------------------------------
println(sepline)
@show dhr
@show DataRS(dhr)


println("\nTest \"ensure\" system:")
#-------------------------------------------------------------------------------
println(sepline)
try;
	ensure(false) do
		ArgumentError("Predicate failed.")
	end
	warn("Failed")
catch e; info("Fail successful: ", e.msg); end


#==
println("\nTest value():")
#Could be made into real test:
for i in 1:length(d10.x)
	@show d10.y[i], value(d10, x=i)
end
==#


:Test_Complete
