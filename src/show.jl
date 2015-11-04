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

#TODO: Print array indicies:
function Base.show(io::IO, ds::DataHR)
	szstr = string(size(ds.subsets))
	print(io, "DataHR$szstr[\n")
	for subset in ds.subsets
		print(io, " (coord): "); show(io, subset); println(io)
	end
	print(io, "]\n")
end

function Base.show(io::IO, p::Point2D)
	print(io, "($(p.x), $(p.y))")
end

#Last line
