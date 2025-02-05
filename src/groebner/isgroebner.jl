
function _isgroebner(polynomials, kws::KeywordsHandler)
    polynomial_repr =
        select_polynomial_representation(polynomials, kws, hint=:large_exponents)
    ring, var_to_index, monoms, coeffs =
        convert_to_internal(polynomial_repr, polynomials, kws)
    if isempty(monoms)
        @log level = -2 "Input consisting of zero polynomials, which is a Groebner basis by our convention"
        return true
    end
    params = AlgorithmParameters(ring, polynomial_repr, kws)
    ring, _ = set_monomial_ordering!(ring, var_to_index, monoms, coeffs, params)
    _isgroebner(ring, monoms, coeffs, params)
end

# isgroebner for Finite fields
function _isgroebner(
    ring::PolyRing,
    monoms::Vector{Vector{M}},
    coeffs::Vector{Vector{C}},
    params
) where {M <: Monom, C <: CoeffFF}
    basis, pairset, hashtable = initialize_structs(ring, monoms, coeffs, params)
    f4_isgroebner!(ring, basis, pairset, hashtable, params.arithmetic)
end

# isgroebner for Rational numbers
function _isgroebner(
    ring::PolyRing,
    monoms::Vector{Vector{M}},
    coeffs::Vector{Vector{C}},
    params
) where {M <: Monom, C <: CoeffQQ}
    buffer = CoefficientBuffer()
    basis, pairset, hashtable = initialize_structs(ring, monoms, coeffs, params)
    # If an honest computation over the rationals is needed
    if params.certify_check
        @log level = -2 """
        Keyword argument `certify=true` was provided. 
        Checking that the given input is a Groebner basis directly over the rationals"""
        flag = f4_isgroebner!(ring, basis, pairset, hashtable, params.arithmetic)
        @log_performance_counters
        return flag
    end
    # Otherwise, check modulo a prime
    @log level = -2 "Checking if a Grobner basis modulo a prime"
    buffer = CoefficientBuffer()
    @log level = -2 "Clearning denominators in the input generators"
    basis_zz = clear_denominators!(buffer, basis, deepcopy=false)
    luckyprimes = LuckyPrimes(basis_zz.coeffs)
    prime = next_check_prime!(luckyprimes)
    @log level = -2 "Reducing input generators modulo $prime"
    ring_ff, basis_ff = reduce_modulo_p!(buffer, ring, basis_zz, prime, deepcopy=true)
    arithmetic = select_arithmetic(prime, CoeffModular)
    flag = f4_isgroebner!(ring_ff, basis_ff, pairset, hashtable, arithmetic)
    @log_performance_counters
    flag
end
