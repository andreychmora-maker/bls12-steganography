# BLS12 Steganography: Point Obfuscation via Explicit Inverse Isogenies

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23017613.svg)](https://doi.org/10.5281/zenodo.23017613)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository provides the open-source Magma computational algebra scripts accompanying the research on steganographic point obfuscation for curves with $j \in \{0, 1728\}$. It includes explicit parameter search algorithms, extraction routines for the standard BLS12-381 11-isogeny kernel, and a computationally trivial 2-isogeny bridge for the steganographically optimal BLS12-479+ and BLS12-539+ curves.

## 🚀 Empirical Performance Benchmarks & Architecture

**Unified Benchmark Environment:** All empirical simulations and cycle counts presented in this repository were evaluated on a single hardware and software platform: a 2.7 GHz Quad-Core Intel Core i7 (MacBookPro13,3) with 16 GB RAM, running the Magma Computational Algebra System (V2.29-6).

### 🌉 Isogeny Bridge: Breaking the Security-Performance Trade-off

To isolate the absolute algebraic efficiency of the isogeny bridges and remove the variance of probabilistic sampling, the benchmarks below represent the **core base cost of a single deterministic pipeline execution**. 

*(Note: In a production constant-time deployment, the Sender's obfuscation step must be wrapped in a fixed loop executed exactly N times to prevent timing side-channels, scaling the absolute obfuscation cost by N. The Receiver's deobfuscation remains exactly 1 iteration.)*

| Curve | Isogeny Degree | Obfuscation Base Cost (Sender) | Deobfuscation (Receiver) | Base Field | Security Level |
| :--- | :--- | :--- | :--- | :--- | :--- |
| BLS12-381 (Baseline) | 11-isogeny | ~26,433,000 cycles | ~2,667,000 cycles | 381-bit | ~128-bit |
| **BLS12-479+** | 2-isogeny | **~19,952,000 cycles** | **~1,842,000 cycles** | 479-bit | **~160-bit** |
| *Gain (479+ vs 381)* | | ***~1.32x Faster*** | ***~1.45x Faster*** | *+98 bits* | *+32 bits* |
| **BLS12-539+** (Optimal)| 2-isogeny | **~25,244,000 cycles** | **~2,318,000 cycles** | 539-bit | **~192-bit** |
| *Gain (539+ vs 381)* | | ***~1.05x Faster*** | ***~1.15x Faster*** | *+158 bits* | *+64 bits* |

**The Genetic Link Bonus & The Total Advantage:** Scaling from a 381-bit to a massive 539-bit base field normally incurs a strict performance penalty due to drastically heavier modular arithmetic. However, because our proposed curves share the optimal $E: y^2 = x^3 + 1$ architecture, their rational maps reduce to a trivial 2-isogeny  ($A'=-15, B'=22$). 

This fundamentally shatters the traditional cryptographic trade-off. The 2-isogeny evaluation and the simplified point arithmetic are so exceptionally lightweight that they completely overpower the base field arithmetic slowdown for **both** the sender and the receiver. The sender pays zero scaling penalty for the base algebraic cost. 

**The ultimate result:** The optimally secure BLS12-539+ profile delivers absolute 192-bit high-end security and exTNFS immunity, yet operates **~1.15x faster** at the steganographic deobfuscation layer and **~1.05x faster** at the base obfuscation layer than the drastically weaker, standard BLS12-381 curve.

**Full Signature Obfuscation ($\mathbb{G}_2$):** While the strictly even cofactor provides an ultra-efficient 2-isogeny bridge for $\mathbb{G}_1$, the structure of the sextic twist over $\mathbb{F}_q$, $q=p^2$ inherently supports an analogous low-degree isogeny bridge for $\mathbb{G}_2$ (paralleling the 3-isogeny in our BLS12-381 implementation). This guarantees complete, low-latency steganographic coverage for both public keys and aggregated signatures.

### 🛡️ The High-Security Profile: BLS12-539+ & The "Genetic Link"
To future-proof the protocol against exTNFS (Extended Tower Number Field Sieve) attacks, this repository also introduces the high-security **BLS12-539+** profile (featuring a massive 539-bit base field). 

For developers and researchers wanting to benchmark this architecture, here is the complete cryptographic specification:

#### Explicit Domain Parameters (BLS12-539+)
*   **Base Curve Equation ($E$):** $y^2 = x^3 + 1$
*   **Seed ($x$):** `0x400000000000000000032F1` *(Hamming Weight = 9)*
*   **Base Field Prime ($p$, 539-bit):**
    ```text
    Hex: 0x5555555555555555556ECDAAAAAAAAAAAAAAADD592341AAAAAAAAAAAE073DA2A83AD55555557570E89126C2FE055555F8E3EF3F9BFCF3E52EAC05D13300080094535DF1
    Dec: 1199710345211519035416219429741786876319311421933497483626991418658478319088544596915796254702839442454587420641007826572438113715342206999017869775578752368205297
    ```
*   **Subgroup Order ($r$):**
    ```text
    Dec: 2348542582773833227889579559074585135706986693842114542365887958205046357838972976018537621768903971344370401
    ```
*   **Curve Cofactor ($h$):**
    ```text
    Dec: 510831846955296286119459770875511248778769497171135232
    ```
*(Note: The cofactor is strictly even, mathematically guaranteeing the existence of the rational 2-torsion kernel).*

#### The "Genetic Link" and Isogeny Constants
While empirical hardware benchmarks currently model the 479-bit curve, a remarkable algebraic property emerged during the parameter search: **BLS12-539+ is genetically linked to BLS12-479+**. 

For both curves, the optimal base equation resolves to $E: y^2 = x^3 + 1$. Because the equation $x^3 + 1 = 0$ yields a trivial integer root ($x_0 = -1$), evaluating Vélu's formulas produces the exact same universally small 2-isogeny constants for both the 479-bit and 539-bit fields.

**Explicit 2-Isogeny Parameters:**
*   **Isogenous Curve ($E'$):** $y^2 = x^3 - 15x + 22$
*   **Rational Map Constants:** $A' = -15, B' = 22$
*   **2-Torsion Root (Kernel):** $x_0 = -1$

#### The Dual Jackpot: Native GLV Endomorphism Acceleration
Beyond the steganographic advantages of the 2-isogeny bridge, the architectural choice of $E: y^2 = x^3 + 1$ (where $B=1$) natively unlocks a highly efficient Gallant-Lambert-Vanstone (GLV) endomorphism for accelerating core base arithmetic. 

Because all BLS curves naturally satisfy $p \equiv 1 \pmod 3$, the 539-bit field $\mathbb{F}_p$ is guaranteed to contain a non-trivial cube root of unity $\beta$. This provides a nearly zero-cost map of the curve onto itself: $\phi(x, y) = (\beta x, y)$, which corresponds to multiplying the point by a specific scalar $\lambda$.

During standard cryptographic operations (such as validator key generation or signing), any massive 539-bit scalar $k$ can be algorithmically decomposed into two ~270-bit halves ($k = k_1 + k_2\lambda$). When evaluated using Shamir's trick, this GLV decomposition effectively cuts the cost of scalar multiplication in half. Thus, the $B=1$ parameter yields a **"dual jackpot"**: it seamlessly preserves the native GLV acceleration expected of standard BLS curves, while simultaneously providing the trivial $x_0 = -1$ kernel required for ultra-fast 2-isogeny payload obfuscation.

### ⚖️ The Asymmetric Advantage of Steganographic Transport

The empirical benchmarks reveal a massive computational asymmetry between the sender (obfuscation) and the receiver (deobfuscation). For the sender, the full obfuscation cost is substantial, as the probabilistic Pick-and-Check loop must be executed sequentially $N$ times in addition to the isogeny mapping and exact cofactor blinding. 

By contrast, the receiver performs zero probabilistic searching. Deobfuscation is a single, deterministic straight-line execution requiring only ~1.8M to ~2.6M cycles.

In the context of decentralized consensus networks (such as the Ethereum Beacon Chain), this native asymmetry is not a flaw, but a highly desirable architectural feature:

*   **One-to-Many Gossip Propagation:** A validator obfuscates a signature or public key only once (bearing the heavy Pick-and-Check and blinding costs), but that packet must be received, deobfuscated, and verified by tens of thousands of nodes. The low latency on the receiver end ensures that the network does not choke on propagation delays during mass block broadcasting.
*   **Light Client & IoT Synchronization:** Resource-constrained receivers (such as mobile wallets, browser clients, or IoT sensors) perform only trivial deterministic math. The heavy lifting of the probabilistic search is entirely offloaded to the powerful sender/validator.

### 🚧 The Direct SW Bottleneck
For the *forward* Hash-to-Curve mapping on curves with $j \in \{0, 1728\}$, recent direct encodings by Koshelev et al. (including SwiftEC) represent the absolute progressive state-of-the-art. These approaches elegantly reduce the forward evaluation to a single field exponentiation, completely bypassing the need for auxiliary isogenies.

However, steganography strictly requires the exact inverse operation (Point-to-Uniform). Simulating a strict constant-time extraction loop (100,000 iterations over the 381-bit base field) reveals the multi-branch penalty of inverting these direct Shallue-van de Woestijne (SW) encodings:

*   **Direct SW Inversion:** ~11.14 seconds (Requires evaluating 3 branches + constant-time Jacobi validations)
*   **Isogeny-Based SSWU:** ~1.89 seconds (0 isogeny roots + exactly 1 SSWU root)
*   **Result:** The proposed isogeny pipeline is **~5.89x faster** for steganographic obfuscation, perfectly corroborating the theoretical algebraic bounds.

### ⏱️ Constant-Time Execution & The Steganographic Boundary
The `bls12_381_constant_time_signatures.m` script models the *forward* Hash-to-Curve process, generating and verifying a BLS digital signature. In this scenario, a message is hashed to a scalar and deterministically mapped to a valid curve point via the SSWU algorithm and an isogeny bridge. 

Generating a signature and *steganographically hiding* it for network transmission are two fundamentally different tasks that enforce a strict architectural boundary:

*   **Generation (Hash-to-Curve):** Deterministically maps uniform data to a curve point. While the direct SW encodings by Koshelev et al. stand as the optimal approach for this specific *forward* task, our SSWU + Isogeny method yields a **~91.2% performance gain** over bounded Try-and-Increment (at 10,000 iterations).
*   **Obfuscation (Point-to-Uniform):** Once the message point is multiplied by the secret key, the resulting signature becomes an arbitrary point on the curve. Transmitting this point in plaintext exposes algebraic invariants to Deep Packet Inspection (DPI). To achieve indistinguishability, the point must be mapped back to uniform noise. 

**The Mathematical Necessity of Elligator Squared & The Pick-and-Check Reality:**
The SSWU algorithm is *not surjective*—its image covers only about 50% of the curve's points. Attempting to apply the inverse SSWU map directly to an arbitrary signature will fail half the time because the target point simply lacks a scalar preimage. 

The **Elligator Squared** framework resolves this by representing any target point as the sum of two new points ($\grave{Q} = P_u + P_v$), both of which are mathematically guaranteed to have SSWU preimages ($u$ and $v$). However, finding this valid pair natively reduces Elligator Squared to a probabilistic **"Pick-and-Check"** algorithm. By integrating Elligator Squared with our explicit inverse isogenies, the cost of each Pick-and-Check iteration drops drastically.

### 🔮 Vision: The "Ultimate Cryptographic Primitive"
Vitalik Buterin describes obfuscation as the "ultimate cryptographic primitive" because it allows a program to operate equivalently while revealing absolutely nothing about its inner workings or secret keys. While current privacy techniques (like ZKP) are often limited to user-owned domains, true obfuscation promises a path toward "perfect privacy" for decentralized systems. 

While Buterin's vision primarily focuses on the obfuscation of *computation*, this repository tackles the foundational prerequisite: the steganographic obfuscation of *cryptographic data in transit*. An adversary (or DPI classifier) cannot distinguish an obfuscated BLS consensus signature from ambient uniform noise. By integrating Elligator Squared with explicit inverse isogenies, we provide the mathematical framework required to achieve steganographic invisibility at the transport layer.

### 📂 Repository Structure

*   `bls12_479_search.m` — Algorithmic parameter search script incorporating a steganographic filter to discover optimal BLS12 curves (yields BLS12-479+).
*   `bls12_479_isogeny_generator.m` — Automated generator for the dual 2-isogeny constants over BLS12-479+.
*   `universal_isogeny_2_generator.m` — A universal framework computing optimal 2-isogeny constants for any arbitrary BLS12 curve ($y^2 = x^3 + B$). 
*   `bls12_381_g1_pipeline.m` — The complete Elligator Squared obfuscation pipeline for $\mathbb{G}_1$ on BLS12-381, integrating Fast Cofactor Clearing and tailored blinding.
*   `bls12_479_g1_pipeline.m` — The complete Elligator Squared obfuscation pipeline for $\mathbb{G}_1$ on BLS12-479+, mapping the mathematically exact Dual 2-Isogeny.
*   `bls12_539_g1_pipeline.m` — The high-security Elligator Squared obfuscation pipeline for $\mathbb{G}_1$ on BLS12-539+, dynamically generating parameters to secure the 2-Isogeny bridge.
*   `bls12_381_kernel_search.m` — Constructive extraction and verification of the $\mathbb{F}_p$ 11-isogeny kernel matching the RFC 9380 target curve for standard BLS12-381.
*   `bls12_381_g2_obfuscation.m` — Obfuscation wrapper evaluating the explicit inverse 3-isogeny for $\mathbb{G}_2$ signatures on the standard BLS12-381 curve over $\mathbb{F}_q$.
*   `direct_sw_bottleneck_simulation.m` — Empirical simulation demonstrating the ~6x multi-branch computational penalty of direct SW inversions.
*   `bls12_381_constant_time_signatures.m` — A comprehensive simulation of BLS signatures comparing Hash-to-Curve strategies.
*   `bls12_539_find_b.m` — Fast twist-search algorithm to determine the optimal $B$ parameter for the high-security BLS12-539+.
*   `universal_bls12_b_finder.m` — A universal twist-search algorithm that dynamically calculates the field prime $p$ from any BLS12 seed $x$.
*   `SHA256_Test.m` — A validation script testing the SHA-256 hash function implementation against standard cryptographic test vectors.

### ⚙️ Quick Start

The scripts are written for the [Magma Computational Algebra System](http://magma.maths.usyd.edu.au/magma/). To reproduce the parameter searches, constant generation, and hardware benchmarks locally, execute the following commands from your terminal:

```bash
# 1. Run the steganographic filter search for the optimal curve
magma bls12_479_search.m

# 2. Extract the 11-isogeny kernel for standard BLS12-381
magma bls12_381_kernel_search.m

# 3. Generate the exact dual 2-isogeny constants for BLS12-479+
magma bls12_479_isogeny_generator.m

# 4. Compute optimally minimized 2-isogeny constants for any BLS12 target
magma universal_isogeny_2_generator.m

# 5. Run the hardware benchmark pipeline for BLS12-381 G1 (11-Isogeny)
magma bls12_381_g1_pipeline.m

# 6. Run the hardware benchmark pipeline for BLS12-479+ (2-Isogeny)
magma bls12_479_g1_pipeline.m

# 7. Run the hardware benchmark pipeline for the high-security BLS12-539+
magma bls12_539_g1_pipeline.m

# 8. Run the hardware benchmark for BLS12-381 G2 signatures (3-Isogeny)
magma bls12_381_g2_obfuscation.m

# 9. Simulate the computational bottleneck of Direct SW Inversion
magma direct_sw_bottleneck_simulation.m

# 10. Simulate BLS signatures comparing Hash-to-Curve strategies
magma bls12_381_constant_time_signatures.m

# 11. Find the B parameter for the high-security BLS12-539+ curve
magma bls12_539_find_b.m

# 12. Find the B parameter for any BLS12 curve
magma universal_bls12_b_finder.m

# 13. Verify the SHA-256 hash function implementation against standard test vectors
magma SHA256_Test.m
```

### 📚 Academic Citation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19285755.svg)](https://doi.org/10.5281/zenodo.19285755)

If you utilize these scripts or the BLS12-479+ curve parameters in your research,
please cite the associated archive:

```bash
@misc{chmora2026bls12steganography,
  author       = {Andrey Chmora},
  title        = {Steganographic Point Obfuscation via Explicit Inverse Isogenies for $j \in \{0, 1728\}$},
  month        = {Sep},
  year         = {2026},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.22736944},
  url          = {[https://doi.org/10.5281/zenodo.19285755](https://doi.org/10.5281/zenodo.19285755)}
}
```
