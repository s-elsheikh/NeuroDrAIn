# NeuroDrAIn
**NeuroDrAIn** is an end-to-end AI-based pipeline for evaluating CT scans following minimally invasive surgery for acute intracerebral hemorrhage (ICH). The pipeline automates ICH volumetry, quantifies drainage coverage by the ICH, and classifies the drain tip position as 'correct' or 'not correct'.

Post-surgery follow-up CT scans for ICH are typically used to assess the volume of hemorrhage and evaluate the drain tip position. Manual volumetry can be time-consuming, and the ABC/2 method is often prone to inaccuracies.

We previously developed a CNN-based model for segmenting ICH and drain structures [Accuracy of automated segmentation and volumetry of acute intracerebral hemorrhage following minimally invasive surgery using a patch‑based convolutional neural network in a small dataset](https://rdcu.be/dyUGM) ([segment_ich](https://github.com/s-elsheikh/segment_ich/)). 

We describe a MATLAB script, that quantifies the coverage profile of ICH and drain segmentations. Additionally, a machine learning algorithm uses this coverage profile to classify the drain tip position as "correct" or "incorrect." (under review). 

This repository includes all necessary files from the [segment_ich](https://github.com/s-elsheikh/segment_ich/) repository to run the complete pipeline.

## Cloning the Repository

Make sure you have Git installed on your system. To get started, clone this repository and navigate to the cloned folder:

```
git clone https://github.com/s-elsheikh/NeuroDrAIn.git
cd NeuroDrAIn
```


## Environment Setup

The pipeline requires Python, MATLAB, and R programming languages. To set up the Python environment, run the following commands:

```
conda env create -f=environment.yml
conda activate NeuroDrAIn
```

This will install [Patchwork CNN Toolbox](https://bitbucket.org/reisert/patchwork/src/master/) including necessary dependancies. 

A MATLAB installation with the [Tools for NIfTI and ANALYZE image](https://de.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image) is required. 

Additionally, an R session with the following packages is required [caret](https://CRAN.R-project.org/package=caret), [jsonlite](https://CRAN.R-project.org/package=jsonlite) and [stepPlr](https://CRAN.R-project.org/package=stepPlr) are required. Please refer to [Session Info](session_info.txt). 


## Script Descriptions
### segment.py:
* Expects a non-contrast CT scan in NIfTI format, located in the `data/` folder. 
* Produces `data/pred_drain_icb.nii.gz`, a 4D NIfTI object containing two 3D isotropic NIfTI volumes (1-mm resolution) indicating the probability of each voxel belonging to ICH/drain or background.
* File names are hardcoded in the script. Batch processing of multiple files or renaming outputs has not been implemented.

#### Usage

```
python3 segment.py
```
------------------------------------------------------------------------------------------------------------

### quantify_drain.m
* Expects:
   * input1: the prediction file, produced by `segment.py`.
   * input2: the non-contrast CT scan in NIfTI format. 
* File names are supplied as command-line arguments to the MATLAB script.

#### Plot of sample data

![Sample data resulting from  `quantify_drain.m`, showing an example of a correct and of a not correct position](images/coverage_profile.png)

#### Usage

*Note: Not tested*

```
matlab -nosplash -nodesktop -r "input1='/data/pred_drain_icb.nii.gz'; input2='/data/s_002.nii'; quantify_drain.m; exit;"
```
#### Outputs
The outputs are named based on `input1` file name (with `.nii.gz` stripped) and the following suffixes are added just before the file extension. Assuming input1='/data/pred_drain_icb.nii.gz' outputs are:
1. **Predicted ICH volume:**
'/data/pred_drain_icb_volume_icb.json'
  * Contains the volume of the ICH in cubic mm. 
3. **Drain Properties:**
'/data/pred_drain_icb_properties.json' 
  * Contains properties of detected drains (true and false positives), including the island number, dimensions (in mm), and volume (in cubic mm).
5. **Coverage profile:**
'/data/pred_drain_icb_profile_counter.json' (incremental numeric counters).
  * Contains the percentage radial coverage (0-1) of the drain by the ICH at 1-mm steps from the tip of the drain. 
6. **Coverage Profile Plot:**
'/data/pred_drain_icb_plot_counter.jpeg' (incremental numeric counters).
  * A plot of the above profile values. 

------------------------------------------------------------------------------------------------------------

### predict_position.R

The R script takes one argument: the path to a folder containing all `profile_[counter].json` files. It classifies each drain tip as "correct" or "not correct" and outputs the results in a CSV file called `prediction_results.csv`.
The script checks if the packages `c("caret", "stepPlr", "jsonlite")`are installed and attempts to install them if not found. 

#### Usage

```
Rscript --vanilla predict_position.R data
```
--------------------------------------------------------------------------------------------------------------

This project is licensed under the [MIT License](LICENSE).

