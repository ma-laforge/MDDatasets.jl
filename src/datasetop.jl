#MDDatasets: Dataset operations
#TODO: optimize operations so they run faster
#TODO: assert length(v)>1?
#TODO: add xaty?
#-------------------------------------------------------------------------------

#Element-by-element difference of y-values:
#(shift x-values @ mean position)
#-------------------------------------------------------------------------------
function deltax(d::DataF1; shiftx=true)
	x = shiftx? meanadj(d.x): d.x[1:end-1]
	return DataF1(x, delta(d.y))
end

#Obtain a dataset of the x-values
#-------------------------------------------------------------------------------
xval(d::DataF1) = DataF1(d.x, copy(d.x))

#Shifts x-values of a dataset by +/-offset:
#-------------------------------------------------------------------------------
function xshift(d::DataF1, offset::Number)
	return DataF1(d.x.+offset, copy(d.y))
end
#xshift(d::DataHR, offset::Number) = apply(d, offset)

#Scales x-values of a dataset by fact:
#-------------------------------------------------------------------------------
function xscale(d::DataF1, fact::Number)
	return DataF1(d.x.*fact, copy(d.y))
end

#-------------------------------------------------------------------------------
function yvsx(y::DataF1, x::DataF1)
	_x = x+0*y
	_y = y+0*x
	@assert(_x.x==_y.x, "xvsy algorithm error: not generating unique x-vector.")
	return DataF1(_x.y, _y.y)
end

#-------------------------------------------------------------------------------
function deriv(d::DataF1; shiftx=true)
	x = shiftx? meanadj(d.x): d.x[1:end-1]
	return DataF1(x, delta(d.y)./delta(d.x))
end

#Indefinite integral:
#-------------------------------------------------------------------------------
function iinteg(d::DataF1)
	#meanadj ≜ (vi+(vi+1))/2
	area = meanadj(d.y).*delta(d.x)
	return DataF1(d.x, vcat(zero(d.y[]), cumsum(area)))
end

#Definite integral:
#TODO: add start/stop?
#-------------------------------------------------------------------------------
function integ(d::DataF1)
	#meanadj ≜ (vi+(vi+1))/2
	area = meanadj(d.y).*delta(d.x)
	return sum(area)
end


#==Sampling algorithm
===============================================================================#

#-------------------------------------------------------------------------------
function sampledisjoint(d::DataF1, x::Range)
	@assert(false, "Currently no support for disjoint sampling")
end

#-------------------------------------------------------------------------------
function sample{TX<:Number, TY<:Number}(d::DataF1{TX,TY}, x::Range)
	validate(d); assertincreasingx(x); #Expensive, but might avoid headaches
	#TODO: deal with empty d
	if length(x) < 1
		return DataF1(zeros(eltype(x),0), zeros(eltype(d.y),0))
	end
	n = length(x)
	y = Vector{TY}(n)
	x = collect(x) #Need it in this form anyways
	dx = d.x #shortcut
	_dx = dx[1]; dx_ = dx[end]
	_x = x[1]; x_ = x[end]
	_xint = max(_dx, _x) #First intersecting point
	xint_ = min(dx_, x_) #Last intersecting point

	if _x > dx_ || _dx > x_
		return applydisjoint(fn, d1, d2)
	end

	i = 1 #index into x/y arrays
	id = 1 #index into dx
	while x[i] < _xint
		y[i] = zero(TY)
		i += 1; #x[i] < _xint and set not disjoint: safe to increment i
	end
	p = pnext = Point2D(d, id)
	while x[i] < xint_ #Intersecting section of x
		while pnext.x <= x[i]
			id += 1 #x[i] < _xint: safe to increment id
			p = pnext; pnext = Point2D(d, id)
		end
		y[i] = interpolate(p, pnext, x=x[i])
		i+=1
	end
	#End of intersecting section (x[i]==xint_):
		while pnext.x < x[i]
			id += 1 #x[i] == xint_ && pnext.x < x[i]: safe to increment id
			p = pnext; pnext = Point2D(d, id)
		end
		y[i] = interpolate(p, pnext, x=x[i])
	while i < n #Get remaining points
		i += 1
		y[i] = zero(TY)
	end
	return DataF1(x,y)
end


#==Crossing algorithm
===============================================================================#

#Constants used to filter out undesired crossings:
#-------------------------------------------------------------------------------
#RISE & FALL are mutually exclusive (but user can want both):
const XINGTYPE_RISE = UInt(0x1)
const XINGTYPE_FALL = UInt(0x2)
#const XINGTYPE_DIRMASK = UInt(0x3)
#FLAT & SING are mutually excluive (but user can want both):
const XINGTYPE_SING = UInt(0x4) #Does not cross @ single point
const XINGTYPE_FLAT = UInt(0x8) #Does not cross @ single point
#THRU & REV are mutually exclusive (but user can want both):
const XINGTYPE_THRU = UInt(0x10) #Goes through
const XINGTYPE_REV = UInt(0x20) #Reverses out.  Does not fully cross
const XINGTYPE_FIRSTLAST = UInt(0x40) #First/last point leaving/entering zero state

const XINGTYPE_ALL =
	XINGTYPE_RISE|XINGTYPE_FALL |
	XINGTYPE_SING|XINGTYPE_FLAT |
	XINGTYPE_THRU|XINGTYPE_REV|XINGTYPE_FIRSTLAST

immutable CrossType
	v::UInt
end

function CrossType(;rise=true, fall=true, sing=true, flat=true, thru=true, rev=false, firstlast=false)
	result = rise*XINGTYPE_RISE | fall*XINGTYPE_FALL |
	         sing*XINGTYPE_SING | flat*XINGTYPE_FLAT |
	         thru*XINGTYPE_THRU | rev*XINGTYPE_REV | firstlast*XINGTYPE_FIRSTLAST
	return CrossType(result)
end

function CrossType(id::Symbol)
	if :all == id
		return CrossType(rise=true, fall=true, sing=true, flat=true, thru=true, rev=true, firstlast=true)
	elseif :default == id
		return CrossType()
	elseif :rise == id
		return CrossType(rise=true, fall=false)
	elseif :fall == id
		return CrossType(rise=false, fall=true)
	else
		throw("Unknown crossing-type preset: $id")
	end
end

#Finds all zero crossing indices in a dataset, up to nmax.
#nmax = 0: find all crossings
#TODO: support xstart
#-------------------------------------------------------------------------------
function icross(d::DataF1, nmax::Integer, xstart::Real, allow::CrossType)
	#TODO: make into function if can force inline
	#(SGNTOXINGDIR >> (1+Int(sgncur)))&0x3 returns the type of xing:
	const SGNTOXINGDIR = XINGTYPE_FALL|XINGTYPE_RISE<<2
	const EMPTYRESULT = Limits1D{Int}[]
	allow = allow.v #Get value

	validate(d); #Expensive, but might avoid headaches
	x = d.x; y = d.y #shortcuts
	ny = length(y)
	if ny < 1; return EMPTYRESULT; end
	xstart = max(x[1], xstart) #Simplify algorithm below
	if xstart > x[end]; return EMPTYRESULT; end
	nmax = nmax<1? ny: min(nmax, ny)
	idx = Vector{Limits1D{Int}}(nmax) #resultant array of indices
	n = 0 #Index into idx[]
	i = 1 #Index into x/y[]
	while x[i] < xstart #Fast-forward to start point
		i+=1
	end
	#Here: x[i] >= xstart

	if x[i] > xstart
		i -= 1 #ok: xstart = max(x[1], xstart)
	end
	istart = i
	ystart = value(d, x=xstart) #TODO: direct interp, instead of using value()
	sgncur = sign(ystart)
	lastnzpos = 0; #Pretend like this is the start of the data
	if (sgncur != 0); lastnzpos = i; end

	#Move up to first non-zero value... if not already done:
	while lastnzpos < 1 && i < ny
		i+=1
		sgncur = sign(y[i])
		if (sgncur != 0); lastnzpos = i; end
	end
	if lastnzpos < 1; return EMPTYRESULT; end
	#Here: y[i] @ first nonzero value since xstart

	#Register first crossing if all initial values were zeros since xstart:
	if 0 == ystart
		xingdir = (SGNTOXINGDIR >> (1+Int(sgncur)))&0x3
		xingtype = XINGTYPE_FIRSTLAST
		xingtype |= xingdir

		if allow & xingtype == xingtype
			needsinterp = (1==lastnzpos-istart && y[istart] != 0)
			n+=1
			if needsinterp
				idx[n] = Limits1D(istart, istart+1)
			else
				idx[n] = Limits1D(lastnzpos-1, lastnzpos-1)
			end
		end
	end

	sgnenter=sgncur #Not really needed; mostly a declaration
	posfirstzero = 0 #No longer reading a zero sequence
	sgnprev = sgncur
	while i < ny
		i+=1
		sgncur = sign(y[i])
		if sgncur != sgnprev
			xingdir = (SGNTOXINGDIR >> (1+Int(sgncur)))&0x3
			if posfirstzero > 0
				xingtype = (posfirstzero == i-1? XINGTYPE_SING: XINGTYPE_FLAT)
				xingtype |= (0 == sgnenter+sgncur? XINGTYPE_THRU: XINGTYPE_REV)
				xingtype |= xingdir
				if allow & xingtype == xingtype
					n+=1
					idx[n] = Limits1D(posfirstzero, i-1)
				end
				posfirstzero = 0
			elseif 0==sgncur
				sgnenter=sgnprev
				posfirstzero = i
			else
				xingtype = XINGTYPE_THRU|XINGTYPE_SING
				xingtype |= (SGNTOXINGDIR >> (1+Int(sgncur)))&0x3
				xingtype |= xingdir
				if allow & xingtype == xingtype
					n+=1
					idx[n] = Limits1D(i-1, i)
				end
			end
			if n >= nmax; break; end
			sgnprev = sgncur
		end
	end

	reachedend = (i >= ny)
	if reachedend && posfirstzero>0
		xingdir = (SGNTOXINGDIR >> (1-Int(sgnenter)))&0x3
		xingtype = XINGTYPE_FIRSTLAST
		xingtype |= xingdir
		if allow & xingtype == xingtype
			n+=1
			idx[n] = Limits1D(posfirstzero, posfirstzero)
		end
	end

	return resize!(idx, n)
end

#TODO: what about infinitiy? convert(Float32,NaN)
#-------------------------------------------------------------------------------
function xveccross{TX<:Number, TY<:Number}(d::DataF1{TX,TY}, nmax::Integer,
	tstart::Real, allow::CrossType)
	idx = icross(d, nmax, tstart, allow)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	result = Vector{TR}(length(idx))
	for i in 1:length(idx)
		rng = idx[i]
		x1 = d.x[rng.min]; y1 = d.y[rng.min]
		if zero(TY) == y1
			result[i] = (d.x[rng.max] + x1)/2
		else
			Δy = d.y[rng.max] - y1
			Δx = d.x[rng.max] - x1
			result[i] = (0-y1)*(Δx/Δy)+x1
		end
	end
	return result
end

#-------------------------------------------------------------------------------
function xcross(d::DataF1, nmax::Integer=0; tstart::Real=0,
	allow::CrossType=CrossType())
	x = xveccross(d, nmax, tstart, allow)
	return DataF1(x, x)
end
xcross(d1::DataF1, d2, nmax::Integer=0; tstart::Real=0,
	allow::CrossType=CrossType()) =
	xcross(d1-d2, nmax, tstart=tstart, allow=allow)

#xcross1: return a single crossing point (new name for type stability)
#-------------------------------------------------------------------------------
function xcross1(d::DataF1; n::Integer=1, tstart::Real=0,
	allow::CrossType=CrossType())
	n = max(n, 1)
	x = xveccross(d, n, tstart, allow)
	if length(x) < n
		return convert(eltype(x), NaN) #TODO: Will fail with int.  Use NA.
	else
		return x[n]
	end
end
xcross1(d1::DataF1, d2; n::Integer=1, tstart::Real=0,
	allow::CrossType=CrossType()) =
	xcross1(d1-d2, n=n, tstart=tstart, allow=allow)

#TODO: Make more efficient (don't use "value")
#-------------------------------------------------------------------------------
function ycross{TX<:Number, TY<:Number}(d1::DataF1{TX,TY}, d2, nmax::Integer=0;
	tstart::Real=0, allow::CrossType=CrossType())
	x = xveccross(d1-d2, nmax, tstart, allow)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	y = Vector{TR}(length(x))
	for i in 1:length(x)
		y[i] = value(d1, x=x[i])
	end
	return DataF1(x, y)
end

#ycross1: return a single crossing point (new name for type stability)
#-------------------------------------------------------------------------------
function ycross1{TX<:Number, TY<:Number}(d1::DataF1{TX,TY}, d2; n::Integer=1,
	tstart::Real=0, allow::CrossType=CrossType())
	n = max(n, 1)
	x = xveccross(d1-d2, n, tstart, allow)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	if length(x) < n
		return convert(TR, NaN) #TODO: Will fail with int.  Use NA.
	else
		return value(d1, x=x[n])
	end
end


#Last line
