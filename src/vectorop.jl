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

#Last line
