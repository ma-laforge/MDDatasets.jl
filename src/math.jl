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
Base.clamp(v, r::Limits1D) = clamp(v, r.min, r.max)
Base.clamp!(v, r::Limits1D) = clamp!(v, r.min, r.max)


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
