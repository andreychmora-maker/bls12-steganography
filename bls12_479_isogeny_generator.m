/* Generator of 2-isogeny constants for BLS12-479+ */

// 1. Core Parameters
p := 1040582850105330743815570414239668597581975900197275493095847470017583224665441180782578049215009464174278151947833029365685675660572997417552727;
r := 2135987035920910082424725939022606311951813826328944970011055391196968409943322276941101673173241;
h := 487167212443634306071281548434774787746726967628;
N := h * r; // Group Order

Fp := FiniteField(p);
PolyRing<x> := PolynomialRing(Fp);

print "--- 1. Locating Target Curve BLS12-479+ ---";
B_target := 0;
E_target := EllipticCurve([Fp | 0, 1]); // Placeholder

// Search for the correct B parameter (usually small integer for j=0 curves)
for B in [1, 2, 3, 4, 5, 6, 7, 8, -1, -2, -3, -4, -5, -6, -7, -8] do
    E_cand := EllipticCurve([Fp | 0, Fp!B]);
    
    // Quick probabilistic check: N * P == O
    P := Random(E_cand);
    if N * P eq E_cand!0 then
        // Verify it's not a subgroup by checking r * P
        if r * P ne E_cand!0 then
            E_target := E_cand;
            B_target := B;
            break;
        end if;
    end if;
end for;

printf "Found target curve E: y^2 = x^3 + %o\n", B_target;

print "\n--- 2. Isolating 2-Torsion Kernel ---";
// The x-coordinate of the 2-torsion point is a root of x^3 + B = 0
roots := Roots(x^3 + Fp!B_target);
if #roots eq 0 then
    error "No 2-torsion points found. Cofactor might not guarantee Fp-rational 2-torsion for this twist.";
end if;

x0 := roots[1][1];
P2 := E_target ! [x0, 0];
printf "2-Torsion point P_2 found with x0 = \n0x%h\n", Integers()!x0;

print "\n--- 3. Constructing 2-Isogeny ---";
// Let Magma compute the isogenous curve E' and the rational map
E_isog, isog_map := Isogeny(E_target, P2);

A_isog := aInvariants(E_isog)[4];
B_isog := aInvariants(E_isog)[5];

printf "Isogenous curve E': y^2 = x^3 + A'x + B'\n";
printf "A' = 0x%h\n", Integers()!A_isog;
printf "B' = 0x%h\n", Integers()!B_isog;

print "\n--- 4. Explicit Rational Mapping (Vélu for Obfuscation) ---";
t := 3 * x0^2;
printf "Precomputed constant t = 3*(x0)^2 = \n0x%h\n", Integers()!t;

print "\nForward Map (E -> E'):";
print "x' = x + t / (x - x0)";
print "y' = y - y * t / (x - x0)^2";
