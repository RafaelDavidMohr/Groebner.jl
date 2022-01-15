
"""
function groebner(
            polys::Vector{Poly};
            reduced::Bool=true,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::LogLevel=Logging.Warn
            ) where {Poly, Rng<:Random.AbstractRNG}

    Computes the Groebner basis of the ideal generated by `polys`.

    If `reduced` is set to true, returns the reduced basis, which is unique.
    Otherwise, there are no guarantees on uniqueness (and also on minimality).

    Uses the ordering on `polys` for computation by default.
    If `ordering` is specialized, it takes precedence.

    By default, the function executes silently.
    This can be changed adjusting the `loglevel`.

    Suported monomial orderings are:
    - `degrevlex`
    - `deglex`
    - `lex`

    Random generator `rng` is responsible for hashing monomials during computation.

"""
function groebner(
            polys::Vector{Poly};
            reduced::Bool=true,
            ordering::Symbol=:input,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::LogLevel=Logging.Warn
            ) where {Poly, Rng<:Random.AbstractRNG}

    #= set the logger =#
    prev_logger = Logging.global_logger(ConsoleLogger(stderr, loglevel))

    #= extract ring information, exponents and coefficients
       from input polynomials =#
    # Copies input, so that polys would not be changed itself.
    ring, exps, coeffs = convert_to_internal(polys, ordering)

    #= compute the groebner basis =#
    if ring.ch != 0
        # if finite field
        bexps, bcoeffs = groebner_ff(ring, exps, coeffs, reduced, rng)
    else
        # if rational coefficients
        bexps, bcoeffs = groebner_qq(ring, exps, coeffs, reduced, rng)
    end

    #=
    Assuming ordering of `bexps` here matches `ring.ord`
    =#

    #= revert logger =#
    Logging.global_logger(prev_logger)

    # ring contains ordering of computation, it is the requested ordering
    #= convert result back to representation of input =#
    convert_to_output(ring, polys, bexps, bcoeffs)
end

#######################################
# Finite field groebner

function groebner_ff(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}},
            reduced::Bool,
            rng::Rng) where {Rng<:Random.AbstractRNG}
    # specialize on ordering (not yet)
    # groebner_ff(ring, exps, coeffs, reduced, rng, Val(ring.ord))
    f4(ring, exps, coeffs, rng, reduced)
end

# TODO
function groebner_ff(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}},
            reduced::Bool,
            rng::Rng,
            ::Val{:degrevlex}
            ) where {Rng<:Random.AbstractRNG}
    f4(ring, exps, coeffs, rng, reduced)
end

# TODO
function groebner_ff(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}},
            reduced::Bool,
            rng::Rng,
            ::Val{:lex}
            ) where {Rng<:Random.AbstractRNG}
    gbexps, gbcoeffs = f4(ring, exps, coeffs, rng, reduced)
    fglm(ring, gbexps, gbcoeffs, rng)
end

#######################################
# Rational field groebner

function modular_f4_step(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}},
            rng::Rng,
            reduced::Bool,
            ::Val{:degrevlex}
            ) where {Rng<:Random.AbstractRNG}

    f4(ring, exps, coeffs, rng, reduced)
end

function modular_f4_step(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}},
            rng::Rng,
            reduced::Bool,
            ::Val{:deglex}
            ) where {Rng<:Random.AbstractRNG}

    f4(ring, exps, coeffs, rng, reduced)
end

function modular_f4_step(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}},
            rng::Rng,
            reduced::Bool,
            ::Val{:lex}
            ) where {Rng<:Random.AbstractRNG}

    # TODO
    # f4
    # gbexps, gbcoeffs = f4(ring, exps, coeffs, rng, reduced)
    # fglm(ring, gbexps, gbcoeffs, rng)
    f4(ring, exps, coeffs, rng, reduced)
end

function groebner_qq(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{Rational{BigInt}}},
            reduced::Bool,
            rng::Rng,
            ) where {Rng<:Random.AbstractRNG}

    # scale coefficients to integer ring inplace
    coeffs_zz = scale_denominators!(coeffs)

    gbcoeffs_accum = Vector{Vector{BigInt}}(undef, 0)
    gbexps = Vector{Vector{Vector{UInt16}}}(undef, 0)
    gbcoeffs_qq = Vector{Vector{Rational{BigInt}}}(undef, 0)

    prime::Int64 = 1
    modulo = BigInt(1)

    i = 1
    while true
        # lucky reduction prime
        prime  = nextluckyprime(coeffs_zz, prime)
        @info "$i: selected lucky prime $prime"

        # compute the image of coeffs_zz in GF(prime),
        # by coercing each coefficient into the finite field
        ring_ff, coeffs_ff = reduce_modulo(coeffs_zz, ring, prime)

        # groebner basis over finite field ideal
        # TODO: gbexps can be only computed once
        @info "Computing Groebner basis"
        gbexps, gbcoeffs_ff = modular_f4_step(
                                    ring_ff, exps, coeffs_ff,
                                    rng, reduced, Val(ring.ord))

        # TODO: add majority rule based choice

        # reconstruct basis coeffs into integers
        # from the previously accumulated basis and the new one,
        @info "CRT modulo ($modulo, $(ring_ff.ch))"
        gbcoeffs_zz, modulo = reconstruct_crt!(
                            gbcoeffs_accum, modulo,
                            gbcoeffs_ff, ring_ff.ch)

        gbcoeffs_accum = gbcoeffs_zz

        # try to reconstruct basis coeffs from integers
        # into rationals
        @info "Reconstructing modulo $modulo"
        gbcoeffs_qq = reconstruct_modulo(gbcoeffs_zz, modulo)

        # run correctness checks to assure the reconstrction is correct
        # TODO: correctness_checks
        if reconstruction_check(gbcoeffs_qq, modulo)
            @info "Reconstructed successfully!"
            break
        end

        # not correct, goto next prime
        i += 1
        if i > 1000
            @error "Something probably went wrong in groebner.."
            return
        end
    end

    gbexps, gbcoeffs_qq
end

#------------------------------------------------------------------------------

"""
function isgroebner(polys::Vector{Poly}) where {Poly}

    Checkes if the input set of polynomials is a Groebner basis.

    At the moment only finite field coefficients are supported.
"""
function isgroebner(polys::Vector{Poly}) where {Poly}
    ring, exps, coeffs = convert_to_internal(polys)
    isgroebner_ff(ring, exps, coeffs)
end


function isgroebner_ff(
            ring::PolyRing,
            exps::Vector{Vector{Vector{UInt16}}},
            coeffs::Vector{Vector{UInt64}};)

    isgroebner_f4(ring, exps, coeffs)
end

#------------------------------------------------------------------------------
