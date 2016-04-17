## temporary compatibility hack
if VERSION < v"0.4.0-dev"
    Base.Dict(z::Base.Zip2) = Dict(z.a, z.b)
    typealias AbstractTriangular Triangular
elseif VERSION < v"0.5.0-dev"
    import Base.LinAlg.AbstractTriangular
    displaysize(io::IO) = Base.tty_size()
end
