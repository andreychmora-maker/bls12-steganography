# BLS12 Steganography: Point Obfuscation via Explicit Inverse Isogenies

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22736944.svg)](https://doi.org/10.5281/zenodo.22736944)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository provides the open-source Magma computational algebra scripts accompanying the research on steganographic point obfuscation for curves with $j \in \{0, 1728\}$. It includes explicit parameter search algorithms, extraction routines for the standard BLS12-381 11-isogeny kernel, and a computationally trivial 2-isogeny bridge for the steganographically optimal BLS12-479+ curve.

## 🚀 Empirical Performance Benchmarks

To empirically validate the steganographic optimization, we conducted hardware benchmarks simulating the **Elligator Squared** obfuscation framework. The evaluation compares the standard BLS12-381 curve (which mathematically mandates an 11-isogeny bridge) against our proposed BLS12-479+ curve (which natively supports a 2-isogeny bridge). 

**Hardware Environment:** 2.7 GHz Quad-Core Intel Core i7 (MacBookPro13,3), 16 GB RAM.

| Curve | Isogeny Degree | Obfuscation (Sender) | Deobfuscation (Receiver) | Base Field |
| :--- | :--- | :--- | :--- | :--- |
| **BLS12-381** (RFC 9381) | 11-isogeny | ~4,250,000 cycles | ~1,439,000 cycles | 381-bit |
| **BLS12-479+** (Proposed) | 2-isogeny | **~947,000 cycles** | **~56,000 cycles** | 479-bit |
| *Performance Gain* | | *~4.5x Speedup* | *~25.7x Speedup* | |

By reducing the algebraic complexity to a trivial quadratic preimage solver, the BLS12-479+ implementation strips the steganographic mask in **less than 20 microseconds**, imposing near-zero latency overhead on receiving validators.

## 📂 Repository Structure

*   `bls12_479_search.m` — Algorithmic parameter search script incorporating a steganographic filter to discover optimal BLS12 curves (yields BLS12-479+).
*   `bls12_479_isogeny_generator.m` — Automated generator for the dual 2-isogeny constants over BLS12-479+, utilizing explicit Vélu's formulas for the 2-torsion kernel.
*   `bls12_479_g1_obfuscation.m` — The complete Elligator Squared obfuscation wrapper for G1 on BLS12-479+, including the 10^5-iteration hardware benchmark loop.
*   `bls12_381_kernel_search.m` — Constructive extraction and verification of the F_p 11-isogeny kernel matching the RFC 9380 target curve for standard BLS12-381.
*   `bls12_381_g1_obfuscation.m` — Baseline obfuscation wrapper evaluating the explicit inverse 11-isogeny for G1 public keys on the standard BLS12-381 curve.
*   `bls12_381_g2_obfuscation.m` — Obfuscation wrapper evaluating the explicit inverse 3-isogeny for G2 signatures on the standard BLS12-381 curve over the F_p² extension field.
*   `direct_sw_bottleneck_simulation.m` — Empirical simulation demonstrating the ~6x multi-branch computational penalty of direct Shallue-van de Woestijne (SW) inversions compared to the proposed isogeny-based pipeline.

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
```

📚 Academic Citation

If you utilize these scripts or the BLS12-479+ curve parameters in your research,
please cite the associated dataset/software archive:
```bash
@misc{chmora2024bls12steganography,
  author       = {Andrey Chmora},
  title        = {BLS12 Steganography: Point Obfuscation via Explicit Inverse Isogenies},
  month        = {Sep},
  year         = {2026},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.22736944},
  url          = {[https://doi.org/10.5281/zenodo.22736944](https://doi.org/10.5281/zenodo.22736944)}
}
```
