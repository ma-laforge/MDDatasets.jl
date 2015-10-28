# MDDatasets.jl: Multi-Dimensional Datasets

## Description

The MDDatasets.jl module provides tools to simplify manipulation of multi-dimensional datasets.

### Principal Types

 - **DataMD**: Abastract data type for multi-dimensional data.
 - **Data2D**: A 2D x/y vector of data.
 - **DataHR=DataHyperRect{Data2D}**: A hyper-rectangle (as opposed to hyper-cube) organizaton of data.  
 - **DataAP=DataArbitraryPoints{Data2D}**: (Not yet implemeted) Each subset of data corresponds to an arbitrary collection of test conditions.

### Compatibility

Extensive compatibility testing of MDDatasets.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-0.4.0

## Disclaimer

The MDDatasets.jl module is not yet mature.  Expect significant changes.

This software is provided "as is", with no guarantee of correctness.  Use at own risk.
