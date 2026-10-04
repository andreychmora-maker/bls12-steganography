/* ===============================================================================
   Universal B-parameter finder for any BLS12 curve
   Objective: Find the optimal B parameter for the curve equation y^2 = x^3 + B
================================================================================= */

function FindBLS12B(x)
    /* BLS12 polynomials */
    h := (x - 1)^2 div 3;
    r := x^4 - x^2 + 1;
    p := h * r + x;
    
    /* Expected order of the BLS12 curve: n = p + 1 - t, where t = x + 1 */
    target_order := p - x; 
    
    Fp := GaloisField(p);
    
    printf "Searching for optimal B parameter for seed x = %o...\n", x;
    
    for B_val in [1..100] do
        /* Check positive B */
        E := EllipticCurve([Fp | 0, B_val]);
        P := Random(E);
        if target_order * P eq E!0 then
            return B_val;
        end if;
        
        /* Check negative B */
        E_neg := EllipticCurve([Fp | 0, -B_val]);
        P_neg := Random(E_neg);
        if target_order * P_neg eq E_neg!0 then
            return -B_val;
        end if;
    end for;
    
    return 0; /* Not found within range */
end function;

/* ===============================================================================
   Execution: Find B for the BLS12-539 curve (steganographically optimal seed)
================================================================================= */
seed_val := 1237940039285380274899137265;
B_opt := FindBLS12B(seed_val);

printf "==================================================\n";
printf "Optimal B parameter : %o\n", B_opt;
printf "==================================================\n";
