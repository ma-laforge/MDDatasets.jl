#MDDatasets: Tools to store/manipulate multi-dimensional data
#-------------------------------------------------------------------------------
module MDDatasets

include("base.jl")
include("vectorop.jl")
include("datasetop.jl")
include("show.jl")

#==TODO: Watch out for val() being exported by multiple modules...
Maybe it can be defined in "Units"
==#

#Data types:
export DataMD #Prefered abstraction for high-level functions
export Index #A way to identify parameters as array indicies
export DataScalar, Data2D
export DataHR

#Accessor functions:
export value #High-collision WARNING: other modules probably want to export "value"
export subsets

#Operations:
export xval
export shift

end

#Last line
