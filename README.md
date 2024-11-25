# NeuroDrAin
NeuroDrAin is an end-to-end AI-based pipeline for evaluating CT scans following minimally invasive surgery for acute intracerebral hemorrhage (ICH). The pipeline automates ICH volumetry, quantifies drainage, and classifies the drain tip position.

Follow-up CT scans after minimally invasive surgery for ICH are commonly used to assess the volume of ICH and evaluate the drain tip position, classifying it as either "correct" or "incorrect." Manual volumetry is time-consuming, and the ABC/2 method is prone to inaccuracies.

We developed a CNN-based model for segmenting ICH and drain structures ([segment_ich](https://github.com/s-elsheikh/segment_ich/)). A MATLAB script quantifies the coverage profile of ICH and drain segmentations. A machine learning algorithm then uses this coverage profile to classify the tip position as "correct" or "incorrect."

This repository includes all necessary files from the [segment_ich](https://github.com/s-elsheikh/segment_ich/) repository to run the complete pipeline.


## Environment Setup

The pipeline requires Python, MATLAB, and R programming languages. Creating the environment using the supplied environment file installs all necessary dependencies, except for MATLAB, which requires a separate license. The pipline was tested with MATLAB R2021a.

```
conda env create -f environment.yml
conda activate NeuroDrAIn
```
## Description of scripts
### segment.py:
1. Expects a non-contrast CT scan in NIfTI format, located in the `data/` folder. 
2. Produces `data/pred_drain_icb.nii.gz`, a 4D NIfTI object containing two 3D isotropic NIfTI volumes (1-mm resolution) indicating the probability of each voxel belonging to ICH/drain or background.
3. File names are hardcoded in the script. Batch processing of multiple files or renaming outputs has not been implemented.

#### Usage

```
python_segment.py
```
------------------------------------------------------------------------------------------------------------

### quantify_drain.m
1. expects the non-contrast CT in NIfTI format and the prediction file.
2. File names are supplied as command-line arguments to the MATLAB script.

#### Usage

```
matlab -nodisplay -nosplash -nodesktop -r "input1='/data/pred_drain_icb.nii.gz'; input2='/data/s_002.nii'; quantify_drain.m; exit;"
```
#### Outputs
Assuming input1='/data/pred_drain_icb.nii.gz' outputs are:
1. **Predicted ICH volume:**
'/data/pred_drain_icb_volume_icb.json'
3. **Drain Properties:**
'/data/pred_drain_icb_properties.json' 
  * Contains properties of detected drains (true and false positives), including the island number, dimensions (in mm), and volume (in cubic mm).
5. **Coverage profile:**
'/data/pred_drain_icb_profile_counter.json' (incremental numeric counters).
6. **Coverage Profile Plot:**
'/data/pred_drain_icb_plot_counter.jpeg' (incremental numeric counters).

------------------------------------------------------------------------------------------------------------

### predict_position.R

The R script expects a folder path containing all `profile_counter.json` files. It classifies each drain tip as "correct" or "incorrect" and outputs the results in a CSV file.

#### Usage

```
Rscript --vanilla predict_position.R ./data
```
--------------------------------------------------------------------------------------------------------------

This project is licensed under the [MIT License](LICENSE).

