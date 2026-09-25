/*===============================================================================
   Search for a steganographically optimal BLS12 curve (BLS12+)
   Objective: Find a seed x yielding a BLS12 curve with a cofactor divisible by L,
   while maintaining high pairing speed (sparse Hamming weight).
=================================================================================*/

FindStegoBLS12 := function(start_seed, L, max_hw)
    x := start_seed;
    
    /* Ensure x = 1 mod 3 to guarantee the cofactor is an integer */
    if (x - 1) mod 3 ne 0 then
        x := x + (3 - ((x - 1) mod 3));
    end if;
    
    while true do
        /* G1 cofactor polynomial: h(x) = (x - 1)^2 / 3 */
        h := (x - 1)^2 div 3;
        
        /* [!] NEW FILTER: Cofactor must be divisible by L (isogeny degree) */
        if h mod L eq 0 then
            
            /* Subgroup order polynomial: r(x) = x^4 - x^2 + 1 */
            r := x^4 - x^2 + 1;
            
            /* Field size polynomial: p(x) = h(x)*r(x) + x */
            p := h * r + x; 
            
            /* Check cryptographic suitability (primality) */
            if IsPrime(r) and IsPrime(p) then
                
                /* Evaluate Hamming weight (impacts Miller loop speed) */
                hw := &+[ b : b in Intseq(Abs(x), 2) ];
                
                if hw le max_hw then
                    print "==================================================";
                    print ">> STEGANOGRAPHICALLY OPTIMAL SEED FOUND! <<";
                    print "==================================================";
                    printf "Seed x (Dec)   : %o\n", x;
                    printf "Seed x (Hex)   : %h\n", x;
                    printf "Hamming Weight : %o (Affects pairing speed)\n", hw;
                    printf "Prime p (Dec)  : %o\n", p;
                    printf "Prime p (Hex)  : %h\n", p;
                    printf "Bit length of p: %o\n", Ilog2(p) + 1;
                    printf "Cofactor h     : %o\n", h;
                    printf "Order r        : %o\n", r;
                    printf "Divisible by %o?: %o (Guarantees %o-isogeny)\n", L, h mod L eq 0, L;                 
                    return x;
                end if;
            end if;
        end if;
        
        /* Increment step (must maintain x = 1 mod 3 constraint) */
        x +:= 3; 
    end while;
end function;

/* Execute the search for BLS12: 
   Looking for a curve where the cofactor is strictly even (L = 2), 
   and Hamming weight does not exceed 10.
   Starting with a value near 2^80 to achieve p ~ 479 bits. */
start_val := 2^80; 
optimal_seed := FindStegoBLS12(start_val, 2, 10);
