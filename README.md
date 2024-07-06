# Fast Automatic Deconvolution (FAD) for Macro X-ray Fluorescence (MA-XRF) data collected from easel paintings

[Su Yan](https://profiles.imperial.ac.uk/s.yan18) ([s.yan18@imperial.ac.uk](mailto:s.yan18@imperial.ac.uk)) and Prof [Pier Luigi Dragotti](https://www.commsp.ee.ic.ac.uk/%7Epld/)

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Citation](#citation)
- [License](#license)

## Introduction

This repository is the official implementation of the Fast Automatic Deconvolution (FAD) method for Macro X-ray Fluorescence (MA-XRF) data collected from easel paintings based on MATLAB. Details of the FAD method can be found in "A fast automatic method for deconvoluting macro X-ray fluorescence data collected from easel paintings," IEEE Transactions on Computational Imaging, vol. 9, pp. 649-664, 2023. Paper links: [arxiv version](https://arxiv.org/abs/2210.17496) and [published version](https://ieeexplore.ieee.org/document/10158498).

![FAD workflow](https://github.com/Su828/XRF_fast_deconvolution/blob/main/doc/workflow.png)
The FAD method performs a pre-detection of the chemical elements from the average spectrum and maximum spectrum of the MA-XRF data. Based on the pre-detected elements, the FAD method then deconvolves the whole MA-XRF data and generates the corresponding element distribution maps.

**Advantages of the FAD method**: 1) Its ability to deconvolve MA-XRF data without a user's selection of expected chemical elements. This avoids unreliable results generated with different user selections. 2) Its ability to identify chemical elements with nearby characteristic energy levels, for example, Zn K&alpha; and Cu K&beta;. 

This work was in part of the EPSRC-funded ARTICT "Art Through the ICT Lens: Big Data Processing Tools to Support the Technical Study, Preservation and Conservation of Old Master Paintings" project (EP/R032785/1). More information: https://art-ict.github.io/artict/home.html

## Installation

- Get MATLAB installed. The code has been tested on MATLAB versions R2021b and R2023b, so it is recommended to use MATLAB version R2021b or newer.
- Download the code.
- Run MATLAB.
- Navigate to the code folder by typing in the MATLAB command window: `cd "the_foler_path"`

## Usage

To run the code, please follow the following steps:
1. Open "pre_processing.m" file. Run each section one by one.
2. Open "decon_fast_global_method.m". Run each section one by one.
3. Open "view_elemental_map_fast_method.m". Run each section one by one.

## Citation

If you use this code in your research, please cite the following paper:

```bibtex
@article{yan2023fast,
  title={A Fast Automatic Method for Deconvoluting Macro X-Ray Fluorescence Data Collected From Easel Paintings},
  author={Yan, Su and Huang, Jun-Jie and Verinaz-Jadan, Herman and Daly, Nathan and Higgitt, Catherine and Dragotti, Pier Luigi},
  journal={IEEE Transactions on Computational Imaging},
  volume={9},
  pages={649--664},
  year={2023},
  publisher={IEEE}
}
```
```bibtex
@article{yan2021prony,
  title={When de Prony Met Leonardo: An Automatic Algorithm for Chemical Element Extraction From Macro X-Ray Fluorescence Data},
  author={Yan, Su and Huang, Jun-Jie and Daly, Nathan and Higgitt, Catherine and Dragotti, Pier Luigi},
  journal={IEEE Transactions on Computational Imaging},
  volume={7},
  pages={908--924},
  year={2021},
  publisher={IEEE}
}
```
```bibtex
@inproceedings{yan2020revealing,
  title={Revealing Hidden Drawings in Leonardo's 'The Virgin of the Rocks' from Macro X-RAY Fluorescence Scanning Data through Element Line Localisation},
  author={Yan, Su and Huang, Jun-Jie and Daly, Nathan and Higgitt, Catherine and Dragotti, Pier Luigi},
  booktitle={ICASSP 2020-2020 IEEE International Conference on Acoustics, Speech and Signal Processing (ICASSP)},
  pages={1444--1448},
  year={2020},
  organization={IEEE}
}
```

## License

This work is licensed under a [Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License](https://creativecommons.org/licenses/by-nc-nd/4.0/) (CC BY-NC-ND 4.0 License).
