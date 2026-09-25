/* Obfuscation of the public key of BLS signature scheme 
using Elligator Squared. */
/*
In Ethereum 2.0 (Eth2 for short), BLS public keys are elliptic curve points from the BLS12-381 G_1 group, thus are 48 bytes long when compressed.
Public key serves as both the unique identity of the validator and the means of cryptographically verifying messages purporting to have been signed by it. The public key is stored raw, unlike in Eth1, where it is hashed to form the account address. This allows public keys to be aggregated for verifying aggregated attestations.
To verify a signature we need to know the public key of the validator that signed it. Every validator's public key is stored in the beacon state and can be simply looked up via the validator's index which, by design, is always available by some means whenever it's required.
Signature verification can be treated as a black-box: we send the message, the public key, and the signature to the verifier; if after some cryptographic magic the signature matches both the public key and the message then we declare it valid. Otherwise, either the signature is corrupt, the incorrect secret key was used, or the message is not what was signed.
To verify an aggregate signature, we need an aggregate public key. As long as we know exactly which validators signed the original message, this is equally easy to construct. Once again, we simply "add up" the public keys of the signers. This time the addition is the group operation of the G_1 elliptic curve group, and the result will also be a member of the G_1 group, so it is mathematically indistinguishable from a non-aggregated public key, and has the same 48 byte size. So aggregation of public keys is simply group addition in the G_1 group.
The reason why public key certificates are not used in the field of cryptocurrencies described in this publication (in Russian):
https://habr.com/ru/articles/651373/
*/

// The prime field for BLS12-381 (381 bits, prime)
p :=0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfff\
eb153ffffb9feffffffffaaab; 

z := -0xd201000000010000;
assert p eq z + (z^4 - z^2 + 1)*(z - 1)^2 / 3;
assert p mod 4 eq 3;

Cofactor := 0x396c8c005555e1568c00aaab0000aaab;
assert Cofactor eq (z - 1)^2 / 3;

 // Subgroup Order (255 bits, prime)
q := 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;
/*
524358751751261904794477405081859658376905525005276378226036586999385811\
84513;
*/
assert q eq (z^4 - z^2 + 1); 

Fp := FiniteField(p);
E_target := EllipticCurve([Fp | 0, 4]);  // The target curve E1: y^2 = x^3 + 4
Identity := E_target!0;
/*
G_target := E_target![3782899677407369731768974123304053494906485590974740018\
252129477145021563287086334800525172514660041056416990368067,8002164755441504\
80085660525456722194361055617050839334227594389928838305480984436087520610115\
833565668908616677533];
*/
G_target := E_target![0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3\
a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb,0x08b3f481e3aaa0f1a09e30ed741d8ae\
4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1];
assert (G_target in E_target) and (G_target ne Identity)\
and (q * G_target eq Identity);

/*
----------------------------------------------------------------
The curve given by y'^2 = g'(x') = x'^3 + A' x' + B' is isogenous 
to the target curve BLS12-381
----------------------------------------------------------------
*/
A_isog := 0x144698a3b8e9433d693a02c96d4982b0ea985383ee66a8d8e8981aefd881a\
c98936f8da0e0f97f5cf428082d584c1d;
B_isog := 0x12e2908d11688030018b12e8753eee3b2016c1f0f24f4070a0b9c14fcef35ef55\
a23215a316ceaa5d1cc48e98e172be0;

// The isogenous curve E_isog:y'^2 = x'^3 + A' x' + B'
E_isog := EllipticCurve([Fp | A_isog, B_isog]);

/*
N := #E_isog;
factors := Factorization(N);
Order_isog := factors[#factors][1];
Cofactor_isog := N div Order_isog;
Cofactor_isog; Order_isog; quit;

assert (Cofactor_isog eq Cofactor) and (Order_isog eq q)\
and (Identity eq E_isog!0);

G_isog := Random(E_isog);
while G_isog eq Identity do
    G_isog := Random(E_isog);
end while;
G_isog := Cofactor * G_isog;
assert (G_isog in E_isog) and (G_isog ne Identity)\
and (q * G_isog eq Identity);
G_isog; quit;
*/

G_isog := E_isog![656268161649936061791969884448485380572551559269404089448198102680776798888016\
175464363221882352079391703221334317, 1099036121931759354786502284943334593989\
739044777464086799860844140237699791402776726687163810855883769140994926851];
assert (G_isog in E_isog) and (G_isog ne Identity)\
and (q * G_isog eq Identity);

//Poly<x> := PolynomialRing(Fp);
//g := x^3+A_isog*x+B_isog;

/*
----------------------------------------------------------------
Constants
----------------------------------------------------------------
*/
Z := Fp!11;
assert JacobiSymbol(Integers()!Z, p) eq -1;

Const1 :=  Integers()!((p - 3) / 4);     // Integer arithmetic
Const2 :=  Sqrt(-Z);

function CMOV(Arg1, Arg2, Arg3)
  if not Arg3 then return Arg1; else return Arg2; end if;
end function;

function sqrt_ratio_3mod4(u, v)
/*
Parameters: F, a finite field of characteristic p and subgroup of order q, where p = 3 mod 4. - Z, the constant from the Simplified SWU map.
Input: u and v, elements of F, where v != 0.
Output: (b, y), where  b = True and y = sqrt(u / v) if (u / v) is square in F, and  b = False and y = sqrt(Z * (u / v)) otherwise.
*/
// Procedure:
  tv1 := v^2;
  tv2 := u * v;
  tv1 := tv1 * tv2;
  y1 := tv1^Const1;
  y1 := y1 * tv2;
  y2 := y1 * Const2;
  tv3 := y1^2;
  tv3 := tv3 * v;
  isQR := tv3 eq u;
  y := CMOV(y2, y1, isQR);
  return isQR, y;
end function;

/*
----------------------------------------------------------------
This function returns either 0 or 1 indicating the "sign" of x,
where LSB_Sign(x) == 1 just when x is "negative".
(In other words, this function always considers 0 to be positive.)
---------------------------------------------------------------- 
*/
function LSB_Sign(x)
    return x mod 2;
end function;

/*
----------------------------------------------------------------
SSWU Forward Map (u -> P_isog)
---------------------------------------------------------------- 
*/
function SSWUHash2Point(u)
  // Optimized, straight-line procedure 
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
  is_gx1_square, y1 := sqrt_ratio_3mod4(tv2, tv6);
  y := tv1 * u;
  y := y * y1;
  x := CMOV(x, tv3, is_gx1_square); 
  y := CMOV(y, y1, is_gx1_square);
  e1 := LSB_Sign(Integers()!u) eq LSB_Sign(Integers()!y);
  y := CMOV(-y, y, e1);
  x := x / tv4;
  return [x, y];
end function;

/*
---------------------------------------------------------------
11-Isogeny Map for BLS12-381 G1
---------------------------------------------------------------
*/
// k_(1,0), k_(1,1), k_(1,2), k_(1,3), k_(1,4), k_(1,5), k_(1,6), k_(1,7), 
// k_(1,8), k_(1,9), k_(1,10), k_(1,11)
k1 := [
0x11a05f2b1e833340b809101dd99815856b303e88a2d7005ff2627b56cdb4e2c85610c2\
d5f2e62d6eaeac1662734649b7, 
0x17294ed3e943ab2f0588bab22147a81c7c17e75b2f6a8417f565e33c70d1e86b4838f2a\
6f318c356e834eef1b3cb83bb,
0xd54005db97678ec1d1048c5d10a9a1bce032473295983e56878e501ec68e25c958c3e3\
d2a09729fe0179f9dac9edcb0,
0x1778e7166fcc6db74e0609d307e55412d7f5e4656a8dbf25f1b33289f1b330835336e25\
ce3107193c5b388641d9b6861,
0xe99726a3199f4436642b4b3e4118e5499db995a1257fb3f086eeb65982fac18985a286f\
301e77c451154ce9ac8895d9,
0x1630c3250d7313ff01d1201bf7a74ab5db3cb17dd952799b9ed3ab9097e68f90a0870d\
2dcae73d19cd13c1c66f652983,
0xd6ed6553fe44d296a3726c38ae652bfb11586264f0f8ce19008e218f9c86b2a8da25128\
c1052ecaddd7f225a139ed84,
0x17b81e7701abdbe2e8743884d1117e53356de5ab275b4db1a682c62ef0f2753339b7c\
8f8c8f475af9ccb5618e3f0c88e,
0x80d3cf1f9a78fc47b90b33563be990dc43b756ce79f5574a2c596c928c5d1de4fa295f29\
6b74e956d71986a8497e317,
0x169b1f8e1bcfa7c42e0c37515d138f22dd2ecb803a0c5c99676314baf4bb1b7fa3190b2\
edc0327797f241067be390c9e,
0x10321da079ce07e272d8ec09d2565b0dfa7dccdde6787f96d50af36003b14866f69b7\
71f8c285decca67df3f1605fb7b,
0x6e08c248e260e70bd1e962381edee3d31d79d7e22c837bc23c0bf1bc24c6b68c24b1b\
80b64d391fa9c8ba2e8ba2d229
];

// k_(2,0), k_(2,1), k_(2,2), k_(2,3), k_(2,4), k_(2,5), k_(2,6), 
// k_(2,7), k_(2,8), k_(2,9)
k2 := [
0x8ca8d548cff19ae18b2e62f4bd3fa6f01d5ef4ba35b48ba9c9588617fc8ac62b558d681\
be343df8993cf9fa40d21b1c,
0x12561a5deb559c4348b4711298e536367041e8ca0cf0800c0126c2588c48bf5713daa8\
846cb026e9e5c8276ec82b3bff,
0xb2962fe57a3225e8137e629bff2991f6f89416f5a718cd1fca64e00b11aceacd6a3d0967\
c94fedcfcc239ba5cb83e19,
0x3425581a58ae2fec83aafef7c40eb545b08243f16b1655154cca8abc28d6fd04976d524\
3eecf5c4130de8938dc62cd8,
0x13a8e162022914a80a6f1d5f43e7a07dffdfc759a12062bb8d6b44e833b306da9bd29b\
a81f35781d539d395b3532a21e,
0xe7355f8e4e667b955390f7f0506c6e9395735e9ce9cad4d0a43bcef24b8982f7400d24b\
c4228f11c02df9a29f6304a5,
0x772caacf16936190f3e0c63e0596721570f5799af53a1894e2e073062aede9cea73b353\
8f0de06cec2574496ee84a3a,
0x14a7ac2a9d64a8b230b3f5b074cf01996e7f63c21bca68a81996e1cdf9822c580fa5b94\
89d11e2d311f7d99bbdcc5a5e,
0xa10ecf6ada54f825e920b3dafc7a3cce07f8d1d7161366b74100da67f39883503826692\
abba43704776ec3a79a1d641,
0x95fc13ab9e92ad4476d6e3eb3a56680f682b4ee96f7d03776df533978f31c1593174e4b\
4b7865002d6384d168ecdd0a
];

// k_(3,0), k_(3,1), k_(3,2), k_(3,3), k_(3,4), k_(3,5), k_(3,6), 
//k_(3,7), k_(3,8), k_(3,9), k_(3,10), 
// k_(3,11), k_(3,12), k_(3,13), k_(3,14), k_(3,15)
k3 := [
0x90d97c81ba24ee0259d1f094980dcfa11ad138e48a869522b52af6c956543d3cd0c7ae\
e9b3ba3c2be9845719707bb33,
0x134996a104ee5811d51036d776fb46831223e96c254f383d0f906343eb67ad34d6c567\
11962fa8bfe097e75a2e41c696,
0xcc786baa966e66f4a384c86a3b49942552e2d658a31ce2c344be4b91400da7d26d5216\
28b00523b8dfe240c72de1f6,
0x1f86376e8981c217898751ad8746757d42aa7b90eeb791c09e4a3ec03251cf9de405ab\
a9ec61deca6355c77b0e5f4cb,
0x8cc03fdefe0ff135caf4fe2a21529c4195536fbe3ce50b879833fd221351adc2ee7f8dc09\
9040a841b6daecf2e8fedb,
0x16603fca40634b6a2211e11db8f0a6a074a7d0d4afadb7bd76505c3d3ad5544e203f63\
26c95a807299b23ab13633a5f0,
0x4ab0b9bcfac1bbcb2c977d027796b3ce75bb8ca2be184cb5231413c4d634f3747a87ac\
2460f415ec961f8855fe9d6f2,
0x987c8d5333ab86fde9926bd2ca6c674170a05bfe3bdd81ffd038da6c26c842642f64550\
fedfe935a15e4ca31870fb29,
0x9fc4018bd96684be88c9e221e4da1bb8f3abd16679dc26c1e8b6e6a1f20cabe69d6520\
1c78607a360370e577bdba587,
0xe1bba7a1186bdb5223abde7ada14a23c42a0ca7915af6fe06985e7ed1e4d43b9b3f705\
5dd4eba6f2bafaaebca731c30,
0x19713e47937cd1be0dfd0b8f1d43fb93cd2fcbcb6caf493fd1183e416389e61031bf3a\
5cce3fbafce813711ad011c132,
0x18b46a908f36f6deb918c143fed2edcc523559b8aaf0c2462e6bfe7f911f643249d9cdf\
41b44d606ce07c8a4d0074d8e,
0xb182cac101b9399d155096004f53f447aa7b12a3426b08ec02710e807b4633f06c851\
c1919211f20d4c04f00b971ef8,
0x245a394ad1eca9b72fc00ae7be315dc757b3b080d4c158013e6632d3c40659cc6cf90\
ad1c232a6442d9d3f5db980133,
0x5c129645e44cf1102a159f748c4a3fc5e673d81d7e86568d9ab0f5d396a7ce46ba1049\
b6579afb7866b1e715475224b,
0x15e6be4e990f03ce4ea50b3b42df2eb5cb181d8f84965a3957add4fa95af01b2b6650\
27efec01c7704b456be69c8b604
];

// k_(4,0), k_(4,1), k_(4,2), k_(4,3), k_(4,4), k_(4,5), k_(4,6), 
// k_(4,7), k_(4,8), k_(4,9), k_(4,10), 
// k_(4,11), k_(4,12), k_(4,13), k_(4,14)
k4 := [
0x16112c4c3a9c98b252181140fad0eae9601a6de578980be6eec3232b5be72e7a07f368\
8ef60c206d01479253b03663c1,
0x1962d75c2381201e1a0cbd6c43c348b885c84ff731c4d59ca4a10356f453e01f78a4260\
763529e3532f6102c2e49a03d,
0x58df3306640da276faaae7d6e8eb15778c4855551ae7f310c35a5dd279cd2eca6757cd\
636f96f891e2538b53dbf67f2,
0x16b7d288798e5395f20d23bf89edb4d1d115c5dbddbcd30e123da489e726af4172736\
4f2c28297ada8d26d98445f5416,
0xbe0e079545f43e4b00cc912f8228ddcc6d19c9f0f69bbb0542eda0fc9dec916a20b15dc\
0fd2ededda39142311a5001d,
0x8d9e5297186db2d9fb266eaac783182b70152c65550d881c5ecd87b6f0f5a6449f38db\
9dfa9cce202c6477faaf9b7ac,
0x166007c08a99db2fc3ba8734ace9824b5eecfdfa8d0cf8ef5dd365bc400a0051d5fa9c0\
1a58b1fb93d1a1399126a775c,
0x16a3ef08be3ea7ea03bcddfabba6ff6ee5a4375efa1f4fd7feb34fd206357132b920f5b0\
0801dee460ee415a15812ed9,
0x1866c8ed336c61231a1be54fd1d74cc4f9fb0ce4c6af5920abc5750c4bf39b4852cfe2f7\
bb9248836b233d9d55535d4a,
0x167a55cda70a6e1cea820597d94a84903216f763e13d87bb5308592e7ea7d4fbc7385e\
a3d529b35e346ef48bb8913f55,
0x4d2f259eea405bd48f010a01ad2911d9c6dd039bb61a6290e591b36e636a5c871a5c2\
9f4f83060400f8b49cba8f6aa8,
0xaccbb67481d033ff5852c1e48c50c477f94ff8aefce42d28c0f9a88cea7913516f968986\
f7ebbea9684b529e2561092,
0xad6b9514c767fe3c3613144b45f1496543346d98adf02267d5ceef9a00d9b86930007\
63e3b90ac11e99b138573345cc,
0x2660400eb2e4f3b628bdd0d53cd76f2bf565b94e72927c1cb748df27942480e420517\
bd8714cc80d1fadc1326ed06f7,
0xe0fa1d816ddc03e6b24255e0d7819c171c40f65e273b853324efcd6356caa205ca2f57\
0f13497804415473a1d634b8f
];
function Isogeny2Target(P_isog);
  x_ := P_isog[1]; y_ := P_isog[2];
  //  x_num = k_(1,11) * x'^11 + k_(1,10) * x'^10 + k_(1,9) * x'^9 + ... + k_(1,0)
  x_num := &+[k1[i]*x_^(i-1):  i  in [#k1..1 by -1]];
  // x_den = x'^10 + k_(2,9) * x'^9 + k_(2,8) * x'^8 + ... + k_(2,0)
  x_den := &+[k2[i]*x_^(i-1) :  i  in [#k2..1 by -1]]; x_den+:= x_^10;

  // y_num = k_(3,15) * x'^15 + k_(3,14) * x'^14 + k_(3,13) * x'^13 + ... + k_(3,0)
  y_num := &+[k3[i]*x_^(i-1) :  i  in [#k3..1 by -1]];
  // y_den = x'^15 + k_(4,14) * x'^14 + k_(4,13) * x'^13 + ... + k_(4,0)
  y_den :=  &+[k4[i]*x_^(i-1) :  i  in [#k4..1 by -1]]; y_den+:= x_^15;
  return [x_num / x_den, y_ * y_num / y_den];
end function;

/*
 Solves A*w^2 + B*w + C = 0 in the field
 Returns a sequence of solutions [w1, w2]
*/
function SolveQuadratic(A, B, C)
    if A eq 0 then
        if B eq 0 then return []; end if;
        return [-C / B];
    end if;
    
    Delta := B^2 - 4*A*C;
    if not IsSquare(Delta) then return []; end if;
    
    s := Sqrt(Delta);
    den_inv := 1 / (2*A);
    w1 := (-B + s) * den_inv;
    w2 := (-B - s) * den_inv;
    
    if w1 eq w2 then return [w1]; else return [w1, w2]; end if;
end function;

/*
----------------------------------------------------------------
SSWU Inverse Map (P_isog -> u)
---------------------------------------------------------------- 
*/
function BasePreimage(P)
    x := P[1];
    y := P[2];
    Candidates := {* *}; // A set to store candidates
    K := x * A_isog + B_isog;

    // --- Invert Case 0 ---
    A0 := Z^2 * K; B0 := Z * K; C0 := B_isog;
    Case_0 := SolveQuadratic(A0, B0, C0);
    for Solution in Case_0 do Include(~Candidates, Solution); end for;

    // --- Invert Case 1 ---
    A1 := B_isog * Z^2;  C1 := K;
    //B1 := Z * K;
    Case_1 := SolveQuadratic(A1, B0, C1);
    for Solution in Case_1 do Include(~Candidates, Solution); end for;

    // --- Verification Loop ---
    for Solution in Candidates do
        if IsSquare(Solution) then
            u_cand := Sqrt(Solution);
            P_check := E_isog!SSWUHash2Point(u_cand);

            if P_check[1] eq x then
                if    P_check[2] eq y   then return true,   u_cand;
                elif P_check[2] eq -y then return true, -u_cand;
                end if;
            end if;
        end if;
    end for;
    
    return false, Fp!0;
end function;

/*
----------------------------------------------------------------
TRANSMITTING END: Obfuscates a point on the isogenous curve.
Given P_isog, finds (u, v) such that
SSWU(u) + SSWU(v) = P_isog
----------------------------------------------------------------
*/

function GenerateAndObfuscateOnIsog(P_isog)  
    // Loop until we find a valid pair
    while true do
    
        // 1. "Pick" a random u
        u := Random(1,p-1);

        // 2. Compute SSWU(u)
        P_u := E_isog!SSWUHash2Point(u);

        // 3. Compute P_v (on the isogenous curve)
        P_v := P_isog - P_u; // Point subtraction

        // 4. "Check": Invert SSWU(v) = P_v
        Success, v := BasePreimage(P_v);

        // 5. Return or Repeat
        if Success then
            return Fp!u, Fp!v; // Success!
        end if;
    end while;
end function;

/*
----------------------------------------------------------------
 RECEIVING END: Reconstructs the point on the target curve
----------------------------------------------------------------
*/

function ReconstructAndMap2Target(u, v)
// 1. Reconstruct Isogenous Point
    P_u_isog := E_isog!SSWUHash2Point(u);
    P_v_isog := E_isog!SSWUHash2Point(v);
    P_isog   := P_u_isog + P_v_isog;
    
// 2. Map to Target Curve
    P_target :=  Isogeny2Target(P_isog);
    
    return E_target! P_target;
end function;

/*
----------------------------------------------------------------
Runtime Test
----------------------------------------------------------------
*/
printf "Target Curve:    %o\n", E_target;
printf "Isogenous Curve: %o\n", E_isog;

// TRANSMITTING END
printf "\n--- Transmitting End ---\n";

// Generate a sample Public Key on the isogenous curve

SecretKey := Random(1,q-1);
PublicKey_isog := SecretKey * G_isog;
assert PublicKey_isog in E_isog;

printf "1. Generated Public Key on isogenous curve:\n%o\n\n", PublicKey_isog;

// Obfuscate it
printf "2. Obfuscating (running \"pick-and-check\")...\n";
u, v := GenerateAndObfuscateOnIsog(PublicKey_isog);
printf "   Found u: %o\n   Found v: %o\n", u, v;

printf "\n3. Transmitting (u, v) over insecure channel...\n";

// 3. RECEIVING END
printf "\n--- Receiving End ---\n";
printf "1. Received u and v.\n";

// Reconstruct the point on the target curve
PublicKey_target := ReconstructAndMap2Target(u, v);

printf "2. Reconstructed point and mapped to target curve:\n%o\n\n", PublicKey_target;

// 4. VERIFICATION
// Let's create the "real" target Public Key to verify
PublicKey_target_real := E_target!Isogeny2Target(PublicKey_isog);

printf "--- Verification ---\n";
printf "Original Public Key on target curve:\n%o\n", PublicKey_target_real;

if (PublicKey_target eq PublicKey_target_real) and \
   (q*PublicKey_target eq Identity)  then
printf "\nSuccess! The reconstructed point matches the original.\n";  else printf "\nFail! \n"; quit; end if;

NumberOfAttempts := 1000; ObfuscateCls := 0;  DeObfuscateCls := 0; i := 0;
repeat
  i +:= 1;

  t := ClockCycles(); 
  u, v := GenerateAndObfuscateOnIsog(PublicKey_isog);
  CyclesSpent := ClockCycles()-t;
  ObfuscateCls +:= CyclesSpent;

  t := ClockCycles(); 
  PublicKey_target := ReconstructAndMap2Target(u, v);
  CyclesSpent:= ClockCycles()-t;
  DeObfuscateCls +:= CyclesSpent;

  PublicKey_target_real := E_target!Isogeny2Target(PublicKey_isog);
  if (PublicKey_target ne PublicKey_target_real) or \
     (q*PublicKey_target ne Identity)  then printf "\nFail! \n"; break; end if;
until (i eq NumberOfAttempts);

print "\n__________________ Clock cycles ___________________";
Res1 := ObfuscateCls div NumberOfAttempts;
print " \nObfuscation:  ", Res1;
Res2 := DeObfuscateCls div NumberOfAttempts;
print " \nDeobfuscation:", Res2;
