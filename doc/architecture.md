# MDDatasets.jl: Core architecture

<a name="PrincipalTypes"></a>
## Principal types

- **`DataInt, DataFloat, DataComplex`**: Useful aliases for largest practical data types on a platform (not yet platform dependent).
- **`DataMD`**: Abastract data type for multi-dimensional data.
- **`DataF1`**: Represents a function of 1 variable, y(x) using a x/y vector pair.
- **`DataHR{DataF1/DataInt/DataFloat/DataComplex}`**: ***DO NOT USE*** A hyper-rectangular organizaton of data.  Principally designed to collect massive datasets with *independent* control variables ([see examples](DataHR.md#SampleUsage_DataHR)).
- **`DataRS{DataF1/DataInt/DataFloat/DataComplex}`**: A recursive-sweep organization of data.  Principally designed to collect massive datasets with *dependent* control variables([see examples](#SampleUsage_DataRS)).
- **`PSweep`**: A parameter sweep (i.e. an independent control variable that generates experimental points in a `DataRS/DataHR` dataset).

<a name="F1Arg"></a>
## Functions of 1 argument (`DataF1`) & interpolation

Type `DataF1` is used to represent *continuous* functions of 1 argument (`y = f(x)`).  `DataF1` stores samples of said functions in its `x` & `y` vectors.

Operations performed on two `DataF1` objects will result in the interpolation of the corresponding `{x, y}` coordinates.  Furthermore, operations beyond the x-range of a `DataF1` object "extrapolate" to 0.

By grouping `x` & `y` vectors together, `DataF1` objects can also lead to simpler/less error-prone interfaces:

	PlottingModule.plot(x, y, ...)

gets simplified to:

	PlottingModule.plot(data, ...)

NOTE: When dealing with complex algorithms, this simplification is rearkably quite significant.

<a name="MDDatasets"></a>
## Multi-dimensional datasets (`DataRS`) & broadcasting

In order to identify trends, or simply to verify the repeatability of a process, one often needs to perform the same operation on multiple "experiments".  This module provides the `DataRS` type to store/organize/access experiment data in a convenient fashion.

As a side-note, `DataRS` collects simpler data elements (like `DataF1` or simple scalar values) into a recursive data structure.  Each `DataRS` element is used to store the results on an "experiment" (or collection of experiments) where a control variable was varied (swept).  Due to the recursive nature of `DataRS`, each "sweep" can potentially represent a control variable that is *dependent* on a previous "sweep".

### Broadcast features

Operations performed on multi-dimensional data sets (`DataRS`) will automatically be broadcast to each element of the dataset ([see Known limitations](#KnownLimitations)).

Explicit looping over `DataRS` structures is therefore typically not required.  Many algorithms can be used unmodified, even after changing the set of experimental points.

By default, reducing functions (like `maximum`, `minimum`, or `mean(::Vector) => Scalar`) will operate on `DataRS` structures by collapsing the inner-most dimension:

	#Assuming sig -> DataRS{sweeps={supply, temp, ctrlVoltage}} of DataF1{x=time}
	freqVctrl = mean(measfreq(sig)) #DataRS{sweeps={supply, temp, ctrlVoltage}}
	maxfVtemp = maximum(freqVctrl) #DataRS{sweeps={supply, temp}}
	maxfVsupply = maximum(maxfVtemp) #DataRS{sweeps={supply}}

As can be inferred from above, the sweep from the inner-most dimension can be thought as the x-coordinate of the data.  That is because subsequent operations will be applied along that dimension.

TODO: Provide a means to re-order dimensions.

<a name="SupportedFunctions"></a>
# Supported functions

## Constructors
 - **`fill`**`()`: Create a DataHR or DataRS structure (see examples for use).

## Helper functions

 - **`ensure`**`(cond, err)`: Similar to assert, but will never compile out (not just for debugging).
   - ex: `ensure(i != 0, SystemError("Some system error"))`

## Imported From `Base`

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

   - `+, -, *, /, ^,`
<br>`max, min,`
<br>`atan, hypot,`
<br>`maximum, minimum,`
<br>`prod, sum,`
<br>`mean, median, middle,`

## Accessor functions
 - **`sweep`**`()`: Access values from a particular parameter sweep (`DataHR` only).
  - `sweep(d::DataHR, dim::Int)`
  - `sweep(d::DataHR, dim::String)`: Access by sweep name
 - **`sweeps`**`(::DataHR)`: Get the list of parameter sweeps in DataHR (`DataHR` only).
 - **`Base.ndims`**`(d::DataHR)`: Return number of dimensions (parametric sweeps).
 - **`dimension`**`(d::DataHR, id::String)`: Returns the dimension corresponding to the given parameter name.
 - **`getsubarray`**`(::DataHR)`: Explain (`DataHR` only).
 - **`coordinates`**`(d::DataHR, subscr::Tuple)`: Get parameter sweep coordinates corresponding to given subscripts (`DataHR` only).
 - **`paramlist`**`(d::DataRS/DataHR)`: Return a list of parameter values being swept.
 - **`parameter`**`(d::DataRS/DataHR, sweepid::String)`: Get parameter values for a particular sweep.

## Differential/Integral math

 - **`deriv`**`(d::DataMD, shiftx=[Bool])`: Returns dataset with derivative of `d`
 - **`integ`**`(d::DataMD, shiftx=[Bool])`: Returns definite integral of `d`
 - **`iinteg`**`(d::DataMD, shiftx=[Bool])`: Returns dataset with indefinite integral of `d`

## Basic dataset operations
 - **`xval`**`(::DataMD)`: Returns a dataset with where y(x) = x.
 - **`xmin`**`(::DataMD)`: Returns minimum x value.
 - **`xmax`**`(::DataMD)`: Returns maximum x value.
 - **`value`**`(y::DataMD, x=[Real])`: Returns `y(x)`
   - High-collision WARNING: other modules probably want to export "value".
 - **`clip`**`()`: Returns a dataset clipped within an x-range
   - `clip(::DataMD, xrng::Range)`
   - `clip(::DataMD, xmin=[Real], xmax=[Real])`
	- TODO: xclip vs clip??
 - **`sanitize`**`(x, min=nothing, max=nothing, nan=nothing)`: Clamp down infinite values & substitute NaNs with value of `nan`.
   - TODO: test & rename clip???.
 - **`sample`**`(::DataMD, xrng::Range)`: Returns dataset sampled @ each point in `xrng`
 - **`delta`**`(::DataMD; shiftx=true)`: Element-by-element difference of y-values (optionally: shift x-values @ mean position).
 - **`xshift`**`(::DataMD, offset::Number)`: Returns dataset with all x-values shifted by `offset` (negative values "shift left")
 - **`xscale`**`(::DataMD, fact::Number)`: Returns dataset with all x-values scaled by `fact`
 - **`yvsx`**`(yv::DataMD, xv::DataMD)`: Returns dataset with `{xv(x), yv(x)}` (interpolating, when necessary)

## Cross-based operations

Note: The `Event` object makes functions return x-vectors that represent the current event number.

 - **`xcross`**`()`: Returns x-values of `d1` (up-to `nmax`) when `d1` crosses 0 (`nmax`=0: get all crossings):
   - `xcross([Event,] d1::DataF1, [nmax::Int,] xstart=[Real], allow=[CrossType])`
 - **`ycross`**`()`: Returns y-values of `d2` (up-to `nmax`) when `d1` crosses `d2` (`nmax`=0: get all crossings):
   - `ycross([Event,] d1::DataF1, d2::DataF1, [nmax::Int,] xstart=[Real], allow=[CrossType])`
 - **`xcross1`**`()`: Returns scalar x-value of `d1` on `n`-th zero-crossing:
   - `xcross1([Event,] d1::DataF1, n=[Int], xstart=[Real], allow=[CrossType])`
 - **`ycross1`**`()`: Returns scalar y-value of `d1` on `n`-th crossing of `d1` & `d2`:
   - `ycross1([Event,] d1::DataF1, n=[Int], xstart=[Real], allow=[CrossType])`

### Operations on clock signals
 - **`measperiod`**`(d::DataF1, nmax=[Int], tstart=[Real], xing=[CrossType], shiftx=[Bool])`
 - **`measfreq`**`(d::DataF1, nmax=[Int], tstart=[Real], xing=[CrossType], shiftx=[Bool])`

### Operations on binary signals
 - **`measdelay`**`(dref::DataF1, dmain::DataF1, nmax=[Int], tstart_ref=[Real], tstart_main=[Real], xing_ref=[CrossType], xing_main=[CrossType])`
 - **`measck2q`**`(ck::DataF1, q::DataF1, delaymin=[Real], tstart_ck=[Real], tstart_q=[Real], xing_ck=[CrossType], xing_q=[CrossType])`

### The `CrossType` object

The `CrossType` object is used to filter out undersired events.

 - `sing`: Include singularities (points that cross at a single point).
 - `flat`: Include middle of crossings that are detected at multiple consecutive points.
 - `thru`: Include crossings make it all the way through the crossing point.
 - `rev`: Include crossings that hit the crossing point, then reverse back.
 - `firstlast`: Include first/last crossing points (when data starts or ends @ crossing point itself).

Constructors:

 - **`CrossType`**: Indicates which crossings are allowed in the result.
   - `CrossType(rise=[Bool], fall=[Bool], sing=[Bool], flat=[Bool], thru=[Bool], rev=[Bool], firstlast=[Bool])`
   - `CrossType(:rise)`: Preset to selecting rising edges
   - `CrossType(:fall)`: Preset to selecting falling edges
   - `CrossType(:risefall)`: Preset to selecting both rising & falling edges

<a name="KnownLimitations"></a>
# Known limitations

 1. Support for broadcasting functions over `DataHR` & `DataRS` types is fairly extensive.
    - Nonetheless, the system is incomplete/imperfect, and unexpected failures will occur.

