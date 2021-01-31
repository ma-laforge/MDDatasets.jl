<!-- Reference-style links to make tables & lists more readable -->
[MDDatasetsJL]: <https://github.com/ma-laforge/MDDatasets.jl>
[CMDimDataJL]: <https://github.com/ma-laforge/CMDimData.jl>
[CMDimCircuitsJL]: <https://github.com/ma-laforge/CMDimCircuits.jl>
[CMDimData_sample]: <https://github.com/ma-laforge/CMDimData.jl/tree/master/sample>
[CMDimCircuits_sample]: <https://github.com/ma-laforge/CMDimCircuits.jl/tree/master/sample>


# MDDatasets.jl: Multi-Dimensional Datasets for Parametric Analysis +Continuous <var>f(x)</var>
[![Build Status](https://github.com/ma-laforge/MDDatasets.jl/workflows/CI/badge.svg)](https://github.com/ma-laforge/MDDatasets.jl/actions?query=workflow%3ACI)

## :warning: Base library
`MDDatasets.jl` is a base library to make parametric analysis simple by broadcasting over its multi-dimensional data structures.  For a more useful analysis solution, it is highly recommended to install one of the following "suites":
 - [CMDimData.jl][CMDimDataJL]: Facilitates parametric analysis with continous <var>f(x)</var> interpolation & multi-dimensional plots. Built using [MDDatasets.jl][MDDatasetsJL] module.
 - [CMDimCircuits.jl][CMDimCircuitsJL]: Extends [CMDimData.jl][CMDimDataJL] with circuit-specific functionnality (ex: signal processing, network analysis, ...).

## Table of contents

 1. [Description](#Description)
    1. [Features/Highlights](#Highlights)
 1. [Sample usage](#SampleUsage)
    1. [demo1](doc/demo1.md)
 1. [Core architecture](doc/architecture.md)
    1. [Principal types](doc/architecture.md#PrincipalTypes)
    1. [Functions of 1 argument (`DataF1`) & interpolation](doc/architecture.md#F1Arg)
    1. [Multi-dimensional datasets (`DataRS`) & broadcasting](doc/architecture.md#MDDatasets)
 1. [Supported functions](doc/architecture.md#SupportedFunctions)

<a name="Description"></a>
## Description
The `MDDatasets.jl` package provides tools to simplify manipulation of multi-dimensional datasets, and represent `{x,y}` vectors as a continuous function of 1 argument: `y=f(x)`.

| <img src="https://github.com/ma-laforge/FileRepo/blob/master/SignalProcessing/sampleplots/demo15.png" width="850"> |
| :---: |

<a name="Highlights"></a>
### Features/Highlights
- ***Single variable for (x,y) values:*** Stores both `(x,y)` values representing `y=f(x)` in a single, coherent structure.  This signficantly improves the simplicity & readability of your calculations.
- ***Automatic Interpolation:*** Calculations will automatically be interpolated over `x` as if `y=f(x)` data represented a ***continuous*** function of x.
- ***Automatic Broadcasting:*** Operations on multi-dimensional datasets will automatically be broadcasted (vectorized) over all subsets.  This significantly improves the readability of programs.

<a name="SampleUsage"></a>
## Sample usage
Examples of how to use `MDDatasets` are provided in the [sample/](sample) subdirectory.

Hilights:
 - [demo1](doc/demo1.md)

Other examples of its capabilities can be found under the [test directory](test/).

More advanced usage examples can be found in the sample directories of [`CMDimData.jl`][CMDimData_sample] and [`CMDimCircuits.jl`][CMDimCircuits_sample] modules.

<a name="SampleUsage_DataRS"></a>
## Usage: Constructing a recursive-sweep dataset

Assuming input data can be generated using the following:

	t = DataF1((0:.01:10)*1e-9) #Time vector stored as a function of 1 argument

	#NOTE: get_ydata returns type "DataF1" (stores data as a function of 1 argument):
	get_ydata(t::DataF1, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd

One can create a relatively complex Recursive-Sweep (DataRS) dataset using the following pattern:

	datars = fill(DataRS, PSweep("tbit", [1, 3, 9] * 1e-9)) do tbit
		fill(DataRS, PSweep("VDD", 0.9 * [0.9, 1, 1.1])) do vdd

			#Inner-most sweep: need to specify element type (DataF1):
			#(Other (scalar) element types: DataInt/DataFloat/DataComplex)
			fill(DataRS{DataF1}, PSweep("trise", [0.1, 0.15, 0.2] * tbit)) do trise
				return get_ydata(t, tbit, vdd, trise)
			end
		end
	end

<a name="KnownLimitations"></a>
## Known limitations

### [TODO](TODO.md)

 1. Support for broadcasting functions over `DataHR` & `DataRS` types is fairly extensive.
    - Nonetheless, the system is incomplete/imperfect, and unexpected failures will occur.

### Compatibility

Extensive compatibility testing of `MDDatasets.jl` has not been performed.  The module has been tested using the following environment(s):

 - Windows 10 / Linux / Julia-1.5.3

## Disclaimer

The `MDDatasets.jl` module is not yet mature.  Expect significant changes.
