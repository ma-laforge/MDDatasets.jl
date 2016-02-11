#MDDatasets: Additional math tools
#-------------------------------------------------------------------------------
#=NOTE:
These tools should eventually be moved to a separate unit.
=#


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
Limits1D{TL<:Number,TH<:Number}(min::TL, max::TH) = Limits1D{promote_type(TL,TH)}(min, max)
Limits1D{T<:Number}(min::T, ::Void) = Limits1D(min, typemax(T))
Limits1D{T<:Number}(::Void, max::T) = Limits1D(typemin(T), max)
Limits1D(;min=nothing, max=nothing) = Limits1D(min, max)
Limits1D(r::Range) = Limits1D(minimum(r), maximum(r)) #TODO: is it preferable to use rng[1/end]?

#Constructor with forced type (Limits1D{Float32}(min=4)):
call{T<:Number}(::Type{Limits1D{T}}, min::Number, ::Void) = Limits1D{T}(convert(T, min), typemax(T))
call{T<:Number}(::Type{Limits1D{T}}, ::Void, max::Number) = Limits1D{T}(typemin(T), convert(T, max))
call{T<:Number}(::Type{Limits1D{T}} ;min=nothing, max=nothing) = Limits1D{T}(min, max)
call{T<:Number}(::Type{Limits1D{T}}, r::Range) = Limits1D{T}(convert(T,minimum(r)), convert(T,maximum(r)))


#==Enhance base functions
===============================================================================#
#Maximum/minimum finite values:
minfinite{T<:Integer}(::Type{T}) = typemin(T)
maxfinite{T<:Integer}(::Type{T}) = typemax(T)
minfinite{T<:AbstractFloat}(::Type{T}) = nextfloat(convert(T, -Inf))
maxfinite{T<:AbstractFloat}(::Type{T}) = prevfloat(convert(T, Inf))

#Use Limits1D with clamp:
Base.clamp(v::Union{Number,Vector}, r::Limits1D) = clamp(v, r.min, r.max)
Base.clamp!(v::Union{Number,Vector}, r::Limits1D) = clamp!(v, r.min, r.max)

#sanitize: clamp down infinite/large values & replace NaNs
#-------------------------------------------------------------------------------
_sanitize_type{T, TL, TH}(::T, ::TL, ::TH) = promote_type_nonvoid(T, TL, TH)
_sanitize_dfltnan{T<:Integer}(::Type{T}) = 0 #Does not matter (input never NaN)
_sanitize_dfltnan{T<:AbstractFloat}(::Type{T}) = convert(T, NaN) #Don't modify NaN
function _sanitize_defaults{T}(::Type{T}, min, max, nan)
	return tuple(convert(T, substvoid(min, minfinite(T))),
		convert(T, substvoid(max, maxfinite(T))),
		convert(T, substvoid(nan, _sanitize_dfltnan(T)))
	)
end

function _sanitize(x, min, max, nan)
	return ifelse(isnan(x), nan,
		ifelse(x>max, max,
		ifelse(x<min, min, x)))
end
function _sanitize{T}(::Type{T}, x::Real, min, max, nan)
	(min, max, nan) = _sanitize_defaults(T, min, max, nan)
	return _sanitize(convert(T, x), min, max, nan)
end
sanitize(x::Real; min=nothing, max=nothing, nan=nothing) =
	_sanitize(_sanitize_type(x,min,max), x, min, max, nan)

function _sanitize{T}(::Type{T}, x::Vector, min, max, nan)
	(min, max, nan) = _sanitize_defaults(T, min, max, nan)
	return T[_sanitize(xi, min, max, nan) for xi in x]
end
sanitize(x::Vector; min=nothing, max=nothing, nan=nothing) =
	_sanitize(promote_type_nonvoid(eltype(x),typeof(min),typeof(max)), x, min, max, nan)

#==Interpolation
===============================================================================#
#Interpolate between two points.
function _interpolate(p1::Point2D, p2::Point2D, x::Number)
	m = (p2.y-p1.y) / (p2.x-p1.x)
	return m*(x-p1.x)+p1.y
end
_interpolate(p1::Point2D, p2::Point2D, x::Void) =
	throw(ArugmentError("Must provide an x-value: interpolate(p1, p2, x=VAL)"))
interpolate(p1::Point2D, p2::Point2D; x=nothing) = _interpolate(p1, p2, x)

#Last line
