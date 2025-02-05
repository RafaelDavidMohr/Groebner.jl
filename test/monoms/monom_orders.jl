
construct_monom = Groebner.construct_monom
lex = (x, y) -> Groebner.monom_isless(x, y, Groebner._Lex{true}([]))
dl = (x, y) -> Groebner.monom_isless(x, y, Groebner._DegLex{true}([]))
drl = (x, y) -> Groebner.monom_isless(x, y, Groebner._DegRevLex{true}([]))

implementations_to_test = [
    Groebner.ExponentVector{T} where {T},
    Groebner.PackedTuple1{T, UInt8} where {T},
    Groebner.PackedTuple2{T, UInt8} where {T},
    Groebner.PackedTuple3{T, UInt8} where {T},
    Groebner.SparseExponentVector{T} where {T}
]

@testset "monom orders: Lex, DegLex, DegRevLex" begin
    for T in (UInt64, UInt32, UInt16)
        for EV in implementations_to_test
            a = construct_monom(EV{T}, [0])
            b = construct_monom(EV{T}, [0])
            @test !lex(a, b)
            @test !dl(a, b)
            @test !drl(a, b)

            a = construct_monom(EV{T}, [0])
            b = construct_monom(EV{T}, [1])
            @test lex(a, b)
            @test dl(a, b)
            @test drl(a, b)
            @test !lex(b, a)
            @test !dl(b, a)
            @test !drl(b, a)

            2 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, [1, 1])
            b = construct_monom(EV{T}, [2, 0])
            @test lex(a, b)
            @test dl(a, b)
            @test drl(a, b)
            @test !lex(b, a)
            @test !dl(b, a)
            @test !drl(b, a)

            2 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, [1, 1])
            b = construct_monom(EV{T}, [0, 2])
            @test !lex(a, b)
            @test !dl(a, b)
            @test !drl(a, b)
            @test lex(b, a)
            @test dl(b, a)
            @test drl(b, a)

            2 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, [1, 1])
            b = construct_monom(EV{T}, [1, 1])
            @test !lex(a, b)
            @test !dl(a, b)
            @test !drl(a, b)

            2 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, [1, 1])
            b = construct_monom(EV{T}, [2, 2])
            @test lex(a, b)
            @test dl(a, b)
            @test drl(a, b)
            @test !lex(b, a)
            @test !dl(b, a)
            @test !drl(b, a)

            3 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, [1, 0, 2])
            b = construct_monom(EV{T}, [2, 0, 1])
            @test lex(a, b)
            @test dl(a, b)
            @test drl(a, b)

            5 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, ones(UInt, 5))
            b = construct_monom(EV{T}, ones(UInt, 5))
            @test !lex(a, b)
            @test !dl(a, b)
            @test !drl(a, b)

            25 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, ones(UInt, 25))
            b = construct_monom(EV{T}, ones(UInt, 25))
            @test !lex(a, b)
            @test !dl(a, b)
            @test !drl(a, b)

            30 > Groebner.max_vars_in_monom(EV{T}) && continue
            a = construct_monom(EV{T}, ones(UInt, 30))
            b = construct_monom(EV{T}, ones(UInt, 30))
            @test !lex(a, b)
            @test !dl(a, b)
            @test !drl(a, b)
        end

        # test that different implementations agree
        for n in 1:10
            k = rand(1:100)

            implementations_to_test_local = filter(
                xxx -> Groebner.max_vars_in_monom(xxx{T}) >= k,
                implementations_to_test
            )

            t = div(typemax(UInt8), k) - 1
            x, y = rand(1:t, k), rand(1:t, k)
            if sum(x) >= Groebner._monom_overflow_threshold(UInt8)
                continue
            end
            if sum(y) >= Groebner._monom_overflow_threshold(UInt8)
                continue
            end
            as = [construct_monom(EV{T}, x) for EV in implementations_to_test_local]
            bs = [construct_monom(EV{T}, y) for EV in implementations_to_test_local]

            @test length(unique(map(lex, as, bs))) == 1
            @test length(unique(map(dl, as, bs))) == 1
            @test length(unique(map(drl, as, bs))) == 1

            # test that a < b && b < a does not happen
            for (a, b) in zip(as, bs)
                k > Groebner.max_vars_in_monom(a) && continue
                if lex(a, b)
                    @test !lex(b, a)
                end
                if dl(a, b)
                    @test !dl(b, a)
                end
                if drl(a, b)
                    @test !drl(b, a)
                end
            end
        end
    end
end

function test_circular_shift(a, b, n, Ord, answers)
    R, x = AbstractAlgebra.QQ[["x$i" for i in 1:n]...]
    vars_to_index = Dict(x .=> 1:n)
    orders = map(
        i -> Groebner.convert_to_internal_monomial_ordering(
            vars_to_index,
            Ord(circshift(x, -i))
        ),
        0:(n - 1)
    )
    cmps = map(ord -> ((x, y) -> Groebner.monom_isless(x, y, ord)), orders)

    for (cmp, answer) in zip(cmps, answers)
        @test answer == cmp(a, b) && !answer == cmp(b, a)
    end
end

@testset "monoms, variable permutation" begin
    for T in (UInt64, UInt32, UInt16)
        for EV in implementations_to_test
            if EV{T} <: Groebner.PackedTuple2 || EV{T} <: Groebner.PackedTuple3
                continue
            end

            n = 3
            n >= Groebner.max_vars_in_monom(EV{T}) && continue

            a = construct_monom(EV{T}, [5, 5, 3])
            b = construct_monom(EV{T}, [1, 1, 10])

            test_circular_shift(a, b, n, Groebner.Lex, [false, false, true])
            test_circular_shift(a, b, n, Groebner.DegLex, [false, false, false])
            test_circular_shift(a, b, n, Groebner.DegRevLex, [false, false, false])

            n = 5
            n >= Groebner.max_vars_in_monom(EV{T}) && continue

            a = construct_monom(EV{T}, [1, 2, 3, 4, 5])
            b = construct_monom(EV{T}, [4, 3, 2, 1, 5])

            test_circular_shift(a, b, n, Groebner.Lex, [true, true, false, false, true])
            test_circular_shift(a, b, n, Groebner.DegLex, [true, true, false, false, true])
            test_circular_shift(
                a,
                b,
                n,
                Groebner.DegRevLex,
                [true, false, false, true, true]
            )
        end
    end
end

function test_orderings(n, v1, v2, ords_to_test)
    R, x = QQ[["x$i" for i in 1:n]...]
    var_to_index = Dict(x .=> 1:n)
    for wo in ords_to_test
        ord = wo.ord
        ans = wo.ans
        internal_ord = Groebner.convert_to_internal_monomial_ordering(var_to_index, ord)
        @test Groebner.monom_isless(v1, v2, internal_ord) == ans[1]
        @test Groebner.monom_isless(v2, v1, internal_ord) == ans[2]
        @test Groebner.monom_isless(v2, v2, internal_ord) == false
        @test Groebner.monom_isless(v1, v1, internal_ord) == false
    end
end

@testset "monom orders: WeightedOrdering" begin
    pv = Groebner.ExponentVector{T} where {T}

    v1 = Groebner.construct_monom(pv{UInt64}, [1, 2, 3])
    v2 = Groebner.construct_monom(pv{UInt64}, [3, 2, 1])

    @test_throws AssertionError Groebner.WeightedOrdering([-1, 0, 0])

    ords_to_test = [
        (ord=Groebner.WeightedOrdering([1, 1, 1]), ans=[true, false]),
        (ord=Groebner.WeightedOrdering([0, 0, 1]), ans=[false, true]),
        (ord=Groebner.WeightedOrdering([0, 1, 0]), ans=[true, false]),
        (ord=Groebner.WeightedOrdering([1, 0, 0]), ans=[true, false]),
        (ord=Groebner.WeightedOrdering([1, 1, 5]), ans=[false, true]),
        (ord=Groebner.WeightedOrdering([1, 0, 0]), ans=[true, false])
    ]

    test_orderings(3, v1, v2, ords_to_test)

    v1 = Groebner.construct_monom(pv{UInt64}, [1, 2, 3])
    v2 = Groebner.construct_monom(pv{UInt64}, [1, 2, 3])

    ords_to_test = [
        (ord=Groebner.WeightedOrdering([1, 1, 1]), ans=[false, false]),
        (ord=Groebner.WeightedOrdering([0, 0, 1]), ans=[false, false]),
        (ord=Groebner.WeightedOrdering([0, 1, 0]), ans=[false, false]),
        (ord=Groebner.WeightedOrdering([1, 0, 0]), ans=[false, false]),
        (ord=Groebner.WeightedOrdering([1, 1, 5]), ans=[false, false]),
        (ord=Groebner.WeightedOrdering([1, 0, 0]), ans=[false, false])
    ]

    test_orderings(3, v1, v2, ords_to_test)

    v1 = Groebner.construct_monom(pv{UInt64}, [1, 2, 3, 0, 0, 7])
    v2 = Groebner.construct_monom(pv{UInt64}, [4, 5, 0, 0, 1, 4])

    ords_to_test = [
        (ord=Groebner.WeightedOrdering([1, 1, 1, 1, 1, 1]), ans=[true, false]),
        (ord=Groebner.WeightedOrdering([0, 0, 0, 0, 0, 4]), ans=[false, true]),
        (ord=Groebner.WeightedOrdering([0, 2, 5, 0, 0, 0]), ans=[false, true]),
        (ord=Groebner.WeightedOrdering([0, 2, 2, 0, 0, 0]), ans=[true, false])
    ]

    test_orderings(6, v1, v2, ords_to_test)
end

@testset "monom orders: ProductOrdering" begin
    pv = Groebner.ExponentVector{T} where {T}

    R, x = QQ[["x$i" for i in 1:3]...]
    v1 = Groebner.construct_monom(pv{UInt64}, [1, 2, 3])
    v2 = Groebner.construct_monom(pv{UInt64}, [3, 2, 1])

    ords_to_test = [
        (
            ord=Groebner.ProductOrdering(Groebner.Lex(x[1]), Groebner.DegLex(x[2], x[3])),
            ans=[true, false]
        ),
        (
            ord=Groebner.ProductOrdering(Groebner.DegRevLex(x[1:2]), Groebner.Lex(x[3])),
            ans=[true, false]
        )
    ]

    test_orderings(3, v1, v2, ords_to_test)

    R, x = QQ[["x$i" for i in 1:6]...]
    v1 = Groebner.construct_monom(pv{UInt64}, [4, 1, 7, 0, 9, 8])
    v2 = Groebner.construct_monom(pv{UInt64}, [1, 6, 3, 5, 9, 100])

    ords_to_test = [
        (
            ord=Groebner.ProductOrdering(Groebner.DegLex(x[1]), Groebner.DegLex(x[2:6])),
            ans=[false, true]
        ),
        (
            ord=Groebner.ProductOrdering(Groebner.DegLex(x[1:2]), Groebner.DegLex(x[3:6])),
            ans=[true, false]
        ),
        (
            ord=Groebner.ProductOrdering(Groebner.DegLex(x[1:3]), Groebner.DegLex(x[4:6])),
            ans=[false, true]
        ),
        (
            ord=Groebner.ProductOrdering(Groebner.DegLex(x[1:4]), Groebner.DegLex(x[5:6])),
            ans=[true, false]
        ),
        (
            ord=Groebner.ProductOrdering(
                Groebner.ProductOrdering(Groebner.DegLex(x[1:2]), Groebner.DegLex(x[3:4])),
                Groebner.DegLex(x[5:6])
            ),
            ans=[true, false]
        ),
        (
            ord=Groebner.ProductOrdering(
                Groebner.ProductOrdering(Groebner.DegLex(x[1:3]), Groebner.DegLex(x[4])),
                Groebner.DegLex(x[5:6])
            ),
            ans=[false, true]
        ),
        (
            ord=Groebner.DegLex(x[1:3]) * Groebner.DegLex(x[4]) * Groebner.DegLex(x[5:6]),
            ans=[false, true]
        )
    ]

    test_orderings(6, v1, v2, ords_to_test)
end

@testset "monom orders: MatrixOrdering" begin
    pv = Groebner.ExponentVector{T} where {T}

    v1 = Groebner.construct_monom(pv{UInt64}, [1, 2, 3])
    v2 = Groebner.construct_monom(pv{UInt64}, [3, 2, 1])

    ord1 = Groebner.MatrixOrdering([
        1 0 0
        0 1 0
        0 0 1
    ])
    ord2 = Groebner.MatrixOrdering([
        1 0 2;
    ])
    ord3 = Groebner.MatrixOrdering([
        0 0 0
        0 1 0
        1 1 1
    ])
    ord4 = Groebner.MatrixOrdering([
        -1 0 0;
    ])
    ord5 = Groebner.MatrixOrdering([
        1 -8 1
        2 0 3
    ])

    mo_to_test = [
        (ord=ord1, ans=[true, false]),
        (ord=ord2, ans=[false, true]),
        (ord=ord3, ans=[false, false]),
        (ord=ord4, ans=[false, true]),
        (ord=ord5, ans=[false, true])
    ]
    test_orderings(3, v1, v2, mo_to_test)
end
