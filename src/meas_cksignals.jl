#MDDatasets: Measure clock signals
#-------------------------------------------------------------------------------
#=NOTE:
 - Many functions make use of "cross" functions.
 - Naming assumes x-values are "time".
=#


#==
===============================================================================#

#measperiod: Measure period between successive zero-crossings:
#-------------------------------------------------------------------------------
function measperiod(d::DataF1; nmax::Integer=0, tstart::Real=-Inf,
	xing::CrossType=CrossType(), shiftx=true)

	dx = xcross(d, nmax=nmax, tstart=tstart, allow=xing)
	return deltax(dx, shiftx=shiftx)
end

#measfreq: Measure 1/period between successive zero-crossings:
#-------------------------------------------------------------------------------
function measfreq(d::DataF1; nmax::Integer=0, tstart::Real=-Inf,
	xing::CrossType=CrossType(), shiftx=true)

	T = measperiod(d, nmax=nmax, tstart=tstart, xing=xing, shiftx=shiftx)
	return DataF1(T.x, 1./T.y)
end

#Last line
