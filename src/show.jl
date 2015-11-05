#MDDatasets show functions
#-------------------------------------------------------------------------------

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

Base.string(::Type{DataHR{Data2D}}) = "DataHR{Data2D}"
Base.string(::Type{DataHR{DataFloat}}) = "DataHR{DataFloat}"
Base.string(::Type{DataHR{DataInt}}) = "DataHR{DataInt}"
Base.string(::Type{DataHR{DataComplex}}) = "DataHR{DataComplex}"

#TODO: Print array indicies:
function Base.show(io::IO, ds::DataHR)
	szstr = string(size(ds.subsets))
	typestr = string(typeof(ds))
	print(io, "$typestr$szstr[\n")
	for i in 1:length(ds.subsets)
		if isdefined(ds.subsets, i)
			subset = ds.subsets[i]
			print(io, " (coord): "); show(io, subset); println(io)
		else
			println(io, " (coord): UNDEFINED")
		end
	end
	print(io, "]\n")
end

#==
function Base.show{T}(io::IO, d::DataScalar{T})
	print(io, "DataScalar{$T}($(d.v))")
end
==#

function Base.show{TX,TY}(io::IO, p::Point2D{TX,TY})
	print(io, "Point2D{$TX,$TY}($(p.x), $(p.y))")
end

function Base.showcompact(io::IO, p::Point2D)
	print(io, "pt($(p.x), $(p.y))")
end

#Last line
