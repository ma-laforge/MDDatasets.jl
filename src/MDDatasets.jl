#MDDatasets: Tools to store/manipulate multi-dimensional data
#-------------------------------------------------------------------------------
module MDDatasets

include("base.jl")
include("operations.jl")
include("show.jl")
include("vectorop.jl")

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
export yval
export shift

end

#Last line
