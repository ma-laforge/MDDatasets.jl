#MDDatasets DataRS (Recursive Sweep) defninitions
#-------------------------------------------------------------------------------

#==Main types
===============================================================================#

@doc """
    DataRS{T} <: DataMD

Recursive data structure used to store results from a parametric sweep.

See also: [fill(::DataRS, ...)](@ref) [ndims(::DataRS)](@ref) [paramlist(::DataRS)](@ref)
""" DataRS

#Linked-list representation of multi-dimensional datasets:
#-------------------------------------------------------------------------------
mutable struct DataRS{T} <: DataMD
	sweep::PSweep
	elem::Vector{T}

	function DataRS{T}(sweep::PSweep, elem::Vector{T}) where {T}
		if !elemallowed(DataRS, eltype(elem))
			msg = "Can only create DataRS{T} for T ∈ {DataRS, DataF1, DataFloat, DataInt, DataComplex}"
			throw(ArgumentError(msg))
		elseif length(sweep) != length(elem)
			throw(ArgumentError("sweep length does not match number of elem"))
		end
		return new(sweep, elem)
	end
end

#Shorthand (because default (non-parameterized) constructor was overwritten):
DataRS(sweep::PSweep, elem::Vector{T}) where T = DataRS{T}(sweep, elem)

elemallowed(::Type{DataRS}, t::Type{T}) where T = elemallowed(DataMD, t) #Allow basic types
elemallowed(::Type{DataRS}, ::Type{DataRS}) = true #Also allow recursive structures

#Generate empty DataRS structure:
(::Type{DataRS{T}})(sweep::PSweep) where T = DataRS{T}(sweep, Array{T}(undef, length(sweep)))


#==Type promotions
===============================================================================#
Base.promote_rule(::Type{T1}, ::Type{T2}) where {T1<:DataRS, T2<:Number} = DataRS


#==Data integrity
===============================================================================#
function _ndims(d::DataRS)
	depth = 0

	#Count depth:
	w = d #walks across data structure
	while isa(w, DataRS)
		depth += 1
		w = w.elem[1]
	end
	return depth
end

function ensure_validsweep(d::DataRS)
	if length(d.elem) != length(d.sweep)
		id = d.sweep.id
		msg = "Sweep length : data length mismatch: $id"
		throw(ArgumentError(msg))
	end
end

function _validate_dimensionality(d::DataRS, depth::Int)
	function validate_depth(d, depth) #Leaf element
		ensure(0 == depth, ArgumentError("DataRS: Inconsistent dimensionality"))
	end

	function validate_depth(d::DataRS, depth)
		ensure(depth > 0, ArgumentError("DataRS: Inconsistent dimensionality")) #Recursion safety
		ensure_validsweep(d)
		nextdepth = depth - 1
		for e in d.elem
			validate_depth(e, nextdepth)
		end
		return
	end
	return validate_depth(d, depth)
end
validate_dimensionality(d::DataRS) = _validate_dimensionality(d, _ndims(d))


#==Accessor functions
===============================================================================#
Base.eltype(d::DataRS{T}) where T = T
Base.length(d::DataRS) = length(d.elem)

"""
    ndims(d::DataRS)

Return number of dimensions for the parametric sweep in d.
""" Base.ndims(::DataRS)
function Base.ndims(d::DataRS)
	depth = _ndims(d)
	_validate_dimensionality(d, depth)
	return depth
end

"""
    paramlist(d::DataRS)

Return a list of parameter values being swept.
"""
function paramlist(d::DataRS)
	plist = String[]

	#Count depth:
	w = d #walks across data structure
	while isa(w, DataRS)
		push!(plist, w.sweep.id)
		w = w.elem[1]
	end
	_validate_dimensionality(d, length(plist))
	return plist
end


#==Help with construction
===============================================================================#

@doc """
    fill(d::DataRS, ...)

Construct a DataRS structure storing results from parametric sweeps using recursive data structures.

# Examples
```julia-repl
signal = fill(DataRS, PSweep("A", [1, 2, 4] .* 1e-3)) do A
    fill(DataRS, PSweep("phi", [0, 0.5, 1] .* (π/4))) do 𝜙
    fill(DataRS{DataF1}, PSweep("freq", [1, 4, 16] .* 1e3)) do 𝑓
       𝜔 = 2π*𝑓; T = 1/𝑓
       Δt = T/100 #Define resolution from # of samples per period
       Tsim = 4T #Simulated time
       t = DataF1(0:Δt:Tsim) #DataF1 creates a t:{y, x} container with y == x
       sig = A * sin(𝜔*t + 𝜙) #Still a DataF1 sig:{y, x=t} container
       return sig
end; end; end
```

Note that inner-most sweep needs to specify element type (DataF1).
Other (scalar) element types include: DataInt/DataFloat/DataComplex.
""" Base.fill(::DataRS, args...)

#Implement "fill(DataRS, ...) do sweepval" syntax:
function Base.fill!(fn::Function, d::DataRS)
	for i in 1:length(d.sweep)
		d.elem[i] = fn(d.sweep.v[i])
	end
	return d
end
Base.fill(fn::Function, ::Type{DataRS{T}}, sweep::PSweep) where T =
	fill!(fn, DataRS(sweep, Array{T}(undef, length(sweep))))
Base.fill(fn::Function, ::Type{DataRS}, sweep::PSweep) = fill(fn, DataRS{DataRS}, sweep)


#==Data generation
===============================================================================#
function _ensuresweepunique(d::DataRS, sweepid::String)
	if sweepid == d.sweep.id
		msg = "Sweep occurs multiple times in DataRS: $sweepid"
		throw(ArgumentError(msg))
	end
end

#Define "parameter".
#(Generates a DataRS object containing the value of a given swept parameter)
#-------------------------------------------------------------------------------

@doc """
    parameter(d::DataRS, sweepid::String)

Get parameter values for a particular sweep.
""" parameter

#Deal with non-leaf elements, once the sweep value is found:
function _parameter(d::DataRS{DataRS}, sweepid::String, sweepval::T) where T
	_ensuresweepunique(d, sweepid)
	elem = DataRS[_parameter(d.elem[i], sweepid, sweepval) for i in 1:length(d.sweep)]
	return DataRS(d.sweep, elem)
end

#Deal with leaf elements, once the sweep value is found:
function _parameter(d::DataRS, sweepid::String, sweepval::T) where T
	_ensuresweepunique(d, sweepid)
	elem = T[sweepval for i in 1:length(d.sweep)]
	return DataRS(d.sweep, elem)
end

#Main "parameter" algorithm (non-leaf elements):
function parameter(d::DataRS{DataRS}, sweepid::String)
	if sweepid == d.sweep.id #Sweep found
		elem = DataRS[_parameter(d.elem[i], sweepid, d.sweep.v[i]) for i in 1:length(d.sweep)]
	else
		elem = DataRS[parameter(d.elem[i], sweepid) for i in 1:length(d.sweep)]
	end
	return DataRS(d.sweep, elem)
end
#Main "parameter" algorithm (leaf elements):
function parameter(d::DataRS, sweepid::String)
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
function printDataRSelem(io::IO, ds::DataRS, idx::Int, indent::String)
	if isassigned(ds.elem, idx)
		println(io, ds.elem[idx])
	else
		println(io, indent, "UNDEFINED")
	end
end
#Print next level of recursive DataRS:
function printDataRSelem(io::IO, ds::DataRS{T}, idx::Int, indent::String) where T<:DataRS
	println(io)
	if isassigned(ds.elem, idx)
		printDataRS(io, ds.elem[idx], indent)
	else
		println(io, indent, "UNDEFINED")
	end
end
#Print DataRS structure:
function printDataRS(io::IO, ds::DataRS, indent::String)
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

