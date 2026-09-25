# bls12-steganography

# BLS12-381 Steganography & Isogeny Obfuscation

This repository contains the Magma computational algebra scripts accompanying the research paper on mitigating DPI (Deep Packet Inspection) censorship for decentralized consensus networks. 

The primary contribution is the deterministic Point-to-Uniform obfuscation for $j=0$ pairing-friendly curves (including BLS12-381) via explicit rational isogeny mappings.

## Contents

1. **`bls12_381_g1_obfuscation.m`**
   A complete proof-of-concept implementation of the Elligator Squared obfuscation wrapper for the BLS12-381 $\mathbb{G}_1$ group (used for Validator Public Keys and Aggregate Signatures).
   - Implements the 11-isogeny forward map to the target curve (`Isogeny2Target`).
   - Implements the exact Base Preimage solver for the SSWU map (`BasePreimage`).
   - Includes full serialization simulation and a benchmarking loop computing CPU clock cycles for both Obfuscation and Deobfuscation.

2. **`bls12_381_g2_obfuscation.m`**
   A complete proof-of-concept implementation of the Elligator Squared obfuscation wrapper for the BLS12-381 $\mathbb{G}_2$ group (used for individual Validator Signatures). 
   - Implements the novel 3-isogeny inverse map (`EvaluateBackwardMap`).
   - Implements the strict RFC 9380 forward map.
   - Contains explicit test vectors to verify correct sign alignment.

3. **`bls12_381_kernel_search.m`**
   A theoretical foundation script demonstrating the explicit discovery of the kernel generator on the standard BLS12-381 curve. 
   - Uses division polynomials to isolate 11-torsion points over the base field $\mathbb{F}_p$.
   - Implements manual Vélu's formulas to construct the candidate isogenous curve.
   - Verifies the isomorphism between the derived curve and the target $E'$ used in the obfuscation mappings.

4. **`bls12_479_search.m`**
   An algorithmic search script introducing an explicit steganographic filter to standard BLS12 parameter generation. Demonstrates the discovery of the "steganographically optimal" **BLS12-479+** curve ($p = 479$ bits, $HW = 7$), which natively supports a 2-isogeny bridge.

5. **`bls12_479_isogeny_generator.m`**
   An automated generator for the 2-isogeny constants of the BLS12-479+ curve.
   - Isolates the $x$-coordinate of the 2-torsion point natively guaranteed by the strictly even cofactor.
   - Computes explicit Vélu's constants and the exact rational mapping coefficients for the ultra-efficient 2-isogeny bridge.

6. **`bls12_479_g1_obfuscation.m`**
   A comparative performance benchmark and proof-of-concept implementation of $\mathbb{G}_1$ obfuscation for the BLS12-479+ curve.
   - Replaces the heavy 11-isogeny arithmetic with the lightweight 2-isogeny equations.
   - Empirically demonstrates the "near-zero latency" advantage of the steganographically optimal curve through a 1000-iteration CPU cycle benchmark.

## How to Run

The scripts are written in Magma. To run the benchmark and verify the mappings, execute:

```bash
magma bls12_381_g1_obfuscation.m
magma bls12_381_g2_obfuscation.m
magma bls12_381_kernel_search.m
magma bls12_479_search.m
magma bls12_479_isogeny_generator.m
magma bls12_479_g1_obfuscation.m
```
The full mathematical derivations, complexity analysis, and proofs are available in the preprint: https://doi.org/10.5281/zenodo.22736944
