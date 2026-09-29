# BLS12 Steganography: Point Obfuscation via Explicit Inverse Isogenies

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23017614.svg)](https://doi.org/10.5281/zenodo.23017614)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository provides the open-source Magma computational algebra scripts accompanying the research on steganographic point obfuscation for curves with $j \in \{0, 1728\}$. It includes explicit parameter search algorithms, extraction routines for the standard BLS12-381 11-isogeny kernel, and a computationally trivial 2-isogeny bridge for the steganographically optimal BLS12-479+ curve.

## 🚀 Empirical Performance Benchmarks & Architecture

**Unified Benchmark Environment:** All empirical simulations and cycle counts presented in this repository were evaluated on a single hardware and software platform: a 2.7 GHz Quad-Core Intel Core i7 (MacBookPro13,3) with 16 GB RAM, running the Magma Computational Algebra System (V2.29-6).

### 🌉 Isogeny Bridge: BLS12-381 vs. BLS12-479+
To validate the steganographic optimization, we compared the standard BLS12-381 curve (which mathematically mandates an 11-isogeny bridge) against our proposed BLS12-479+ curve (which natively supports a 2-isogeny bridge) within the **Elligator Squared** framework.

| Curve | Isogeny Degree | Obfuscation (Sender) | Deobfuscation (Receiver) | Base Field | Security Level |
| :--- | :--- | :--- | :--- | :--- | :--- |
| BLS12-381 (RFC 9381) | 11-isogeny | ~4,250,000 cycles | ~1,439,000 cycles | 381-bit | ~128-bit |
| **BLS12-479+** (Proposed) | 2-isogeny | **~947,000 cycles** | **~56,000 cycles** | 479-bit | **~160-bit** |
| *Performance Gain* | | *~4.5x Speedup* | *~25.7x Speedup* | | *+32 bits* |

By reducing the algebraic complexity to a trivial quadratic preimage solver, the BLS12-479+ implementation strips the steganographic mask in **less than 20 microseconds**, imposing near-zero latency overhead on receiving validators.

### ⚖️ The Asymmetric Advantage of Steganographic Transport

The empirical benchmarks reveal a massive computational asymmetry between the sender (obfuscation) and the receiver (deobfuscation). It is important to note that the ~947,000 cycles (for BLS12-479+) and ~4,250,000 cycles (for BLS12-381) represent the baseline overhead of evaluating the explicit inverse isogeny. For the sender, the full obfuscation cost is substantially higher, as the probabilistic Pick-and-Check loop must be executed in addition to this mapping. 

By contrast, the receiver performs zero probabilistic searching. Deobfuscation is a single, deterministic straight-line execution requiring only ~56,000 cycles on the optimal BLS12-479+ curve.

In the context of decentralized consensus networks (such as the Ethereum Beacon Chain), this native asymmetry is not a flaw, but a highly desirable architectural feature:

*   **One-to-Many Gossip Propagation:** A validator obfuscates a signature or public key only once (bearing the heavy Pick-and-Check and isogeny costs), but that packet must be received, deobfuscated, and verified by tens of thousands of nodes. The near-zero latency on the receiver end (<20 microseconds) ensures that the network does not choke on propagation delays during mass block broadcasting.
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

*   **Generation (Hash-to-Curve):** Deterministically maps uniform data to a curve point. While the direct SW encodings by Koshelev et al. stand as the most progressive and optimal approach for this specific *forward* task, our script demonstrates that even our SSWU + Isogeny method yields a **~91.2% performance gain** over bounded Try-and-Increment (at 10,000 iterations) and a **~58.5% gain** over unbounded trivial hashing.
*   **Obfuscation (Point-to-Uniform):** Once the message point is multiplied by the secret key, the resulting signature becomes an arbitrary point on the curve. Transmitting this point in plaintext exposes algebraic invariants to Deep Packet Inspection (DPI). To achieve indistinguishability, the point must be mapped back to uniform noise. 

**The Mathematical Necessity of Elligator Squared & The Pick-and-Check Reality:**
The SSWU algorithm is *not surjective*—its image covers only about 50% of the curve's points. Attempting to apply the inverse SSWU map directly to an arbitrary signature will fail half the time because the target point simply lacks a scalar preimage. 

The **Elligator Squared** framework resolves this non-surjectivity by representing any target point as the sum of two new points ($\grave{Q} = P_u + P_v$), both of which are mathematically guaranteed to have SSWU preimages ($u$ and $v$). However, finding this valid pair natively reduces Elligator Squared to a probabilistic **"Pick-and-Check"** algorithm. 

*The ensuing consequence:* To prevent timing side-channels during this probabilistic extraction, the Pick-and-Check loop must be artificially bounded to a fixed, constant number of iterations $N$. This is exactly where the computational bottleneck of direct SW encodings ($\ge 7$ heavy exponentiations per iteration) becomes catastrophic for high-throughput networks. By integrating Elligator Squared with our explicit inverse isogenies, the cost of each Pick-and-Check iteration drops to exactly 1 quadratic root extraction. Thus, while state-of-the-art direct Hash-to-Curve methods excel at signature generation, the Elligator Squared Pick-and-Check loop—powered by our inverse isogenies—is strictly mandatory at the transport layer to ensure *any* signature can be obfuscated securely and efficiently.

### 🔮 Vision: The "Ultimate Cryptographic Primitive"
Vitalik Buterin describes obfuscation as the "ultimate cryptographic primitive" because it allows a program to operate equivalently while revealing absolutely nothing about its inner workings or secret keys. While current privacy techniques (like zero-knowledge proofs) are often limited to user-owned domains, true obfuscation promises a path toward "perfect privacy" for decentralized systems. 

While Buterin's vision primarily focuses on the obfuscation of *computation*—such as hiding smart contract logic, obfuscating auctions, or enabling ultra-cheap ZKP verification where verifying a proof is as simple as verifying a signature—this repository tackles the foundational prerequisite: the steganographic obfuscation of *cryptographic data in transit*.

*   **The Indistinguishability Property:** Buterin formalizes privacy by stating that observers should be unable to distinguish between two obfuscated programs that implement the same functionality. Our Point-to-Uniform pipeline applies this exact theoretical principle to network traffic: an adversary (or DPI classifier) cannot distinguish an obfuscated BLS consensus signature from ambient uniform noise.
*   **Consensus Layer Survival:** Buterin notes that attackers might attempt to extract information from obfuscated contracts by simulating local, private forks. However, before complex smart contract obfuscation can even be realized, the underlying Layer-1 consensus (which relies on continuously broadcasting BLS signatures) must survive immediate state-level censorship. 

By integrating Elligator Squared with explicit inverse isogenies, we provide the mathematical framework required to achieve steganographic invisibility at the transport layer, securing the classical foundation necessary to support the "ultimate cryptographic primitives" of the future.

## 📂 Repository Structure

*   `bls12_479_search.m` — Algorithmic parameter search script incorporating a steganographic filter to discover optimal BLS12 curves (yields BLS12-479+).
*   `bls12_479_isogeny_generator.m` — Automated generator for the dual 2-isogeny constants over BLS12-479+, utilizing explicit Vélu's formulas for the 2-torsion kernel.
*   `bls12_479_g1_obfuscation.m` — The complete Elligator Squared obfuscation wrapper for $\mathbb{G}_1$ on BLS12-479+, including the $10^5$-iteration hardware benchmark loop.
*   `bls12_381_kernel_search.m` — Constructive extraction and verification of the $\mathbb{F}_p$ 11-isogeny kernel matching the RFC 9380 target curve for standard BLS12-381.
*   `bls12_381_g1_obfuscation.m` — Baseline obfuscation wrapper evaluating the explicit inverse 11-isogeny for $\mathbb{G}_1$ public keys on the standard BLS12-381 curve.
*   `bls12_381_g2_obfuscation.m` — Obfuscation wrapper evaluating the explicit inverse 3-isogeny for $\mathbb{G}_2$ signatures on the standard BLS12-381 curve over $\mathbb{F}_q$ extension field, where $q=p^2$.
*   `direct_sw_bottleneck_simulation.m` — Empirical simulation demonstrating the ~6x multi-branch computational penalty of direct Shallue-van de Woestijne (SW) inversions compared to the proposed isogeny-based pipeline.
*   `bls12_381_constant_time_signatures.m` — A comprehensive simulation of BLS signatures over BLS12-381 comparing three Hash-to-Curve strategies. It empirically demonstrates the severe performance penalties of achieving artificial constant-time execution via bounded Try-and-Increment versus the natively constant-time SSWU + Isogeny pipeline.

## ⚙️ Quick Start

The scripts are written for the [Magma Computational Algebra System](http://magma.maths.usyd.edu.au/magma/). To reproduce the parameter searches, constant generation, and hardware benchmarks locally, execute the following commands from your terminal:

```bash
# 1. Run the steganographic filter search for the optimal curve
magma bls12_479_search.m

# 2. Extract the 11-isogeny kernel for standard BLS12-381
magma bls12_381_kernel_search.m

# 3. Generate the exact dual 2-isogeny constants for BLS12-479+
magma bls12_479_isogeny_generator.m

# 4. Run the 100,000-iteration hardware benchmark for BLS12-479+ (2-Isogeny)
magma bls12_479_g1_obfuscation.m

# 5. Run the baseline hardware benchmark for BLS12-381 G1 (11-Isogeny)
magma bls12_381_g1_obfuscation.m

# 6. Run the hardware benchmark for BLS12-381 G2 signatures (3-Isogeny)
magma bls12_381_g2_obfuscation.m

# 7. Simulate the computational bottleneck of Direct SW Inversion
magma direct_sw_bottleneck_simulation.m

# 8. Simulate BLS signatures over BLS12-381 comparing three Hash-to-Curve strategies
magma bls12_381_constant_time_signatures.m
```
### 📚 Academic Citation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22736944.svg)](https://doi.org/10.5281/zenodo.22736944)

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
  url          = {[https://doi.org/10.5281/zenodo.22736944](https://doi.org/10.5281/zenodo.22736944)}
}
```
