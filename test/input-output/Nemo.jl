import Nemo
import Primes

@testset "Nemo.jl, univariate" begin
    R, x = PolynomialRing(Nemo.GF(2^62 + 135), "x")
    @test Groebner.groebner([R(2)]) == [R(1)]
    @test Groebner.groebner([R(0), R(0)]) == [R(0)]
    @test Groebner.groebner([R(0), R(3), R(0)]) == [R(1)]

    for ground in [Nemo.GF(2^31 - 1), Nemo.GF(2^62 + 135), Nemo.QQ]
        for gb_ord in [Groebner.Lex(), Groebner.DegLex(), Groebner.DegRevLex()]
            R, x = PolynomialRing(ground, "x")
            @test Groebner.groebner([x^2 - 4, x + 2], ordering=gb_ord) == [x + 2]
        end
    end
end

@testset "Nemo.jl, input-output" begin
    R, (x, y) = AbstractAlgebra.GF(Primes.nextprime(BigInt(2)^100))["x", "y"]
    @test_throws DomainError Groebner.groebner([x, y])

    nemo_orderings_to_test = [:lex, :deglex, :degrevlex]
    nemo_grounds_to_test = [Nemo.GF(2^62 + 135), Nemo.GF(2^31 - 1), Nemo.GF(17), Nemo.QQ]

    for ord in nemo_orderings_to_test
        for ground in nemo_grounds_to_test
            R, x = Nemo.PolynomialRing(ground, "x")
            gb = Groebner.groebner([(x - 1) * (x + 8), (x + 8) * (x + 10)])
            @test gb == [(x + 8)]

            R, (x, y) = Nemo.PolynomialRing(ground, ["x", "y"], ordering=ord)
            fs = [x^2 * y + 3, (2^31 - 5) * x - (2^31 - 4) * y]
            gb = Groebner.groebner(fs)
            @test parent(gb[1]) == R
            @test Groebner.isgroebner(gb)
        end
    end

    # Test for different Groebner.jl orderings
    for nemo_ord in [:lex, :deglex, :degrevlex]
        for ground in nemo_grounds_to_test
            R, (x,) = PolynomialRing(ground, ["x"], ordering=nemo_ord)
            for gb_ord in [
                Groebner.Lex(),
                Groebner.DegLex(),
                Groebner.DegRevLex(),
                Groebner.Lex(x),
                Groebner.DegLex(x)
            ]
                gb = Groebner.groebner([x^2], ordering=gb_ord)
                @test parent(first(gb)) == R
                @test gb == [x^2]
            end

            R, (x, y) = PolynomialRing(ground, ["x", "y"], ordering=nemo_ord)
            fs = [x^2 + 3, y - 1]
            for gb_ord in [
                Groebner.Lex(),
                Groebner.DegLex(),
                Groebner.DegRevLex(),
                Groebner.Lex(x, y),
                Groebner.Lex(y, x)
            ]
                gb = Groebner.groebner(fs, ordering=gb_ord)
                @test parent(first(gb)) == R
                @test all(in(fs), gb) && all(in(gb), fs)
            end
        end
    end
end
