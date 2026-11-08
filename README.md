# Type-1 Fuzzy Logic Algorithm in an Industrial PLC (FCA vs. MBA)

IEC 61131-3 Structured Text (ST) source codes for a Mamdani Type-1 Fuzzy Inference System (FIS) embedded in an ARM-based **Altus Nexto XP325 PLC** using MasterTool IEC XE (CODESYS).

## Repository Contents
* **`Fuzzy_FCA_XP325.st`**: *Function Computation Approach (FCA)* — Real-time analytical evaluation of triangular and trapezoidal membership functions using 32-bit/64-bit floating-point arithmetic (`REAL`/`LREAL`).
* **`Fuzzy_MBA_XP325.st`**: *Memory Based Approach (MBA)* — Pre-calculated Lookup Tables (LUTs) stored in RAM (`ARRAY [0..4] OF ARRAY [0..1000] OF INT`) with scaled fixed-point integer arithmetic.

## Authors
* **Matheus dos Santos Oliveira** — Department of Electrical Engineering, UTFPR (Apucarana, Brazil)
* **Prof. Dr. Willian Ricardo Bispo Murbak Nunes** — Department of Electrical Engineering, UTFPR (Apucarana, Brazil)
