#MDDatasets base types & core functions
#-------------------------------------------------------------------------------


#==Main data structures
===============================================================================#
abstract DataMD #Multi-dimensional data
abstract LeafDS <: DataMD #Leaf dataset

#Explicitly tells multi-dispatch engine a value is meant to be an index:
immutable Index
	v::Int
end
Index(idx::AbstractFloat) = Index(round(Int,idx)) #Convenient
value(x::Index) = x.v

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
	@assert(length(d.x)==length(d.y), "Invalid Data2D: x & y lengths do not match")
end

#==Base "vector"-like operations
===============================================================================#
function Base.length(d::Data2D)
	validate(d)
	return length(d.x)
end

#==TODO:
Check out statistical stuff

isempty, isfinite, isinf, isinteger, isnan, isposdef, isreal

fft, etc

2 vectors:
atan2
hypot
imag
max(v1,v2)/min

Mapping ??
map, mapreduce, mapreducedim, mapslices
maxabs, prod, sum

#Number converters
#Bool(): map(Bool, x)
round
...

#other
#clamp: lo, hi
#eachindex
rand
==#

_basefn = [
	:zeros, :ones, :maximum, :minimum, :abs, :abs2, :angle,
	:imag, :real, :exponent,
	:exp, :exp2, :exp10, :expm1,
	:log, :log10, :log1p, :log2,
	:ceil, :floor,
	:asin, :asind, :asinh, :acos, :acosd, :acosh,
	:atan, :atand, :atanh, :acot, :acotd, :acoth,
	:asec, :asecd, :asech, :acsc, :acscd, :acsch,
	:sin, :sind, :sinh, :cos, :cosd, :cosh,
	:tan, :tand, :tanh, :cot, :cotd, :coth,
	:sec, :secd, :sech, :csc, :cscd, :csch,
	:sinpi, :cospi,
	:sinc, :cosc, #cosc: d(sinc)/dx
	:deg2rad, :rad2deg,
	:cummax, :cummin, :cumprod, :cumsum,
	:mean, :median, :middle,
]

for fn in _basefn; @eval begin

#fn(Data2D)
function Base.$fn{TX<:Number, TY<:Number}(d::Data2D{TX,TY})
	return Data2D(d.x, $fn(d.y))
end

end; end


#==Support basic math operations
===============================================================================#
#==NOTE
Data2D cannot represent matrices.  Element-by-element operations will therefore
be the default.  There is not need to use the "." operator versions.
==#
const _operators = Symbol[:-, :+, :/, :*]
_dotop(x)=Symbol(".$x")

for op in _operators; @eval begin

#Data2D op Data2D
function Base.$op{TX1<:Number, TX2<:Number, TY<:Number}(d1::Data2D{TX1,TY}, d2::Data2D{TX2,TY})
	assertsamex(d1, d2)
	return Data2D(d1.x, $(_dotop(op))(d1.y, d2.y))
end

#Data2D op Number
function Base.$op{TX<:Number, TY<:Number, TN<:Number}(d::Data2D{TX,TY}, n::TN)
	return Data2D(d.x, $(_dotop(op))(d.y, n))
end

#Number op Data2D
function Base.$op{TX<:Number, TY<:Number, TN<:Number}(n::TN, d::Data2D{TX,TY})
	return Data2D(d.x, $(_dotop(op))(n, d.y))
end

#Index op Index
Base.$op(i1::Index, i2::Index) = Index($(_dotop(op))(i1.v, i2.v))
end; end

#Last line

