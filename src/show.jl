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

#Don't show module name/subtypes for DataF1:
function Base.show{TX<:Number, TY<:Number}(io::IO, ds::DataF1{TX,TY})
	print(io, "DataF1(x=")
		_showcompact(io, ds.x)
		print(io, ",y=")
		_showcompact(io, ds.y)
		print(io, ")")
end

#Also changes string()
Base.print(io::IO, ::Type{DataHR{DataF1}}) = print(io, "DataHR{DataF1}")
Base.print(io::IO, ::Type{DataHR{DataFloat}}) = print(io, "DataHR{DataFloat}")
Base.print(io::IO, ::Type{DataHR{DataInt}}) = print(io, "DataHR{DataInt}")
Base.print(io::IO, ::Type{DataHR{DataComplex}}) = print(io, "DataHR{DataComplex}")

function Base.show(io::IO, ds::DataHR)
	szstr = string(size(ds.subsets))
	typestr = string(typeof(ds))
	print(io, "$typestr$szstr[\n")
	for coord in subscripts(ds)
		if isdefined(ds.subsets, coord...)
			subset = ds.subsets[coord...]
			print(io, " $coord: "); show(io, subset); println(io)
		else
			println(io, " $coord: UNDEFINED")
		end
	end
	print(io, "]\n")
end

function Base.show{T<:Number}(io::IO, ds::DataHR{T})
	szstr = string(size(ds.subsets))
	typestr = string(typeof(ds))
	print(io, "$typestr$szstr:\n")
	print(io, ds.subsets)
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
