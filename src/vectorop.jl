#MDDatasets vector operations
#-------------------------------------------------------------------------------

#==Useful tests
===============================================================================#

#Verifies that v is strictly increasing (no repeating values):
function isincreasing{T}(v::Vector{T})
	prev = v[1]
	for x in v[2:end]
		if x <= prev
			return false
		end
	end
	return true
end

isincreasing(r::Range) = (step(r) > 0)


#==Useful assertions
===============================================================================#


#==Helper functions
===============================================================================#

#Assumes vector is ordered... Not currently checking that it is true..
function findclosestindex(v::Vector, val)
	const reltol =  1/1000
	if length(v) < 2
		if abs(1-val/v[1]) < reltol
			return 1
		else
			throw("Value not found: $val")
		end
	end
	vlast = v[2] #Gets an order of magnitude for first point
	for idx in 1:length(v)
		Δ = abs(v[idx] - vlast)
		if abs(val-v[idx]) < reltol*Δ
			return idx
		end
		vlast = v[idx]
	end
	throw("Value not found: $val")
end


#==
===============================================================================#

#Create vector with data left-shifted by n (padded with 0s)
function lshift{T<:Vector}(v::T, n::Int)
	@assert(n >= 0, "Cannot shfit by a negative number")
	result = zeros(v)
	for i in 1:(length(v)-n)
		result[i] = v[i+n]
	end
	return result
end

#Create vector with data right-shifted by n (padded with 0s)
function rshift{T<:Vector}(v::T, n::Int)
	@assert(n >= 0, "Cannot shfit by a negative number")
	result = zeros(v)
	for i in length(v):-1:(1+n)
		result[i] = v[i-n]
	end
	return result
end

#Create vector with data shifted by +/-n (padded with 0s)
function shift{T<:Vector}(v::T, n::Int)
	if n >= 0
		return rshift(v, n)
	else
		return lshift(v, -n)
	end
end

#Compute difference between two adjacent points:
#TODO: optimize operations so they run faster
function delta{T<:Vector}(v::T)
	return v[2:end] .- v[1:end-1]
end

#Compute mean of two adjacent points:
#TODO: optimize operations so they run faster
function meanadj{T<:Vector}(v::T)
	return (v[1:end-1] .+ v[2:end])./2
end

#Last line
