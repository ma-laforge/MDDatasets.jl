#Test code
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:

#==Input data
===============================================================================#
sepline = "---------------------------------------------------------------------"


#==Basic Tests
===============================================================================#

println("\nShow physics constants:")
#-------------------------------------------------------------------------------
println(sepline)
MDDatasets.Physics.Constants._show()

println("\nTest basic operations on DataF1:")
#-------------------------------------------------------------------------------
println(sepline)
d1 = DataF1(1:10.0)
d2 = xshift(d1, 4.5) + 12
d3 = d1 + 12
d4 = DataF1(d1.x, d1.y[end:-1:1])
d9 = xshift(d1, 100)

@show d1
@show d2
@show d3

r1 = d1+d2
r2 = d1+d3
#r3 = d1+d4

@show r1
@show r2
@show length(d1), length(d2), length(d3), length(r1), length(r2)

println("\nTest clip() function:")
#-------------------------------------------------------------------------------
println(sepline)
@show d3
@show clip(d3, xmin=1.5, xmax=5.5)
@show d1
@show clip(d1, xmin=1.5, xmax=5.5)
@show clip(d1, xmin=2, xmax=5)
@show clip(d1, xmin=1, xmax=9)
@show clip(d1, 3:10)
@show clip(d1, xmin=3)
@show clip(d1, xmax=8.5)


#For cross function testing, mostly
y = [0,0,0,0,1,-3,4,5,6,7,-10,-5,0,0,0,-5,-10,10,-3,1,-4,0,0,0,0,0,0]
d10=DataF1(collect(1:length(y)), y)

println("\nTest cross functions:")
#-------------------------------------------------------------------------------
println(sepline)
xingsall = CrossType(:all)
xingsrise = CrossType(:rise)
xingsfall = CrossType(:fall)

@show d10.y
@show xcross(d10, allow=xingsall).y
@show xcross(d10).y
@show xcross(d10, allow=xingsrise).y
@show xcross(d10, allow=xingsfall).y
@show xcross1(d10, n=1)
@show xcross(d10-.5).y
@show xcross1(d10-.5, n=2)

@show d10.y-.5
@show ycross(d10, .5, allow=xingsall).x
@show ycross(d10, .5, allow=xingsall).y
@show ycross(d10, .5).y
@show ycross(d10, .5, allow=xingsrise).y
@show ycross(d10, .5, allow=xingsfall).y

@show ycross1(d10, .5, n=3)

println("\nTest meas() interface:")
#-------------------------------------------------------------------------------
println(sepline)
@show meas(:xcross, d10, allow=xingsrise).x
@show meas(:xcross, Event, d10, allow=xingsrise).x


#==DataHR/DataRS Tests
===============================================================================#
include("runtests_datahr.jl")
include("runtests_datars.jl")

:Test_Complete
