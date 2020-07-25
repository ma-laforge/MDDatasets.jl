# MDDatasets.jl: Multi-Dimensional Datasets
## [:heavy_exclamation_mark: Core of C-Data Analysis/Visualization Suite](https://github.com/ma-laforge/CData.jl)

[![Build Status](https://travis-ci.org/ma-laforge/MDDatasets.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/MDDatasets.jl)

## Description

The MDDatasets.jl module provides tools to simplify manipulation of multi-dimensional datasets.  MDDatasets.jl implements the core algorithms of the [C-Data Analysis/Visualization Suite](https://github.com/ma-laforge/CData.jl)

| <img src="https://github.com/ma-laforge/FileRepo/blob/master/SignalProcessing/sampleplots/demo15.png" width="850"> |
| :---: |

### Important Features
- ***Single variable for (x,y) values:*** Stores both `(x,y)` values representing `y=f(x)` in a single, coherent structure.  This signficantly improves the simplicity & readability of your calculations.
- ***Automatic Interpolation:*** Calculations will automatically be interpolated over `x` as if `y=f(x)` data represented a ***continuous*** function of x.
- ***Automatic Broadcasting:*** Operations on multi-dimensional datasets will automatically be broadcasted (vectorized) over all subsets.  This significantly improves the readability of programs.

## Table of Contents

 1. [Sample Usage](#SampleUsage)
    1. [demo1](doc/demo1.md)
 1. [Core Architecture](doc/architecture.md)
    1. [Principal Types](doc/architecture.md#PrincipalTypes)
    1. [Functions Of 1 Argument (`DataF1`) & Interpolation](doc/architecture.md#F1Arg)
    1. [Multi-Dimensional Datasets (`DataRS`) & Broadcasting](doc/architecture.md#MDDatasets)
 1. [Supported Functions](doc/architecture.md#SupportedFunctions)

<a name="SampleUsage"></a>
## Sample Usage

 - [demo1](doc/demo1.md)

Other examples of the MDDatasets.jl capabilities can be found under the [test directory](test/).

More advanced usage examples can be found in the [sample directory](https://github.com/ma-laforge/SignalProcessing.jl/tree/master/sample) of the [SignalProcessing.jl module](https://github.com/ma-laforge/SignalProcessing.jl).

<a name="SampleUsage_DataRS"></a>
## Usage: Constructing A Recursive-Sweep Dataset

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
## Known Limitations

 1. Support for broadcasting functions over `DataHR` & `DataRS` types is fairly extensive.
    - Nonetheless, the system is incomplete/imperfect, and unexpected failures will occur.

### [TODO](TODO.md)

### Compatibility

Extensive compatibility testing of MDDatasets.jl has not been performed.  The module has been tested using the following environment(s):

- Linux / Julia-1.3.1 (64-bit)

## Disclaimer

The MDDatasets.jl module is not yet mature.  Expect significant changes.
