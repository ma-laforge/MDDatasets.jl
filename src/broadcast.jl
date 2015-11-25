#MDDatasets broadcast support
#-------------------------------------------------------------------------------

import Base: broadcast


#==Type definitions
===============================================================================#
type CoordinateMap
	outidx::Vector{Int} #List of indices (of output coordinate)
	outlen::Int #Number of indices in output coordinate
end
CoordinateMap(inlen::Int, outlen::Int) =
	CoordinateMap(Vector{Int}(inlen), outlen)


#==Error generators
===============================================================================#

function error_mismatchedsweep(basesweep::Vector{PSweep}, subsweep::Vector{PSweep})
	msg = "Mismatched sweeps:\n\nSweep1:\n$basesweep\n\nSweep2:\n$subsweep"
	return ArgumentError(msg)
end

#==Helper functions
===============================================================================#

function assertuniqueids(s::Vector{PSweep})
	n = length(s)
	for i in 1:n
		for j in (i+1):n
			if s[i] == s[j]
				throw(ArgumentError("Sweep id not unique: \"$(s[i])\""))
			end
		end
	end
end

#Find "base" sweep (most complex data configuration to broadcast up to)
#-------------------------------------------------------------------------------
function basesweep(s1::Vector{PSweep}, s2::Vector{PSweep})
	return length(s1)>length(s2)? s1: s2
end
basesweep(s::Vector{PSweep}, d::DataHR) = basesweep(s,d.sweeps)
basesweep(s::Vector{PSweep}, d::DataF1) = s
basesweep(s::Vector{PSweep}, d::Number) = s
basesweep(d1::DataHR, d2::DataHR) = basesweep(d1.sweeps,d2.sweeps)
basesweep(d1::DataHR, d2) = basesweep(d1.sweeps,d2)
basesweep(d1, d2::DataHR) = basesweep(d2.sweeps,d2)

#Functions to map coordinates when broadcasting up a DataHR dataset
#-------------------------------------------------------------------------------
function getmap(basesweep::Vector{PSweep}, subsweep::Vector{PSweep})
	assertuniqueids(basesweep)
	result = CoordinateMap(length(basesweep), length(subsweep))
	found = zeros(Bool, length(subsweep))
	for i in 1:length(basesweep)
		idx = findfirst((x)->(x.id==basesweep[i].id), subsweep)
		result.outidx[i] = idx
		if idx>1
			if basesweep[i].v != subsweep[idx].v
				msg = "Mismatched sweeps:\n$basesweep\n$subsweep"
				throw(error_mismatchedsweep(basesweep, subsweep))
			end
			found[idx] = true
		end
	end
	if !all(found); throw(error_mismatchedsweep(basesweep, subsweep)); end
	return result
end
function remap(_map::CoordinateMap, coord::Vector{Int})
	result = Vector{Int}(_map.outlen)
	for i in 1:length(coord)
		idx = _map.outidx[i]
		if idx > 0; result[idx] = coord[i]; end
	end
	return result
end


#==Broadcasting data up-to a given sweep dimension
===============================================================================#
function broadcast{T<:Number}(s::Vector{PSweep}, d::T)
	result = DataHR{T}(s)
	for i in 1:length(result.subsets)
		result.subsets[i] = d
	end
	return result
end
function broadcast(s::Vector{PSweep}, d::DataF1)
	result = DataHR{DataF1}(s)
	for i in 1:length(result.subsets)
		result.subsets[i] = d
	end
	return result
end
function broadcast{T}(s::Vector{PSweep}, d::DataHR{T})
	if s == d.sweeps; return d; end
	_map = getmap(s, d.sweeps)
	result = DataHR{T}(s)
	for coord in subscripts(result)
		result.subsets[coord...] = d.subsets[remap(_map, coord)...]
	end
	return result
end

#==Broadcast function call on multi-dimensional data
===============================================================================#
#Broadcast data up to base sweep of two first arguments, then call fn
function broadcast{T}(::Type{T}, s::Vector{PSweep}, fn::Function, args...; kwargs...)
	bargs = Vector{Any}(length(args)) #Broadcasted version of args
	for i in 1:length(args)
		if typeof(args[i])<:DataMD
			bargs[i] = broadcast(s, args[i])
		else
			bargs[i] = args[i]
		end
	end
	bkwargs = Vector{Any}(length(kwargs)) #Broadcasted version of kwargs
	for i in 1:length(kwargs)
		(k,v) = kwargs[i]
		if typeof(v)<:DataMD
			bkwargs[i] = tuple(k, broadcast(s, v))
		else
			bkwargs[i] = kwargs[i]
		end
	end
	result = DataHR{T}(s) #Create empty result
	for i in 1:length(result.subsets)
		curargs = Vector{Any}(length(bargs))
		for j in 1:length(bargs)
			if typeof(bargs[j]) <: DataHR
				curargs[j] = bargs[j].subsets[i]
			else
				curargs[j] = bargs[j]
			end
		end
		curkwargs = Vector{Any}(length(bkwargs))
		for j in 1:length(bkwargs)
			(k,v) = bkwargs[j]
			if typeof(v) <: DataHR
				curkwargs[j] = tuple(k, v.subsets[i])
			else
				curkwargs[j] = bkwargs[j]
			end
		end
		result.subsets[i] = fn(curargs...; curkwargs...)
	end
	return result
end

#Find base sweep for a 1-argument broadcast:
function broadcast1_basesweep(fn::Function, d)
	local s
	try
		s = d.sweeps
	catch
		t = typeof(d)
		msg = "No signature found for $fn($t, ...)"
		throw(ArgumentError(msg))
	end
	return s
end
#Broadcast data up to base sweep of two first arguments, then call fn
broadcast1{T}(::Type{T}, fn::Function, d, args...; kwargs...) =
	broadcast(T, broadcast1_basesweep(fn, d), fn, d, args...; kwargs...)
#For functions that are prefixed with ::DS:
broadcast1{T}(::Type{T}, fn::Function, ds::DS, d, args...; kwargs...) =
	broadcast(T, broadcast1_basesweep(fn, d), fn, ds, d, args...; kwargs...)
#For data reduction functions:
function broadcast1(::Type{Number}, fn::Function, d::DataHR{DataF1}, args...; kwargs...)
	TR = promote_type(findytypes(d.subsets)...)
	return broadcast(TR, broadcast1_basesweep(fn, d), fn, d, args...; kwargs...)
end

#Find base sweep for a 2-argument broadcast:
function broadcast2_basesweep(fn::Function, d1, d2)
	local s
	try
		s = basesweep(d1,d2)
	catch
		t1 = typeof(d1); t2 = typeof(d2)
		msg = "No signature found for $fn($t1, $t2, ...)"
		throw(ArgumentError(msg))
	end
end

#Broadcast data up to base sweep of two first arguments, then call fn
broadcast2{T}(::Type{T}, fn::Function, d1, d2, args...; kwargs...) =
	broadcast(T, broadcast2_basesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
#For functions that are prefixed with ::DS:
broadcast2{T}(::Type{T}, fn::Function, ds::DS, d1, d2, args...; kwargs...) =
	broadcast(T, broadcast2_basesweep(fn, d1, d2), fn, ds, d1, d2, args...; kwargs...)

#Last Line
