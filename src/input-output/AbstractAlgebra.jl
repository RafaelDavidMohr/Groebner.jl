# Conversion from AbstractAlgebra.jl into internal representation.

# This all is just not fantastic. 
# We are practically dancing for rain around AbstractAlgebra.jl internals here.

const _AA_supported_orderings_symbols = (:lex, :deglex, :degrevlex)
const _AA_exponent_type = UInt64

###
# Converting from AbstractAlgebra to internal representation

function peek_at_polynomials(polynomials::Vector{T}) where {T}
    if isempty(polynomials)
        __throw_input_not_supported(polynomials, "Input must not be empty")
    end
    R = parent(first(polynomials))
    nvars = AbstractAlgebra.nvars(R)
    ord = if hasmethod(AbstractAlgebra.ordering, Tuple{typeof(R)})
        # if multivariate
        AbstractAlgebra.ordering(R)
    else
        # if univariate, defaults to lex
        :lex
    end
    char = AbstractAlgebra.characteristic(R)
    if char > typemax(UInt)
        __throw_input_not_supported(
            char,
            "The characteristic of the field of input is too large and is not supported, sorry"
        )
    end
    :abstractalgebra, length(polynomials), UInt(BigInt(char)), nvars, ord
end

# Determines the monomial ordering of the output,
# given the original ordering `origord` and the targer ordering `targetord`
ordering_typed2sym(origord, targetord::Lex) = :lex
ordering_typed2sym(origord, targetord::DegLex) = :deglex
ordering_typed2sym(origord, targetord::DegRevLex) = :degrevlex
ordering_typed2sym(origord) = origord
ordering_typed2sym(origord, targetord::AbstractMonomialOrdering) = origord

function ordering_sym2typed(ord::Symbol)
    if !(ord in _AA_supported_orderings_symbols)
        __throw_input_not_supported(ord, "Not a supported ordering.")
    end
    if ord === :lex
        Lex()
    elseif ord === :deglex
        DegLex()
    elseif ord === :degrevlex
        DegRevLex()
    end
end

function extract_ring(polynomials)
    R = parent(first(polynomials))
    T = typeof(R)
    @assert hasmethod(AbstractAlgebra.nvars, Tuple{T})
    @assert hasmethod(AbstractAlgebra.characteristic, Tuple{T})
    nv = AbstractAlgebra.nvars(R)
    # lex is the default ordering on univariate polynomials
    ord = if hasmethod(AbstractAlgebra.ordering, Tuple{T})
        AbstractAlgebra.ordering(R)
    else
        :lex
    end
    # type unstable:
    ordT = ordering_sym2typed(ord)
    ch   = AbstractAlgebra.characteristic(R)
    PolyRing{typeof(ordT)}(nv, ordT, UInt(BigInt(ch)))
end

function extract_coeffs(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    orig_polys::Vector{T}
) where {T}
    npolys = length(orig_polys)
    coeffs = Vector{Vector{representation.coefftype}}(undef, npolys)
    @inbounds for i in 1:npolys
        poly = orig_polys[i]
        coeffs[i] = extract_coeffs(representation, ring, poly)
    end
    coeffs
end

function extract_coeffs(representation::PolynomialRepresentation, ring::PolyRing, orig_poly)
    if ring.ch > 0
        extract_coeffs_ff(representation, ring, orig_poly)
    else
        extract_coeffs_qq(representation, ring, orig_poly)
    end
end

# specialization for univariate polynomials
function extract_coeffs_ff(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    poly::Union{AbstractAlgebra.Generic.Poly, AbstractAlgebra.PolyElem}
)
    iszero(poly) && (return zero_coeffs(representation.coefftype, ring))
    reverse(
        map(
            # NOTE: type instable!
            representation.coefftype ∘ AbstractAlgebra.data,
            filter(!iszero, collect(AbstractAlgebra.coefficients(poly)))
        )
    )
end

# specialization for univariate polynomials
function extract_coeffs_qq(
    representation,
    ring::PolyRing,
    poly::Union{AbstractAlgebra.Generic.Poly, AbstractAlgebra.PolyElem}
)
    iszero(poly) && (return zero_coeffs(representation.coefftype, ring))
    reverse(map(Rational, filter(!iszero, collect(AbstractAlgebra.coefficients(poly)))))
end

# specialization for multivariate polynomials
function extract_coeffs_ff(
    representation::PolynomialRepresentation,
    ring::PolyRing{T},
    poly
) where {T}
    iszero(poly) && (return zero_coeffs(representation.coefftype, ring))
    Ch = representation.coefftype
    # TODO: Get rid of this composed function
    map(Ch ∘ AbstractAlgebra.data, AbstractAlgebra.coefficients(poly))
end

function _is_input_compatible_in_apply(graph, ring, kws)
    # TODO: Check that leading monomials coincide!
    @log level = -7 "" graph.original_ord ring.ord
    if graph.original_ord != ring.ord
        @log level = 1 "Input ordering $(ring.ord) is different from the one used to learn the graph ($(graph.original_ord))"
        return false
    end
    if graph.sweep_output != kws.sweep
        @log level = 1 "Input sweep option ($(kws.sweep)) is different from the one used to learn the graph ($(graph.sweep_output))."
        return false
    end
    @log level = -1 "In groebner_apply! the argument monom=$(kws.monoms) was ignored"
    true
end

function extract_coeffs_raw!(
    graph,
    representation::PolynomialRepresentation,
    polys::Vector{T},
    kws::KeywordsHandler
) where {T}
    # write new coefficients directly to graph.basis
    ring = extract_ring(polys)
    if !_is_input_compatible_in_apply(graph, ring, kws)
        __throw_input_not_supported(
            ring,
            "Input does not seem to be compatible with the learned graph."
        )
    end
    basis = graph.buf_basis
    input_polys_perm = graph.input_permutation
    term_perms = graph.term_sorting_permutations
    homog_term_perm = graph.term_homogenizing_permutations
    CoeffType = representation.coefftype
    _extract_coeffs_raw!(
        basis,
        input_polys_perm,
        term_perms,
        homog_term_perm,
        polys,
        CoeffType
    )
    if graph.homogenize
        @assert length(basis.coeffs[length(polys) + 1]) == 2
        C = eltype(basis.coeffs[length(polys) + 1][1])
        basis.coeffs[length(polys) + 1][1] = one(C)
        basis.coeffs[length(polys) + 1][2] =
            iszero(ring.ch) ? -one(C) : (ring.ch - one(ring.ch))
    end
    @log level = -6 "Extracted coefficients from $(length(polys)) polynomials." basis
    ring
end

function _extract_coeffs_raw!(
    basis,
    input_polys_perm::Vector{Int},
    term_perms::Vector{Vector{Int}},
    homog_term_perms::Vector{Vector{Int}},
    polys,
    ::Type{CoeffsType}
) where {CoeffsType}
    permute_input_terms = !isempty(term_perms)
    permute_homogenizing_terms = !isempty(homog_term_perms)
    @assert basis.nfilled == count(!iszero, polys) + permute_homogenizing_terms
    polys = filter(!iszero, polys)
    @log level = -2 """
    Permuting input terms: $permute_input_terms
    Permuting for homogenization: $permute_homogenizing_terms"""
    @log level = -7 """Permutations:
      Of polynomials: $input_polys_perm
      Of terms (change of ordering): $term_perms
      Of terms (homogenization): $homog_term_perms"""
    for i in 1:length(polys)
        basis_cfs = basis.coeffs[i]
        poly_index = input_polys_perm[i]
        poly = polys[poly_index]
        @assert length(poly) == length(basis_cfs)
        for j in 1:length(poly)
            coeff_index = j
            if permute_input_terms
                coeff_index = term_perms[poly_index][coeff_index]
            end
            if permute_homogenizing_terms
                coeff_index = homog_term_perms[poly_index][coeff_index]
            end
            coeff = AbstractAlgebra.data(AbstractAlgebra.coeff(poly, coeff_index))
            basis_cfs[j] = convert(CoeffsType, coeff)
        end
    end
    nothing
end

# specialization for multivariate polynomials
function extract_coeffs_qq(representation, ring::PolyRing, poly)
    iszero(poly) && (return zero_coeffs(representation.coefftype, ring))
    map(Rational, AbstractAlgebra.coefficients(poly))
end

function get_var_to_index(
    aa_ring::Union{AbstractAlgebra.MPolyRing{T}, AbstractAlgebra.PolyRing{T}}
) where {T}
    Dict{elem_type(aa_ring), Int}(
        AbstractAlgebra.gens(aa_ring) .=> 1:AbstractAlgebra.nvars(aa_ring)
    )
end

function extract_monoms(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    poly::T
) where {T}
    exps = Vector{representation.monomtype}(undef, length(poly))
    @inbounds for j in 1:length(poly)
        exps[j] = construct_monom(
            representation.monomtype,
            AbstractAlgebra.exponent_vector(poly, j)
        )
    end
    exps
end

function extract_monoms(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    poly::P
) where {P <: AbstractAlgebra.Generic.PolyElem}
    exps = Vector{representation.monomtype}(undef, 0)
    @inbounds while !iszero(poly)
        push!(
            exps,
            construct_monom(representation.monomtype, [AbstractAlgebra.degree(poly)])
        )
        poly = AbstractAlgebra.tail(poly)
    end
    exps
end

function extract_monoms(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    orig_polys::Vector{T}
) where {T}
    npolys = length(orig_polys)
    var_to_index = get_var_to_index(AbstractAlgebra.parent(orig_polys[1]))
    exps = Vector{Vector{representation.monomtype}}(undef, npolys)
    @inbounds for i in 1:npolys
        poly = orig_polys[i]
        exps[i] = extract_monoms(representation, ring, poly)
    end
    false, var_to_index, exps
end

function extract_monoms(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    orig_polys::Vector{T},
    ::DegLex
) where {T}
    npolys = length(orig_polys)
    var_to_index = get_var_to_index(AbstractAlgebra.parent(orig_polys[1]))
    exps = Vector{Vector{representation.monomtype}}(undef, npolys)
    for i in 1:npolys
        poly = orig_polys[i]
        exps[i] = Vector{representation.monomtype}(undef, length(poly))
        @inbounds for j in 1:length(poly)
            exps[i][j] =
                construct_monom(representation.monomtype, poly.exps[(end - 1):-1:1, j])
        end
    end
    false, var_to_index, exps
end

function extract_monoms(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    orig_polys::Vector{T},
    ::Lex
) where {T}
    npolys = length(orig_polys)
    var_to_index = get_var_to_index(AbstractAlgebra.parent(orig_polys[1]))
    exps = Vector{Vector{representation.monomtype}}(undef, npolys)
    for i in 1:npolys
        poly = orig_polys[i]
        exps[i] = Vector{representation.monomtype}(undef, length(poly))
        @inbounds for j in 1:length(poly)
            exps[i][j] = construct_monom(representation.monomtype, poly.exps[end:-1:1, j])
        end
    end
    false, var_to_index, exps
end

function extract_monoms(
    representation::PolynomialRepresentation,
    ring::PolyRing,
    orig_polys::Vector{T},
    ::DegRevLex
) where {T}
    npolys = length(orig_polys)
    var_to_index = get_var_to_index(AbstractAlgebra.parent(orig_polys[1]))
    exps = Vector{Vector{representation.monomtype}}(undef, npolys)
    for i in 1:npolys
        poly = orig_polys[i]
        exps[i] = Vector{representation.monomtype}(undef, length(poly))
        @inbounds for j in 1:length(poly)
            exps[i][j] =
                construct_monom(representation.monomtype, poly.exps[1:(end - 1), j])
        end
    end
    false, var_to_index, exps
end

###
# Converting from internal representation to AbstractAlgebra.jl

function _convert_to_output(
    ring::PolyRing,
    polynomials,
    monoms::Vector{Vector{M}},
    coeffs::Vector{Vector{C}},
    params::AlgorithmParameters
) where {M <: Monom, C <: Coeff}
    origring = parent(first(polynomials))
    _convert_to_output(origring, monoms, coeffs, params)
end

# Specialization for univariate polynomials
function _convert_to_output(
    origring::R,
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    params::AlgorithmParameters
) where {
    R <: Union{AbstractAlgebra.Generic.PolyRing, AbstractAlgebra.PolyRing},
    M <: Monom,
    C <: Coeff
}
    ground   = base_ring(origring)
    exported = Vector{elem_type(origring)}(undef, length(gbexps))
    @inbounds for i in 1:length(gbexps)
        if iszero_monoms(gbexps[i])
            exported[i] = origring()
            continue
        end
        cfs = zeros(ground, Int(totaldeg(gbexps[i][1]) + 1))
        for (idx, j) in enumerate(gbexps[i])
            cfs[totaldeg(j) + 1] = ground(gbcoeffs[i][idx])
        end
        exported[i] = origring(cfs)
    end
    exported
end

# The most generic specialization
# (Nemo.jl opts this specialization)
function _convert_to_output(
    origring::R,
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    params::AlgorithmParameters
) where {R, M <: Monom, C <: Coeff}
    nv       = AbstractAlgebra.nvars(origring)
    ground   = base_ring(origring)
    exported = Vector{elem_type(origring)}(undef, length(gbexps))
    @inbounds for i in 1:length(gbexps)
        cfs = map(ground, gbcoeffs[i])
        exps = Vector{Vector{Int}}(undef, length(gbcoeffs[i]))
        for jt in 1:length(gbcoeffs[i])
            exps[jt] = Vector{Int}(undef, nv)
            monom_to_dense_vector!(exps[jt], gbexps[i][jt])
        end
        exported[i] = origring(cfs, exps)
    end
    exported
end

function create_aa_polynomial(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    coeffs::Vector{T},
    exps::Matrix{U}
) where {T, U}
    ground = base_ring(origring)
    if !isempty(coeffs)
        AbstractAlgebra.Generic.MPoly{elem_type(ground)}(origring, coeffs, exps)
    else
        AbstractAlgebra.Generic.MPoly{elem_type(ground)}(origring)
    end
end

function create_aa_polynomial(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    coeffs::Vector{T},
    exps::Vector{Vector{U}}
) where {T, U}
    ground = base_ring(origring)
    if !isempty(coeffs)
        origring(coeffs, exps)
    else
        AbstractAlgebra.Generic.MPoly{elem_type(ground)}(origring)
    end
end

# Dispatch between monomial orderings
function _convert_to_output(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    params::AlgorithmParameters
) where {T, M <: Monom, C <: Coeff}
    ord_aa = AbstractAlgebra.ordering(origring)
    _ord_aa = ordering_sym2typed(ord_aa)
    input_ordering_matches_output = true
    if params.target_ord != _ord_aa
        input_ordering_matches_output = false
        @log level = -1 """
          Basis is computed in $(params.target_ord).
          Terms in the output are in $(ord_aa)"""
    end
    _convert_to_output(
        origring,
        gbexps,
        gbcoeffs,
        params.target_ord,
        Val{input_ordering_matches_output}()
    )
end

# Specialization for degrevlex for matching orderings
function _convert_to_output(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    ::DegRevLex,
    input_ordering_matches_output::Val{true}
) where {T, M <: Monom, C <: Coeff}
    nv       = AbstractAlgebra.nvars(origring)
    ground   = base_ring(origring)
    exported = Vector{elem_type(origring)}(undef, length(gbexps))
    tmp      = Vector{_AA_exponent_type}(undef, nv)
    @inbounds for i in 1:length(gbexps)
        cfs  = map(ground, gbcoeffs[i])
        exps = Matrix{_AA_exponent_type}(undef, nv + 1, length(gbcoeffs[i]))
        for jt in 1:length(gbcoeffs[i])
            # for je in 1:nv
            #     exps[je, jt] = gbexps[i][jt][je]
            # end
            # exps[nv + 1, jt] = gbexps[i][jt][end]
            monom_to_dense_vector!(tmp, gbexps[i][jt])
            for k in 1:length(tmp)
                exps[k, jt] = tmp[k]
            end
            exps[end, jt] = sum(tmp)
        end
        exported[i] = create_aa_polynomial(origring, cfs, exps)
    end
    exported
end

# Specialization for lex for matching orderings
function _convert_to_output(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    ::Lex,
    input_ordering_matches_output::Val{true}
) where {T, M <: Monom, C <: Coeff}
    nv       = AbstractAlgebra.nvars(origring)
    ground   = base_ring(origring)
    exported = Vector{elem_type(origring)}(undef, length(gbexps))
    tmp      = Vector{_AA_exponent_type}(undef, nv)
    @inbounds for i in 1:length(gbexps)
        cfs  = map(ground, gbcoeffs[i])
        exps = Matrix{_AA_exponent_type}(undef, nv, length(gbcoeffs[i]))
        for jt in 1:length(gbcoeffs[i])
            # for je in 1:nv
            #     exps[je, jt] = gbexps[i][jt][nv - je + 1]
            # end
            monom_to_dense_vector!(tmp, gbexps[i][jt])
            exps[end:-1:1, jt] .= tmp
        end
        # exps   = UInt64.(hcat(map(x -> x[end-1:-1:1], gbexps[i])...))
        exported[i] = create_aa_polynomial(origring, cfs, exps)
    end
    exported
end

# Specialization for deglex for matching orderings
function _convert_to_output(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    ::DegLex,
    input_ordering_matches_output::Val{true}
) where {T, M <: Monom, C <: Coeff}
    nv       = AbstractAlgebra.nvars(origring)
    ground   = base_ring(origring)
    exported = Vector{elem_type(origring)}(undef, length(gbexps))
    tmp      = Vector{_AA_exponent_type}(undef, nv)
    @inbounds for i in 1:length(gbexps)
        cfs  = map(ground, gbcoeffs[i])
        exps = Matrix{_AA_exponent_type}(undef, nv + 1, length(gbcoeffs[i]))
        for jt in 1:length(gbcoeffs[i])
            # for je in 1:nv
            #     exps[je, jt] = gbexps[i][jt][nv - je + 1]
            # end
            # exps[nv + 1, jt] = gbexps[i][jt][end]
            monom_to_dense_vector!(tmp, gbexps[i][jt])
            exps[(end - 1):-1:1, jt] .= tmp
            exps[end, jt] = sum(tmp)
        end
        exported[i] = create_aa_polynomial(origring, cfs, exps)
    end
    exported
end

# All other orderings
function _convert_to_output(
    origring::AbstractAlgebra.Generic.MPolyRing{T},
    gbexps::Vector{Vector{M}},
    gbcoeffs::Vector{Vector{C}},
    ord::Ord,
    input_ordering_matches_output
) where {T, M <: Monom, C <: Coeff, Ord <: AbstractMonomialOrdering}
    nv       = AbstractAlgebra.nvars(origring)
    ground   = base_ring(origring)
    exported = Vector{elem_type(origring)}(undef, length(gbexps))
    tmp      = Vector{_AA_exponent_type}(undef, nv)
    @inbounds for i in 1:length(gbexps)
        cfs  = map(ground, gbcoeffs[i])
        exps = Vector{Vector{Int}}(undef, length(gbcoeffs[i]))
        for jt in 1:length(gbcoeffs[i])
            monom_to_dense_vector!(tmp, gbexps[i][jt])
            exps[jt] = tmp
        end
        exported[i] = create_aa_polynomial(origring, cfs, exps)
    end
    exported
end
