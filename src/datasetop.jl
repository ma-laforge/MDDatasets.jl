#MDDatasets: Dataset operations
#-------------------------------------------------------------------------------


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


#==Support more functionality from Base
===============================================================================#

#==TODO:
Check out statistical stuff

isempty, isfinite, isinf, isinteger, isnan, isposdef, isreal

fft, etc

2 vectors:


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
	:zeros, :ones, :abs, :abs2, :angle,
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

Base.maximum(d::Data2D) = DataScalar(maximum(d.y))
Base.minimum(d::Data2D) = DataScalar(minimum(d.y))

#2-argument functions from base:
_basefn2 = [
	:max, :min,
	:atan2, :hypot,
]

for fn in _basefn2; @eval begin

#fn(Data2D, Data2D)
function Base.$fn{TX<:Number, TY1<:Number, TY2<:Number}(d1::Data2D{TX,TY1}, d2::Data2D{TX,TY2})
	return apply($fn, d1, d2)
end

end; end


#==Miscellaneous dataset operations
===============================================================================#

#Obtain a dataset of the x-values
xval(d::Data2D) = Data2D(d.x, copy(d.x))

#Shifts a dataset by +/-offset:
function shift(d::Data2D, offset::Number)
	return Data2D(d.x.+offset, copy(d.y))
end

#Last line
