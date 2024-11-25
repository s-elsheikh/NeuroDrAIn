# Suppress startup messages from loaded libraries
suppressMessages({
  # Load required libraries for data manipulation, modeling, and file handling
  library(magrittr)  # Provides pipe operators for cleaner syntax
  library(caret)     # Tools for modeling and machine learning
  library(jsonlite)  # Functions for reading and writing JSON
  library(readr)     # Efficient reading and writing of data
  library(purrr)     # Functional programming tools
  library(dplyr)     # Data manipulation tools
  library(stringr)   # String manipulation utilities
  library(tidyr)     # Tools for reshaping and tidying data
  library(tibble)    # Modern and flexible data frames
})

# Get command-line arguments (used for passing folder path)
cli_args <- commandArgs(TRUE)

# Load a pre-trained model from a file
model <- read_rds("model.rds")

# Print the input file paths to the console
cat(cli_args, "\n")

jsons <- list.files(cli_args, full.names = TRUE,
                    pattern = "profile_\\d+.json")


# Process each file path in `cli_args` and combine the results into a data frame
result <- map_df(jsons, function(x) {
  # Extract the file name (without path) and remove the `.json` extension
  id <- x # fs::path_file(x) %>% str_remove(".json")
  
  # Read the JSON file into an R object
  coverage <- read_json(x)
  
  # Transform the JSON object into a structured data frame
  input <- coverage %>%
    unlist() %>%                      # Flatten the JSON structure
    as.data.frame() %>%               # Convert to a data frame
    rownames_to_column() %>%          # Convert row names to a column
    as_tibble() %>%                   # Convert to a tibble for better manipulation
    `names<-`(c("posi", "value")) %>% # Rename columns to "posi" and "value"
    slice(1:15) %>%                   # Select the first 15 rows
    mutate(
      posi = str_replace(posi, "profile", "drain.position_") # Rename positions
    ) %>% 
    pivot_wider(names_from = posi, values_from = value)      # Reshape to wide format
  
  # Generate a prediction using the pre-trained model and input data
  out <- tibble(
    id = id,                              # Add file ID as a column
    prediction = predict(model, input)   # Add prediction results
  )
  
  # Return the processed output
  return(out)
})

# Save the results to a CSV file
write_csv2(result, "result.csv")