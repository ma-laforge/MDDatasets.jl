#Test code
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:

@show d1 = Data2D([1,2,3], [4,5,6])
@show dhr = DataHR([d1 d1; d1 d1])

d1 = Data2D(1:10.0)
d2 = Data2D(d1.x .+ 4.5, d1.y .+ 12)
d3 = Data2D(d1.x, d1.y .+ 12)
d4 = Data2D(d1.x, collect(10.0:-1:1))
d9 = Data2D(d1.x .+100, d1.y)

@show d1
@show d2
@show d3

r1 = d1+d2
r2 = d1+d3
#r3 = d1+d4

@show r1
@show r2

@show length(d1), length(d2), length(d3), length(r1), length(r2)


:Test_Complete
