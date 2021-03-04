using Test, MDDatasets


#==Logging functions
===============================================================================#
function printheader(title)
	println("\n", title, "\n", repeat("=", 80))
end

function show_testset_section()
	println()
	@info "SECTION: " * Test.get_testset().description * "\n" * repeat("=", 80)
end

function show_testset_description()
	@info "Testing: " * Test.get_testset().description
end


#==Test functions
===============================================================================#
_isdeltazero(Δ::Number; abstol=0) = (Δ<=abstol)
_isdeltazero(Δ::Array; abstol=0) = _isdeltazero(maximum(Δ), abstol=abstol)
_isdeltazero(Δ::DataMD; abstol=0) = _isdeltazero(maximum(Δ), abstol=abstol)
_datamatch(d1::Array, d2::Array; abstol=0) where {T1<:DataMD, T2<:DataMD} = false #Type mismatch
_datamatch(d1::Array{T}, d2::Array{T}; abstol=0) where {T<:Number} = _isdeltazero(abs.(d1 .- d2))
_datamatch(d1::T1, d2::T2; abstol=0) where {T1<:DataMD, T2<:DataMD} = false #Type mismatch
_datamatch(d1::T, d2::T; abstol=0) where T<:DataMD = _isdeltazero(abs(d1-d2))


#==Run tests
===============================================================================#
testfiles = ["dataf1.jl", "datahr.jl", "datars.jl"]

for testfile in testfiles
	include(testfile)
end

:Test_Complete
