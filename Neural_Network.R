library(neuralnet)



# Train neural network
fit_nn <- function(data,
                   response,
                   predictors,
                   hidden = 2,
                   seed = 1234) {
  
  # Keep only variables needed for the model
  model_data <- data[
    complete.cases(
      data[, c(response, predictors)]
    ),
    c(response, predictors)
  ]
  
  # Training means
  means <- sapply(
    model_data,
    mean
  )
  
  # Training standard deviations
  sds <- sapply(
    model_data,
    sd
  )
  
  # Scale training data
  scaled_data <- as.data.frame(
    scale(model_data)
  )
  
  # Create regression formula
  formula <- as.formula(
    paste(
      response,
      "~",
      paste(
        predictors,
        collapse = " + "
      )
    )
  )
  
  # Reproducible starting weights
  set.seed(seed)
  
  # Train neural network
  nn_model <- neuralnet(
    formula = formula,
    data = scaled_data,
    hidden = hidden,
    linear.output = TRUE,
    threshold = 0.05,
    stepmax = 1000000,
    rep = 5
  )
  
  return(
    list(
      model = nn_model,
      means = means,
      sds = sds,
      response = response,
      predictors = predictors,
      hidden = hidden
    )
  )
}



# Make predictions
predict_nn <- function(nn_fit, new_data) {
  
  response <- nn_fit$response
  predictors <- nn_fit$predictors
  means <- nn_fit$means
  sds <- nn_fit$sds
  
  # Keep predictor columns only
  predictor_data <- new_data[
    ,
    predictors,
    drop = FALSE
  ]
  
  # Scale using TRAINING means and SDs
  for (variable in predictors) {
    
    predictor_data[[variable]] <-
      (
        predictor_data[[variable]] -
          means[[variable]]
      ) /
      sds[[variable]]
  }
  
  # Find the repetition with the lowest training error
  best_rep <- which.min(
    nn_fit$model$result.matrix["error", ]
  )
  
  # Predict using that repetition
  scaled_predictions <- compute(
    nn_fit$model,
    predictor_data,
    rep = best_rep
  )$net.result[, 1]
  
  # Return prediction to original response scale
  predictions <-
    scaled_predictions * sds[[response]] +
    means[[response]]
  
  return(predictions)
}