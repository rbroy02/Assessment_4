# Experiment Plan

## Research question

This experiment investigates how increasing levels of data contamination affect the behaviour of Ordinary Least Squares (OLS), Least Median of Squares (LMS), and neural-network regression.

The aim is not to select a best model. The aim is to compare how the different modelling approaches respond as the proportion of contaminated observations increases.

## Dataset

The experiment will use the same stock-return dataset used in the previous assessment.

The data were obtained from Yahoo Finance using the R package `quantmod`. A fixed snapshot of the dataset is stored in the repository so that the experiment can be reproduced using the same observations.

The script used to generate the snapshot is also included in the repository.

The original snapshot will remain unchanged and will be used as the uncontaminated baseline for the experiment.

## Response and predictor variables

The same response and predictor variables used in the previous application will be retained.

The response variable will be:

- AAPL return

The predictor variables will be:

- SPY return
- QQQ return
- XLK return

These variables will be used consistently across all experimental conditions.

## Data preparation

Rows containing missing values in the variables required for modelling will be removed before the experiment.

The cleaned dataset will then be divided into training and testing data using a fixed random seed.

The same training and testing observations will be used throughout the experiment.

Only the training data will be contaminated.

The testing data will remain unchanged so that all models are evaluated against the same uncontaminated observations.

## Contamination

A contaminated observation is an observation in the training dataset whose response value has been deliberately altered.

Contamination will be introduced only into the AAPL response variable.

The magnitude of the modification will remain fixed throughout the experiment so that the main experimental factor is the proportion of contaminated observations.

The following contamination levels will be investigated:

- 0%
- 10%
- 20%
- 30%
- 40%
- 50%

The 0% condition represents the original uncontaminated training data.

The observations to be contaminated will be selected reproducibly using specified random seeds.

## Models

Five regression models will be investigated.

### Ordinary Least Squares

OLS will be fitted using the existing implementation from the previous application.

OLS estimates the regression coefficients by minimising the sum of squared residuals.

### Least Median of Squares

LMS will also use the existing implementation from the previous application.

LMS estimates the regression coefficients by minimising the median of the squared residuals.

### Neural Network 1

The first neural network will use one small hidden layer.

```r
hidden = 2
```

### Neural Network 2

The second neural network will use a wider hidden layer.

```r
hidden = 5
```

### Neural Network 3

The third neural network will use two hidden layers.

```r
hidden = c(5, 2)
```

The three configurations are intended to provide a simple comparison of neural networks with different levels of model complexity.

The neural networks will be implemented using the `neuralnet` package as required by the assessment.

All neural networks will use:

```r
linear.output = TRUE
```

because the response variable is continuous.

## Scaling

The variables used by the neural networks will be scaled before training.

Scaling parameters will be calculated using the training data and then applied to the corresponding test data.

This prevents information from the test data from influencing model training.

Predictions will be converted back to the original response scale before evaluation.

## Evaluation

All five models will be evaluated using the same uncontaminated test data.

The main evaluation measure will be Root Mean Squared Error (RMSE).

RMSE provides a common measure of prediction error that can be used to compare OLS, LMS and the neural-network models.

Mean Absolute Error (MAE) will also be calculated as a secondary measure.

Using the same evaluation measures for every model allows their behaviour under contamination to be compared directly.

## Experimental procedure

For each contamination level:

1. Begin with the same original training dataset.
2. Contaminate the required proportion of training observations.
3. Fit OLS to the contaminated training data.
4. Fit LMS to the contaminated training data.
5. Train Neural Network 1.
6. Train Neural Network 2.
7. Train Neural Network 3.
8. Generate predictions for the unchanged test dataset.
9. Calculate RMSE and MAE for each model.
10. Record the results.

The resulting model behaviour will then be compared across contamination levels.

## Neural-network training

The neural networks will be trained before the Shiny application is run.

The trained neural-network objects used to produce the final results will be saved as `.rds` files in the repository.

The Shiny application will display the previously calculated experimental results rather than retraining the neural networks interactively.

## Results to be presented

The application will present:

- the experimental question;
- the contamination levels;
- the models used;
- the three neural-network configurations;
- RMSE results across contamination levels;
- MAE results across contamination levels;
- a comparison of model behaviour;
- interpretation of similarities and differences;
- unexpected or unstable behaviour where observed;
- limitations of the experiment.

The main visualisation will compare model error against contamination level.

## Reproducibility

The repository will contain:

- the original fixed dataset snapshot;
- the code used to generate the dataset snapshot;
- the experimental plan;
- the contamination code;
- the OLS and LMS implementations;
- the neural-network code;
- the script used to conduct the experiment;
- saved `.rds` neural-network objects;
- saved experimental results.

Random seeds and modelling settings will be recorded in the code so that the experimental procedure can be reproduced.

## Limitations

The experiment uses one dataset and one particular method of introducing contamination.

The conclusions therefore describe the behaviour observed under these experimental conditions and should not be interpreted as general proof that one modelling method is always more robust than another.

The three neural-network configurations represent only a small selection of possible architectures.

The experiment is designed to investigate model behaviour rather than perform model selection or hyperparameter optimisation.