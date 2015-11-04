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

immutable Point2D{TX<:Number, TY<:Number}
	x::TX
	y::TY
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
#ASSERT SORTED

#Will have to remove this as a requirement
function assertsamex(d1::Data2D, d2::Data2D)
	@assert(d1.x==d2.x, "Operation currently only supported for the same x-data")
end

#Perform simple checks to validate data integrity
function validate(d::Data2D)
	@assert(length(d.x)==length(d.y), "Invalid Data2D: x & y lengths do not match")
end

#==Useful functions
===============================================================================#
Base.copy(d::Data2D) = Data2D(d.x, copy(d.y))

#Default linear interpolation:
#NOTE:
#    -Assumes value is zero when out of bounds
#TODO: inline?
#function interpolate{TX<:Number, TY<:Number}(d1::Data2D{TX,TY}; x::TX=0)
#end

function interpolate{TX<:Number, TY<:Number}(p1::Point2D{TX,TY}, p2::Point2D{TX,TY}; x::TX=0)
	m = (p2.y-p1.y) / (p2.x-p1.x)
	return m*(x-p1.x)+p1.y
end

Point2D(d::Data2D, i::Int) = Point2D(d.x[i], d.y[i])

function applydisjoint{TX<:Number, TY1<:Number, TY2<:Number}(fn::Function, d1::Data2D{TX,TY1}, d2::Data2D{TX,TY2})
	@assert(false, "Currently no support for disjoint datasets")
end

#Apply a function of two scalars to two Data2D objects:
#NOTE:
#   -Do not use "map", because this is more complex than one-to-one mapping
#   -Assumes ordered x-values
function apply{TX<:Number, TY1<:Number, TY2<:Number}(fn::Function, d1::Data2D{TX,TY1}, d2::Data2D{TX,TY2})
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
	_x12 = max(_x1, _x2) #First intersecting point
	x[1] = min(_x1, _x2) #First point

	while x[i] < _x2 #Only d1 has values (assume d2 is 0)
		y[i] = fn(d1.y[i1], zero2)
		i += 1; i1 += 1
		x[i] = d1.x[i1]
	end
	while x[i] < _x1 #Only d2 has values (assume d1 is 0)
		y[i] = fn(zero1, d2.y[i2])
		i += 1; i2 += 1
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
			i1 += 1
			p1 = p1next; p1next = Point2D(d1, i1)
		else
			y1 = interpolate(p1, p1next, x=x[i])
		end
		if p2next.x == x[i]
			y2 = p2next.y
			i2 += 1
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
	#Deal with last point:
#==
	if x1_ < x2_
		y[i] = fn(zero1, d2.y[i2])
	else
		y[i] = fn(d1.y[i1], zero2)
	end
==#
	npts = i

	return Data2D(resize!(x, npts), resize!(y, npts))
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
	return apply(Base.$op, d1, d2)
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

