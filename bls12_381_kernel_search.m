/* Finding the kernel generator on BLS12-381 curve */

/* 1. Setup BLS12-381 Field and Curves */
p := 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512b\
f6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;
Fp := FiniteField(p);

/* The Standard BLS12-381 Curve E (y^2 = x^3 + 4) */
E_target := EllipticCurve([Fp!0, Fp!4]);

/* The Target Isogenous Curve E_acute */
A_isog := 0x144698a3b8e9433d693a02c96d4982b0ea985383ee6\
6a8d8e8981aefd881ac98936f8da0e0f97f5cf428082d584c1d;
B_isog := 0x12e2908d11688030018b12e8753eee3b2016c1f0f24\
f4070a0b9c14fcef35ef55a23215a316ceaa5d1cc48e98e172be0;
E_acute := EllipticCurve([Fp | A_isog, B_isog]);

print "--- Searching for Inverse Kernel (Manual Velu Implementation) ---";

/* 2. Find x-coordinates of order 11 points on Standard BLS12-381 */
psi_11 := DivisionPolynomial(E_target, 11);
roots := Roots(psi_11);

if #roots eq 0 then
    error "No 11-torsion points found over Fp.";
else
    printf "Found %o potential x-coordinates for the kernel.\n", #roots;
end if;

found := false;

/* 3. Iterate through roots */
for r in roots do
    x_val := r[1];
    
    /* Evaluate y^2 = x^3 + 4 */
    rhs := x_val^3 + 4;
    is_sq, y_val := IsSquare(rhs);
    
    if is_sq then
        // Construct the generator point P
        P := E_target![x_val, y_val];
        
        if Order(P) eq 11 then
            // --- MANUAL VELU CALCULATION ---
            /* We need the x-coordinates of the kernel points {P, [2]P, ..., [5]P}
               (The isogeny depends on the subgroup, and x([k]P) = x([-k]P)) */
            
            sum_x_sq := Fp!0;
            sum_term_B := Fp!0;
            
            for i in [1..5] do
                Q := i*P;
                x_Q := Q[1];
                
                /* Accumulate sums for Velu's formulas for E: y^2 = x^3 + 4
                   A_new = A - 5 * Sum(3x^2 + A) -> A=0, so -15 * Sum(x^2) */
                sum_x_sq +:= x_Q^2;
                
                /* B_new = B - 7 * Sum(5x^3 + 3Ax + 2B) -> A=0, B=4, 
                   so Sum(5x^3 + 8) */
                sum_term_B +:= 5*x_Q^3 + 8;
            end for;
            
            /* Calculate coefficients of the isogenous curve E_candidate.
            Note: We multiply sums by 2 because we sum 
            over K\{O} and points come in pairs +/- */
        
            /* A' = A - 5 * (2 * Sum(3x^2)) = -30 * sum_x_sq */
            A_candidate := -30 * sum_x_sq;
            
            /* B' = B - 7 * (2 * Sum(5x^3 + 8)) = 4 - 14 * sum_term_B */
            B_candidate := 4 - 14 * sum_term_B;
            
            /* Create the candidate curve */
            E_candidate := EllipticCurve([Fp | A_candidate, B_candidate]);
            
            /* 4. Check if this curve is isomorphic to your target E_acute */
            if IsIsomorphic(E_candidate, E_acute) then
                print "\n>> MATCH FOUND!";
                print "The kernel generator P on BLS12-381 is:";
                printf "x: %o\n", P[1];
                printf "y: %o\n", P[2];
                assert 11*P eq E_target!0;
                
                found := true;
                break;
            end if;
        end if;
    end if;
end for;

if not found then
    print "No matching isogeny found.";
end if;
