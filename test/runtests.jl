#Test code
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:

@show d1 = Data2D([1,2,3], [4,5,6])

@show dhr = DataHR([d1 d1; d1 d1])

:Test_Complete
