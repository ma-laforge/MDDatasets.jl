# MDDatasets.jl: Multi-Dimensional Datasets

## Description

The MDDatasets.jl module provides tools to simplify manipulation of multi-dimensional datasets.

### Principal Types

 - **`DataInt, DataFloat, DataComplex`**: Useful aliases for largest practical data types on a platform (not yet platform dependent).
 - **`DataMD`**: Abastract data type for multi-dimensional data.
 - **`DataF1`**: Represens a function of 1 variable, y(x) using a x/y vector pair.
 - **`DataHR{DataF1/DataInt/DataFloat/DataComplex}`**: A hyper-rectangle (as opposed to hyper-cube) organizaton of data.  Principally designed to collect massive datasets with *independent* control variables ([see examples](#SampleUsage_DataHR)).
 - **`DataRS{DataF1/DataInt/DataFloat/DataComplex}`**: A recursive-sweep organization of data.  Principally designed to collect massive datasets with *dependent* control variables([see examples](#SampleUsage_DataRS)).
 - **`PSweep`**: A parameter sweep (i.e. an independent control variable that generates experimental points in a `DataHR` dataset).

### Automatic Interpolation

Operations performed on two `DataF1` objects will result in the interpolation of the corresponding `{x, y}` coordinates.

By default, "interpolation" of data outside the range of a `DataF1` object (extrapolated) is assumed to be 0.

### Automatic Broadcast

Operations performed on multi-dimensional data sets, `DataHR` and `DataRS`, will be broadcast to each element of the dataset.

Thus, explicit looping over `DataHR` & `DataRS` structures is not typically required.

### Function Listing

#### Imported from `Base`

 - Single-argument functions:

  - `zeros, ones, abs, abs2, angle,`
<br>`imag, real, exponent,`
<br>`exp, exp2, exp10, expm1,`
<br>`log, log10, log1p, log2,`
<br>`ceil, floor,`
<br>`asin, asind, asinh, acos, acosd, acosh,`
<br>`atan, atand, atanh, acot, acotd, acoth,`
<br>`asec, asecd, asech, acsc, acscd, acsch,`
<br>`sin, sind, sinh, cos, cosd, cosh,`
<br>`tan, tand, tanh, cot, cotd, coth,`
<br>`sec, secd, sech, csc, cscd, csch,`
<br>`sinpi, cospi,`
<br>`sinc, cosc,`
<br>`deg2rad, rad2deg,`

 - Two-argument functions:

  - `+, -, *, /,`
<br>`max, min,`
<br>`atan2, hypot,`
<br>`maximum, minimum, minabs, maxabs,`
<br>`prod, sum,`
<br>`mean, median, middle,`

#### Differential/Integral Math

 - **`deriv`**`(d::DataF1, shiftx=[T/F])`: Returns dataset with derivative of `d`
 - **`integ`**`(d::DataF1, shiftx=[T/F])`: Returns definite integral of `d`
 - **`iinteg`**`(d::DataF1, shiftx=[T/F])`: Returns dataset with indefinite integral of `d`

#### Basic Dataset Operations
 - **`xval`**`(::DataF1)`: Returns a dataset with where y(x) = x.
 - **`value`**`(::DataF1, x=[XVALUE])`: Returns `y(XVALUE)`
 - **`clip`**`()`: Returns a dataset clipped within an x-range
  - `clip(::DataF1, xrng::Range)`
  - `clip(::DataF1, xmin=[MINVALUE], xmax=[MAXVALUE])`
 - **`sample`**`(::DataF1, xrng::Range)`: Returns dataset sampled @ each point in `xrng`
 - **`xshift`**`(::DataF1, offset::Number)`: Returns dataset with all x-values shifted by +/-`offset`
 - **`xscale`**`(::DataF1, fact::Number)`: Returns dataset with all x-values scaled by `fact`
 - **`yvsx`**`(yv::DataF1, xv::DataF1)`: Returns dataset with `{xv(x), yv(x)}` (interpolating, when necessary)

#### Cross-based Functions

Note: The `Event` object makes functions return x-vectors that represent the current event number.

TODO: rename `tstart => xstart`
<br>TODO: rename `tstart_ref, tstart_main => xstart_ref, xstart_main`
<br>TODO: rename `xing1, xing2 => xref, xmain`

 - **`xcross`**`()`: Returns x-values of `d1` (up-to `nmax`) when `d1` crosses 0 (`nmax`=0: get all crossings):
  - `xcross([Event,] d1::DataF1, [nmax::Int,] tstart=[TSTART], allow::CrossType=[XTYPE])`
 - **`ycross`**`()`: Returns y-values of `d2` (up-to `nmax`) when `d1` crosses `d2` (`nmax`=0: get all crossings):
  - `ycross([Event,] d1::DataF1, d2::DataF1, [nmax::Int,] tstart=[TSTART], allow::CrossType=[XTYPE])`
 - **`xcross1`**`()`: Returns scalar x-value of `d1` on `n`-th zero-crossing:
  - `xcross1([Event,] d1::DataF1, n=[NCROSSING], tstart=[TSTART], allow::CrossType=[XTYPE])`
 - **`ycross1`**`()`: Returns scalar y-value of `d1` on `n`-th crossing of `d1` & `d2`:
  - `ycross1([Event,] d1::DataF1, n=[NCROSSING], tstart=[TSTART], allow::CrossType=[XTYPE])`
 - **`measdelay`**`(dref::DataF1, dmain::DataF1, nmax=[NMAX], tstart_ref=[TSTART_REF], tstart_main=[TSTART_MAIN], xing1::CrossType=[XTYPE_REF], xing2::CrossType=[XTYPE_MAIN])`
 - **`measperiod`**`(d::DataF1, nmax=[NMAX], tstart=[TSTART], xing::CrossType=[XTYPE], shiftx=[T/F])`
 - **`measfreq`**`(d::DataF1, nmax=[NMAX], tstart=[TSTART], xing::CrossType=[XTYPE], shiftx=[T/F])`

##### The `CrossType` Object

The `CrossType` object is used to filter out undersired events.

 - `sing`: Include singularities (points that cross at a single point).
 - `flat`: Include middle of crossings that are detected at multiple consecutive points.
 - `thru`: Include crossings make it all the way through the crossing point.
 - `rev`: Include crossings that hit the crossing point, then reverse back.
 - `firstlast`: Include first/last crossing points (where all first/last points are @ crossing point).

Constructors:

 - **`CrossType`**: Indicates which crossings are allowed in the result.
  - `CrossType(rise=[T/F], fall=[T/F], sing=[T/F], flat=[T/F], thru=[T/F], rev=[T/F], firstlast=[T/F])`
  - `CrossType(:rise)`: Preset to selecting rising edges
  - `CrossType(:fall)`: Preset to selecting falling edges
  - `CrossType(:risefall)`: Preset to selecting both rising & falling edges

<a name="SampleUsage"></a>
## Sample Usage

Examples of the MDDatasets.jl capabilities can be found under the [test directory](test/).

More advanced usage examples can be found in the [sample directory](https://github.com/ma-laforge/SignalProcessing.jl/tree/master/sample) of the [SignalProcessing.jl module](https://github.com/ma-laforge/SignalProcessing.jl).

<a name="SampleUsage_DataHR"></a>
## Sample Usage: Constructing a Hyper-Rectangular Dataset:

Assuming input data can be generated using the following:

	t = DataF1((0:.01:10)*1e-9) #Time vector stored as a function of 1 argument

	#NOTE: get_ydata returns type "DataF1" (stores data as a function of 1 argument):
	get_ydata(t::DataF1, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd

One can create a relatively complex Hyper-Rectangular (DataHR) dataset using the following pattern:

	#Parametric sweep representing independent variables of an experiment:
	sweeplist = PSweep[
		PSweep("tbit", [1, 3, 9] * 1e-9)
		PSweep("VDD", 0.9 * [0.9, 1, 1.1])
		PSweep("trise_frac", [0.1, 0.15, 0.2]) #Rise time as fraction of bit rate
	]

	#Generate Hyper-Recangular dataset (DataHR, using dimensions from sweeplist)
	datahr = fill(DataHR{DataF1}, sweeplist) do tbit, vdd, trise_frac
		trise = trise_frac*tbit
		return get_ydata(t, tbit, vdd, trise)
	end

<a name="SampleUsage_DataRS"></a>
## Sample Usage: Constructing a Recursive-Sweep Dataset:

Assuming input data can be generated using the following:

	t = DataF1((0:.01:10)*1e-9) #Time vector stored as a function of 1 argument

	#NOTE: get_ydata returns type "DataF1" (stores data as a function of 1 argument):
	get_ydata(t::DataF1, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd

One can create a relatively complex Recursive-Sweep (DataRS) dataset using the following pattern:

	datars = fill(DataRS, PSweep("tbit", [1, 3, 9] * 1e-9)) do tbit
		fill(DataRS, PSweep("VDD", 0.9 * [0.9, 1, 1.1])) do vdd

			#Inner-most sweep: need to specify element type (DataF1):
			fill(DataRS{DataF1}, PSweep("trise", [0.1, 0.15, 0.2] * tbit)) do trise
				return get_ydata(t, tbit, vdd, trise)
			end
		end
	end

## Known Limitations

### Implementation

 1. Support for broadcasting functions over `DataHR` types is fairly extensive.
  - Nonetheless, the system is incomplete/imperfect, and unexpected failures will occur.
 1. Support of `DataRS` vectors is very limited at the moment.
  - Very limited support of function broadcasting.
  - No support in EasyPlot/EasyData.

### Compatibility

Extensive compatibility testing of MDDatasets.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-0.4.2 (64-bit)

## Disclaimer

The MDDatasets.jl module is not yet mature.  Expect significant changes.

This software is provided "as is", with no guarantee of correctness.  Use at own risk.
