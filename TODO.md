# Deprecate DataHR in favour of DataRS

# Verify that functions for DataHR has an equivalent in DataRS
Implement `getsubarray`

# Move definitions in physics.jl to another module
Probably CDimData.jl

# Move circuit-like functions to another module
 - measperiod, measfreq, measdelay (mabe keep this one), measck2q

# Deprecate ensure-do syntax?
 - Probably better just to use an if statement.
 - ensure(cond, err) is nice because it looks cleaner as a one-liner.

# Create docstrings
Create docs with Documenter.jl?
