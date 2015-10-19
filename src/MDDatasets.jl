#MDDatasets: Tools to store/manipulate multi-dimensional data
#-------------------------------------------------------------------------------
module MDDatasets

include("base.jl")

#Data types:
export DataMD #Prefered abstraction for high-level functions
export DataScalar, Data2D
export DataHR

#Functions:
export subsets

end

#Last line
