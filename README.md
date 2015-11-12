# MDDatasets.jl: Multi-Dimensional Datasets

## Description

The MDDatasets.jl module provides tools to simplify manipulation of multi-dimensional datasets.

### Principal Types

 - **DataMD**: Abastract data type for multi-dimensional data.
 - **DataInt, DataFloat, DataComplex**: Useful aliases for largest practical data types on a platform (not yet platform dependent).
 - **DataF1**: Represens a function of 1 variable, y(x) using a x/y vector pair.
 - **DataHR{DataF1/DataInt/DataFloat/DataComplex}**: A hyper-rectangle (as opposed to hyper-cube) organizaton of data.  Principally designed to collect massive datasets with independent control variables ([see examples](#SampleUsage)).
 - **DataAP{DataF1/...}**: (Not yet implemeted) Each subset of data corresponds to an arbitrary collection of test conditions.

<a name="SampleUsage"></a>
## Sample Usage

Examples of the MDDatasets.jl capabilities can be found under the [test directory](test/).

More advanced usage examples can be found in the [sample directory](https://github.com/ma-laforge/SignalProcessing.jl/tree/master/sample) of the [SignalProcessing.jl module](https://github.com/ma-laforge/SignalProcessing.jl).

## Known Limitations

### Compatibility

Extensive compatibility testing of MDDatasets.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-0.4.0

## Disclaimer

The MDDatasets.jl module is not yet mature.  Expect significant changes.

This software is provided "as is", with no guarantee of correctness.  Use at own risk.
