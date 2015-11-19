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

#Allows one to specify limits of a 1D range
immutable Limits1D{T<:Number}
	min::T
	max::T
end

#Finds all zero crossing indices in a dataset, up to nmax.
#nmax = 0: find all crossings
#TODO: support tstart
#-------------------------------------------------------------------------------
function icross(d::DataF1, nmax::Integer=0)
	validate(d); #Expensive, but might avoid headaches
	y = d.y #shortcut
	ny = length(y)
	if ny < 1; return Limits1D{Int}[]; end
	nmax = nmax<1? ny: min(nmax, ny)
	idx = Vector{Limits1D{Int}}(nmax) #resultant array of indices
	n = 0
	sgnprev = sign(y[1])
	lastzero = 0==sgnprev? 1 :0
	reachedend=true
	for i in 1:ny
		sgncur = sign(y[i])
		if sgncur != sgnprev
			if lastzero > 0
				n+=1
				idx[n] = Limits1D(lastzero, i-1)
				lastzero = 0
			elseif 0==sgncur
				lastzero = i
			else
				n+=1
				idx[n] = Limits1D(i-1, i)
			end
			if n >= nmax; reachedend=false; break; end
			sgnprev = sgncur
		end
	end
	if reachedend && lastzero>0
		n+=1
		idx[n] = Limits1D(lastzero, lastzero)
	end
	if 0==y[1] #Fix first crossing
		v = idx[1].max
		idx[1] = Limits1D(v,v)
	end

	return resize!(idx, n)
end

#icross(d::DataF1, nmax::Integer=0)=0
#TODO: what about infinitiy? convert(Float32,NaN)
#-------------------------------------------------------------------------------
function xveccross{TX<:Number, TY<:Number}(d::DataF1{TX,TY}, nmax::Integer=0)
	idx = icross(d, nmax)
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
function xcross(d::DataF1, nmax::Integer=0)
	x = xveccross(d, nmax)
	return DataF1(x, x)
end
xcross(d1::DataF1, d2, nmax::Integer=0) = xcross(d1-d2, nmax)

#xcross1: return a single crossing point (new name for type stability)
#-------------------------------------------------------------------------------
function xcross1(d::DataF1; n::Integer=1)
	n = max(n, 1)
	x = xveccross(d, n)
	if length(x) < n
		return convert(eltype(x), NaN) #TODO: Will fail with int.  Use NA.
	else
		return x[n]
	end
end
xcross1(d1::DataF1, d2; n::Integer=0) = xcross1(d1-d2, n=n)

#TODO: Make more efficient (don't use "value")
#-------------------------------------------------------------------------------
function ycross{TX<:Number, TY<:Number}(d1::DataF1{TX,TY}, d2, nmax::Integer=0)
	x = xveccross(d1-d2, nmax)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	y = Vector{TR}(length(x))
	for i in 1:length(x)
		y[i] = value(d1, x=x[i])
	end
	return DataF1(x, y)
end

#ycross1: return a single crossing point (new name for type stability)
#-------------------------------------------------------------------------------
function ycross1{TX<:Number, TY<:Number}(d1::DataF1{TX,TY}, d2; n::Integer=1)
	n = max(n, 1)
	x = xveccross(d1-d2, n)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	if length(x) < n
		return convert(TR, NaN) #TODO: Will fail with int.  Use NA.
	else
		return value(d1, x=x[n])
	end
end


#Last line
