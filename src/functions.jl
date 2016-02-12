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

#==Ensure interface (similar to assert)
===============================================================================#
#=Similar to assert.  However, unlike assert, "ensure" is not meant for
debugging.  Thus, ensure is never meant to be compiled out.
=#
function ensure(cond::Bool, err)
	if !cond; throw(err); end
end

#Conditionnally generate error using "do" syntax:
function ensure(fn::Function, cond::Bool)
	if !cond; throw(fn()); end
end

#Last line
