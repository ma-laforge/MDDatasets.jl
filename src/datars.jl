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


#==User-friendly show functions
===============================================================================#

function showDataRS(io::IO, ds::DataRS, indent::AbstractString="")
	for i in 1:length(ds.elem)
		println(io, "$indent", ds.sweep.id, "=", ds.sweep.v[i], ": ", ds.elem[i])
	end
end
function showDataRS{T<:DataRS}(io::IO, ds::DataRS{T}, indent::AbstractString="")
	for i in 1:length(ds.elem)
		println(io, "$indent", ds.sweep.id, "=", ds.sweep.v[i], ":")
		showDataRS(io, ds.elem[i], "$indent  ")
	end
end

function Base.show(io::IO, ds::DataRS)
	print(io, "DataRS[\n")
	showDataRS(io, ds, "  ")
	print(io, "]\n")
end

