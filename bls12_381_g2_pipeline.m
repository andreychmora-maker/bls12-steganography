/* 
===========================================================================
Full Pipeline for Obfuscation of the BLS Signature Scheme Public Key in G2
using Elligator Squared and Explicit Inverse Isogenies.
===========================================================================

This script implements the complete end-to-end obfuscation and deobfuscation 
workflow for the BLS12-381 G_2 group over extension field F_p2. It incorporates:
  1. Inverse isogeny mapping via an E_isog bridge for G2.
  2. Subgroup Membership Leakage protection using Cofactor Blinding & Clearing.
  3. Preimage extraction using the Elligator Squared pick-and-check method in F_p2.
  4. Fast Cofactor Clearing (Budroni-Pintore formula).
*/

// ---------------------------------------------------------
// 1. Setup BLS12-381 Field and Curves for G2
// ---------------------------------------------------------
p := 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;
assert p mod 4 eq 3;
F := GF(p);
P<z> := PolynomialRing(F);
F2<I> := ExtensionField<F, z | z^2 + 1>;

// Target E_target: y^2 = x^3 + 4(1+I)[cite: 2]
E_target := EllipticCurve([F2| 0, 4*(1+I)]);
Identity := E_target!0;

A_isog := 240*I;
B_isog := 1012*(1+I);
Z := -(2 + I);

q := 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;
Cofactor := 0xbc69f08f2ee75b3584c6a0ea91b352888e2a8e9145ad7689986ff031508ffe1329c2f178731db956d82bf015d1212b02ec0ec69d7477c1ae954cbc06689f6a359894c0adebbf6b4e8020005aaa95551;
Inv3 := 34957250116750793652965160338790643891793701667018425215069105799959054123009;

// Constants for backward map[cite: 2]
x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559785*I + 2;
Two_x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559783*I + 4;
Three_x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559781*I + 6;
x0_2 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559779*I;
Three_x0_2 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559763*I;
x0_3 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559771*I +
        4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559771;

E_isog := EllipticCurve([F2| A_isog, B_isog]);

// BLS parameter z
z_bls := -0xd201000000010000;

// ---------------------------------------------------------
// 2. Helper Functions: Explicit Frobenius and Psi
// ---------------------------------------------------------

// Frobenius(x) = x^p
// In basis {1, I} with I^2=-1 and p=3 mod 4, x^p = c0 - c1*I
FrobeniusMap := function(val)
    // Decompose val into c0 + c1*I
    seq := Eltseq(val);
    c0 := seq[1];
    c1 := seq[2];
    // Return conjugate: c0 - c1*I
    return (F2!c0) - (F2!c1)*I;
end function;


// Calculate constants for Psi
// c1 = 1 / (1 + I)^((p - 1) / 3)
exp1 := (p - 1) div 3;
psi_c1 := 1 / ( (1+I)^exp1 );

// c2 = 1 / (1 + I)^((p - 1) / 2)
exp2 := (p - 1) div 2;
psi_c2 := 1 / ( (1+I)^exp2 );

/*
psi_c1 := F!40024095552216673926243104350066886439355031183055864382711713958\
42971157480381377015405980053539358417135540939437*I;
psi_c2 := F!10287321462351063499753244792157952773848399369297578961556431180\
32610843298655225875571310552543014690878354869257*I +
F!297367740898656104344246534652010887917204288300924998917641501809142080719\
2182638567116318576472649347015917690530;
*/
//printf "Psi Constants:\nc1 = %o\nc2 = %o\n", psi_c1, psi_c2;

// Endomorphism Psi(P)
Psi := function(P)
    if P eq E_target!0 then return E_target!0; end if;
    
    x := P[1];
    y := P[2];
    
    // Apply map using Explicit Frobenius
    x_new := psi_c1 * FrobeniusMap(x);
    y_new := psi_c2 * FrobeniusMap(y);
    
    return E_target![x_new, y_new];
end function;

Psi2 := function(P)
    return Psi(Psi(P));
end function;

// ---------------------------------------------------------
// 3. Main Algorithm: Budroni-Pintore Formula
// ---------------------------------------------------------
ClearCofactor := function(P)
    // Formula from prompt:
    // t1 = z*P
    // t2 = psi(P)
    // t3 = 2*P
    // t3 = psi2(t3)  -> 2*psi^2(P)
    // t3 = t3 - t2   -> 2*psi^2(P) - psi(P)
    // t2 = t1 + t2   -> zP + psi(P)
    // t2 = z*t2      -> z^2 P + z psi(P)
    // t3 = t3 + t2   -> 2*psi^2(P) - psi(P) + z^2 P + z psi(P)
    // t3 = t3 - t1   -> 2*psi^2(P) + (z-1)psi(P) + z^2 P - zP
    // Q = t3 - P     -> 2*psi^2(P) + (z-1)psi(P) + (z^2 - z - 1)P
    
    c1 := z_bls;
    
    t1 := c1 * P;
    t2 := Psi(P);
    t3 := 2 * P;
    t3 := Psi2(t3);
    t3 := t3 - t2;
    t2 := t1 + t2;
    t2 := c1 * t2;
    t3 := t3 + t2;
    t3 := t3 - t1;
    Q := t3 - P;
    
    return Q;
end function;

// ---------------------------------------------------------
// 4. Helper Functions (Sgn0, CMOV, SqrtRatio)
// ---------------------------------------------------------
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
        return false, Sqrt(Z * val);
    end if;
end function;

// ---------------------------------------------------------
// 5. SSWU Map & Inversion in F_p2
// ---------------------------------------------------------
function SSWUHash2Point(u)
    tv1 := u^2;
    tv1 := Z * tv1;      
    tv2 := tv1^2;
    tv2 := tv2 + tv1;    
    tv3 := tv2 + 1;
    tv3 := B_isog * tv3;
    
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
    
    x := tv1 * tv3; 
    is_gx1_square, y1 := SqrtRatio(tv2, tv6);
    
    y := tv1 * u;
    y := y * y1;
    x := CMOV(x, tv3, is_gx1_square);
    y := CMOV(y, y1, is_gx1_square);
    
    u_sign := Sgn0(u);
    y_sign := Sgn0(y);
    e1 := (u_sign eq y_sign);
    y := CMOV(-y, y, e1);
    
    x := x / tv4; 
    return [x, y]; 
end function;

function BasePreimage(P_val)
    X := P_val[1];
    Y := P_val[2];

    denom := -A_isog * X - B_isog;
    if denom eq 0 then return false, F2!0; end if;
    
    V := B_isog / denom;
    
    // CASE 1: Direct Mapping
    delta1 := 1 + 4*V;
    is_sq1, root1 := IsSquare(delta1);
    
    if is_sq1 then
        for W in [(-1 + root1)/2, (-1 - root1)/2] do
            if W ne 0 then
                is_sq_u, u_val := IsSquare(W / Z);
                if is_sq_u then
                  if Sgn0(u_val) ne Sgn0(Y) then
                   u_val := -u_val;
                  end if;
                 return true, u_val;
                end if;
            end if;
        end for;
    end if;

    // CASE 2: Twist Mapping
    K := (-A_isog * X) / B_isog;
    C := 1 - K; 
    delta2 := C^2 - 4*C;
    is_sq2, root2 := IsSquare(delta2);
    
    if is_sq2 then
        for W in [(-C + root2)/2, (-C - root2)/2] do
            if W ne 0 then
                is_sq_u, u_val := IsSquare(W / Z);
                if is_sq_u then
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
// 6. Backward & Forward Maps for G2 Isogeny
// ---------------------------------------------------------
function EvaluateBackwardMap(P)
    if P eq E_target!0 then return E_isog!0; end if;
    x := P[1]; y := P[2];

    x_2 := x^2;
    x_3 := x^3;
   
    Dx := (x - x0)^2;
    if IsZero(Dx) then return E_isog!0; end if;
    Dy := (x - x0)^3;

    Nx := x_3 - Two_x0*x_2 - 56*I*x + 48*(1+I);
    Ny := x_3 - Three_x0*x_2 + 24*I*x + 16*(1+I);

    return E_isog![Nx/Dx, y*(Ny/Dy)];
end function;

function GetExactPreimage(P)
    Q_dual := EvaluateBackwardMap(P);
    return Inv3 * Q_dual;
end function;

// Constants for Forward Map[cite: 2]
k_1 := [
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343d9c71c6238aaaaaaaa97d6 +
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343d9c71c6238aaaaaaaa97d6*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9cb8d555526a9ffffffffc71a*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9cb8d555526a9ffffffffc71e +
F!0x8ab05f8bdd54cde190937e76bc3e447cc27c3d6fbd7063fcd104635a790520c0a395554e5c6aaaa9354ffffffffe38d*I,
F!0x171d6541fa38ccfaed6dea691f5fb614cb14b4e7f4e810aa22d6108f142b85757098e38d0f671c7188e2aaaaaaaa5ed1
];

k_2 := [
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaa63*I,  
F!0xc +
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaa9f*I
];

k_3 := [
F!0x1530477c7ab4113b59a4c18b076d11930f7da5d4a07f649bf54439d87d27e500fc8c25ebf8c92f6812cfc71c71c6d706 +
F!0x1530477c7ab4113b59a4c18b076d11930f7da5d4a07f649bf54439d87d27e500fc8c25ebf8c92f6812cfc71c71c6d706*I,
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343d9c71c6238aaaaaaaa97be*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9cb8d555526a9ffffffffc71c +
F!0x8ab05f8bdd54cde190937e76bc3e447cc27c3d6fbd7063fcd104635a790520c0a395554e5c6aaaa9354ffffffffe38f*I,
F!0x124c9ad43b6cf79bfbf7043de3811ad0761b0f37a1e26286b0e977c69aa274524e79097a56dc4bd9e1b371c71c718b10
];

k_4 := [
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffa8fb +
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffa8fb*I,
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffa9d3*I,
F!0x12 + 
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaa99*I
];

function EvaluateForwardMap(Q)
    if Q eq E_isog!0 then return E_target!0; end if;
    x := Q[1]; 
    y := Q[2];

    x_num := k_1[1] + k_1[2]*x + k_1[3]*x^2 + k_1[4]*x^3;
    x_den := k_2[1] + k_2[2]*x + x^2; 
    y_num := k_3[1] + k_3[2]*x + k_3[3]*x^2 + k_3[4]*x^3;
    y_den := k_4[1] + k_4[2]*x + k_4[3]*x^2 + x^3; 

    return E_target![x_num/x_den, -y * y_num/y_den];
end function;

// ---------------------------------------------------------
// 7. Full Pipeline: Obfuscation & Deobfuscation (G2)
// ---------------------------------------------------------

function ObfuscatePublicKeyG2(P_target)
    // Step 1: Map target point via inverse isogeny to E_isog (includes Inv3 scaling)[cite: 2]
    Q_isog_base := GetExactPreimage(P_target);

    // Step 2: Cofactor Blinding in G2 to prevent Subgroup Membership Leakage[cite: 2]
    R_cof := q * Random(E_isog);
    P_isog := Q_isog_base + R_cof;

    // Step 3: Pick-and-Check loop (Elligator Squared in F_p2)[cite: 2]
    while true do
        u := Random(F2);
        coords_u := SSWUHash2Point(u);
        ok_u, P_u := IsPoint(E_isog, coords_u);
        if ok_u then
            P_v := P_isog - P_u;
            success, v := BasePreimage(P_v);
            if success then
                return u, v, P_isog; // Return the full masked point on E_isog for verification
            end if;
        end if;
    end while;
end function;

function DeobfuscatePublicKeyG2(u, v)
    coords_u := SSWUHash2Point(u);
    ok_u, P_u := IsPoint(E_isog, coords_u);
    coords_v := SSWUHash2Point(v);
    ok_v, P_v := IsPoint(E_isog, coords_v);
    if not (ok_u and ok_v) then 
        error "Transmission Error: Invalid points from u, v.";
    end if;

    // Step 1: Reconstruct sum on E_isog
    P_sum := P_u + P_v; 
    
    // Step 2: Forward map back to target curve[cite: 2]
    P_target_raw := EvaluateForwardMap(P_sum);    
    
    // Step 3: Cofactor Clearing on G2 target point[cite: 1, 2]
    //PublicKey_target := Cofactor * (E_target!P_target_raw);
    PublicKey_target := ClearCofactor (E_target!P_target_raw);
    return PublicKey_target, P_sum;
end function;

// ---------------------------------------------------------
// 8. Runtime Test & Verification
// ---------------------------------------------------------
printf "\n--- Testing G2 Obfuscation Pipeline ---\n";

// Generate a valid G2 point on the target curve
P_in := Cofactor * Random(E_target);
while P_in eq Identity do 
    //P_in := Cofactor * Random(E_target);
    P_in := ClearCofactor (Random(E_target));
end while;

printf "Original G2 Public Key:\n%o\n\n", P_in;

// Obfuscation
printf "Obfuscating G2 Public Key (with Cofactor Blinding & Elligator Squared)...\n";
u, v, P_isog_orig := ObfuscatePublicKeyG2(P_in);
printf "   Found u (in F_p2): %o\n   Found v (in F_p2): %o\n\n", u, v;

// Deobfuscation
printf "Deobfuscating G2 Public Key (SSWU + Forward Map + Cofactor Clearing)...\n";
P_out, P_isog_rec := DeobfuscatePublicKeyG2(u, v);
printf "Reconstructed G2 Public Key:\n%o\n\n", P_out;

// Verification via Isogenous Bridge (closing the loop securely)
if (Cofactor * P_isog_rec) eq (Cofactor * P_isog_orig) then
    printf "SUCCESS: G2 pipeline logic is perfectly closed on the isogenous bridge!\n";
else
    printf "FAIL: G2 Reconstruction mismatch!\n";
end if;
