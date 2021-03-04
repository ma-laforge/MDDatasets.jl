@testset "DataHR tests" begin show_testset_section() #Scope for test data

using MDDatasets
using Test


#==Input data
===============================================================================#
#Sample DataF1 leaf dataset:
d1 = DataF1([1,2,3], [4,5,6])
sweeplist1 = PSweep[
	PSweep("v1", [1,2])
	PSweep("v2", [4,5])
]
sweeplist2 = PSweep[ #2nd sweep is different variable than sweeplist1
	PSweep("v1", [1,2])
	PSweep("v4", [4,5])
]
sweeplist3 = PSweep[ #Points of 2nd sweep are different than sweeplist1
	PSweep("v1", [1,2])
	PSweep("v2", [3,4])
]

#Construct using low-level functions:
dhr1_ll = DataHR(sweeplist1,DataF1[d1 d1; d1 d1])

dhr1 = fill(d1, DataHR, sweeplist1)
dhr2 = fill(d1, DataHR, sweeplist2)
dhr3 = fill(d1, DataHR, sweeplist3)


#==Tests
===============================================================================#
@testset "Validate _datamatch()" begin show_testset_description()
	other = dhr1*1.0
	@test !_datamatch(dhr1, other+1) #Make sure _datamatch works
	@test _datamatch(dhr1, other)
end

@testset "Construction of DataHR objects" begin show_testset_description()
	dhr1_0 = zeros(DataHR, sweeplist1)
	dhr1_1 = ones(DataHR, sweeplist1)
	dhr1_2 = fill(2, DataHR, sweeplist1)

	@test _datamatch(dhr1_2-dhr1_1, dhr1_1)
	@test _datamatch(dhr1_2-dhr1_1, dhr1_1)
	@test _datamatch(dhr1_2-2*dhr1_1, dhr1_0)

	@test _datamatch(dhr1_0.elem, zeros(Float64, size(DataHR, sweeplist1)))
	@test _datamatch(dhr1_1.elem, ones(Float64, size(DataHR, sweeplist1)))
end

@testset "Broadcast operations on DataHR" begin show_testset_description()
	s1 = dhr1 + dhr1
	@testset "Validate s1 = dhr1+dhr2" begin
		for (es1, e1) in zip(s1.elem, dhr1.elem)
			@test es1.x == e1.x
			@test es1.y == (e1.y .+ e1.y)
		end
	end
	@test_throws ArgumentError dhr1+dhr2 #Mismatched sweeps
	@test_throws ArgumentError dhr1+dhr3 #Mismatched sweeps
end

@testset "Conversion (DataRS <=> DataHR)" begin show_testset_description()
	datahr_1 = dhr1
	datars = convert(DataRS, datahr_1)
	datahr_2 = convert(DataHR, datars)
	@test _datamatch(datahr_1, datahr_2)

	#Verify that the sweeps match:
	@test datars.sweep == dhr1.sweeps[1]
	@test datars.elem[1].sweep == datahr_1.sweeps[2]
	@test datars.elem[2].sweep == datahr_1.sweeps[2]

end

end
