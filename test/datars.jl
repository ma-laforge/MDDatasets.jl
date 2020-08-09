@testset "DataRS tests" begin show_testset_section() #Scope for test data

using MDDatasets
using Test


#==Input data
===============================================================================#
#get_ydata: Generates sine data from input parameters
get_ydata(t, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd

t = DataF1((1:2)*1e-9)

#Construct DataRS object from parametric sweeps:
data = fill(DataRS, PSweep("tbit", [1, 3] * 1e-9)) do tbit
	#Need to explicitly specify DataRS{DataF1} as type for inner-most sweep:
	fill(DataRS{DataF1}, PSweep("VDD", 0.9 * [0.9, 1])) do vdd
		trise = 0.1*tbit
		return get_ydata(t, tbit, vdd, trise)
	end
end

#Construct DataRS object from parametric sweeps:
_datagen1(indep::Bool) = fill(DataRS, PSweep("A", Float64[1, 3])) do A
	offset = indep ? 0 : A
	#Need to explicitly specify DataRS{DataFloat} as type for inner-most sweep:
	fill(DataRS{DataFloat}, PSweep("B", Float64[3, 5, 6] .+ offset)) do B
		return 10A + B
	end
end


#==Tests
===============================================================================#
@testset "Construction of DataRS objects" begin show_testset_description()
	#TODO: write tests to verify structure
	@info("Visually confirm structure of \"data\":")
	@show data

	@test data.sweep.id == "tbit" #should be outer-most loop
	@test data.elem[1].sweep.id == "VDD" #should be inner-most loop
end

@testset "Access parameter data" begin show_testset_description()
	#Extract value of tbit (first sweep):
	data_tbit = parameter(data, "tbit")

	#Get sweep values:
	sw_tbit = data.sweep.v
	sw_vdd = data.elem[1].sweep.v
	
	for itbit in 1:length(sw_tbit), ivdd in 1:length(sw_vdd)
		@test data_tbit.elem[itbit].elem[ivdd] == sw_tbit[itbit]
	end
end

@testset "Broacasting operations on DataRS" begin show_testset_description()
	#Get sweep values:
	sw_tbit = data.sweep.v
	sw_vdd = data.elem[1].sweep.v


	_v = 0*data+5 #Same dimensionality as data
	@testset "_v = 0*data+5" begin
		v5 = zeros(length(t)) .+ 5
	
		for itbit in 1:length(sw_tbit), ivdd in 1:length(sw_vdd)
			_elem = _v.elem[itbit].elem[ivdd]
			@test _elem.x == t.x
			@test _elem.y == v5
		end
	end

	_vshift = data + _v
	@testset "_vshift = data + _v" begin
		for itbit in 1:length(sw_tbit), ivdd in 1:length(sw_vdd)
			_elem = _vshift.elem[itbit].elem[ivdd]
			@test _elem.x == t.x
			@test _elem.y == data.elem[itbit].elem[ivdd].y .+ 5
		end
	end

	_m1 = maximum(data)
	@testset "_m1 = maximum(data)" begin
		for itbit in 1:length(sw_tbit), ivdd in 1:length(sw_vdd)
			_elem = _m1.elem[itbit].elem[ivdd]
			@test typeof(_elem) == Float64
			@test _elem == maximum(data.elem[itbit].elem[ivdd].y)
		end
	end

	_delta = data - _m1
	@testset "_delta = data - _m1" begin
		for itbit in 1:length(sw_tbit), ivdd in 1:length(sw_vdd)
			_elem = _delta.elem[itbit].elem[ivdd]
			@test _elem.x == t.x
			_y = data.elem[itbit].elem[ivdd].y
			@test _elem.y == _y .- maximum(_y)
		end
	end

	_m2 = maximum(_m1) #Collapse inner-most dimension again
	@testset "_m2 = maximum(_m1)" begin
		for itbit in 1:length(sw_tbit)
			_elem = _m2.elem[itbit]
			@test typeof(_elem) == Float64
			@test _elem == maximum(_m1.elem[itbit])
		end
	end

	_m3 = maximum(_m2) #Collapse inner-most dimension again
	@testset "_m3 = maximum(_m2)" begin
		_elem = _m3
		m2val = [_m2.elem[i] for i in 1:length(_m2)] #collect values in m2
		@test typeof(_elem) == Float64
		@test _elem == maximum(m2val)
	end
end

@testset "Conversion DataRS => DataHR" begin show_testset_description()
	datars_indep=_datagen1(true)
	datars_dep=_datagen1(false)

	datahr = convert(DataHR, datars_indep)
		#TODO: test something
	@test_throws ArgumentError convert(DataHR, datars_dep)

	datars_2 = convert(DataRS, datahr)
	@test !_datamatch(datars_2, datars_2+1) #Make sure _datamatch works
	@test _datamatch(datars_2, datars_2)

	try
		datars_2 - datars_indep
	catch
		@warn("Cannot operate with DataRS re-created through DataHR because of PSweep comparison & way fill!(::DataRS) works.")
	end
end

end
