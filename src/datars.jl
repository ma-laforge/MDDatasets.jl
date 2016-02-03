#MDDatasets DataRS (Recursive Sweep) defninitions
#-------------------------------------------------------------------------------

#==Main types
===============================================================================#

#Linked-list representation of multi-dimensional datasets:
#-------------------------------------------------------------------------------
type DataRS{T} <: DataMD
	sweep::PSweep
	elem::Vector{T}

	function DataRS(sweep::PSweep, elem::Vector)
		if !elemallowed(DataRS, eltype(elem))
			msg = "Can only create DataRS{T} for T ∈ {DataRS, DataF1, DataFloat, DataInt, DataComplex}"
			throw(ArgumentError(msg))
		elseif length(sweep) != length(elem)
			throw(ArgumentError("sweep length does not match number of elem"))
		end
		return new(sweep, elem)
	end
end
elemallowed{T}(::Type{DataRS}, t::Type{T}) = elemallowed(DataMD, t) #Allow basic types
elemallowed(::Type{DataRS}, ::Type{DataRS}) = true #Also allow recursive structures

#Shorthand (because default (non-parameterized) constructor was overwritten):
DataRS{T}(sweep::PSweep, elem::Vector{T}) = DataRS{T}(sweep, elem)

#Generate empty DataRS structure:
call{T}(::Type{DataRS{T}}, sweep::PSweep) = DataRS{T}(sweep, Array(T, length(sweep)))


#==Type promotions
===============================================================================#
Base.promote_rule{T1<:DataRS, T2<:Number}(::Type{T1}, ::Type{T2}) = DataRS


#==Accessor functions
===============================================================================#
Base.eltype{T}(d::DataRS{T}) = T
Base.length(d::DataRS) = length(d.elem)


#==Help with construction
===============================================================================#

#Implement "fill(DataRS, ...) do sweepval" syntax:
function Base.fill!(fn::Function, d::DataRS)
	for i in 1:length(d.sweep)
		d.elem[i] = fn(d.sweep.v[i])
	end
	return d
end
Base.fill{T}(fn::Function, ::Type{DataRS{T}}, sweep::PSweep) =
	fill!(fn, DataRS(sweep, Array(T, length(sweep))))
Base.fill(fn::Function, ::Type{DataRS}, sweep::PSweep) = fill(fn, DataRS{DataRS}, sweep)


#==Data generation
===============================================================================#
function _ensuresweepunique(d::DataRS, sweepid::AbstractString)
	if sweepid == d.sweep.id
		msg = "Sweep occurs multiple times in DataRS: $sweepid"
		throw(ArgumentError(msg))
	end
end

#Define "parameter".
#(Generates a DataRS object containing the value of a given swept parameter)
#-------------------------------------------------------------------------------

#Deal with non-leaf elements, once the sweep value is found:
function _parameter{T}(d::DataRS{DataRS}, sweepid::AbstractString, sweepval::T)
	_ensuresweepunique(d, sweepid)
	elem = DataRS[_parameter(d.elem[i], sweepid, sweepval) for i in 1:length(d.sweep)]
	return DataRS(d.sweep, elem)
end

#Deal with leaf elements, once the sweep value is found:
function _parameter{T}(d::DataRS, sweepid::AbstractString, sweepval::T)
	_ensuresweepunique(d, sweepid)
	elem = T[sweepval for i in 1:length(d.sweep)]
	return DataRS(d.sweep, elem)
end

#Main "parameter" algorithm (non-leaf elements):
function parameter(d::DataRS{DataRS}, sweepid::AbstractString)
	if sweepid == d.sweep.id #Sweep found
		elem = DataRS[_parameter(d.elem[i], sweepid, d.sweep.v[i]) for i in 1:length(d.sweep)]
	else
		elem = DataRS[parameter(d.elem[i], sweepid) for i in 1:length(d.sweep)]
	end
	return DataRS(d.sweep, elem)
end
#Main "parameter" algorithm (leaf elements):
function parameter(d::DataRS, sweepid::AbstractString)
	T = eltype(d.sweep.v)
	if sweepid == d.sweep.id #Sweep found
		return DataRS(d.sweep, d.sweep.v)
	else
		msg = "Sweep not found in DataRS: $sweepid"
		throw(ArgumentError(msg))
	end
end

#Generate DataRS from DataHR.
#-------------------------------------------------------------------------------
function _buildDataRS(d::DataHR, firstinds::Vector{Int})
	curidx = length(firstinds) + 1
	sweep = d.sweeps[curidx]
	if curidx < length(d.sweeps)
		result = DataRS{DataRS}(sweep)
		for i in 1:length(sweep.v)
			result.elem[i] = _buildDataRS(d, vcat(firstinds, i))
		end
	else #Last index.  Copy data over:
		result = DataRS{eltype(d.elem)}(sweep)
		for i in 1:length(sweep.v)
			result.elem[i] = d.elem[firstinds..., i]
		end
	end
	return result
end

function DataRS(d::DataHR)
	return _buildDataRS(d, Int[])
end


#==User-friendly show functions
===============================================================================#

#Print leaf element:
function printDataRSelem(io::IO, ds::DataRS, idx::Int, indent::AbstractString)
	if isdefined(ds.elem, idx)
		println(io, ds.elem[idx])
	else
		println(io, indent, "UNDEFINED")
	end
end
#Print next level of recursive DataRS:
function printDataRSelem{T<:DataRS}(io::IO, ds::DataRS{T}, idx::Int, indent::AbstractString)
	println(io)
	if isdefined(ds.elem, idx)
		printDataRS(io, ds.elem[idx], indent)
	else
		println(io, indent, "UNDEFINED")
	end
end
#Print DataRS structure:
function printDataRS(io::IO, ds::DataRS, indent::AbstractString)
	for i in 1:length(ds.elem)
		print(io, "$indent", ds.sweep.id, "=", ds.sweep.v[i], ": ")
		printDataRSelem(io, ds, i, "$indent  ")
	end
end

function Base.show(io::IO, ds::DataRS)
	print(io, "DataRS[\n")
	printDataRS(io, ds, "  ")
	print(io, "]\n")
end

