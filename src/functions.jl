#MDDatasets function tools
#-------------------------------------------------------------------------------

#==Basic tools
===============================================================================#

#Get the value of a particular keyword in the list of keyword arguments:
function getkwarg(kwargs::Vector{Any}, s::Symbol)
	idx = findfirst((kvp)->(s==kvp[1]), kwargs)
	if idx > 0
		return kwargs[idx][2]
	else
		return nothing
	end
end

#Generate error that a function using dispatchable symbols is not supported:
function nosupport(fn::Function, symlist::Vector{Symbol}, args...; kwargs...)
	argstr = [typeof(a) for a in args]
		arglist = join(argstr, ", ")
	kvstr = ["$k=$(typeof(v))" for (k,v) in kwargs]
		kwarglist = join(kvstr, ", ")
	symstr = [string(sym) for sym in symlist]
		symlist = join(symstr, ", ")
	return ArgumentError("Unsupported: $fn{$symlist}($arglist; $kwarglist)")
end

#Last line
