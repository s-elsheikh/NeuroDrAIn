# List of packages to check and install if necessary
packages <- c("caret", "reshape2", "stepPlr", "jsonlite")

# Check if each package is installed, and install it if not
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

# Get command-line arguments (used for passing folder path)
cli_args <- commandArgs(TRUE)

# Load a pre-trained model from a file
model <- readRDS("model.rds")  # Using base R's readRDS

# Print the input file paths to the console
cat(cli_args, "\n")

# List JSON files in the directory
jsons <- list.files(cli_args, full.names = TRUE, pattern = "profile_\\d+.json")

cat("jsons are:", jsons)


# Initialize a results data frame
result <- do.call(rbind, lapply(jsons, function(x) {
  
  # Extract the file name
  id <- basename(x) 
  
  # Read the JSON file
  coverage <- jsonlite::fromJSON(x)  
  
  # Transform JSON object into a structured data frame
  input <- data.frame(posi = names(unlist(coverage)), value = unlist(coverage))
  # Modify position names to match trained model input
  input$posi <- sub("profile", "drain.position_", input$posi)  
  
  # Select the first 15 rows
  input <- input[1:15, ]
  
  # Reshape to wide format to match model input
  wide_input <- as.data.frame(t(input$value))
  colnames(wide_input) <- input$posi
  
  # Predict using the pre-trained model
  prediction <- predict(model, wide_input)
  
  # Combine ID and prediction into a data frame
  out <- data.frame(id = id, prediction = prediction, stringsAsFactors = FALSE)
  
  # Return the processed output
  return(out)
}))

# Write results to a CSV file using base R
write.csv(result, "prediction_results.csv", row.names = FALSE)


