//____BLS__signature_under__BLS12-381_______________________________________
clear;
function UppercaseFirst(s)
    // Return an empty string if the input is empty.
    if #s eq 0 then
        return "";
    end if;

    FirstChar := s[1];
    RestOfString := Substring(s, 2, #s-1); // Get the rest of the string

    // Get ASCII values for the character and the "a"-"z" range.
    ASCII_char := StringToCode(FirstChar);
    ASCII_a := StringToCode("a");
    ASCII_z := StringToCode("z");

    // Check if the first character is a lowercase letter.
    if (ASCII_char ge ASCII_a) and (ASCII_char le ASCII_z) then
        // It's lowercase, so convert it to uppercase by subtracting 32.
        NewFirstChar := CodeToString(ASCII_char - 32);
        return NewFirstChar cat RestOfString;
    else
        // It's not a lowercase letter, so return the original string.
        return s;
    end if;
end function;

// Define a small dictionary of words
Dictionary := [
 "I", "she", "he", "above", "across", "after", "against", 
 "among", "around", "at", "before", "behind", "below", "beneath",
 "beside", "between", "beyond", "but", "by", "concerning", "despite",
 "down", "during", "except", "for", "from", "I", "in", "inside", "into",
 "it", "like", "near", "next", "of", "off", "on", "onto", "out", "outside",
 "over", "past", "regarding", "since", "she", "that", "they", "through",
 "throughout", "to", "toward", "under", "underneath", "unlike", "until",
 "unto", "up", "upon", "us", "versus", "we", "what", "which", "who", "whom",
 "whose", "with", "within", "without", "you", "abandon", "abbey", "ability",
 "able", "abolish", "abortion", "about", "absence", "absorb", "abstract",
 "absurd", "abundance", "abuse", "academy", "accelerate", "accent", "accept",
 "acceptable", "acceptance", "access", "accessible", "accident",
 "accommodate", "accommodation", "accompany", "accomplish",
 "accomplishment", "according", "account", "accountability", "accountable",
 "accountant", "accounting", "accuracy", "mine", "yours", "his", "hers",
 "ours", "theirs", "myself", "yourself", "himself", "herself", "itself",
 "ourselves", "yourselves", "themselves", "one", "two", "three", "four",
 "five", "six", "seven", "eight", "nine", "ten",
 //"!", "@", "#", "$", "%", "^", "&", "*", 
 //"(", ")",
 "homomorphism", "abelian", "finite", "prime", "polynomial",
 "magma", "group", "field", "ring", "isomorphism", "matrix",
 "computes", "finds", "determines", "is", "a", "the", "an",
 "homomorphism", "abelian", "finite", "prime", "polynomial"
];

// Function to generate a sentence of a given length
function GenerateSentence(Dictionary, Count)
    Sentence := "";
    for i in [1..Count] do
        // Select a random word from the list
        RandomWord := Dictionary[Random(1,#Dictionary)];
        Sentence cat:= RandomWord cat " ";
    end for;

    // Capitalize the first letter and add a period “.”   
    Sentence := Prune(UppercaseFirst(Sentence)) cat ".";
    return Sentence;
end function;

function AppendErrorToMessage(Message)
   MessageWithError := "__ ERROR __ " cat Message;
   return MessageWithError;
end function;

//GenerateSentence(Dictionary, #Dictionary); quit;

//___________________________________________________________________________
// The prime field for BLS12-381
p :=0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfff\
eb153ffffb9feffffffffaaab;

z := -0xd201000000010000;
assert p eq z + (z^4 - z^2 + 1)*(z - 1)^2 / 3;
assert p mod 4 eq 3;

h_1 := 0x396c8c005555e1568c00aaab0000aaab;
assert h_1 eq (z - 1)^2 / 3;

q := 524358751751261904794477405081859658376905525005276378226036586999385811\
84513; // Order
assert q eq (z^4 - z^2 + 1); 

Cofactor := 76329603384216526031706109802092473003;

Fp := FiniteField(p);
E_target := EllipticCurve([Fp | 0, 4]);  // The target curve E1: y^2 = x^3 + 4
Identity := E_target!0;
G_target := E_target![3782899677407369731768974123304053494906485590974740018\
252129477145021563287086334800525172514660041056416990368067,8002164755441504\
80085660525456722194361055617050839334227594389928838305480984436087520610115\
833565668908616677533];
assert (G_target in E_target) and (G_target ne Identity)\
and (q * G_target eq Identity);

// ===================================================================
// The curve given by y'^2 = g'(x') = x'^3 + A' x' + B' is isogenous 
// to the target curve
// ===================================================================
A_isog := 0x144698a3b8e9433d693a02c96d4982b0ea985383ee66a8d8e8981aefd881ac989\
36f8da0e0f97f5cf428082d584c1d;
B_isog := 0x12e2908d11688030018b12e8753eee3b2016c1f0f24f4070a0b9c14fcef35ef55\
a23215a316ceaa5d1cc48e98e172be0;
// The isogenous curve E_isog:y'^2 = x'^3 + A' x' + B'
E_isog := EllipticCurve([Fp | A_isog, B_isog]);

//Poly<x> := PolynomialRing(Fp);
//g := x^3+A_isog*x+B_isog;

// ===================================================================
// PART 1: A BLS12-381 SETUP
// ===================================================================

/*
// 1b. Calculate G1 parameters programmatically
N := #E_target;
factors := Factorization(N);
r := factors[#factors][1];
cofactor := N div r;
quit;
*/

/*
// 1c. Calculate the G1 generator programmatically
G_target := Random(E_target);
while G_target eq E_target!0 do
    G_target := Random(E_target);
end while;
G_target := cofactor * G_target;
assert (G_target in E_target) and (G_target ne E_target!0)\
and (r * G_target eq E_target!0);
quit;
*/

// 1d. Standard Field Extension Fp^2
P_Fp<x> := PolynomialRing(Fp);
Fp2<u> := ext<Fp | x^2 + 1>;

// 1e. Field Tower Element xi and Twisted Curve
xi := u + 1;
E_twisted := EllipticCurve([Fp2 | 0, 4*xi]);

/*
// 1f. Calculate G2 parameters programmatically
print "Calculating order of the twisted curve";
N_twisted := #E_twisted;
print "Calculation complete.";
cofactor_twisted := N_twisted div r;
quit;
*/

/*
// 1g. Generate the G2 generator programmatically
G_twisted := Random(E_twisted);
while G_twisted eq E_twisted!0 do
    G_twisted := Random(E_twisted);
end while;
G_twisted := cofactor_twisted * G_twisted;
assert (G_twisted in E_twisted) and (G_twisted ne E_twisted!0)\
and (q * G_twisted eq E_twisted!0);
quit;
*/

/*
cofactor_twisted := 305502333931268344200999753193121504214466019254188142667\
66403298226760418297188402650742735925997784783227283904161666128580382337837\
2096355777062779109;
*/
Identity_twist := E_twisted!0;
G_twisted := E_twisted![10262136003146452180985140214523076624611344967267615\
0971113299607157363256660546264161495958887616832608405420165*u + 32961087432\
94957981507650710421324493511550892913354720927016283120561620952453112692891\
597507591988896836146277781,1954547723374416515826528805429496475738465727831\
114337933185622976738722494900477369817111463880116587499652171864*u + 384118\
67062367695278511843900589731085070805744752384829418489189353318738980470021\
22512986285318573837344416359865];
assert (G_twisted in E_twisted) and (G_twisted ne Identity_twist)\
and (q * G_twisted eq Identity_twist);

// 1h. Final Field Tower to Fp^12
P_Fp2<y> := PolynomialRing(Fp2);
Fp12<v> := ext<Fp2 | y^6 - xi>;
E_extended := ChangeRing(E_target, Fp12);

/*
// 1i. Map the G2 point to the main curve E_target over Fp12
x_twisted := G_twisted[1];
y_twisted := G_twisted[2];
G_ext := E_extended![x_twisted / v^2, y_twisted / v^3];
assert (G_ext in E_extended) and (G_ext ne E_extended!0)\
and (r * G_ext eq E_extended!0);
quit;
*/

Identity_ext := E_extended!0;

G_ext := E_extended![(2405665863589920663568890171597857292924164098318668600\
354106644367329521642941581228322578354663478005780402130979*u + 169936505166\
32112516587510562832776298788321712930154359490647913638594921045568294785265\
46733239802864722275848973)*v^4,(10578852861796571906965671205532137618941339\
86647441870161697420082719249543845669844995877153788603394024754185893*u + 8\
96662437194759325129961684876282713844331741183672467771488202894019472951054\
807524821234310091513193474897985971)*v^3];
assert (G_ext in E_extended) and (G_ext ne Identity_ext)\
and (q * G_ext eq Identity_ext);

// 1j. Pairing Function
// NOTE: For functional validation and mathematical proof of concept in this script, 
// the built-in ReducedTatePairing is utilized. In production environments (C/Rust), 
// Optimal Ate (R-ate) pairing over sextic twists is strictly deployed to minimize 
// Miller loop iterations and bypass heavy Fp12 arithmetic.

Pairing := ReducedTatePairing; //TatePairing;

// --- Define the final exponent ---
// final_exponent := (p^12 - 1) div q;

// ===================================================================
// PART 2: HASH-TO-CURVE FUNCTIONS (TO G1)
// ===================================================================

function HashToPoint(Message)
    x_coord := Fp!StringToInteger(SHA1(Message),16);
    while true do
        PointsOnCurve := Points(E_target,x_coord);
        if #PointsOnCurve gt 0 then
            AnyPoint := Cofactor * PointsOnCurve[1];
            assert q * AnyPoint eq Identity;
            return AnyPoint;
        end if;
        x_coord +:= 1;
    end while;
end function;

// -----------------------------------------------------------------------------
// == The Constant-Time Hashing Function                                    ==
// -----------------------------------------------------------------------------
function ConstantTimeHashToPoint(Message)
    // 1. Hash the message to get a starting integer.
    // NOTE: SHA256 is not a standard Magma function, but SHA1 is.
    // Using SHA1 here for compatibility with the online calculator,
    // though SHA256 would be preferred.
    x_coord := Fp!StringToInteger(SHA1(Message), 16);

    // 2. Set parameters for the constant-time loop.
    // The limit is chosen to be high enough to statistically guarantee 
    // finding a point.
    LIMIT := 20;
    FinalPoint := Identity; // Initialize result to the point at infinity.
    Ding := false;

    // 3. Main constant-time loop. This loop ALWAYS runs LIMIT times.
    for i in [1..LIMIT] do
        // --- Unconditional Work Block ---
        // These expensive operations are performed in EVERY iteration.
        PointsOnCurve := Points(E_target, x_coord);
        IsValidPoint := #PointsOnCurve gt 0;

        // If a point is found, clear the cofactor. Otherwise, use 
        // the point at infinity.
        CurrentPoint := IsValidPoint select Cofactor * PointsOnCurve[1]
        else Identity;

        // --- Conditional Selection (Constant-Time) ---
        // If this is the *first* valid point we've found, update our final result.
        // This 'if' statement on a boolean is not a source of a timing leak.
        if (not Ding) and IsValidPoint then
            FinalPoint := CurrentPoint;
            Ding := true;
        end if;

        // Increment the coordinate for the next iteration.
        x_coord +:= 1;
    end for;

    // 4. Final check and return.
    // This assertion ensures the loop limit was sufficient.
    assert (FinalPoint ne Identity) and (q * FinalPoint eq Identity);

    return FinalPoint;
end function;

// -----------------------------------------------------------------------------
//  Simplified SWU Hashing Function
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//  Constants
// -----------------------------------------------------------------------------
Z := Fp!11;
assert JacobiSymbol(Integers()!Z, p) eq -1;

Const1 :=  -B_isog/ A_isog;
Const2 :=  B_isog/ (Z * A_isog);
Const4 :=  Integers()!((p - 3) / 4);     // Integer arithmetic
Const5 :=  Sqrt(-Z);

function CMOV(Arg1, Arg2, Arg3)
  if not Arg3 then return Arg1; else return Arg2; end if;
end function;

function sqrt_ratio_3mod4(u, v) 
// Parameters: F, a finite field of characteristic p and subgroup of order q,
// where p = 3 mod 4. - Z, the constant from the Simplified SWU map.
// Input: u and v, elements of F, where v != 0.
// Output: (b, y), where  b = True and y = sqrt(u / v) if (u / v) is square
// in F, and  b = False and y = sqrt(Z * (u / v)) otherwise.

  // Procedure:
  tv1 := v^2;
  tv2 := u * v;
  tv1 := tv1 * tv2;
  y1 := tv1^Const4;
  y1 := y1 * tv2;
  y2 := y1 * Const5;
  tv3 := y1^2;
  tv3 := tv3 * v;
  isQR := tv3 eq u;
  y := CMOV(y2, y1, isQR);
  return isQR, y;
end function;

function SimplifiedSWUHashToPoint(Message)
  u := Fp!StringToInteger(SHA1(Message), 16);
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
  e1 := Sign(Integers()!u) eq Sign(Integers()!y);
  y := CMOV(-y, y, e1);
  x := x / tv4;

/*
  // Non optimized procedure 
  tv1 := (Z^2 * u^4 + Z * u^2)^-1;
  x1 := Const2 * (1 + tv1);
  if tv1 eq 0 then x1 := Const2; end if;
  gx1 := x1^3 + A_isog * x1 + B_isog;
  x2 := Z * u^2 * x1;
  gx2 := x2^3 + A_isog * x2 + B_isog;
  if IsSquare(gx1) then x := x1;  y := Sqrt(gx1); else x := x2; y := Sqrt(gx2); end if;
  if Sign(Integers()!u) ne Sign(Integers()!y) then  y := -y; end if;
*/

  return [x, y];
end function;

// -----------------------------------------------------------------------------
//  11-Isogeny Map for BLS12-381 G1
// -----------------------------------------------------------------------------

// k_(1,0), k_(1,1), k_(1,2), k_(1,3), k_(1,4), k_(1,5), k_(1,6), k_(1,7), k_(1,8), k_(1,9), k_(1,10), k_(1,11)
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

// k_(2,0), k_(2,1), k_(2,2), k_(2,3), k_(2,4), k_(2,5), k_(2,6), k_(2,7), k_(2,8), k_(2,9)
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

// k_(3,0), k_(3,1), k_(3,2), k_(3,3), k_(3,4), k_(3,5), k_(3,6), k_(3,7), k_(3,8), k_(3,9), k_(3,10), 
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

// k_(4,0), k_(4,1), k_(4,2), k_(4,3), k_(4,4), k_(4,5), k_(4,6), k_(4,7), k_(4,8), k_(4,9), k_(4,10), 
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
function IsogenyToTarget(P_isog);
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

// ===================================================================
// PART 3 & 4: BLS ALGORITHMS AND EXECUTION
// ===================================================================

function KeyGen()
    SecretKey := Random(1, q - 1);
    PublicKey := SecretKey * G_ext;
    return SecretKey, PublicKey;
end function;

function Sign(Message, SecretKey)
    //AnyPoint := SimplifiedSWUHashToPoint(Message);
    // assert AnyPoint in E_isog; 
    //AnyPoint := Cofactor * E_target!IsogenyToTarget(AnyPoint);
    AnyPoint := Cofactor * E_target!IsogenyToTarget\
    (SimplifiedSWUHashToPoint(Message));
    // assert AnyPoint in E_target;
    //AnyPoint :=  ConstantTimeHashToPoint(Message);
    //AnyPoint := HashToPoint(Message);
    //AnyPoint := E_extended!AnyPoint;
    return SecretKey * E_extended!AnyPoint;
end function;

function Verify(Message, PublicKey, Signature)
    //AnyPoint := SimplifiedSWUHashToPoint(Message);
    // assert AnyPoint in E_isog; 
    //AnyPoint := Cofactor * E_target!IsogenyToTarget(AnyPoint);
    AnyPoint := E_extended!(Cofactor * E_target!IsogenyToTarget\
    (SimplifiedSWUHashToPoint(Message))); // Clearing the cofactor
    // assert AnyPoint in E_target;
    //AnyPoint :=  ConstantTimeHashToPoint(Message);
    //AnyPoint := HashToPoint(Message);
    //AnyPoint := E_extended!AnyPoint;

    // 1. Calculate the raw Tate pairings
    // assert Signature in E_extended;
    //raw_e1 := Pairing(Signature, G_ext, q);
    //raw_e2 := Pairing(AnyPoint, PublicKey, q);
    
    // 2. Apply the final exponentiation
    //e1 := raw_e1 ^ final_exponent;
    //e2 := raw_e2 ^ final_exponent;

    // 3. Now the comparison is valid
    //return e1 eq e2;
/*
    return Pairing(Signature, G_ext, q) ^ final_exponent eq \
                Pairing(AnyPoint, PublicKey, q) ^ final_exponent;
*/
    return Pairing(Signature, G_ext, q) eq Pairing(AnyPoint, PublicKey, q);

end function;

print "\n______________ Executing BLS Scheme _______________";

// 1. Generate Keys
print "\n1. Generating keys...";
SecretKey, PublicKey := KeyGen();
print "   Secret Key is an integer within the order of G1.";
print "   Public Key in G2 is a point mapped on the extended curve.";

// Define a message and Sign it

print "\n2. Generating a message...";
Message :=  GenerateSentence(Dictionary, #Dictionary);
//message := "This signature is verified on the standard BLS12-381 curve.";
print "\n3. Signing the message...";//, Message;
Signature := Sign(Message, SecretKey);
print "   Signature in G1 is a point mapped on the extended curve.";//, Signature;

Error := false;
if Random(1) eq 1 then \
Message := AppendErrorToMessage(Message); Error := true; end if;

// Verify the signature
print "\n4. Verifying the signature...";
// Pass the final_exponent to the Verify function
isValid := Verify(Message, PublicKey, Signature);
if isValid then
    print "   SUCCESS: The signature is valid.";
else
    print "   FAILURE: The signature is invalid.";
end if;
if Error then \
print "   The message being checked differs from the original because";
print "   it is marked with the flag \"__ ERROR __\"."; end if;

NumberOfAttempts := 1000; Sum1 := 0; Sum2 := 0; Sum3 := 0; i := 0;
repeat
  i +:= 1;
  Message :=  GenerateSentence(Dictionary, #Dictionary); 

  t:=ClockCycles();
  _ := Cofactor * E_target!IsogenyToTarget\
  (SimplifiedSWUHashToPoint(Message));
  SWUandMapClocks := ClockCycles()-t;
  Sum1 +:= SWUandMapClocks;

  t := ClockCycles();
  _ :=  ConstantTimeHashToPoint(Message);
  TryAndIncrementClocks := ClockCycles()-t;
  Sum2 +:= TryAndIncrementClocks;

  t := ClockCycles();   
  _ := HashToPoint(Message);
  TrivialMethodClocks := ClockCycles()-t;
  Sum3 +:= TrivialMethodClocks;
  
until (i eq NumberOfAttempts);

print "\n__________________ Clock cycles ___________________";
Res2 := Sum2 div NumberOfAttempts;
print "1st. \"Try-and-Increment\" Hashing:", Res2;

Res3 := Sum3 div NumberOfAttempts;
print "2nd. Trivial Hashing            :", Res3;

Res1 := Sum1 div NumberOfAttempts;
printf "\Simplified SWU & Isogeny Map    : %o\n", Res1; 
printf "The gain of SWU & Isogeny Map is: %.2o%% (1st), %.2o%% (2nd)\n",\
100-(100/(Res2/Res1)*1.0), 100-(100/(Res3/Res1)*1.0);
