split_data <- function(data,
                       response,
                       predictors,
                       train_fraction = 0.80) {
  
  # Keep only the variables needed for modelling
  model_data <- data[
    complete.cases(
      data[, c(response, predictors)]
    ),
    c(response, predictors)
  ]
  
  # Total number of usable observations
  n <- nrow(model_data)
  
  # Number of observations assigned to training
  train_size <- floor(
    n * train_fraction
  )
  
  # First 80% of observations
  train_data <- model_data[
    1:train_size,
    ,
    drop = FALSE
  ]
  
  # Remaining 20% of observations
  test_data <- model_data[
    (train_size + 1):n,
    ,
    drop = FALSE
  ]
  
  return(
    list(
      train = train_data,
      test = test_data
    )
  )
}