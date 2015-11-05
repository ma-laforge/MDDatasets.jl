#MDDatasets: Dataset operations
#-------------------------------------------------------------------------------

#==NOTE:
	:cummax, :cummin, :cumprod, :cumsum, maxabs, are high-level functions... not sure
	if these should be ported, or new names/uses should be found
==#

#==Support basic math operations
===============================================================================#
#==NOTE
Data2D cannot represent matrices.  Element-by-element operations will therefore
be the default.  There is not need to use the "." operator versions.
==#
const _operators = Symbol[:-, :+, :/, :*]
_dotop(x)=Symbol(".$x")

for op in _operators; @eval begin #CODEGEN--------------------------------------

#Index op Index:
Base.$op(i1::Index, i2::Index) = Index($(_dotop(op))(i1.v, i2.v))

#Data2D op Data2D:
Base.$op(d1::Data2D, d2::Data2D) = apply(Base.$op, d1, d2)

#Data2D op Number:
Base.$op(d::Data2D, n::Number) = Data2D(d.x, $(_dotop(op))(d.y, n))

#Number op Data2D:
Base.$op(n::Number, d::Data2D) = Data2D(d.x, $(_dotop(op))(n, d.y))

#DataHR op DataHR:
Base.$op(d1::DataHR, d2::DataHR) = apply(Base.$op, d1, d2)

#DataHR op Data2D/Number:
Base.$op(d1::DataHR, d2::Union{Data2D,Number}) = apply(Base.$op, d1, d2)

#Data2D/Number op DataHR:
Base.$op(d1::Union{Data2D,Number}, d2::DataHR) = apply(Base.$op, d1, d2)


end; end #CODEGEN---------------------------------------------------------------


#==Data2D support for 1-argument functions from Base
===============================================================================#

#==TODO:
Check out statistical stuff

isempty, isfinite, isinf, isinteger, isnan, isposdef, isreal

fft, etc

Mapping ??
map, mapreduce, mapreducedim, mapslices

#Number converters
#Bool(): map(Bool, x)
round
...

#other
#clamp: lo, hi
#eachindex
rand
==#

#1-argument functions from base:
const _basefn1 = [:(Base.$fn) for fn in [
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
]]

for fn in _basefn1; @eval begin #CODEGEN----------------------------------------

#fn(Data2D)
$fn(d::Data2D) = Data2D(d.x, $fn(d.y))

end; end #CODEGEN---------------------------------------------------------------


#==Data2D support for 2-argument functions from Base
===============================================================================#

#2-argument functions from base:
#-------------------------------------------------------------------------------
const _basefn2 = [:(Base.$fn) for fn in [
	:max, :min,
	:atan2, :hypot,
]]

for fn in _basefn2; @eval begin #CODEGEN----------------------------------------

#fn(Data2D, Data2D):
$fn(d1::Data2D, d2::Data2D) = apply($fn, d1, d2)

end; end #CODEGEN---------------------------------------------------------------


#==Data2D support for reducing/collpasing functions
===============================================================================#
const _baseredfn1 = [:(Base.$fn) for fn in [
	:maximum, :minimum, :minabs, :maxabs,
	:prod, :sum,
	:mean, :median, :middle,
]]

for fn in _baseredfn1; @eval begin #CODEGEN-------------------------------------

#fn(Data2D):
$fn(d::Data2D) = $fn(d.y)

end; end #CODEGEN---------------------------------------------------------------


#==Custom 1-argument functions of Data2D
===============================================================================#

#Obtain a dataset of the x-values
xval(d::Data2D) = Data2D(d.x, copy(d.x))

#Shifts a dataset by +/-offset:
function shift(d::Data2D, offset::Number)
	return Data2D(d.x.+offset, copy(d.y))
end
shift(d::DataHR, offset::Number) = apply(d, offset)

#1-argument functions that can be generically extended:
const _custfn1 = [
	:xval
]

#==Custom 2-argument functions of Data2D
===============================================================================#

const _custfn2 = [
]

#==Register functions with DataHR
===============================================================================#

#1-argument functions
for fn in vcat(_basefn1, _custfn1); @eval begin #CODEGEN------------------------


#fn(DataHR)
$fn(d::DataHR) = apply($fn, d)

end; end #CODEGEN---------------------------------------------------------------

#2-argument functions
for fn in vcat(_basefn2, _custfn2); @eval begin #CODEGEN------------------------

#fn(DataHR, DataHR):
$fn(d1::DataHR, d2::DataHR) = apply($fn, d1, d2)

#fn(DataHR, Data2D/Number):
$fn(d1::DataHR, d2::Union{Data2D,Number}) = apply($fn, d1, d2)

#fn(Data2D/Number, DataHR):
$fn(d1::Union{Data2D,Number}, d2::DataHR) = apply($fn, d1, d2)

end; end #CODEGEN---------------------------------------------------------------

#1-argument reducing/collpasing functions:
#NOTE: Only work on non-scalar values
for fn in vcat(_baseredfn1, []); @eval begin #CODEGEN---------------------------

#fn(DataHR)
$fn(d::DataHR{Data2D}) = applyreduce($fn, d)

end; end #CODEGEN---------------------------------------------------------------
#Last line
