#MDDatasets base types & core functions
#-------------------------------------------------------------------------------


#==High-level types
===============================================================================#
abstract DataMD #Multi-dimensional data
abstract LeafDS <: DataMD #Leaf dataset


#==Helper types (TODO: move to somewhere else?)
===============================================================================#

#For type stability.  Identifies result as having event count in x-axis
const Event = DS{:event}()

#Parameter sweep
type PSweep{T}
	id::ASCIIString #TODO: Support UTF8?? - concrete type simplifies writing to HDF5
	v::Vector{T}
#TODO: ensure increasing order?
end

#Explicitly tells multi-dispatch engine a value is meant to be an index:
immutable Index
	v::Int
end
Index(idx::AbstractFloat) = Index(round(Int,idx)) #Convenient
value(x::Index) = x.v

#TODO: Deprecate DataScalar?? - and LeafDS?
#immutable DataScalar{T<:Number} <: LeafDS
#	v::T
#end

immutable Point2D{TX<:Number, TY<:Number}
	x::TX
	y::TY
end

#Allows one to specify limits of a 1D range
#TODO: do we want to enforce min<=max???
#TODO: Add parameter to indicate if limits can go negative, overlap, ...??
immutable Limits1D{T<:Number}
	min::T
	max::T
end
#Auto-detect type (Limits1D(min=4)):
Limits1D{T<:Number}(min::T, ::Void) = Limits1D(min, typemax(T))
Limits1D{T<:Number}(::Void, max::T) = Limits1D(typemin(T), max)
Limits1D(;min=nothing, max=nothing) = Limits1D(min, max)
Limits1D(r::Range) = Limits1D(minimum(r), maximum(r)) #TODO: is it preferable to use rng[1/end]?

#Constructor with forced type (Limits1D{Float32}(min=4)):
call{T<:Number}(::Type{Limits1D{T}}, min::Number, ::Void) = Limits1D{T}(convert(T, min), typemax(T))
call{T<:Number}(::Type{Limits1D{T}}, ::Void, max::Number) = Limits1D{T}(typemin(T), convert(T, max))
call{T<:Number}(::Type{Limits1D{T}} ;min=nothing, max=nothing) = Limits1D{T}(min, max)
call{T<:Number}(::Type{Limits1D{T}}, r::Range) = Limits1D{T}(convert(T,minimum(r)), convert(T,maximum(r)))


#==Leaf data elements
===============================================================================#

#DataF1, Function of 1 variable, y(x): optimized for processing on y-data
#(All y-data points are stored contiguously)
type DataF1{TX<:Number, TY<:Number} <: LeafDS
	x::Vector{TX}
	y::Vector{TY}
#==TODO: find a way to assert lengths:
	function DataF1{TX<:Number, TY<:Number}(x::Vector{TX}, y::Vector{TY})
		@assert(length(x)==length(y), "Invalid DataF1: x & y lengths do not match")
		return new(x,y)
	end
==#
end
#DataF1{TX<:Number, TY<:Number}(::Type{TX}, ::Type{TY}) = DataF1(TX[], TY[]) #Empty dataset

function DataF1{TX<:Number}(x::Vector{TX}, y::Function)
	ytype = typeof(y(x[1]))
	DataF1(x, ytype[y(elem) for elem in x])
end

#Build a DataF1 object from a x-value range (make y=x):
function DataF1(x::Range)
	assertincreasingx(x)
	return DataF1(collect(x), collect(x))
end

function DataF1(x::Range, y::Function)
	assertincreasingx(x)
	return DataF1(collect(x), y)
end


#==Multi-dimensional data
===============================================================================#
#Types f data to be supported by large multi-dimensional datasets:
#typealias MDDataElem Union{DataF1,DataFloat,DataInt,DataComplex}

#Asserts whether a type is allowed as an element of a DataMD container:
elemallowed{T}(::Type{DataMD}, ::Type{T}) = false #By default
elemallowed(::Type{DataMD}, ::Type{DataFloat}) = true
elemallowed(::Type{DataMD}, ::Type{DataInt}) = true
elemallowed(::Type{DataMD}, ::Type{DataComplex}) = true
elemallowed(::Type{DataMD}, ::Type{DataF1}) = true
#==TODO:
   -Is this a good idea?
   -Would using DataScalar wrapper & <: LeafDS be better?==#

#Hyper-rectangle -representation of data:
#-------------------------------------------------------------------------------
#==IMPORTANT:
   -Want DataHR to support ONLY select concrete types & leaf types
	-Want to support leaf types like DataF1 in GENERIC fashion
    (support DataF1[] ONLY - not specific versions of DataF1{X,Y} ==#
#==NOTE:
   -Do not restrict DataHR{T} parameter T until constructor.  This allows for
    a nicer error message.
      #ie: type DataHR{T<:MDDataElem} <: DataMD ==#
type DataHR{T} <: DataMD
	sweeps::Vector{PSweep}
	subsets::Array{T}

	function DataHR{TA,N}(sweeps::Vector{PSweep}, a::Array{TA,N})
		@assert(elemallowed(DataMD, T),
			"Can only create DataHR{T} for T ∈ {DataF1, DataFloat, DataInt, DataComplex}")
		@assert(arraydims(sweeps)==N, "Number of sweeps must match dimensionality of subsets")
		return new(sweeps, a)
	end
end

#Shorthand (because default (non-parameterized) constructor was overwritten):
DataHR{T,N}(sweeps::Vector{PSweep}, a::Array{T,N}) = DataHR{T}(sweeps, a)

#Construct DataHR from Vector{PSweep}:
call{T}(::Type{DataHR{T}}, sweeps::Vector{PSweep}) = DataHR{T}(sweeps, Array{T}(arraysize(sweeps)...))

#Construct DataHR{DataF1} from DataHR{Number}
#Collapse inner-most sweep (last dimension), by default:
function call{T<:Number}(::Type{DataHR{DataF1}}, d::DataHR{T})
	sweeps = d.sweeps[1:end-1]
	x = d.sweeps[end].v
	result = DataHR{DataF1}(sweeps) #Construct empty results
	_sub = length(d.sweeps)>1?subscripts(result):[tuple()]
	for coord in _sub
		y = d.subsets[coord...,:]
		result.subsets[coord...] = DataF1(x, reshape(y, length(y)))
	end
	return result
end

#==Type promotions
===============================================================================#
Base.promote_rule{T1<:DataF1, T2<:Number}(::Type{T1}, ::Type{T2}) = DataF1
Base.promote_rule{T1<:DataHR, T2<:Number}(::Type{T1}, ::Type{T2}) = DataHR
Base.promote_rule{TX1,TX2,TY1,TY2}(::Type{DataF1{TX1,TY1}},::Type{DataF1{TX2,TY2}}) =
	DataF1{promote_type(TX1,TX2),promote_type(TY1,TY2)}


#==Useful assertions
===============================================================================#

#Make sure two datasets have the same x-coordinates:
function assertsamex(d1::DataF1, d2::DataF1)
	@assert(d1.x==d2.x, "Operation currently only supported for the same x-data.")
end

#WARNING: relatively expensive
function assertincreasingx(d::DataF1)
	@assert(isincreasing(d.x), "DataF1.x must be in increasing order.")
end

function assertincreasingx(x::Range)
	@assert(isincreasing(x), "Data must be ordered with increasing x")
end

function assertmultipoint(x::Limits1D)
	@assert(x.min < x.max, "Limits1D: min must be smaller than max")
end

function assertnotinverted(x::Limits1D)
	@assert(x.min <= x.max, "Limits1D: max cannot be smaller than min")
end


#Validate data lengths:
function validatelengths(d::DataF1)
	@assert(length(d.x)==length(d.y), "Invalid DataF1: x & y lengths do not match.")
end

#Perform simple checks to validate data integrity
function validate(d::DataF1)
	validatelengths(d)
	assertincreasingx(d)
end


#==Basic Point2D functionality
===============================================================================#


#==Basic Limits1D functionality
===============================================================================#
Base.clamp(v, r::Limits1D) = clamp(v, r.min, r.max)
Base.clamp!(v, r::Limits1D) = clamp!(v, r.min, r.max)


#==Basic PSweep functionality
===============================================================================#
Base.names(list::Vector{PSweep}) = [s.id for s in list]

#dimensionality of array
arraydims(list::Vector{PSweep}) = max(1, length(list))

#Compute the size of an array from a Vector{PSweep}:
function arraysize(list::Vector{PSweep})
	dims = Int[]
	for s in list
		push!(dims, length(s.v))
	end
	if 0 == length(dims) #Without sweeps, you can still have a single subset
		push!(dims, 1)
	end
	return tuple(dims...)
end

#Returns the dimension corresponding to the given string:
function dimension(list::Vector{PSweep}, id::AbstractString)
	dim = findfirst((s)->(id==s.id), list)
	@assert(dim>0, "Sweep not found: $id.")
end

#Return a list of indicies corresponding to desired sweep values:
function indices(sweep::PSweep, vlist)
	result = Int[]
	for v in vlist
		push!(result, findclosestindex(sweep.v, v))
	end
	return result
end


#==Basic LeafDS functionality
===============================================================================#

subsets{T<:LeafDS}(ds::T) = [ds]


#==Basic DataF1 functionality
===============================================================================#
Base.copy(d::DataF1) = DataF1(d.x, copy(d.y))

function Base.length(d::DataF1)
	validatelengths(d) #Should be sufficiently inexpensive
	return length(d.x)
end

#Obtain a Point2D structure from a DataF1 dataset, at a given index.
Point2D(d::DataF1, i::Int) = Point2D(d.x[i], d.y[i])

#Obtain a list of y-element types in an array of DataF1
function findytypes(a::Array{DataF1})
	result = Set{DataType}()
	for elem in a
		push!(result, eltype(elem.y))
	end
	return [elem for elem in result]
end


#==Basic DataHR functionality
===============================================================================#
subsets(ds::DataHR) = ds.subsets
subscripts(d::DataHR) = [ind2sub(d.subsets,i) for i in 1:length(d.subsets)]
sweeps(d::DataHR) = d.sweeps

#Obtain parameter info
#-------------------------------------------------------------------------------
parameter(d::DataHR, dim::Int, idx::Int=0) = d.sweeps[dim].v[idx]
parameter(d::DataHR, dim::Int, coord::Tuple=0) = parameter(d, dim, coord[dim])
parameter(d::DataHR, id::AbstractString, idx::Int=0) =
	parameter(d, dimension(d.sweeps, id), idx)
parameter(d::DataHR, id::AbstractString, coord::Tuple=0) =
	parameter(d, dimension(d.sweeps, id), coord[dim])

#Returns all parameters (not a single parameter) @ specified coordinate
#TODO: rename?
function parameter(d::DataHR, coord::Tuple=0)
	result = []
	if length(d.sweeps) > 0
		for i in 1:length(coord)
			push!(result, parameter(d, i, coord[i]))
		end
	end
	return result
end


#==Dataset reductions
===============================================================================#

#Like sub(A, inds...), but with DataHR:
function getsubarray{T}(d::DataHR{T}, inds...)
	sweeps = PSweep[]
	idx = 1
	for rng in inds
		sw = d.sweeps[idx]

		#Only provide a sweep if user selects a range of more than one element:
		addsweep = Colon == typeof(rng) || length(rng)>1
		if addsweep
			push!(sweeps, PSweep(sw.id, sw.v[rng]))
		end
		idx +=1
	end
	return DataHR{T}(sweeps, reshape(sub(d.subsets, inds...), arraysize(sweeps)))
end

#sub(DataHR, inds...), using key/value pairs:
function getsubarraykw{T}(d::DataHR{T}; kwargs...)
	sweeps = PSweep[]
	indlist = Vector{Int}[]
	for sweep in d.sweeps
		keepsweep = true
		arg = getkwarg(kwargs, symbol(sweep.id))
		if arg != nothing
			inds = indices(sweep, arg)
			push!(indlist, inds)
			if length(inds) > 1
				keepsweep = false
				push!(sweeps, PSweep(sweep.id, sweep.v[inds...]))
			end
		else #Keep sweep untouched:
			push!(indlist, 1:length(sweep.v))
			push!(sweeps, sweep)
		end
	end
	return DataHR{T}(sweeps, reshape(sub(d.subsets, indlist...), arraysize(sweeps)))
end

function Base.sub{T}(d::DataHR{T}, args...; kwargs...)
	if length(kwargs) > 0
		return getsubarraykw(d, args...; kwargs...)
	else
		return getsubarray(d, args...)
	end
end


#==Interpolations
===============================================================================#

#Interpolate between two points.
function interpolate{TX<:Number, TY<:Number}(p1::Point2D{TX,TY}, p2::Point2D{TX,TY}; x::Number=0)
	m = (p2.y-p1.y) / (p2.x-p1.x)
	return m*(x-p1.x)+p1.y
end

#Interpolate value of a DataF1 dataset for a given x:
#NOTE:
#    -Uses linear interpolation
#    -Assumes value is zero when out of bounds
#    -TODO: binary search
function value{TX<:Number, TY<:Number}(d::DataF1{TX, TY}; x::Number=0)
	validate(d) #Expensive, but might avoid headaches
	nd = length(d) #Somewhat expensive
	RT = promote_type(TX, TY) #For type stability
	y = zero(RT) #Initialize

	pos = 0
	for i in 1:nd
		if x <= d.x[i]
			pos = i
			break
		end
	end
	#Here: pos=0, or x<=d.x[pos]

	if pos > 1
		y = interpolate(Point2D(d, pos-1), Point2D(d, pos), x=x)
	elseif pos > 0 && x==d.x[1]
		y = convert(RT, d.y[1])
	end
	return y
end

#==Apply fn(d1,d2); where {d1,d2} ∈ DataF1 have independent (but sorted) x-values
===============================================================================#

function applydisjoint{TX<:Number, TY1<:Number, TY2<:Number}(fn::Function, d1::DataF1{TX,TY1}, d2::DataF1{TX,TY2})
	@assert(false, "Currently no support for disjoint datasets")
end

#Apply a function of two scalars to two DataF1 objects:
#NOTE:
#   -Uses linear interpolation
#   -Do not use "map", because this is more complex than one-to-one mapping
#   -Assumes ordered x-values
function apply{TX<:Number, TY1<:Number, TY2<:Number}(fn::Function, d1::DataF1{TX,TY1}, d2::DataF1{TX,TY2})
	validate(d1); validate(d2); #Expensive, but might avoid headaches
	zero1 = zero(TY1); zero2 = zero(TY2)
	npts = length(d1)+length(d2)+1 #Allocate for worse case
	x = zeros(TX, npts)
	y = zeros(promote_type(TY1,TY2),npts)
	_x1 = d1.x[1]; _x2 = d2.x[1] #First x-values of d1 & d2
	x1_ = d1.x[end]; x2_ = d2.x[end] #Last x-values of d1 & d2

	if _x1 > x2_ || _x2 > x1_
		return applydisjoint(fn, d1, d2)
	end

	i = 1; i1 = 1; i2 = 1
	#NOTE: i ≜ index into result (x[]).  Low risk of being out of range.
	_x12 = max(_x1, _x2) #First intersecting point
	x[1] = min(_x1, _x2) #First point

	while x[i] < _x2 #Only d1 has values (assume d2 is 0)
		y[i] = fn(d1.y[i1], zero2)
		i += 1; i1 += 1 #x[i] < _x2 and set not disjoint: safe to increment i1
		x[i] = d1.x[i1]
	end
	while x[i] < _x1 #Only d2 has values (assume d1 is 0)
		y[i] = fn(zero1, d2.y[i2])
		i += 1; i2 += 1 #x[i] < _x1 and set not disjoint: safe to increment i2
		x[i] = d2.x[i2]
	end
	x[i] = _x12
	x12_ = min(x1_, x2_) #Last intersecting point
	p1 = p1next = Point2D(d1, i1)
	p2 = p2next = Point2D(d2, i2)
	if i1 > 1; p1 = Point2D(d1, i1-1); end
	if i2 > 1; p2 = Point2D(d2, i2-1); end
	while x[i] < x12_ #Intersecting section of x
		local y1, y2
		if p1next.x == x[i]
			y1 = p1next.y
			i1 += 1 #x[i] < x12_: safe to increment i1
			p1 = p1next; p1next = Point2D(d1, i1)
		else
			y1 = interpolate(p1, p1next, x=x[i])
		end
		if p2next.x == x[i]
			y2 = p2next.y
			i2 += 1 #x[i] < x12_: safe to increment i2
			p2 = p2next; p2next = Point2D(d2, i2)
		else
			y2 = interpolate(p2, p2next, x=x[i])
		end
		y[i] = fn(y1, y2)
		i+=1
		x[i] = min(p1next.x, p2next.x)
	end
	#End of intersecting section:
		y1 = interpolate(p1, p1next, x=x[i])
		y2 = interpolate(p2, p2next, x=x[i])
		y[i] = fn(y1, y2)
	while x[i] < x1_ #Only d1 has values left (assume d2 is 0)
		i += 1
		x[i] = d1.x[i1]
		y[i] = fn(d1.y[i1], zero2)
		i1 += 1
	end
	while x[i] < x2_ #Only d2 has values left (assume d1 is 0)
		i += 1
		x[i] = d2.x[i2]
		y[i] = fn(zero1, d2.y[i2])
		i2 += 1
	end
	npts = i

	return DataF1(resize!(x, npts), resize!(y, npts))
end

#Last line
