# Matlab PBPK toolbox

Badges (will probably only work when visibility is set to public):

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=niklhart/matpbpk)

## Initialization and getting started

Initialization

- execute `initPBPKtoolbox.m`
- now all toolbox folders are on the Matlab path

Getting started

- Cheatsheets are available online on the Moodle page, the MATLAB file containing code for the Toolbox cheatsheet is located in folder "projects".
- Tutorials are available online on the Moodle page, corresponding MATLAB files are located in folder "projects/Tutorials". At the end, these files contain solutions to the exercises shown in the Tutorial videos. 
- Create your own scripts in another subfolder of the "projects" folder.

## Important abbreviations

### Tissue subspaces

The following abbreviations are used to label particular tissue subspaces, expressed as their organ weights / volumes / fractions thereof

| Abbr      | Description                                                                                |
| --------- | ------------------------------------------------------------------------------------------ |
| `cel`     | Cellular part                                                                              |
| `int`     | Interstitial part                                                                          |
| `pla`     | Plasma in vascular part                                                                    |
| `ery`     | Erythrocytes in vascular part                                                              |
| `vas`     | Vascular part (`pla` + `ery`)                                                              |
| `tis`     | Tissue (`cel` + `int`)                                                                     |
| `exc`     | Extracellular (`int` + `vas`)                                                              |
| `tot`     | Total (`tis` + `vas`)                                                                      |
| `reg`     | Regional blood (identical to vascular part, see note below)                                |
| `res`     | Residual blood (contained in `vas`)                                                        |
| `rbt`     | Tissue contaminated with residual blood (`tis` + `res`)                                    |
| `exp`     | Experimentally measured (depending on the experimental conditions, `tis`, `rbt`, or `tot`) |
| **`spc`** | **To discuss** Generic notation for a tissue subspace (any of the above)                   |

**Difference `vas` vs `reg`**   

* a fraction `vas` refers to *tissue volume*  
* a fraction `reg` refers to *total blood volume*

### Body parts / sites

The following notation is used consistenly in the toolbox to denote particular parts of the body. 
For tissues (=non-blood compartments), these labels can be combined with the 
subspace notation above to denote the respective tissue subspaces.

| Abbr      | Description                                                                                              |
| --------- | -------------------------------------------------------------------------------------------------------- |
| `art`     | arterial blood                                                                                           |
| `adi`     | adipose tissue                                                                                           |
| `blo`     | blood (depending on the context, it may or may not contain regional blood)                               |
| `bon`     | (total) bone tissue                                                                                      |
| `bra`     | brain tissue                                                                                             |
| `ery`     | erythrocytes (red blood cells)                                                                           |
| `gut`     | gut (small + large intestine)                                                                            |
| `hea`     | heart tissue                                                                                             |
| `kid`     | kidney tissue                                                                                            |
| `liv`     | liver tissue                                                                                             |
| `lun`     | lung tissue                                                                                              |
| `mus`     | muscle tissue                                                                                            |
| `pla`     | blood plasma (depending on the context, it may or may not contain the plasma fraction of regional blood) |
| `rob`     | rest of body                                                                                             |
| `ski`     | skin                                                                                                     |
| `spl`     | spleen tissue                                                                                            |
| `tbl`     | total blood, incl. vascular part of tissues, i.e. regional blood                                         |
| `ven`     | venous blood                                                                                             |
| **`org`** | **To discuss** Generic notation for a site (any of the above)                                            |

### Tissue composition (constituents)

Used for prediction of tissue partitioning.

| Abbr (old) | Description           |
| ---------- | --------------------- |
| `nli`      | Neutral lipids        |
| `nph`      | Neutral phospholipids |
| `aph`      | Acidic phospholipids  |
| `Alb`      | Albumin               |
| `Lip`      | Lipoprotein           |

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
