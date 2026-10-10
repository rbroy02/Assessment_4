contaminate_response <- function(data,
                                 response,
                                 proportion,
                                 magnitude = 5,
                                 seed = 1234) {
  
  # Copy version so the original data is not modified
  contaminated_data <- data
  
  # Number of observations
  n <- nrow(contaminated_data)
  
  # Number of observations to contaminate
  n_contaminated <- floor(n * proportion)
  
  # 0% contamination returns the original data
  if (n_contaminated == 0) {
    
    contaminated_data$contaminated <- FALSE
    
    return(contaminated_data)
  }
  
  # Reproducible random selection
  set.seed(seed)
  
  contaminated_rows <- sample(
    1:n,
    size = n_contaminated,
    replace = FALSE
  )
  
  # Standard deviation of the response
  response_sd <- sd(
    contaminated_data[[response]],
    na.rm = TRUE
  )
  
  # Randomly move contaminated observations
  # upward or downward
  direction <- sample(
    c(-1, 1),
    size = n_contaminated,
    replace = TRUE
  )
  
  # Apply contamination
  contaminated_data[[response]][contaminated_rows] <-
    contaminated_data[[response]][contaminated_rows] +
    direction * magnitude * response_sd
  
  # Mark contaminated observations
  contaminated_data$contaminated <- FALSE
  
  contaminated_data$contaminated[contaminated_rows] <- TRUE
  
  return(contaminated_data)
}