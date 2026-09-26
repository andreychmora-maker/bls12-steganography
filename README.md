# bls12-steganography

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

*   `bls12_479_isogeny_generator.m` — Automated generator for the dual 2-isogeny constants over BLS12-479+, utilizing explicit Vélu's formulas for the 2-torsion kernel.
*   `bls12_479_g1_obfuscation.m` — The complete Elligator Squared obfuscation wrapper for $\mathbb{G}_1$ on BLS12-479+, including the $10^5$-iteration hardware benchmark loop.
*   `bls12_381_g1_obfuscation.m` — Baseline obfuscation wrapper evaluating the 11-isogeny on the standard BLS12-381 curve.
*   `bls12_381_inverse_11_isogeny.m` — Constructive extraction of the $\mathbb{F}_p$ 11-isogeny kernel matching the RFC 9380 target curve.

## ⚙️ Quick Start

The scripts are written for the [Magma Computational Algebra System](http://magma.maths.usyd.edu.au/magma/). To reproduce the hardware benchmarks locally, execute the following from your terminal:

```bash
# Run the 2-Isogeny Benchmark for BLS12-479+
magma bls12_479_g1_obfuscation.m

# Run the 11-Isogeny Baseline for BLS12-381
magma bls12_381_g1_obfuscation.m
