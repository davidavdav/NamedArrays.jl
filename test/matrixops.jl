print("matrixops, ")
## this test for typos, mainly, not for correct functioning...

## TODO I am not convinced this does anything related to NamedArrays...

using LinearAlgebra

for t in (Float32, Float64)
    global a = rand(t, 10, 10)
    global b = rand(t, 10, 5)
    global c = rand(t, 10, 10)
    apd = a' * a
    asym = a' + a
    luf = lu(a)
    chf = cholesky(apd, Val(false))
    qrf = qr(a)
    eif = eigen(a)
    eigvals(a)
    hsf = hessenberg(a)
    scf = schur(a)
    scf1 = schur(a, c)
    svdf = svd(a)
    svdvals(a)
    global d = Matrix(Diagonal(a))
    Matrix(Diagonal(d))
    cond(a)
    nullspace(a)
    kron(a, a)
    # linreg(a[:,1], b[:,1])
    lyap(a, c)
    sylvester(a, c, a)
    isposdef(apd)
end
