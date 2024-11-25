# Computational Physiology Toolbox

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=niklhart/compphysiol) 
[![compphysiol CI](https://github.com/niklhart/compphysiol/actions/workflows/main.yml/badge.svg)](https://github.com/niklhart/compphysiol/actions/workflows/main.yml)
[![compphysiol code coverage](https://codecov.io/gh/niklhart/compphysiol/branch/master/graph/badge.svg)](https://app.codecov.io/gh/niklhart/compphysiol?branch=master)
![MATLAB Versions Tested](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/niklhart/compphysiol/master/reports/badge/tested_with.json)

The Computational Physiology Toolbox is a MATLAB toolbox for computations with 
physiology-based models, in particular physiologically-based pharmacokinetics (PBPK). 
It features a modular object-oriented design, has fully integrated unit 
computation capabilities and an intuitive scripting language.

## Using the Computational Physiology Toolbox

See `gettingStarted.mlx` for a first overview, and the `examples` folder
for a more detailed introduction to specific topics.

## Physiological abbreviations used in the toolbox

### Tissue subspaces

The following abbreviations are used to label particular tissue subspaces, expressed as their organ weights / volumes / fractions thereof

| Abbr  | Description                                                                                |
| ----- | ------------------------------------------------------------------------------------------ |
| `cel` | Cellular part                                                                              |
| `int` | Interstitial part                                                                          |
| `pla` | Plasma in vascular part                                                                    |
| `ery` | Erythrocytes in vascular part                                                              |
| `vas` | Vascular part (`pla` + `ery`)                                                              |
| `tis` | Tissue (`cel` + `int`)                                                                     |
| `exc` | Extracellular (`int` + `vas`)                                                              |
| `tot` | Total (`tis` + `vas`)                                                                      |
| `reg` | Regional blood (identical to vascular part, see note below)                                |
| `res` | Residual blood (contained in `vas`)                                                        |
| `rbt` | Tissue contaminated with residual blood (`tis` + `res`)                                    |
| `exp` | Experimentally measured (depending on the experimental conditions, `tis`, `rbt`, or `tot`) |
| `spc` | Generic notation for a tissue subspace (any of the above)                                  |

**Difference `vas` vs `reg`**   

* a fraction `vas` refers to *tissue volume*  
* a fraction `reg` refers to *total blood volume*

### Body parts / sites

The following notation is used consistenly in the toolbox to denote particular parts of the body. 
For tissues (=non-blood compartments), these labels can be combined with the 
subspace notation above to denote the respective tissue subspaces.

| Abbr  | Description                                                                                              |
| ----- | -------------------------------------------------------------------------------------------------------- |
| `art` | arterial blood                                                                                           |
| `adi` | adipose tissue                                                                                           |
| `blo` | blood (depending on the context, it may or may not contain regional blood)                               |
| `bon` | (total) bone tissue                                                                                      |
| `bra` | brain tissue                                                                                             |
| `ery` | erythrocytes (red blood cells)                                                                           |
| `gut` | gut (small + large intestine)                                                                            |
| `hea` | heart tissue                                                                                             |
| `kid` | kidney tissue                                                                                            |
| `liv` | liver tissue                                                                                             |
| `lun` | lung tissue                                                                                              |
| `mus` | muscle tissue                                                                                            |
| `pla` | blood plasma (depending on the context, it may or may not contain the plasma fraction of regional blood) |
| `rob` | rest of body                                                                                             |
| `ski` | skin                                                                                                     |
| `spl` | spleen tissue                                                                                            |
| `tbl` | total blood, incl. vascular part of tissues, i.e. regional blood                                         |
| `ven` | venous blood                                                                                             |
| `org` | Generic notation for a site (any of the above)                                                           |

### Tissue composition (constituents)

Used for prediction of tissue partitioning.

| Abbr (new) | Description           |
| ---------- | --------------------- |
| `nl`       | Neutral lipids        |
| `np`       | Neutral phospholipids |
| `ap`       | Acidic phospholipids  |
| `ew`       | Extracellular water   |
| `iw`       | Interstitial water    |
| `cw`       | Cellular water        |
| `pw`       | Plasma water          |
| `pr`       | Proteins              |
| `Alb`      | Albumin               |
| `Lip`      | Lipoprotein           |
