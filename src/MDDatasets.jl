#MDDatasets: Tools to store/manipulate multi-dimensional data
#-------------------------------------------------------------------------------
module MDDatasets

include("vectorop.jl") #Some useful vector-only tools
include("base.jl")
include("datasetop.jl")
include("show.jl")

#==TODO: Watch out for val() being exported by multiple modules...
Maybe it can be defined in "Units"
==#

#Data types:
export DataMD #Prefered abstraction for high-level functions
export PSweep #Parameter sweep
export Index #A way to identify parameters as array indicies
export DataFloat, DataInt, DataComplex, Data2D #Leaf data types
export DataHR

#Accessor functions:
export value #High-collision WARNING: other modules probably want to export "value"
export subsets
export subscripts #Get subscripts to access each element in DataHR.
export sweeps #Get the list of parameter sweeps in DataHR.
export parameter #Get parameter sweep info regarding as DataHR subset

#Operations:
export xval
export shift

end

#Last line
