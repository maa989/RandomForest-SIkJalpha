# RandomForest-SIkJalpha
## Paper
https://arxiv.org/abs/2206.08967
## Repo Structure:
### 22_data-forecasts
This directory contains all the submission results for each team fetched from https://github.com/cdcepi/Flusight-forecast-data as well as some of our own generated results for 2022. All 2022 projections must be placed in this folder for evaluations
### Data_Processing
This directory containts one script to be run to generate and process the passed data for our 2022 predictors scripts. (So run this file first)
### Evaluation_Scripts
This contains all scripts necessary for evaluations. Use FLU_Evalutation.m for 2022 evaluation of flu hospitalizations and Evauluate_ILI.m for 2017-2019 evaluation of ILI hospitalizations (choose the year as an input). ForecastsOld.m simply evaluates the past team's submissions for the FluSight challenges per state and ForecastsOldT.m for the whole US population
### ILI_data_res
All ILI projections for the previous years are saved here. Place each year's projection in corresponding directory, the prefix "l" is for LSBoosted trees projections and "p" is for the ensemble of the predictors. The remaining .mat files are generated from ForecastsOld.m/ForecastsOldT.m for other teams' results.
