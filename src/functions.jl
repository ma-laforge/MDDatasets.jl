#MDDatasets function tools
#-------------------------------------------------------------------------------

#==Basic tools
===============================================================================#
function getkwarg(kwargs::Vector{Any}, s::Symbol)
	idx = findfirst((kvp)->(s==kvp[1]), kwargs)
	if idx > 0
		return kwargs[idx][2]
	else
		return nothing
	end
end

#Last line
