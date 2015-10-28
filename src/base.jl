#MDDatasets base types & core functions
#-------------------------------------------------------------------------------


#==Main data structures
===============================================================================#
abstract DataMD #Multi-dimensional data
abstract LeafDS <: DataMD #Leaf dataset

immutable DataIndex
	v::Int
end
DataIndex(idx::AbstractFloat) = DataIndex(round(Int,idx)) #Convenient
value(x::DataIndex) = x.v

immutable DataScalar{T<:Number} <: LeafDS
	v::T
end

#Data2D, y(x): optimized for processing on y-data
#(All y-data points are stored contiguously)
type Data2D{TX<:Number, TY<:Number} <: LeafDS
	x::Vector{TX}
	y::Vector{TY}
end
#Build a Data2D object from a vector:
Data2D(r::Range) = Data2D(collect(r), collect(r))

#Hyper-rectangle -representation of data:
#TODO: Implement me
type DataHR <: DataMD
	subsets::Array{Data2D}
	#TODO: Add struct to identify parameters associated with subsets indicies
end

subsets(ds::DataHR) = ds.subsets
subsets{T<:LeafDS}(ds::T) = [ds]

#==Useful assertions
===============================================================================#

#Will have to remove this as a requirement
function assertsamex(d1::Data2D, d2::Data2D)
	@assert(d1.x==d2.x, "Operation currently only supported for the same x-data")
end

#Perform simple checks to validate data integrity
function validate(d::Data2D)
	@assert(d.x==d.y, "Invalid Data2D: x & y lengths do not match")
end

#==Base "vector"-like operations
===============================================================================#
function Base.length(d::Data2D)
	validate(d)
	return length(d.x)
end

Base.zeros(d::Data2D) = Data2D(d.x, zeros(d.y))
Base.ones(d::Data2D) = Data2D(d.x, ones(d.y))


#==Support basic math operations
===============================================================================#
#==NOTE
Data2D cannot represent matrices.  Element-by-element operations will therefore
be the default.  There is not need to use the "." operator versions.
==#
function Base.(:-){TX1<:Number, TX2<:Number, TY<:Number}(d1::Data2D{TX1,TY}, d2::Data2D{TX2,TY})
	assertsamex(d1, d2)
	return Data2D(d1.x, -(d1.y, d2.y))
end

Base.(:+)(i1::DataIndex, i2::DataIndex) = DataIndex(i1.v+i2.v)


#==Generate friendly show functions
===============================================================================#
#Don't want to overwrite Base.showcompact of a vector...
function _showcompact{T<:Number}(io::IO, x::Vector{T})
	const maxelem = 10
	if length(x)>maxelem
		print(io, "[")
		for i in 1:(maxelem-3)
			print(io, x[i], ",")
		end
		print(io, "...")
		for v in x[end-1:end]
			print(io, ",", v)
		end
		print(io, "]")
	else
		show(io, x)
	end
end

#Don't show module name/subtypes for Data2D:
function Base.show{TX<:Number, TY<:Number}(io::IO, ds::Data2D{TX,TY})
	print(io, "Data2D(x=")
		_showcompact(io, ds.x)
		print(io, ",y=")
		_showcompact(io, ds.y)
		print(io, ")")
end

#TODO: Print array indicies:
function Base.show(io::IO, ds::DataHR)
	szstr = string(size(ds.subsets))
	print(io, "DataHR$szstr[\n")
	for subset in ds.subsets
		print(io, " (coord): "); show(io, subset); println(io)
	end
	print(io, "]\n")

end

#Last line

