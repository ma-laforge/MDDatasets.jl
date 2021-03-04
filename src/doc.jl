#EasyPlot: docstring definitions
#-------------------------------------------------------------------------------

#==
===============================================================================#

@doc """`fill(fn::Function d::DataRS, sweeplist)`

Construct a DataRS structure storing results from parametric sweeps using recursive data structures.

# Examples
```julia-repl
signal = fill(DataRS, PSweep("A", [1, 2, 4] .* 1e-3)) do A
    fill(DataRS, PSweep("phi", [0, 0.5, 1] .* (π/4))) do 𝜙
    fill(DataRS{DataF1}, PSweep("freq", [1, 4, 16] .* 1e3)) do 𝑓
       𝜔 = 2π*𝑓; T = 1/𝑓
       Δt = T/100 #Define resolution from # of samples per period
       Tsim = 4T #Simulated time
       t = DataF1(0:Δt:Tsim) #DataF1 creates a t:{y, x} container with y == x
       sig = A * sin(𝜔*t + 𝜙) #Still a DataF1 sig:{y, x=t} container
       return sig
end; end; end
```

Note that inner-most sweep needs to specify element type (DataF1).
Other (scalar) element types include: DataInt/DataFloat/DataComplex.
""" Base.fill(::Function, ::Type{DataRS}, args...)

@doc """`fill(value, [DataRS/DataF1], sweeplist)`

Construct a filled DataRS or DataHR structure with the provided list of parametric sweeps.

# Examples
```julia-repl
sweeplist = PSweep[
	PSweep("A", [1, 2, 4])
	PSweep("freq", [1, 2, 4, 8, 16] .* 1e3)
	PSweep("phi", π .* [1/4, 1/3, 1/2])
]

all32s = fill(32.0, DataRS, sweeplist)
```
""" Base.fill(::DF1_Num, ::Type{DataMD}, args...)

@doc """`zeros([DataRS/DataF1], sweeplist)`

Construct a 0.0-filled DataRS or DataHR structure with the provided list of parametric sweeps.

# Examples
```julia-repl
sweeplist = PSweep[
	PSweep("A", [1, 2, 4])
	PSweep("freq", [1, 2, 4, 8, 16] .* 1e3)
	PSweep("phi", π .* [1/4, 1/3, 1/2])
]

all0s = zeros(DataRS, sweeplist)
```
""" Base.zeros(::Type{DataMD}, args...)

@doc """`ones([DataRS/DataF1], sweeplist)`

Construct a 1.0-filled DataRS or DataHR structure with the provided list of parametric sweeps.

# Examples
```julia-repl
sweeplist = PSweep[
	PSweep("A", [1, 2, 4])
	PSweep("freq", [1, 2, 4, 8, 16] .* 1e3)
	PSweep("phi", π .* [1/4, 1/3, 1/2])
]

all1s = ones(DataRS, sweeplist)
```
""" Base.ones(::Type{DataMD}, args...)

#Last line
