print("matrixops, ")
## this test for typos, mainly, not for correct functioning...

for t in (Float32, Float64)
    a = rand(t, 10, 10)
    b = rand(t, 10, 5)
    c = rand(t, 10, 10)
    apd = a' * a
    asym = a' + a
    luf = lufact(a)
    chf = cholfact(apd)
    qrf = qrfact(a)
    eif = eigfact(a)
    eigvals(a)
    hsf = hessfact(a)
    scf = schurfact(a)
    scf1 = schurfact(a, c)
    svdf = svdfact(a)
    svdvals(a)
    d = diag(a)
    diagm(d)
    cond(a)
    null(a)
    kron(a, a)
    linreg(a[:,1], b[:,1])
    lyap(a, c)
    sylvester(a, c, a)
    isposdef(apd)
end
