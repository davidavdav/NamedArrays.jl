n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)
setnames!(n, ["a", "b", "c", "d"], 2)

v = NamedArray(rand(1:100, 6), (["a", "b", "c", "d", "e", "f"],), (:index,))

m = NamedArray(rand(2,3,4,3,2,3))
