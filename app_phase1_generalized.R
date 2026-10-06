library(shiny)
library(plotly)

source("model_engine.R")
source("Actual_vs_fitted.R")
source("Correlation_heatmap.R")
source("Cumulative_returns.R")
source("Residuals_vs_fitted.R")


# -----------------------------
# UI
# -----------------------------

ui <- fluidPage(

  titlePanel("Regression Analysis"),

  tabsetPanel(

    # -------------------------
    # Data tab
    # -------------------------

    tabPanel(
      "Data",

      br(),

      fluidRow(

        column(
          width = 4,

          wellPanel(

            h3("1. Upload Data"),

            fileInput(
              "file",
              "Upload CSV File",
              accept = ".csv"
            ),

            helpText(
              "Upload a CSV file containing the variables you want to analyse.
               Each row should represent one observation."
            ),

            hr(),

            h3("2. Select Response Variable"),

            uiOutput("response_selector"),

            helpText(
              "Select the numeric variable that will be modelled."
            ),

            hr(),

            h3("3. Select Predictor Variables"),

            uiOutput("explanatory_selector"),

            helpText(
              "Select one or more numeric variables to use as predictors."
            ),

            hr(),

            actionButton(
              "fit_models",
              "Fit Regression Models",
              width = "100%"
            )
          )
        ),

        column(
          width = 8,

          h2("Dataset Preview"),

          p(
            "The first 10 observations from the uploaded dataset are displayed below."
          ),

          tableOutput("data_preview"),

          hr(),

          h3("How the model is structured"),

          p(
            "The selected response variable is modelled using the selected predictor variables."
          ),

          wellPanel(
            p(
              strong("Example using the original stock-return sample:")
            ),
            p(
              "AAPL = Intercept + a(SPY) + b(QQQ) + c(XLK)"
            )
          ),

          h3("Variable Roles"),

          p(
            strong("Response variable: "),
            "the numeric outcome that the regression model attempts to explain or predict."
          ),

          p(
            strong("Predictor variables: "),
            "numeric variables used to explain variation in the response variable."
          )
        )
      )
    ),


    # -------------------------
    # Regression tab
    # -------------------------

    tabPanel(
      "Regression",

      br(),

      h2("OLS and LMS Regression"),

      p(
        "This section compares Ordinary Least Squares and Least Median of Squares regression."
      ),

      hr(),

      fluidRow(

        column(
          width = 6,

          wellPanel(
            h3("Ordinary Least Squares"),

            p(
              "OLS chooses regression coefficients that minimise the sum of squared residuals."
            ),

            strong("Objective:"),

            p("Minimise the Residual Sum of Squares (RSS)"),

            tableOutput("ols_coefficients")
          )
        ),

        column(
          width = 6,

          wellPanel(
            h3("Least Median of Squares"),

            p(
              "LMS chooses regression coefficients that minimise the median of squared residuals."
            ),

            strong("Objective:"),

            p("Minimise the Median of Squared Residuals"),

            tableOutput("lms_coefficients")
          )
        )
      ),

      hr(),

      h2("Regression Plot"),

      p(
        "When exactly one predictor is selected, this plot shows the observed data together with the fitted OLS and LMS relationships."
      ),

      plotOutput(
        "regression_plot",
        height = "450px"
      ),

      hr(),

      h2("Actual vs Fitted Values"),

      p(
        "This plot compares the observed response values with the fitted values produced by OLS and LMS."
      ),

      plotOutput(
        "fitted_plot_base",
        height = "400px"
      ),

      hr(),

      h2("Residual Comparison"),

      p(
        "A residual is the difference between an observed response value and the value fitted by the model."
      ),

      plotOutput(
        "residual_plot_base",
        height = "400px"
      ),

      hr(),

      h2("Model Results"),

      tableOutput("model_comparison"),

      hr(),

      h2("How to Interpret the Results"),

      wellPanel(

        h3("Regression Coefficients"),

        p(
          "Each coefficient describes the estimated relationship between a predictor and the response while the other selected predictors are held constant."
        ),

        hr(),

        h3("R-squared"),

        p(
          "R-squared represents the proportion of variation in the response variable explained by the selected predictors."
        ),

        hr(),

        h3("Residuals"),

        p(
          "Residuals represent the difference between observed and fitted response values."
        )
      )
    ),


    # -------------------------
    # Graphs tab
    # -------------------------

    tabPanel(
      "Graphs",

      br(),

      h2("Exploratory and Diagnostic Graphs"),

      p(
        "These visualisations help inspect relationships between variables and the fitted regression model."
      ),

      hr(),

      h2("Correlation Heatmap"),

      p(
        "This graph displays correlations between numeric variables in the uploaded dataset."
      ),

      plotlyOutput(
        "correlation_heatmap",
        height = "500px"
      ),

      hr(),

      h2("Actual vs Fitted Values"),

      plotlyOutput(
        "fitted_plot_interactive",
        height = "450px"
      ),

      hr(),

      h2("Residuals vs Fitted Values"),

      plotlyOutput(
        "residual_plot_interactive",
        height = "450px"
      ),

      hr(),

      h2("Cumulative Returns"),

      p(
        "This plot is relevant only when the uploaded dataset contains return data. It is retained from the original stock-return application."
      ),

      uiOutput("cumulative_section")
    )
  )
)


# -----------------------------
# Server
# -----------------------------

server <- function(input, output, session) {

  # Read uploaded CSV
  dataset <- reactive({

    req(input$file)

    read.csv(
      input$file$datapath,
      header = TRUE,
      check.names = FALSE
    )
  })


  # Dataset preview
  output$data_preview <- renderTable({

    head(dataset(), 10)
  })


  # Numeric variable names
  numeric_variables <- reactive({

    data <- dataset()

    names(data)[sapply(data, is.numeric)]
  })


  # Response selector
  output$response_selector <- renderUI({

    vars <- numeric_variables()

    validate(
      need(
        length(vars) >= 2,
        "The dataset must contain at least two numeric variables."
      )
    )

    default_response <- if ("AAPL" %in% vars) "AAPL" else vars[1]

    selectInput(
      "response",
      "Response Variable:",
      choices = vars,
      selected = default_response
    )
  })


  # Predictor selector
  output$explanatory_selector <- renderUI({

    req(input$response)

    vars <- setdiff(
      numeric_variables(),
      input$response
    )

    default_predictors <- intersect(
      c("SPY", "QQQ", "XLK"),
      vars
    )

    if (length(default_predictors) == 0 && length(vars) > 0) {
      default_predictors <- vars[1]
    }

    selectInput(
      "explanatory",
      "Predictor Variables:",
      choices = vars,
      selected = default_predictors,
      multiple = TRUE
    )
  })


  # Complete-case model dataset
  model_data <- eventReactive(input$fit_models, {

    req(input$response)
    req(input$explanatory)
    req(length(input$explanatory) >= 1)

    data <- dataset()

    required_columns <- c(
      input$response,
      input$explanatory
    )

    data[
      complete.cases(data[, required_columns, drop = FALSE]),
      required_columns,
      drop = FALSE
    ]
  })


  # OLS
  model_result <- eventReactive(input$fit_models, {

    data <- model_data()

    fit_model(
      data = data,
      response = input$response,
      predictors = input$explanatory
    )
  })


  # LMS
  lms_result <- eventReactive(input$fit_models, {

    data <- model_data()

    fit_lms(
      data = data,
      response = input$response,
      predictors = input$explanatory
    )
  })


  # OLS coefficients
  output$ols_coefficients <- renderTable({

    result <- model_result()

    data.frame(
      Variable = names(result$coefficients),
      Coefficient = round(
        as.numeric(result$coefficients),
        6
      )
    )
  })


  # LMS coefficients
  output$lms_coefficients <- renderTable({

    result <- lms_result()

    data.frame(
      Variable = names(result$coefficients),
      Coefficient = round(
        as.numeric(result$coefficients),
        6
      )
    )
  })


  # Regression plot
  output$regression_plot <- renderPlot({

    result <- model_result()
    lms <- lms_result()
    data <- model_data()

    validate(
      need(
        length(input$explanatory) == 1,
        "Select exactly one predictor to display the regression plot."
      )
    )

    x <- data[[input$explanatory]]
    y <- data[[input$response]]

    plot(
      x,
      y,
      pch = 19,
      xlab = input$explanatory,
      ylab = input$response,
      main = paste(
        input$response,
        "vs",
        input$explanatory
      )
    )

    order_x <- order(x)

    lines(
      x[order_x],
      result$fitted[order_x],
      lwd = 2
    )

    lines(
      x[order_x],
      lms$fitted[order_x],
      lwd = 2,
      lty = 2
    )

    legend(
      "topleft",
      legend = c("OLS", "LMS"),
      lty = c(1, 2),
      lwd = 2
    )
  })


  # Base actual vs fitted plot
  output$fitted_plot_base <- renderPlot({

    result <- model_result()
    lms <- lms_result()
    data <- model_data()

    actual <- data[[input$response]]

    plot(
      actual,
      type = "l",
      lwd = 2,
      xlab = "Observation",
      ylab = input$response,
      main = paste(
        input$response,
        "- Actual vs Fitted Values"
      )
    )

    lines(
      result$fitted,
      lwd = 2,
      lty = 2
    )

    lines(
      lms$fitted,
      lwd = 2,
      lty = 3
    )

    legend(
      "topright",
      legend = c("Actual", "OLS", "LMS"),
      lty = c(1, 2, 3),
      lwd = 2
    )
  })


  # Base residual comparison
  output$residual_plot_base <- renderPlot({

    result <- model_result()
    lms <- lms_result()

    plot(
      result$residuals,
      type = "p",
      pch = 19,
      xlab = "Observation",
      ylab = "Residual",
      main = "OLS and LMS Residuals"
    )

    points(
      lms$residuals,
      pch = 1
    )

    abline(
      h = 0,
      lty = 2
    )

    legend(
      "topright",
      legend = c("OLS", "LMS"),
      pch = c(19, 1)
    )
  })


  # Model comparison
  output$model_comparison <- renderTable({

    result <- model_result()
    lms <- lms_result()

    data.frame(
      Statistic = c(
        "Residual Sum of Squares",
        "R-squared",
        "Optim Convergence Code"
      ),

      OLS = c(
        round(result$rss, 6),
        round(result$r_squared, 6),
        result$convergence
      ),

      LMS = c(
        round(lms$rss, 6),
        round(lms$r_squared, 6),
        lms$convergence
      )
    )
  })


  # Correlation heatmap
  output$correlation_heatmap <- renderPlotly({

    data <- dataset()

    numeric_data <- data[
      ,
      sapply(data, is.numeric),
      drop = FALSE
    ]

    validate(
      need(
        ncol(numeric_data) >= 2,
        "At least two numeric variables are required."
      )
    )

    make_correlation_heatmap(
      numeric_data
    )
  })


  # Interactive actual vs fitted
  output$fitted_plot_interactive <- renderPlotly({

    result <- model_result()

    make_actual_vs_fitted_plot(
      result
    )
  })


  # Interactive residual plot
  output$residual_plot_interactive <- renderPlotly({

    result <- model_result()

    make_residuals_vs_fitted_plot(
      result
    )
  })


  # Cumulative returns: retain old functionality, but only when appropriate
  output$cumulative_section <- renderUI({

    data <- dataset()

    if (!("date" %in% tolower(names(data)))) {

      return(
        wellPanel(
          p(
            "Cumulative returns are not shown because this dataset does not contain a date column."
          )
        )
      )
    }

    plotlyOutput(
      "cumulative_return_plot",
      height = "450px"
    )
  })


  output$cumulative_return_plot <- renderPlotly({

    data <- dataset()

    date_column <- names(data)[
      tolower(names(data)) == "date"
    ][1]

    req(date_column)

    data[[date_column]] <- as.Date(
      data[[date_column]]
    )

    make_cumulative_return_plot(
      data
    )
  })
}


# -----------------------------
# Run application
# -----------------------------

shinyApp(
  ui = ui,
  server = server
)
