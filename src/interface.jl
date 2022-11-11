
"""
    function groebner(
            polynomials;
            reduced=true,
            ordering=:input,
            certify=false,
            forsolve=false,
            linalg=:exact,
            monom_representation=best(),
            rng=MersenneTwister(42),
            loglevel=Logging.Warn
    )

Computes a Groebner basis of the ideal generated by array `polynomials`.

If `reduced` is set, the returned basis is reduced, which is **unique** (default).

Uses the term ordering from `polynomials` by default (if any).
If `ordering` parameter is explicitly specified, it takes precedence.
Possible term orderings to specify are

- :input for preserving the input ordering (default),
- :lex for lexicographic,
- :deglex for graded lexicographic,
- :degrevlex for graded reverse lexicographic.

*Graded term orderings tend to be the fastest.*

The algorithm is randomized. The obtained result will be correct with high probability.
Set `certify` to `true` to obtain correct result guaranteedly.

Set `forsolve` to `true` to tell the algorithm to automatically select parameters
for producing a basis that further can used for *solving the input system*. In this case,
the output basis will be in generic position in lexicographic monomial order.
The computation will, however, fail, if the input polynomial system is not solvable.

The `linalg` parameter is responsible for linear algebra backend to be used.
Currently, available options are

- `:exact` for exact sparse linear algebra (default),
- `:prob` for probabilistic sparse linear algebra. Tends to be faster.

The algorithm automatically chooses the best monomial representation.
Otherwise, you can set `monom_representation` to one of the following:

- `best()` for automatic choice,
- NotPacked{<:Unsigned}, e.g., NotPacked{UInt32}, for not packed representation with 32 bits per exponent,
- Packed{<:Unsigned}, e.g., Packed{UInt8}, for packed representation with 8 bits per exponent.

The algorithm uses randomized hashing that depends on random number generator `rng`.

Verboseness can be tweaked with the `loglevel` parameter (default is that only warnings are produced).

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> groebner([x*y^2 + x, y*x^2 + y])
```

"""
function groebner(
            polynomials::Vector{Poly};
            reduced::Bool=true,
            ordering::Symbol=:input,
            certify::Bool=false,
            forsolve::Bool=false,
            linalg::Symbol=:exact,
            monom_representation=best(),
            rng::Rng=Random.MersenneTwister(42),
            loglevel::Logging.LogLevel=Logging.Warn
        ) where {Poly, Rng<:Random.AbstractRNG}
    #= set the logger =#
    prev_logger = Logging.global_logger(ConsoleLogger(stderr, loglevel))
    
    #= guess the best representation for polynomials =#
    representation = guess_effective_representation(polynomials, UnsafeRepresentation(), monom_representation)
    
    try
        #= try to compute in this representation =# 
        return groebner(polynomials, representation, reduced, ordering, certify, forsolve, linalg, rng)
    catch beda
        if isa(beda, OverflowError)
            # if computation fails due to exponent vector overflow,
            # then compute safely
            @warn "Monomial overflow ($(representation)); switching to another representation."
            representation = default_safe_representation()
            return groebner(polynomials, representation, reduced, ordering, certify, forsolve, linalg, rng)
        else
            # if the computation just fails for some reason
            rethrow(beda)
        end
    finally
        #= revert logger =#
        Logging.global_logger(prev_logger)
    end
end

"""
    function isgroebner(
                polynomials;
                ordering=:input,
                certify=false,
                rng=MersenneTwister(42),
                loglevel=Logging.Warn
    )

Checks if `polynomials` forms a Groebner basis.

Uses the ordering on `polynomials` by default.
If `ordering` is explicitly specified, it takes precedence.

By default, a fast randomized algorithm is used. Use `certify=true` 
to obtain a guaranteed result.

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> isgroebner([y^2 + x, x^2 + y])
```

"""
function isgroebner(
            polynomials::Vector{Poly};
            ordering=:input,
            certify::Bool=false,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::LogLevel=Logging.Warn
    ) where {Poly, Rng<:Random.AbstractRNG}

    #= set the logger =#
    prev_logger = Logging.global_logger(ConsoleLogger(stderr, loglevel))

    #= extract ring information, exponents and coefficients
       from input polynomials =#
    # Copies input, so that polys would not be changed itself.
    ring, exps, coeffs = convert_to_internal(default_safe_representation(), polynomials, ordering)

    #= check and set algorithm parameters =#
    metainfo = set_metaparameters(ring, ordering, certify, false, :exact, rng)
    # now ring stores computation ordering
    # metainfo is now a struct to store target ordering

    iszerobasis = clean_input_isgroebner!(ring, exps, coeffs)
    iszerobasis && (return true)

    #= change input ordering if needed =#
    assure_ordering!(ring, exps, coeffs, metainfo)

    #= check if groebner basis =#
    flag = isgroebner(ring, exps, coeffs, metainfo)

    #=
    Assuming ordering of `bexps` here matches `ring.ord`
    =#

    #= revert logger =#
    Logging.global_logger(prev_logger)

    flag
end

"""
    function normalform(
                basis,
                tobereduced;
                check=true,
                ordering=:input,
                rng=MersenneTwister(42),
                loglevel=Logging.Warn
    )

Computes the normal form of `tobereduced` w.r.t `basis`.

`tobereduced` can be either a single polynomial or an array of polynomials.
In the latter case, normal form is computed for each of its entries 
*(which is faster than computing separately)*.

The `basis` is assumed to be a Groebner basis.
If `check=true`, we use randomized algorithm to quickly check 
if `basis` is indeed a Groebner basis (default).

Uses the ordering on `basis` by default.
If `ordering` is explicitly specified, it takes precedence.

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> normalform([y^2 + x, x^2 + y], x^2 + y^2 + 1, check=false)
```

"""
function normalform(
            basispolys::Vector{Poly},
            tobereduced::Poly;
            check::Bool=true,
            ordering::Symbol=:input,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::LogLevel=Logging.Warn
            ) where {Poly, Rng<:Random.AbstractRNG}
    
    iszero(tobereduced) && (return tobereduced)

    first(normalform(
            basispolys, [tobereduced], check=check,
            ordering=ordering, rng=rng, loglevel=loglevel)
    )
end

function normalform(
            basispolys::Vector{Poly},
            tobereduced::Vector{Poly};
            check::Bool=true,
            ordering::Symbol=:input,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::LogLevel=Logging.Warn
            ) where {Poly, Rng<:Random.AbstractRNG}

    #= set the logger =#
    prev_logger = Logging.global_logger(ConsoleLogger(stderr, loglevel))

    check && check_isgroebner(basispolys)

    #= extract ring information, exponents and coefficients
       from input basis polynomials =#
    # Copies input, so that polys would not be changed itself.
    ring1, basisexps, basiscoeffs = convert_to_internal(default_safe_representation(), basispolys, ordering)
    ring2, tbrexps, tbrcoeffs = convert_to_internal(default_safe_representation(), tobereduced, ordering)

    @assert ring1.nvars == ring2.nvars && ring1.ch == ring2.ch
    @assert ring1.ord == ring2.ord

    ring = ring1

    #= check and set algorithm parameters =#
    metainfo = set_metaparameters(ring, ordering, false, false, :exact, rng)

    iszerobasis = clean_input_normalform!(ring, basisexps, basiscoeffs, tbrexps, tbrcoeffs)
    iszerobasis && (return convert_to_output(ring, tobereduced, tbrexps, tbrcoeffs, metainfo))

    #= change input ordering if needed =#
    assure_ordering!(ring, basisexps, basiscoeffs, metainfo)
    assure_ordering!(ring, tbrexps, tbrcoeffs, metainfo)

    # We assume basispolys is already a Groebner basis! #

    #= compute the groebner basis =#
    bexps, bcoeffs = normal_form_f4(
                        ring, basisexps, basiscoeffs,
                        tbrexps, tbrcoeffs, rng)

    #=
    Assuming ordering of `bexps` here matches `ring.ord`
    =#

    #= revert logger =#
    Logging.global_logger(prev_logger)

    # ring contains ordering of computation, it is the requested ordering
    #= convert result back to representation of input =#
    convert_to_output(ring, tobereduced, bexps, bcoeffs, metainfo)
end

"""
    function fglm(
            basis;
            check=true,
            rng=MersenneTwister(42),
            loglevel=Warn
    )

Applies FGLM algorithm to `basis` and returns a Groebner basis in `lex` ordering.

The `basis` is assumed to be a Groebner basis.
If `check=true`, we use randomized algorithm to quickly check 
if `basis` is indeed a Groebner basis (default).

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> fglm([y^2 + x, x^2 + y], check=true)
```

"""
function fglm(
            basis::Vector{Poly};
            check::Bool=true,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::Logging.LogLevel=Logging.Warn
            ) where {Poly, Rng<:Random.AbstractRNG}

    #= set the logger =#
    prev_logger = Logging.global_logger(ConsoleLogger(stderr, loglevel))

    check && check_isgroebner(basis)

    #= extract ring information, exponents and coefficients
       from input polynomials =#
    # Copies input, so that polynomials would not be changed itself.
    ring, exps, coeffs = convert_to_internal(default_safe_representation(), basis, :input)

    metainfo = set_metaparameters(ring, :lex, false, false, :exact, rng)
    
    iszerobasis = clean_input_fglm!(ring, exps, coeffs)
    iszerobasis && (return convert_to_output(ring, basis, exps, coeffs, metainfo))

    bexps, bcoeffs = fglm_f4(ring, exps, coeffs, metainfo)

    # lol
    ring.ord = :lex

    # ordering in bexps here matches target ordering in metainfo

    #= revert logger =#
    Logging.global_logger(prev_logger)

    # ring contains ordering of computation, it is the requested ordering
    #= convert result back to representation of input =#
    convert_to_output(ring, basis, bexps, bcoeffs, metainfo)
end

"""
    function kbase(
            basis;
            check=true,
            rng=MersenneTwister(42),
            loglevel=Warn
    )

Computes the basis of polynomial ring modulo the zero-dimensional ideal
generated by `basis` as a basis of vector space.

The `basis` is assumed to be a Groebner basis.
If `check=true`, we use randomized algorithm to quickly check 
if `basis` is indeed a Groebner basis (default).

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> kbase([y^2 + x, x^2 + y], check=true)
```

"""
function kbase(
            basis::Vector{Poly};
            check::Bool=true,
            rng::Rng=Random.MersenneTwister(42),
            loglevel::Logging.LogLevel=Logging.Warn
            ) where {Poly, Rng<:Random.AbstractRNG}

    #= set the logger =#
    prev_logger = Logging.global_logger(ConsoleLogger(stderr, loglevel))

    check && check_isgroebner(basis)

    #= extract ring information, exponents and coefficients
       from input polynomials =#
    # Copies input, so that polynomials would not be changed itself.
    ring, exps, coeffs = convert_to_internal(default_safe_representation(), basis, :input)

    metainfo = set_metaparameters(ring, :input, false, false, :exact, rng)
    
    iszerobasis = clean_input_kbase!(ring, exps, coeffs)
    iszerobasis && (throw(DomainError(basis, "Groebner.kbase does not work with such ideals, sorry")))

    bexps, bcoeffs = kbase_f4(ring, exps, coeffs, metainfo)

    # ordering in bexps here matches target ordering in metainfo

    #= revert logger =#
    Logging.global_logger(prev_logger)

    # ring contains ordering of computation, it is the requested ordering
    #= convert result back to representation of input =#
    convert_to_output(ring, basis, bexps, bcoeffs, metainfo)
end
