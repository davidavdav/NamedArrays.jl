## temporary compatibility hack
if VERSION < v"0.4.0-dev"
    Base.Dict(z::Base.Zip2) = Dict(z.a, z.b)
##    round(::Integer, x::FloatingPoint) = iround(x)
end
