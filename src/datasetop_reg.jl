#MDDatasets: Register dataset operations
#-------------------------------------------------------------------------------

#==NOTE:
	:cummax, :cummin, :cumprod, :cumsum, maxabs, are high-level functions... not sure
	if these should be ported, or new names/uses should be found
==#

#==Support basic math operations
===============================================================================#
#==NOTE
DataF1 cannot represent matrices.  Element-by-element operations will therefore
be the default.  There is not need to use the "." operator versions.
==#
const _operators = Symbol[:-, :+, :/, :*]
_dotop(x)=Symbol(".$x")

for op in _operators; @eval begin #CODEGEN--------------------------------------

#Index op Index:
Base.$op(i1::Index, i2::Index) = Index($(_dotop(op))(i1.v, i2.v))

#DataF1 op DataF1:
Base.$op(d1::DataF1, d2::DataF1) = apply(Base.$op, d1, d2)

#DataF1 op Number:
Base.$op(d::DataF1, n::Number) = DataF1(d.x, $(_dotop(op))(d.y, n))

#Number op DataF1:
Base.$op(n::Number, d::DataF1) = DataF1(d.x, $(_dotop(op))(n, d.y))

#DataHR op DataHR:
Base.$op{T1,T2}(d1::DataHR{T1}, d2::DataHR{T2}) = broadcast2(promote_type(T1,T2), Base.$op, d1, d2)

#DataHR op DataF1/Number:
Base.$op{T1,T2<:Union{DataF1,Number}}(d1::DataHR{T1}, d2::T2) = broadcast2(promote_type(T1,T2), Base.$op, d1, d2)

#DataF1/Number op DataHR:
Base.$op{T1<:Union{DataF1,Number},T2}(d1::T1, d2::DataHR{T2}) = broadcast2(promote_type(T1,T2), Base.$op, d1, d2)


end; end #CODEGEN---------------------------------------------------------------


#==DataF1 support for 1-argument functions from Base
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

#fn(DataF1)
$fn(d::DataF1) = DataF1(d.x, $fn(d.y))

end; end #CODEGEN---------------------------------------------------------------


#==DataF1 support for 2-argument functions from Base
===============================================================================#

#2-argument functions from base:
#-------------------------------------------------------------------------------
const _basefn2 = [:(Base.$fn) for fn in [
	:max, :min,
	:atan2, :hypot,
]]

for fn in _basefn2; @eval begin #CODEGEN----------------------------------------

#fn(DataF1, DataF1):
$fn(d1::DataF1, d2::DataF1) = apply($fn, d1, d2)

end; end #CODEGEN---------------------------------------------------------------


#==DataF1 support for reducing/collpasing functions
===============================================================================#
const _baseredfn1 = [:(Base.$fn) for fn in [
	:maximum, :minimum, :minabs, :maxabs,
	:prod, :sum,
	:mean, :median, :middle,
]]

for fn in _baseredfn1; @eval begin #CODEGEN-------------------------------------

#fn(DataF1):
$fn(d::DataF1) = $fn(d.y)

end; end #CODEGEN---------------------------------------------------------------


#==Custom 1-argument functions of DataF1
===============================================================================#

#1-argument functions that can be generically extended:
const _custfn1 = [
	:clip, :xval, :sample,
	:xshift, :xscale,
	:deriv, :integ, :iinteg,
	:xcross, :measperiod, :measfreq,
]

#Data reducing:
const _custredfn1 = [
	:xcross1,
]


#==Custom 2-argument functions of DataF1
===============================================================================#
const _custfn2 = [
	:yvsx,
	:measdelay,
	:ycross,
]

#Data reducing:
const _custredfn2 = [
	:ycross1,
]

#Custom 2-argument functions of DataF1 with ::DS{} as first argument
const _custfn2DS = [
	:measdelay,
]


#==Register functions with DataHR
===============================================================================#

#1-argument functions
for fn in vcat(_basefn1, _custfn1); @eval begin #CODEGEN------------------------


#fn(DataHR)
$fn{T}(d::DataHR{T}, args...; kwargs...) = broadcast1(T, $fn, d, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------

#2-argument functions
for fn in vcat(_basefn2, _custfn2); @eval begin #CODEGEN------------------------

#fn(DataHR, DataHR):
$fn{T1, T2}(d1::DataHR{T1}, d2::DataHR{T2}, args...; kwargs...) =
	broadcast2(promote_type(T1,T2), $fn, d1, d2, args...; kwargs...)

#fn(DataHR, DataF1/Number):
$fn{T1,T2<:Union{DataF1,Number}}(d1::DataHR{T1}, d2::T2, args...; kwargs...) =
	broadcast2(promote_type(T1,T2), $fn, d1, d2, args...; kwargs...)

#fn(DataF1/Number, DataHR):
$fn{T1<:Union{DataF1,Number},T2}(d1::T1, d2::DataHR{T2}, args...; kwargs...) =
	broadcast2(promote_type(T1,T2), $fn, d1, d2, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------


#2-argument functions with ::DS{} as first argument
for fn in vcat(_custfn2DS); @eval begin #CODEGEN------------------------

#fn(DataHR, DataHR):
$fn{T1, T2}(ds::DS, d1::DataHR{T1}, d2::DataHR{T2}, args...; kwargs...) =
	broadcast2(promote_type(T1,T2), $fn, ds, d1, d2, args...; kwargs...)

#fn(DataHR, DataF1/Number):
$fn{T1,T2<:Union{DataF1,Number}}(ds::DS, d1::DataHR{T1}, d2::T2, args...; kwargs...) =
	broadcast2(promote_type(T1,T2), $fn, ds, d1, d2, args...; kwargs...)

#fn(DataF1/Number, DataHR):
$fn{T1<:Union{DataF1,Number},T2}(ds::DS, d1::T1, d2::DataHR{T2}, args...; kwargs...) =
	broadcast2(promote_type(T1,T2), $fn, ds, d1, d2, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------


#2-argument reducing/collpasing functions:
for fn in vcat(_custredfn2); @eval begin #CODEGEN------------------------

$fn(d1, d2, args...; kwargs...) =
	broadcast2(Number, $fn, d1, d2, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------


#1-argument reducing/collpasing functions:
for fn in vcat(_baseredfn1, _custredfn1); @eval begin #CODEGEN---------------------------

#fn(DataHR)
$fn(d::DataHR{DataF1}, args...; kwargs...) = broadcast1(Number, $fn, d, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------
#Last line
