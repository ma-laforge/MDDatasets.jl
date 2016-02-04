#MDDatasets: Output formatting tools
#-------------------------------------------------------------------------------
#=
Floating-point display modes:
   SHORTEST, FIXED, PRECISION
Prefixes:
	:SI (m, μ, n, ...), :ENG (XE-10)
=#


#==Constants
===============================================================================#

#Don't use μ ... in case some algorithms don't deal well with UTF8:
const _SIPREFIXES = ASCIIString[
	"y", "z", "a", "f", "p", "n", "u", "m", "",
	"k", "M", "G", "T", "P", "E", "Z", "Y"
]
const _SIPREFIXES_OFFSET = 9


#==Base types
===============================================================================#

abstract DataFormatter

immutable FormattedData{FT<:DataFormatter, T}
	data::T
	fmt::FT
end

#Describes how to format floating point values:
immutable FloatFormatter{DISPLAYMODE,PREFIX} <: DataFormatter
	ndigits::Int
end


#==Constructors
===============================================================================#
#Only support SHORTEST & PRECISION, for now:
function FloatFormatter(pfx::Symbol=:ENG; ndigits::Int=0)
	dm = 0==ndigits? (Base.Grisu.SHORTEST) : (Base.Grisu.PRECISION)
	return FloatFormatter{dm,pfx}(ndigits)
end


#==Hooks to use DataFormatter objects in a natural fashion
===============================================================================#
#Print formatted data to IO (print_formatted implemented by each DataFormatter)
Base.print(io::IO, d::FormattedData) = print_formatted(io, d.fmt, d.data)

#Give DataFormatter objects a means to create FormattedData objects:
call(r::DataFormatter, v::Number) = FormattedData(v, r)


#==Display formatted numbers
===============================================================================#

#Engineering notation
function print_formatted{DM}(io::IO, r::FloatFormatter{DM,:ENG}, v::AbstractFloat)
	Base.Grisu._show(io, v, DM, r.ndigits, false)
end

#SI notation
function print_formatted{DM, T<:AbstractFloat}(io::IO, r::FloatFormatter{DM,:SI}, v::T)
	if isinf(v) || isnan(v)
		print(io, v)
		return
	end
	len, pt, neg, buffer = Base.Grisu.grisu(v, DM, r.ndigits)
	xpnt = pt - 3 #Targeted exponent value
	#Compute index of SI:
	idx = clamp(ceil(Int,xpnt/3), 1-_SIPREFIXES_OFFSET, length(_SIPREFIXES)-_SIPREFIXES_OFFSET)
	xpnt = idx * 3 #Back to exponent, rounded off to SI steps
	vbase = v/(10^T(xpnt)) #Eliminate portion of exponent
	idx += _SIPREFIXES_OFFSET
	Base.Grisu._show(io, vbase, Base.Grisu.FIXED, r.ndigits, false)
	print(io, _SIPREFIXES[idx])
end

print_formatted(io::IO, r::FloatFormatter, v::Real) = print_formatted(io, r, Float64(v))

#Last line
