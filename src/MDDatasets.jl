#MDDatasets: Tools to store/manipulate multi-dimensional data
#-------------------------------------------------------------------------------
module MDDatasets

#==Suggested scalar data types
	-Use concrete types of the largest size natively supported by processor
   -Eventually should move to 128-bit values, etc.==#
typealias DataFloat Float64
typealias DataInt Int64
typealias DataComplex Complex{Float64}
#==NOTES:
Don't use Int.  If this is like c, "Int" represents the "native" integer
size/type.  That might not be the same as the largest integer that can be
handled with reasonable efficiency

No reason to have an alias for Bool.  Probably best to keep the default
representation.==#

include("functions.jl")
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
export DataFloat, DataInt, DataComplex, DataF1 #Leaf data types
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

export DataFloat, DataInt, DataComplex

end

#Last line
