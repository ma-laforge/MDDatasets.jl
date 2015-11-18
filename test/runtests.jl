#Test code
#-------------------------------------------------------------------------------

using MDDatasets

#No real test code yet... just run demos:

@show d1 = DataF1([1,2,3], [4,5,6])
sweeplist = PSweep[
	PSweep("v1", [1,2])
	PSweep("v2", [1,2])
]
@show dhr = DataHR(sweeplist,DataF1[d1 d1; d1 d1])

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

println("\nConverter tests:")
@show dB10(2), dB20(2)
@show dB(2,:Wratio), dB(2,:Vratio), dB(2,:Iratio)
@show dBm(2,:W), dBm(2,:VRMS), dBm(2,:Vpk)
@show dBW(2,:W), dBW(2,:VRMS), dBW(2,:Vpk)
@show Vpk(2,:W; R=50), Vpk(2,:VRMS)
@show Ipk(2,:W; R=50), Ipk(2,:IRMS)
@show VRMS(2,:W; R=50), VRMS(2,:Vpk)
@show IRMS(2,:W; R=50), IRMS(2,:Ipk)



:Test_Complete
