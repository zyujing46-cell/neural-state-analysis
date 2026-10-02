# Decode Latent States

[![DOI](https://zenodo.org/badge/1400620014.svg)](https://doi.org/10.5281/zenodo.23090165)

MATLAB code for decoding latent neural states from dorsal medial prefrontal cortex spike recordings in Wistar and alcohol-preferring P rats drinking alcohol or quinine-adulterated alcohol.

## What the code does

All analyses are in `Main.m`, organised as sections that are switched on or off with flags at the top of the file. The sections are ordered so that, starting from the raw data alone, switching every flag on regenerates all results and figures:

1. **Preprocessing:** spike trains are binned and smoothed into firing rates.
2. **Behavior:** drinking time per trial and a seeking-intensity model (drinking time convolved with a canonical HRF).
3. **Neural dynamics:** trial-set recurrence matrices (RM) and affinity matrices (AM) are built from dynamic functional connectivity.
4. **Latent states:** latent neural states are identified as Louvain modules of the AM.
5. **Neural-behavioral alignment:** the states are compared with drinking and seeking behavior using state specificity, mutual information and PCA-based models.
6. **Figures:** main and supplementary figures.

Helper functions are in `functions/`, one per file. These include the third-party `community_louvain` (Brain Connectivity Toolbox), `shadedErrorBar`, `sigstar` and `violinplot`.

## Data

The data folder `Rodent data set` is available on figshare: https://doi.org/10.6084/m9.figshare.34047264. It contains:

- `Raw_data/`: spike-sorted and behavioral recordings (74 sessions)
- `Processed_sessions/`: per-session variables computed by `Main.m`
- `Saved_variables/`: cross-session variables computed by `Main.m`
- `exported_data/`: figure source data, one CSV file per figure (Fig1IJ, Fig3E, Fig6CD, Fig7ABCFI, FigS1, FigS3, FigS5ABCD, FigS6)

The raw recordings are from Timme et al. (2022), *Nature Communications*, https://doi.org/10.1038/s41467-022-31731-4 (public data: https://doi.org/10.6084/m9.figshare.19387511.v2), and were provided by the Lapish lab.

## Getting started

1. Download this repository and the data folder.
2. Put them side by side in one folder:

   ```
   AnyFolder/
   ├── Decode_Latent_States/
   └── Rodent data set/
   ```

   If the downloaded code folder is named `Decode_Latent_States-main`, rename it to `Decode_Latent_States`.
3. Open `Main.m` in MATLAB, set the flags of the sections you want to run to `1`, and run the script.

## Requirements

- MATLAB (tested with R2023a)
- Statistics and Machine Learning Toolbox
- Signal Processing Toolbox
- Image Processing Toolbox
- [Hatchfill2](https://www.mathworks.com/matlabcentral/fileexchange/53593-hatchfill2) from MATLAB File Exchange
