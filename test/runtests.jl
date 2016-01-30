#Test code
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:

println("\nShow physics constants:")
MDDatasets.Physics.Constants._show()

include("runtests_datahr.jl")
include("runtests_datars.jl")

:Test_Complete
