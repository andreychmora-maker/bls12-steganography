/* Universal Optimized 2-Isogeny Constants Generator */
p := 1040582850105330743815570414239668597581975900197275493095847470017583224665441180782578049215009464174278151947833029365685675660572997417552727;
Fp := FiniteField(p);

// Arbitrary target parameter
B_target := 1; 
E_target := EllipticCurve([Fp | 0, B_target]);

print "--- 1. Target Curve ---";
printf "E : y^2 = x^3 + %o\n", B_target;

// Find all 2-torsion points (roots of x^3 + B_target = 0)
roots := Roots(PolynomialRing(Fp)!([Fp!B_target, 0, 0, 1]));

if #roots eq 0 then
    print "Error: No 2-torsion points found in this field for the given B_target.";
    quit;
end if;

// Helper function to calculate absolute integer size of a field element
AbsSize := func<x | Integers()!x gt p div 2 select p - Integers()!x else Integers()!x>;

// Dynamically select the root that yields the smallest coefficients
best_x0 := roots[1][1];
min_size := AbsSize(best_x0);

for r in roots do
    current_size := AbsSize(r[1]);
    if current_size lt min_size then
        min_size := current_size;
        best_x0 := r[1];
    end if;
end for;

x0 := best_x0;
// Format for nice negative printing
FormatField := func<x | Integers()!x gt p div 2 select Integers()!x - p else Integers()!x>;

printf "Optimal 2-Torsion point selected: x0 = %o\n", FormatField(x0);

print "\n--- 2. Isogenous Curve Constants (Manual Velu) ---";
t := 3 * x0^2;
A_isog := -5 * t;
B_isog := Fp!B_target - 7 * x0 * t;

printf "A' = %o\n", FormatField(A_isog);
printf "B' = %o\n", FormatField(B_isog);
printf "t  = %o\n", FormatField(t);

printf "\nIsogenous curve E': y^2 = x^3 + (%o)x + (%o)\n", FormatField(A_isog), FormatField(B_isog);
quit;
