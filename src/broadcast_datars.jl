#MDDatasets: Support broadcast of DataRS types
#-------------------------------------------------------------------------------


#==General broadcast tools
===============================================================================#
#TODO: Move to broadcast.jl

#==result_type: Figure out result type for a function call with given arguments
===============================================================================#
#Consider result to be abstract "DataRS" when dealing with DataRS:
result_type{T1<:DataRS, T2<:DataRS}(fn::Function, ::Type{T1}, ::Type{T2}) = DataRS
result_type{T1<:DataRS, T2}(fn::Function, ::Type{T1}, ::Type{T2}) = DataRS
result_type{T1, T2<:DataRS}(fn::Function, ::Type{T1}, ::Type{T2}) = DataRS


#==eltype/valtype: Figure out result type for a function call with given arguments
===============================================================================#

#Element type of an operation with a DataRS (result: DataRS):
Base.eltype(fn::Function, d1::DataRS) = result_type(fn, eltype(d1))
Base.eltype(fn::Function, d1::DataRS, d2::DataRS) = 
	result_type(fn, eltype(d1), eltype(d2))
Base.eltype(fn::Function, d1::DataRS, d2) = 
	result_type(fn, eltype(d1), typeof(d2))
Base.eltype(fn::Function, d1, d2::DataRS) = 
	result_type(fn, typeof(d1), eltype(d2))


#==Broadcast tools specific to DataRS
===============================================================================#

#Broadcast functions capable of operating directly on 1 base type (Number):
#-------------------------------------------------------------------------------
#fn(DataRS) - core: fn(Number):
function broadcast(CT::CastType1{Number,1}, fn::Function, d::DataRS, args...; kwargs...)
	result = DataRS{eltype(fn, d)}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcast(CT, fn, d.elem[i], args...; kwargs...)
	end
	return result
end

#=
#Data reducing (DataRS{DataF1/Number})
broadcast{T<:Number}(::CastTypeRed1{Number,1}, fn::Function, d::DataRS{T}, args...; kwargs...) =
	_broadcast(T, fnbasesweep(fn, d), fn, d, args...; kwargs...)
function broadcast(::CastTypeRed1{Number,1}, fn::Function, d::DataRS{DataF1}, args...; kwargs...)
	TR = promote_type(findytypes(d.elem)...) #TODO: Better way?
	_broadcast(TR, fnbasesweep(fn, d), fn, d, args...; kwargs...)
end
=#

#Broadcast functions capable of operating only on a dataF1 value:
#-------------------------------------------------------------------------------
#fn(DataRS) - core: fn(DataF1):
function broadcast{T}(CT::CastType1{DataF1,1}, fn::Function, d::DataRS{T}, args...; kwargs...)
	result = DataRS{T}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcast(CT, fn, d.elem[i], args...; kwargs...)
	end
	return result
end
#=
#fn(???, DataRS) - core: fn(DataF1):
function broadcast(::CastType1{DataF1,2}, fn::Function, dany1, d, args...; kwargs...)
	d = ensure_coll_DataF1(fn, d) #Collapse DataRS{Number}  => DataRS{DataF1}
	_broadcast(DataF1, fnbasesweep(fn, d), fn, dany1, d, args...; kwargs...)
end
#Data reducing fn(DataRS) - core: fn(DataF1):
function broadcast(::CastTypeRed1{DataF1,1}, fn::Function, d, args...; kwargs...)
	d = ensure_coll_DataF1(fn, d) #Collapse DataRS{Number}  => DataRS{DataF1}
	TR = promote_type(findytypes(d.elem)...) #TODO: Better way?
	_broadcast(TR, fnbasesweep(fn, d), fn, d, args...; kwargs...)
end
=#


#Broadcast functions capable of operating directly on base types (Number, Number):
#-------------------------------------------------------------------------------
#fn(DataRS, DataRS) - core: fn(Number, Number):
function broadcast(CT::CastType2{Number,1,Number,2}, fn::Function,
	d1::DataRS, d2::DataRS, args...; kwargs...)
	if d1.sweep != d2.sweep
		msg = "Sweeps do not match (not yet supported):"
		throw(ArgumentError(string(msg, "\n", d1.sweep, "\n", d2.sweep)))
	end
	result = DataRS{eltype(fn, d1, d2)}(d1.sweep)
	for i in 1:length(d1.sweep)
		result.elem[i] = broadcast(CT, fn, d1.elem[i], d2.elem[i], args...; kwargs...)
	end
	return result
end

#fn(DataRS, DataF1/Number) - core: fn(Number, Number):
function broadcast(CT::CastType2{Number,1,Number,2}, fn::Function,
	d1::DataRS, d2::DF1_Num, args...; kwargs...)
	result = DataRS{eltype(fn, d1, d2)}(d1.sweep)
	for i in 1:length(d1.sweep)
		result.elem[i] = broadcast(CT, fn, d1.elem[i], d2, args...; kwargs...)
	end
	return result
end

#fn(DataF1/Number, DataRS) - core: fn(Number, Number):
function broadcast(CT::CastType2{Number,1,Number,2}, fn::Function,
	d1::DF1_Num, d2::DataRS, args...; kwargs...)
	result = DataRS{eltype(fn, d1, d2)}(d2.sweep)
	for i in 1:length(d2.sweep)
		result.elem[i] = broadcast(CT, fn, d1, d2.elem[i], args...; kwargs...)
	end
	return result
end


#Last line
