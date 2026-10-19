/* FCC G2 */
/* Fast Cofactor Clearing in RFC 9380 BLS12-381 G2 */
// ---------------------------------------------------------
// 1. Setup BLS12-381 G2 Parameters
// ---------------------------------------------------------
p := 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;
F := GF(p);
P<t> := PolynomialRing(F);
F2<I> := ExtensionField<F, t | t^2 + 1>; // I^2 = -1

// Curve E: y^2 = x^3 + 4(1+I)
B := 4*(1+I);
E := EllipticCurve([F2| 0, B]);

// Group Order r
q := 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;

Cofactor := 0xbc69f08f2ee75b3584c6a0ea91b352888e2a8e9145ad7689986ff031508ffe\
1329c2f178731db956d82bf015d1212b02ec0ec69d7477c1ae954cbc06689f6a359894c0adeb\
bf6b4e8020005aaa95551;

// BLS parameter z
z_bls := -0xd201000000010000;

print "=========================================";
print "   BLS12-381 G2 Cofactor Clearing        ";
print "=========================================";

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

/*
// Calculate constants for Psi
// c1 = 1 / (1 + I)^((p - 1) / 3)
exp1 := (p - 1) div 3;
psi_c1 := 1 / ( (1+I)^exp1 );

// c2 = 1 / (1 + I)^((p - 1) / 2)
exp2 := (p - 1) div 2;
psi_c2 := 1 / ( (1+I)^exp2 );
*/

psi_c1 := F!40024095552216673926243104350066886439355031183055864382711713958\
42971157480381377015405980053539358417135540939437*I;
psi_c2 := F!10287321462351063499753244792157952773848399369297578961556431180\
32610843298655225875571310552543014690878354869257*I +
F!297367740898656104344246534652010887917204288300924998917641501809142080719\
2182638567116318576472649347015917690530;

//printf "Psi Constants:\nc1 = %o\nc2 = %o\n", psi_c1, psi_c2;

// Endomorphism Psi(P)
Psi := function(P)
    if P eq E!0 then return E!0; end if;
    
    x := P[1];
    y := P[2];
    
    // Apply map using Explicit Frobenius
    x_new := psi_c1 * FrobeniusMap(x);
    y_new := psi_c2 * FrobeniusMap(y);
    
    return E![x_new, y_new];
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
// 4. Verification
// ---------------------------------------------------------
print "\n--- Verification ---";

P_rand := Random(E);
while P_rand eq E!0 do P_rand := Random(E); end while;

printf "Input P (random):\n%o\n", P_rand;

P_fast := ClearCofactor(P_rand); //Fast cofactor clearing

printf "\nOutput P_fast (fast cofactor clearing):\n%o\n", P_fast;

// Check 1: G2 Membership
/*
if (q * P_fast) eq E!0 then
    print "SUCCESS: P_fast is in subgroup G2 (q * P_fast = 0).";
else
    print "FAILURE: P_fast is NOT in subgroup G2.";
end if;
*/

P_slow := Cofactor * P_rand; //Slow cofactor clearing

printf "\nOutput P_slow (ordinary cofactor clearing):\n%o\n", P_slow;

if (P_slow eq P_fast) and ((q * P_fast) eq E!0) \
and ((q * P_slow) eq E!0) then
  print "\nP_fast = P_slow and q * P_fast, q * P_slow \
are in subgroup G2.";
  //P_tmp; Q_out;
  else
    print "FAILURE: P_fast and P_slow are NOT in subgroup G2.";
end if;

// Check 2: Verify against explicit formula sum
// Q = (z^2 - z - 1)P + (z - 1)psi(P) + 2 psi^2(P)
print "\nVerifying logic consistency...";
Term1 := (z_bls^2 - z_bls - 1) * P_rand;
Term2 := (z_bls - 1) * Psi(P_rand);
Term3 := 2 * Psi2(P_rand);

P_formula := Term1 + Term2 + Term3;

if P_fast eq P_formula then
    print "SUCCESS: Procedure matches standard Budroni-Pintore formula.";
else
    print "FAILURE: Logic mismatch.";
    print "Formula:", P_formula;
    print "Steps:  ", P_fast;
end if;
quit;
