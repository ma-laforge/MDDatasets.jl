#MDDatasets base types & core functions
#-------------------------------------------------------------------------------


#==Main data structures
===============================================================================#
abstract DataMD #Multi-dimensional data
abstract LeafDS <: DataMD #Leaf dataset

immutable DataScalar{T<:Number} <: LeafDS
	v::T
end

#Data2D, y(x): optimized for processing on y-data
#(All y-data points are stored contiguously)
type Data2D{TX<:Number, TY<:Number} <: LeafDS
	x::Vector{TX}
	y::Vector{TY}
end

#Hyper-rectangle -representation of data:
#TODO: Implement me
type DataHR <: DataMD
	subsets::Array{Data2D}
	#TODO: Add struct to identify parameters associated with subsets indicies
end

subsets(ds::DataHR) = ds.subsets
subsets{T<:LeafDS}(ds::T) = [ds]

#==Generate friendly show functions
===============================================================================#
#TODO: Print array indicies:
function Base.show{T<:DataHR}(io::IO, ds::T)
	szstr = string(size(ds.subsets))
	print(io, "DataHR$szstr[\n")
	for subset in ds.subsets
		print(io, " (coord): "); show(io, subset); println(io)
	end
	print(io, "]\n")

end

#Last line

