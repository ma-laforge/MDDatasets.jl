# MDDatasets.jl: [demo1.jl](../sample/demo1.jl)
```
using MDDatasets
```

Create `(x,y)` container pair, and call it “x”:
```
x = DataF1(0:.1:20)
#NOTE: Both x & y coordinates of "x" object initialized as y = x = [supplied range]
```

“Extract” maximum x-value from data:
```
xmax = maximum(x)
```

Construct a normalized ramp dataset, `unity_ramp`:
```
unity_ramp = x/xmax
```

## Observe `x` and `unity_ramp`
(Note how `unity_ramp` is normalized such that maximum value is 1)
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_1.png">

Compute `cos(kx)` & `ksinkx = cos'(kx)`:
```
coskx = cos((2.5pi/10)*x)
ksinkx = deriv(coskx)
```

Compute ramps with different slopes using `unity_ramp` (previously computed):
```
#NOTE: for Inner-most sweep, we need to specify leaf element type (DataF1 here):
ramp = fill(DataRS{DataF1}, PSweep("slope", [0, 0.5, 1, 1.5, 2])) do slope
	return unity_ramp * slope
end
```

NOTE: the above expression constructs a multi-dimensional `DataRS` structure, and fills it with `(x,y)` values for each of the desired parameter values (the slope).

## Observe `coskx`, `ksinkx` and `ramp`
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_2.png">


Merge two datasets with different # of sweeps (`coskx` & `ramp`):
```
r_cos = coskx+ramp
```

## Observe newly constructed `r_cos` dataset:
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_3.png">

Shift all ramped cos(kx) waveforms to make them centered at their mid-points:
```
midval = (minimum(ramp) + maximum(ramp)) / 2
c_cos = r_cos - midval #Shift by midval (different for each swept slope of "ramp")
```

## Observe newly constructed `c_cos` dataset:
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_4.png">
