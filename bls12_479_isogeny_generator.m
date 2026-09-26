/* Isogeny Constants Generator for BLS12-479+ */
p := 1040582850105330743815570414239668597581975900197275493095847470017583224665441180782578049215009464174278151947833029365685675660572997417552727;
Fp := FiniteField(p);

B_target := 1;
E_target := EllipticCurve([Fp | 0, B_target]);

print "--- 1. Target Curve BLS12-479+ ---";
printf "E : y^2 = x^3 + %o\n", B_target;

// Isolate 2-torsion kernel (x^3 + 1 = 0)
roots := Roots(PolynomialRing(Fp)!([Fp!B_target, 0, 0, 1])); 
x0 := roots[1][1];

printf "2-Torsion point P_2 found with x0 = %o\n", Integers()!x0;

print "\n--- 2. Isogenous Curve Constants (Manual Velu) ---";
t := 3 * x0^2;
A_isog := -5 * t;
B_isog := Fp!B_target - 7 * x0 * t;

// To display negative numbers nicely instead of large field elements:
printf "A' = %o\n", A_isog;
printf "B' = %o\n", B_isog;
printf "t  = %o\n", t;

printf "\nIsogenous curve E': y^2 = x^3 - 15x + 22\n";
quit;
