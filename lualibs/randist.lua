--package for random numbers from Dodge & Jerse

--return uniform random number between 0 and 1
--(in order to make sure no arguments are supplied)
local fran = math.random

--linear distribution between 0 and 1 [0, 1)
local function xlnear()
	local first = fran()
	local second = fran()
	if second < first then first = second end
	return first
end

--triangular distribution [0, 1)
local function triang()
	local first = fran()
	local second = fran()
	return 0.5*(first + second)
end

--exponential distribution (density: lambda^(-lambda*x))
local function expone(lambda)
	local u
	repeat
		u = fran()
	until u ~= 0.0
	return -math.log(u)/lambda
end

--bilateral exponential function (density:
-- 0.5*lambda*e^(-lambda*abs(x))
local function bilex(lambda)
	local u
	repeat
		u = 2*fran()
	until u ~= 0.0
	if u > 1 then
		u = 2 - u
		return -math.log(u)/lambda
	else
		return math.log(u)/lambda
	end
end

--approximation of gaussian distribution:
-- exp((x - mu)^2/(2*sigma^2))/(sqrt(2*pi)*sigma)
--uses 12 iterations
local function gauss(dev, mean)
	local sum = 0.0
	for _=1, 12 do
		sum = sum + fran()
	end
	return dev*(sum-6) + mean
end

--cauchy distribution:
-- alpha/(pi*(alpha^2 + x^2))
local function cauchy(alpha)
	local u
	repeat
		u = fran()
	until u ~= 0.5
	u = u*math.pi
	return alpha*math.tan(u)
end

--beta distribution:
-- ((x^(a - 1))*((1 - x)^(b - 1)))/beta(a, b) where
--beta is Euler's beta function
local function beta(a, b)
	if a == 0 or b == 0 then
		error("arguments to beta cannot be 0")
		return
	end
	a = 1/a
	b = 1/b
	local sum
	local root
	repeat
		local first
		local second
		repeat
			first = fran()
		until first ~= 0.0
		repeat
			second = fran()
		until second ~= 0.0
		root = math.pow(first, a)
		sum = root + math.pow(second, b)
	until sum <= 1
	return root/sum
end

--weibull distribution:
-- (t*exp((-x/s)^t)*x^(t - 1))/s^t
-- s scales horizontal spread, t controls "sharpness" around s
local function weibull(s, t)
	if t == 0 then error ("weibull: t cannot be 0")
	else t = 1/t end
	local u
	repeat
		u = fran()
	until u ~= 0
	u = 1/(1 - u)
	return s*math.pow(math.log(u), t)
end

--poisson distribution:
-- generates integer distribution: probability of drawing
-- integer j is:
-- (exp(-lambda)*lambda^j)/j!
local function poisson(lambda)
	local n = 0
	local v = math.exp(-lambda)
	local u = fran()
	while u >= v do
		u = u*fran()
		n = n + 1
	end
	return n
end


local randist = {
	fran = fran,
	xlnear = xlnear,
	triang = triang,
	expone = expone,
	bilex = bilex,
	gauss = gauss,
	cauchy = cauchy,
	beta = beta,
	weibull = weibull,
	poisson = poisson,
}

return randist
