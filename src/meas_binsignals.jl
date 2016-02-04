#MDDatasets: Measure binary signals
#-------------------------------------------------------------------------------
#=NOTE:
 - Many functions make use of "cross" functions.
 - Naming assumes x-values are "time".
=#


#==
===============================================================================#

#measdelay: Measure delay between crossing events of two signals:
#-------------------------------------------------------------------------------
function measdelay(dref::DataF1, dmain::DataF1; nmax::Integer=0,
	tstart_ref::Real=-Inf, tstart_main::Real=-Inf,
	xing1::CrossType=CrossType(), xing2::CrossType=CrossType())

	xref = xcross(dref, nmax=nmax, tstart=tstart_ref, allow=xing1)
	xmain = xcross(dmain, nmax=nmax, tstart=tstart_main, allow=xing2)
	npts = min(length(xref), length(xmain))
	delay = xmain.y[1:npts] - xref.y[1:npts]
	x = xref.x[1:npts]
	return DataF1(x, delay)
end
function measdelay(::DS{:event}, dref::DataF1, dmain::DataF1, args...; kwargs...)
	d = measdelay(dref, dmain, args...;kwargs...)
	return DataF1(collect(1:length(d.x)), d.y)
end

#_measperiod: Core algorithm to measure period between successive zero-crossings
#-------------------------------------------------------------------------------
#delaymin: Minimum circuit delay used to align clock & q edges
function _measck2q(xingck::DataF1, xingq::DataF1, delaymin::Real)
	xq = copy(xingq.x) - delaymin
	qlen = length(xq) #Maximum # of q-events
	x = copy(xingq.x) #Allocate space for delay starts
	Δ = copy(xingq.y) #Allocate space for delays
	cklen = length(xingck.x)
	npts = 0
	stop = false


	if qlen < 1 || cklen < 2 #Need to know if q is between 2 ck events
		xt = eltype(xingq.x)
		return DataF1(Vector{xt}(), Vector{xt}())
	end

	iq = 1
	ick = 1
	xqi = xq[iq]
	xcki = xingck.x[ick]
	xcki1 = xingck.x[ick+1]
	while xcki > xqi #Find first q event after first ck event.
		iq += 1
		xqi = xq[iq]
	end

	while iq <= qlen
		xqi = xq[iq]
		#Find clock triggering q event:
		while xcki1 <= xqi
			ick +=1
			if ick < cklen
				xcki = xingck.x[ick]
				xcki1 = xingck.x[ick+1]
			else #Not sure if this xqi corresponds to xcki
				stop = true
				break
			end
		end
		if stop; break; end

		#Compute delay (re-insert removed minimum delay):
		npts += 1
		x[npts] = xcki
		Δ[npts] = xqi - xcki + delaymin

		#Consider next q transition:
		iq += 1
	end

	return DataF1(x[1:npts], Δ[1:npts])
end

#measperiod: Measure period between successive zero-crossings
#-------------------------------------------------------------------------------
#delaymin: Minimum circuit delay used to align clock & q edges
#          Needed when delay is larger than time between ck events.
function measck2q(ck::DataF1, q::DataF1; delaymin::Real=0,
	tstart_ck::Real=-Inf, tstart_q::Real=-Inf,
	xing_ck::CrossType=CrossType(), xing_q::CrossType=CrossType())

	xingck = xcross(ck, tstart=tstart_ck, allow=xing_ck)
	xingq = xcross(q, tstart=tstart_ck, allow=xing_q)
	return _measck2q(xingck, xingq, delaymin)
end

#function measdcd(sref::DataF1; tstart_ref::Real=-Inf)

#Last line
