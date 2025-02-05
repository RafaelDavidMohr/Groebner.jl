
function _normalform(polynomials, to_be_reduced, kws::KeywordsHandler)
    polynomial_repr =
        select_polynomial_representation(polynomials, kws, hint=:large_exponents)
    ring, var_to_index1, monoms, coeffs =
        convert_to_internal(polynomial_repr, polynomials, kws)
    if isempty(monoms)
        @log level = -2 "Input basis consisting of zero polynomials only."
        return to_be_reduced
    end
    ring_to_be_reduced, var_to_index2, monoms_to_be_reduced, coeffs_to_be_reduced =
        convert_to_internal(polynomial_repr, to_be_reduced, kws, dropzeros=false)
    var_to_index = merge(var_to_index1, var_to_index2)
    nonzero_indices = findall(!iszero_coeffs, coeffs_to_be_reduced)
    if isempty(nonzero_indices)
        @log level = -2 "Polynomials to be reduced are all zero."
        return to_be_reduced
    end
    monoms_to_be_reduced_nonzero = monoms_to_be_reduced[nonzero_indices]
    coeffs_to_be_reduced_nonzero = coeffs_to_be_reduced[nonzero_indices]
    params = AlgorithmParameters(ring, polynomial_repr, kws)
    ring, _ = set_monomial_ordering!(ring, var_to_index, monoms, coeffs, params)
    ring_, _ = set_monomial_ordering!(
        ring_to_be_reduced,
        var_to_index,
        monoms_to_be_reduced_nonzero,
        coeffs_to_be_reduced_nonzero,
        params
    )
    @assert ring.nvars == ring_to_be_reduced.nvars && ring.ch == ring_to_be_reduced.ch
    if kws.check
        @log level = -2 "As `check=true` was provided, checking that the given input is indeed a Groebner basis"
        if !_isgroebner(ring, monoms, coeffs, params)
            __not_a_basis_error(
                polynomials,
                "Input polynomials do not look like a Groebner basis."
            )
        end
    end
    monoms_reduced, coeffs_reduced = _normalform(
        ring,
        monoms,
        coeffs,
        monoms_to_be_reduced_nonzero,
        coeffs_to_be_reduced_nonzero,
        params
    )
    monoms_to_be_reduced[nonzero_indices] .= monoms_reduced
    coeffs_to_be_reduced[nonzero_indices] .= coeffs_reduced
    monoms_reduced = monoms_to_be_reduced
    coeffs_reduced = coeffs_to_be_reduced
    # TODO: remove `to_be_reduced` from arguments here
    @log_performance_counters
    convert_to_output(ring, to_be_reduced, monoms_reduced, coeffs_reduced, params)
end

function _normalform(
    ring::PolyRing,
    monoms::Vector{Vector{M}},
    coeffs::Vector{Vector{C}},
    monoms_to_be_reduced::Vector{Vector{M}},
    coeffs_to_be_reduced::Vector{Vector{C}},
    params
) where {M <: Monom, C <: Coeff}
    @log level = -3 "Initializing structs for F4"
    basis, _, hashtable = initialize_structs(ring, monoms, coeffs, params)
    tobereduced = initialize_basis_using_existing_hashtable(
        ring,
        monoms_to_be_reduced,
        coeffs_to_be_reduced,
        hashtable
    )
    f4_normalform!(ring, basis, tobereduced, hashtable, params.arithmetic)
    export_basis_data(tobereduced, hashtable)
end
