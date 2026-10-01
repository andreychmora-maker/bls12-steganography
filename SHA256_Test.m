// ====================================================================
// Helper bitwise functions for 32-bit words
// ====================================================================

function ROTR(x, n)
    // Right circular shift. We use addition instead of bitwise OR, 
    // as the shifted bits are guaranteed not to overlap.
    return (x div (2^n)) + ((x * (2^(32-n))) mod 4294967296);
end function;

function SHR(x, n)
    return x div (2^n);
end function;

function CH(x, y, z)
    // NOT x is implemented as (4294967295 - x) to ensure safe unsigned behavior
    return BitwiseXor(BitwiseAnd(x, y), BitwiseAnd(4294967295 - x, z));
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
    while (#m mod 64) ne 56 do
        Append(~m, 0);
    end while;

    // Append length (64 bits, big-endian)
    for i in [7..0 by -1] do
        Append(~m, (ml div (256^i)) mod 256);
    end for;

    // 2. Process blocks of 512 bits (64 bytes)
    for i in [1..#m by 64] do
        W := [0 : j in [1..64]];
        
        // First 16 words
        for j in [0..15] do
            W[j+1] := m[i+j*4]*16777216 + m[i+j*4+1]*65536 + m[i+j*4+2]*256 + m[i+j*4+3];
        end for;

        // Extend to 64 words
        for j in [17..64] do
            s0 := SIG0(W[j-15]);
            s1 := SIG1(W[j-2]);
            W[j] := (W[j-16] + s0 + W[j-7] + s1) mod 4294967296;
        end for;

        a := H[1]; b := H[2]; c := H[3]; d := H[4];
        e := H[5]; f := H[6]; g := H[7]; h := H[8];

        // Main compression loop
        for j in [1..64] do
            S1 := EP1(e);
            ch := CH(e, f, g);
            temp1 := (h + S1 + ch + K[j] + W[j]) mod 4294967296;
            S0 := EP0(a);
            maj := MAJ(a, b, c);
            temp2 := (S0 + maj) mod 4294967296;

            h := g;
            g := f;
            f := e;
            e := (d + temp1) mod 4294967296;
            d := c;
            c := b;
            b := a;
            a := (temp1 + temp2) mod 4294967296;
        end for;

        H[1] := (H[1] + a) mod 4294967296;
        H[2] := (H[2] + b) mod 4294967296;
        H[3] := (H[3] + c) mod 4294967296;
        H[4] := (H[4] + d) mod 4294967296;
        H[5] := (H[5] + e) mod 4294967296;
        H[6] := (H[6] + f) mod 4294967296;
        H[7] := (H[7] + g) mod 4294967296;
        H[8] := (H[8] + h) mod 4294967296;
    end for;

    // 3. Format result as a byte array
    out_bytes := [];
    for x in H do
        Append(~out_bytes, (x div 16777216) mod 256);
        Append(~out_bytes, (x div 65536) mod 256);
        Append(~out_bytes, (x div 256) mod 256);
        Append(~out_bytes, x mod 256);
    end for;

    return out_bytes;
end function;

// ====================================================================
// Testing
// ====================================================================

function BytesToHex(bytes)
    return &cat[ Sprintf("%02x", b) : b in bytes ];
end function;

function StringToBytes(str)
    return [ StringToInteger(Sprintf("%o", s), 8) : s in Eltseq(str) ];
end function;

// Test vector for the string "abc"
// Expected hash: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
test_str := "abc";
test_bytes := StringToBytes(test_str);
hash_result := SHA256(test_bytes);

print "Message:", test_str;
print "SHA-256:", BytesToHex(hash_result);
