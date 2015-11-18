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

#Last line
