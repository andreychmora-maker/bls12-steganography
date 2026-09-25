/* Obfus. G2 */
// ---------------------------------------------------------
// 1. Setup BLS12-381 Field and Curves
// ---------------------------------------------------------
p := 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;
assert p mod 4 eq 3;
F := GF(p);
P<z> := PolynomialRing(F);
F2<I> := ExtensionField<F, z | z^2 + 1>;

// Target E: y^2 = x^3 + 4(1+I)
E_target := EllipticCurve([F2| 0, 4*(1+I)]);

// Constants

A_isog := 240*I;
B_isog := 1012*(1+I);

Z := -(2 + I);

q := 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;

Cofactor := 0xbc69f08f2ee75b3584c6a0ea91b352888e2a8e9145ad7689986ff031508ffe1329c2f178731db956d82bf015d1212b02ec0ec69d7477c1ae954cbc06689f6a359894c0adebbf6b4e8020005aaa95551;
Inv3 := 34957250116750793652965160338790643891793701667018425215069105799959054123009;

//2*(1-I)
x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559785*I + 2;
//2*x0
Two_x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559783*I + 4;
//3*x0
Three_x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559781*I + 6;
//x0^2
x0_2 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559779*I;
//3*x0_2
Three_x0_2 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559763*I;
//x0^3
x0_3 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559771*I +
4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559771;

// Isogeny E': y^2 = x^3 + A_isog * x + B_isog
E_isog := EllipticCurve([F2| A_isog, B_isog]);

//=====================================================================
// HELPERS
//=====================================================================

function Sgn0(u)
    seq := ElementToSequence(u);
    u0  := Integers()!seq[1];
    u1  := Integers()!seq[2];
    if u0 ne 0 then return u0 mod 2; else return u1 mod 2; end if;
end function;

function CMOV(a, b, cond)
    if cond then return b; else return a; end if;
end function;

function SqrtRatio(u, v)
    if v eq 0 then return false, 0; end if;
    val := u / v;
    is_sq, root := IsSquare(val);
    if is_sq then
        return true, root;
    else 
        // Forward map twist handling
        return false, Sqrt(Z * val);
    end if;
end function;

//===================================================================
// SSWU FORWARD MAP (RFC 9380)
//===================================================================

function SSWUHash2Point(u)
    tv1 := u^2;
    tv1 := Z * tv1;      // tv1 = W = Z*u^2
    tv2 := tv1^2;
    tv2 := tv2 + tv1;    // tv2 = W^2 + W
    tv3 := tv2 + 1;
    tv3 := B_isog * tv3;
    
    // tv4 = -A * tv2 (handling tv2=0 case)
    tv4 := CMOV(Z, -tv2, tv2 ne 0);
    tv4 := A_isog * tv4;
    
    tv2 := tv3^2;
    tv6 := tv4^2;
    tv5 := A_isog * tv6;
    tv2 := tv2 + tv5;
    tv2 := tv2 * tv3;
    tv6 := tv6 * tv4;
    tv5 := B_isog * tv6;
    tv2 := tv2 + tv5;
    
    x := tv1 * tv3; // x_num
    
    // Check if g(x1) is square. 
    // If not, we are in Twist case (output x2, y2)
    is_gx1_square, y1 := SqrtRatio(tv2, tv6);
    
    y := tv1 * u;
    y := y * y1;
    x := CMOV(x, tv3, is_gx1_square);
    y := CMOV(y, y1, is_gx1_square);
    
    u_sign := Sgn0(u);
    y_sign := Sgn0(y);
    e1 := (u_sign eq y_sign);
    y := CMOV(-y, y, e1);
    
    x := x / tv4; // x_den
    return [x, y]; 
end function;

// ---------------------------------------------------------
// SSWU INVERSION (RFC 9380 Optimized version)
// Handles both the Direct and Twist cases for u and v
// ---------------------------------------------------------

function BasePreimage(P_val)
    X := P_val[1];
    Y := P_val[2];
    //F := Parent(X);

    /* Common denominator for the forward relation: 
    x = -B/A * (1 + 1/(W^2+W))
    */

    denom := -A_isog * X - B_isog;
    if denom eq 0 then return false, F2!0; end if;
    
    // V represents the T = W^2 + W value from the forward map
    V := B_isog / denom;
    
    // --- CASE 1: Direct Mapping (g(x1) was square) ---
    // Relation: W^2 + W - V = 0
    delta1 := 1 + 4*V;
    is_sq1, root1 := IsSquare(delta1);
    
    if is_sq1 then
        // Solve quadratic for W = Z*u^2
        for W in [(-1 + root1)/2, (-1 - root1)/2] do
            if W ne 0 then
                is_sq_u, u_val := IsSquare(W / Z);
                if is_sq_u then
                  // Verify sign: sgn0(u) == sgn0(y)
                  if Sgn0(u_val) ne Sgn0(Y) then
                   u_val := -u_val;
                  end if;
                 return true, u_val;
                end if;
            end if;
        end for;
    end if;

    // --- CASE 2: Twist Mapping (g(x1) was NOT square) ---
    // In this case, X is x2 = Z * u^2 * x1. 
    // Relation results in W^2 + (1-K)W + (1-K) = 0 where K = -AX/B
    K := (-A_isog * X) / B_isog;
    C := 1 - K; 
    delta2 := C^2 - 4*C;
    is_sq2, root2 := IsSquare(delta2);
    
    if is_sq2 then
        for W in [(-C + root2)/2, (-C - root2)/2] do
            if W ne 0 then
                is_sq_u, u_val := IsSquare(W / Z);
                if is_sq_u then

                    /*
                    Verify this u would actually result
                    in a twist path
                    */

                    T := W^2 + W;
                    if T ne 0 then
                        x1  := (-B_isog / A_isog) * (1 + 1/T);
                        gx1 := x1^3 + A_isog * x1 + B_isog;
                        if not IsSquare(gx1) then
                            if Sgn0(u_val) ne Sgn0(Y) then
                             u_val := -u_val; end if;
                            return true, u_val;
                        end if;
                    end if;
                end if;
            end if;
        end for;
    end if;

    return false, F2!0;
end function;

// ---------------------------------------------------------
// OBFUSCATION WRAPPER
// ---------------------------------------------------------

function ObfuscateOnIsog(P_isog)
    
    while true do
        // Generate random u in Fp2
        u := Random(F2);
        
        // Map to P_u
        coords := SSWUHash2Point(u);
        
        // Ensure coords are valid point on curve
        IsOnCurve, P_u := IsPoint(E_isog, coords);
        if IsOnCurve then
            P_v := P_isog - P_u;
            
            // Search for preimage of P_v
            success, v := BasePreimage(P_v);
            
            if success then
                return u, v;
            end if;
        end if;
    end while;
end function;

// ---------------------------------------------------------
// The Backward Map (Dual Isogeny)
// ---------------------------------------------------------
EvaluateBackwardMap := function(P)
    if P eq E_target!0 then return E_isog!0; end if;
    x := P[1]; y := P[2];

    x_2 := x^2;
    x_3 := x^3;
   
    Dx := (x - x0)^2;
    //Dx := x_2-x*Two_x0+x0_2;
​
    if IsZero(Dx) then return E_isog!0; end if;
    Dy := (x - x0)^3;
    //Dy := x_3-x_2*Three_x0+x*Three_x0_2​-x0_3;
​
    Nx := x_3 - Two_x0*x_2 - 56*I*x + 48*(1+I);
    Ny := x_3 - Three_x0*x_2 + 24*I*x + 16*(1+I);

    // Note: We might need to handle a sign flip on Y depending on
    // RFC definition.
    // Standard dual isogeny usually matches up to sign.
    return E_isog![Nx/Dx, y*(Ny/Dy)];
end function;

GetExactPreimage := function(P)
    Q_dual := EvaluateBackwardMap(P);
    //inv3 := InverseMod(3, q);
    return Inv3 * Q_dual;
end function;

// ---------------------------------------------------------
// The Forward Map (RFC 9380 Appendix E.3 Constants)
// ---------------------------------------------------------

// Coefficient Arrays (No line breaks within numbers!)
k_1 := [
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343\
  d9c71c6238aaaaaaaa97d6 +
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a8\
  8b58423c50ae15d5c2638e343d9c71c6238aaaaaaaa97d6*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9c\
  b8d555526a9ffffffffc71a*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9c\
  b8d555526a9ffffffffc71e +
F!0x8ab05f8bdd54cde190937e76bc3e447cc27c3d6fbd7063f\
  cd104635a790520c0a395554e5c6aaaa9354ffffffffe38d*I,
F!0x171d6541fa38ccfaed6dea691f5fb614cb14b4e7f4e810aa22d6108f142b85757098e38d0\
  f671c7188e2aaaaaaaa5ed1
];

k_2 := [
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb\
  153ffffb9feffffffffaa63*I,
F!0xc +
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241ea\
  bfffeb153ffffb9feffffffffaa9f*I
];

k_3 := [
F!0x1530477c7ab4113b59a4c18b076d11930f7da5d4a07f649bf54439d87d27e500fc8c25ebf\
  8c92f6812cfc71c71c6d706 +
F!0x1530477c7ab4113b59a4c18b076d11930f7da5d4a07f649\
  bf54439d87d27e500fc8c25ebf8c92f6812cfc71c71c6d706*I,
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343\
  d9c71c6238aaaaaaaa97be*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9c\
  b8d555526a9ffffffffc71c +
F!0x8ab05f8bdd54cde190937e76bc3e447cc27c3d6fbd7063f\
  cd104635a790520c0a395554e5c6aaaa9354ffffffffe38f*I,
F!0x124c9ad43b6cf79bfbf7043de3811ad0761b0f37a1e26286b0e977c69aa274524e79097a5\
  6dc4bd9e1b371c71c718b10
];

k_4 := [
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb\
  153ffffb9feffffffffa8fb +
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512b\
  f6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffa8fb*I,
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb\
  153ffffb9feffffffffa9d3*I,
F!0x12 + 
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241e\
  abfffeb153ffffb9feffffffffaa99*I
];

EvaluateForwardMap := function(Q)
    if Q eq E_isog!0 then return E_target!0; end if;
    x := Q[1]; 
    y := Q[2];

    x_num := k_1[1] + k_1[2]*x + k_1[3]*x^2 + k_1[4]*x^3;
    x_den := k_2[1] + k_2[2]*x + x^2; // Monic
    y_num := k_3[1] + k_3[2]*x + k_3[3]*x^2 + k_3[4]*x^3;
    y_den := k_4[1] + k_4[2]*x + k_4[3]*x^2 + x^3; // Monic

    return E_target![x_num/x_den, -y * y_num/y_den];
end function;

/*
----------------------------------------------------------------
 RECEIVING END: Reconstructs the point on the target curve
----------------------------------------------------------------
*/

function DeobfuscateAndMapBack(u, v)

/*
   1. Compute Points on E_isog 
   Using IsPoint optimization to safely
   handle the mapping
*/
    coords_u := SSWUHash2Point(u);
    ok_u, P_u := IsPoint(E_isog, coords_u);
    coords_v := SSWUHash2Point(v);
    ok_v, P_v := IsPoint(E_isog, coords_v);
    if not (ok_u and ok_v) then 
    error "Transmission Error: Reconstructed u or v does not map to curve.";
    end if;

    P_sum := P_u + P_v; // Sum points (on E_isog)
/*   
    2. Map to Target Curve
*/
    P_target :=  EvaluateForwardMap(P_sum);    
    return E_target!P_target;
end function;

// ---------------------------------------------------------
// 4. Verification
// ---------------------------------------------------------
//print "\n--- RFC 9380 Compatibility Check ---";

// Generate a valid G2 point
/*
P_in := E_target![311239377245729298639705630879096582513771610094021204\
7461750274430713149704205290193003948471186869462417635945031*I +
    468501228389008053928024403101883933954271108602648340557471649194131935698\
    962329377720844403251861997656247727923,
    901138056545509810716514081486150255194327924327785762188272351723553958849\
    954249958671562633244397095658575999302*I +
    115110429142010975971033108941029327217868417078947234322174444252156474654\
    6688094924008602989686100387087884256314, 1];
*/

/*
----------------------------------------------------------------
Runtime Test
----------------------------------------------------------------
*/
// printf "Target Curve:    %o\n", E_target;
// printf "Isogenous Curve: %o\n", E_isog;

// TRANSMITTING END
printf "--- Transmitting End ---\n";

// Generate a sample point on the isogenous curve

P_in := Cofactor * Random(E_target);
while P_in eq E_target!0 do P_in := Cofactor * Random(E_target);
end while;

print "Random P_in (Target):", P_in;

// Calculate Preimage (Inverse Map)
printf "Map to isogeny...\n";
Q := GetExactPreimage(P_in);
print "Q (Isogeny):", Q;

// Obfuscate it
printf "Obfuscate Q (running \"pick-and-check\")...\n";
u, v := ObfuscateOnIsog(Q);
printf "   Found u: %o\n   Found v: %o\n", u, v;

// Serialization
Data_u := [Integers()!x : x in ElementToSequence(u)];
Data_v := [Integers()!x : x in ElementToSequence(v)];

printf "   Serialized data for u (48+48 bytes): %h, %h\n   Serialized data for v (48+48 bytes): %h, %h\n", Data_u[1], Data_u[2], Data_v[1], Data_v[2];

// Transmit serialized data over insecure channel

printf "\nData transmission over insecure channel...\n";

// RECEIVING END
printf "\n--- Receiving End ---\n";

// Deobfuscate and map to target using hardcoded RFC forward map
printf "Deobfuscate and map to target...\n";

// Convert serialized data back to elements of finite field
u :=F2!Data_u;
v :=F2!Data_v;

P_out := DeobfuscateAndMapBack(u, v);
print "P_out (Deobfuscated):", P_out;

// Strict Identity Verification
if P_out eq P_in then
    print "\nSUCCESS: P_out is IDENTICAL to P_in.";
    print "The derived inverse map is perfectly compatible with the RFC constants.";
elif P_out eq -P_in then
    print "\nSUCCESS (Sign Flip): P_out is -P_in.";
    print "The maps are compatible, but the Y-coordinate sign differs.";
    print "FIX: Change 'y*(Ny/Dy)' to '-y*(Ny/Dy)' in InverseVarPhi().";
else
    print "\nFAILURE: Points do not match.";
end if;

/* Test Vector 1: Random Point in G2

Input Point P (Target Curve)
$y^2=x^3+4(1+i)$

Coordinate	Component	Value (Hex, Big Endian)
P.x	$c_0$(Real)	1832b45cc2d6fc412003a6bd412b7bc5f7711fefeaf37102ed6ae16e138947c2a4996599929122e2c1744135c679da1a
	$c_1$(Imag)	14c7ed7457988de9731d063f2bd6c64f8dc3fe4217cb5b75e904aef478c7c011817353757419f6601ef5fbe4d85e0fdd
P.y	$c_0$(Real)	0673af9f8e34c5683ca009a2a858cba71bfc168b57ab050ffe58a08e19c0ee5fcc6bd108b31cbdf6f1fe9d046c0c0837
	$c_1$(Imag)	1093a72d54edb0c25fd6a0c2fcddb843c3fc116ea698073cf0aa9f5dd213984b346664fe980c460b707223ec696ed14b
*/

/*
Expected Output Q (Source Curve)
$y’^2=x’^3+240ix’+1012(1+i)$

Coordinate	Component	Value (Hex, Big Endian)
Q.x	$c_0$(Real)	1404b3ba3172429748ab89038191883a67afe624c021a43f7ac93dc2059d0e5536cc1ab8259e57717828e6282ceae50c
	$c_1$(Imag)	05873a3804c49ad358ffb56985d7403c577ea0dbd3888720c5ad50666a518805b0319f23a9a170acf5353fdd4b3723a
Q.y	$c_0$(Real)	0dd49698dc7b37ee84b0152867f0f07b9a62276330b673c63a38d37bc19b1751af4d9b11b2148351689e518df640ac98
	$c_1$(Imag)	176c1fc63afbbd2aa7a1a3ec6c1d4f275cb21f74d395ef6b5db84b8f498af684f6ac487ce82a7a8bafa0ecc08ec6e4c1
*/

/* Test Vector 2: Point at Infinity (Identity)
Coordinate	Component	Value (Hex, Big Endian)
P.x	$c_0$(Real)	000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002
	$c_1$(Imag)	1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaa9 $(-2 \pmod p)$
P.y	$c_0$(Real)	0c634af69d66b5398282361732551421008035252814867472098656821262d1406834375b3472052445c1109a066efb
	$c_1$(Imag)	00f07455d491f2479e0a058957438448a30896022e334303867c293674622b37060423c8928c0490800392301934c561
*/

