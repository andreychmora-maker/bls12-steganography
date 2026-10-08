/* 
====================================================================
Optimized helper bitwise functions for 32-bit words
Utilizing Magma's native bit operations for improved performance
==================================================================== 
*/

function ROTR(x, n)
    // Right circular shift using native ShiftRight and ShiftLeft.
    // Addition is safe here as shifted bits do not overlap.
    return ModByPowerOf2(ShiftRight(x, n) + ShiftLeft(x, 32-n), 32);
end function;

function SHR(x, n)
    return ShiftRight(x, n);
end function;

function CH(x, y, z)
    // NOT x is implemented as (4294967295 - x) safely capped to 32 bits
    return BitwiseXor(BitwiseAnd(x, y), BitwiseAnd(ModByPowerOf2(4294967295 - x, 32), z));
end function;

function MAJ(x, y, z)
    return BitwiseXor(BitwiseXor(BitwiseAnd(x, y), BitwiseAnd(x, z)), BitwiseAnd(y, z));
end function;

function EP0(x)
    return BitwiseXor(BitwiseXor(ROTR(x, 2), ROTR(x, 13)), ROTR(x, 22));
end function;

function EP1(x)
    return BitwiseXor(BitwiseXor(ROTR(x, 6), ROTR(x, 11)), ROTR(x, 25));
end function;

function SIG0(x)
    return BitwiseXor(BitwiseXor(ROTR(x, 7), ROTR(x, 18)), SHR(x, 3));
end function;

function SIG1(x)
    return BitwiseXor(BitwiseXor(ROTR(x, 17), ROTR(x, 19)), SHR(x, 10));
end function;

// ====================================================================
// Main SHA-256 function
// ====================================================================

function SHA256(msg_bytes)
    // SHA-256 constants
    K := [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];

    // Initial hash values
    H := [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ];

    m := msg_bytes;
    ml := #m * 8; // Original message length in bits
    
    // 1. Padding
    Append(~m, 0x80); // Append '1' bit (followed by zeros)
    //while (#m mod 64) ne 56 do
    while ModByPowerOf2(#m, 6) ne 56 do 
        Append(~m, 0);
    end while;

    // Append length (64 bits, big-endian)
    for i in [7..0 by -1] do
        //Append(~m, (ml div (256^i)) mod 256);
        Append(~m, ModByPowerOf2(ShiftRight(ml, 8*i), 8));
    end for;

    // 2. Process blocks of 512 bits (64 bytes)
    for i in [1..#m by 64] do
        W := [0 : j in [1..64]];
        for j in [0..15] do
            W[j+1] := ShiftLeft(m[i+j*4], 24) + ShiftLeft(m[i+j*4+1], 16) + ShiftLeft(m[i+j*4+2], 8) + m[i+j*4+3];
        end for;
        
        // Extend to 64 words using ModByPowerOf2
        for j in [17..64] do
            s0 := SIG0(W[j-15]);
            s1 := SIG1(W[j-2]);
            W[j] := ModByPowerOf2(W[j-16] + s0 + W[j-7] + s1, 32);
        end for;

        a := H[1]; b := H[2]; c := H[3]; d := H[4];
        e := H[5]; f := H[6]; g := H[7]; h := H[8];

        // Main compression loop
        for j in [1..64] do
            S1 := EP1(e);
            ch := CH(e, f, g);
            temp1 := ModByPowerOf2(h + S1 + ch + K[j] + W[j], 32);
            S0 := EP0(a);
            maj := MAJ(a, b, c);
            temp2 := ModByPowerOf2(S0 + maj, 32);

            h := g;
            g := f;
            f := e;
            e := ModByPowerOf2(d + temp1, 32);
            d := c;
            c := b;
            b := a;
            a := ModByPowerOf2(temp1 + temp2, 32);
        end for;

        H[1] := ModByPowerOf2(H[1] + a, 32);
        H[2] := ModByPowerOf2(H[2] + b, 32);
        H[3] := ModByPowerOf2(H[3] + c, 32);
        H[4] := ModByPowerOf2(H[4] + d, 32);
        H[5] := ModByPowerOf2(H[5] + e, 32);
        H[6] := ModByPowerOf2(H[6] + f, 32);
        H[7] := ModByPowerOf2(H[7] + g, 32);
        H[8] := ModByPowerOf2(H[8] + h, 32);
    end for;

    // 3. Extract final byte array
    out_bytes := [];
    for x in H do
        word_hex := IntegerToString(x, 16);
        // Ensure strictly 8 hex characters per 32-bit word
        while #word_hex lt 8 do 
            word_hex := "0" cat word_hex; 
        end while;
        
        // Parse hex string back to individual bytes
        for idx in [1..7 by 2] do
            Append(~out_bytes, StringToInteger(word_hex[idx..idx+1], 16));
        end for;
    end for;

    return out_bytes;
end function;

// ====================================================================
// Utility functions for string / hex / byte array conversions
// ====================================================================

function BytesToHex(bytes)
    // Hardcode lowercase hex characters to guarantee standard formatting 
    // and avoid dependency on Magma intrinsic case variations.
    hex_chars := ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
    res := "";
    for b in bytes do
        res cat:= hex_chars[(b div 16) + 1] cat hex_chars[(b mod 16) + 1];
    end for;
    return res;
end function;

function HexToBytes(hex_str)
    if #hex_str eq 0 then return []; end if;
    return [ StringToInteger(hex_str[i..i+1], 16) : i in [1..#hex_str by 2] ];
end function;

function StringToBytes(str)
    // StringToCode safely and natively returns the ASCII integer value of a character
    return [ StringToCode(s) : s in Eltseq(str) ];
end function;

// ====================================================================
// NIST Standard Test Vectors for SHA-256
// ====================================================================
// Test vectors are provided in Hex to bypass Magma's ASCII parsing limitations.

test_vectors := [
    // 1. Empty string ("")
    <"", 
     "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855">,
     
    // 2. Short string ("abc")
    <"616263", 
     "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad">,
     
    // 3. Long string 448 bits ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
    <"6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f7071", 
     "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1">
];

print "--- Running NIST SHA-256 Test Vectors ---";
all_passed := true;

for i in [1..#test_vectors] do
    msg_hex := test_vectors[i][1];
    expected_hex := test_vectors[i][2];
    
    msg_bytes := HexToBytes(msg_hex);
    actual_hex := BytesToHex(SHA256(msg_bytes));
    
    if actual_hex eq expected_hex then
        printf "Test %o: PASSED\n", i;
    else
        printf "Test %o: FAILED!\n", i;
        printf "  Expected: %o\n", expected_hex;
        printf "  Actual  : %o\n", actual_hex;
        all_passed := false;
    end if;
end for;

if all_passed then
    print "\nSUCCESS: All NIST test vectors passed perfectly! The SHA-256 implementation is solid.";
end if;
