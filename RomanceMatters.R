
# Clear the environment and console
rm(list = ls())
cat("\014")

# Load required libraries
required_packages <- c("statnet", "coda", "ergm", "network", "dplyr", "tidyr", 
                       "readxl", "mice", "tergm", "ergMargins", "stargazer", "psych", "GGally")

# Install missing libraries
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

lapply(required_packages, library, character.only = TRUE)

# Set working directory (modify this as needed)
# setwd("<your-path>")


### Data Preparation
# Function to load and process network data
load_network <- function(file_path, max_rows) {
  data <- read.csv(file = file_path, header = TRUE, stringsAsFactors = FALSE, row.names = 1)
  if (nrow(data) > max_rows) {
    data <- data[1:max_rows, ]
  }
  as.matrix(data)
}

# Load network files
A_mat <- load_network("FriendshipNetwork_t1_binary.csv", 133)
B_mat <- load_network("FriendshipNetwork_t2_binary.csv", 133)
C_mat <- load_network("FriendshipNetwork_t3_binary.csv", 134)

# Load and process attribute data
att <- read.csv(file = "attribute_AgeSexRom_analysis.csv", header = TRUE, stringsAsFactors = FALSE)
if (nrow(att) > 133) {
  att <- att[1:133, ]
}

# Rename columns for consistency
colnames(att)[colnames(att) %in% c("Age", "Male", "romantic.t1", "romantic.t2", "romantic.t3")] <- 
  c("age", "male", "romantic1", "romantic2", "romantic3")

# View attribute data summary
psych::describe(att)

### Network Creation
# Convert adjacency matrices to network objects
create_network <- function(matrix) {
  as.network.matrix(matrix, directed = TRUE, matrix.type = "adjacency")
}

ft1 <- create_network(A_mat)
ft2 <- create_network(B_mat)
ft3 <- create_network(C_mat)

### Imputation and Attribute Assignment

# Impute missing values
att_imp <- mice::mice(att)
att_imp <- mice::complete(att_imp)

# Reverse coding for selected columns
reverse_columns <- c("church1", "church2", "church3", "dance1", "dance2", "dance3")
att_imp[, reverse_columns] <- 5 - att_imp[, reverse_columns]

# Add attributes to networks
add_attributes <- function(network, attributes, suffix) {
  for (col in colnames(attributes)) {
    network %v% col <- attributes[[paste0(col, suffix)]]
  }
}

add_attributes(ft1, att_imp, "1")
add_attributes(ft2, att_imp, "2")
add_attributes(ft3, att_imp, "3")


### Friendship Dynamics
# Calculate friendship dynamics between time periods
calculate_dynamics <- function(mat1, mat2) {
  new_friends <- mat2 - mat1
  new_friends[new_friends < 0] <- 0
  
  lost_friends <- mat1 - mat2
  lost_friends[lost_friends < 0] <- 0
  
  list(new = sum(new_friends), lost = sum(lost_friends))
}

friendship_dynamics_t12 <- calculate_dynamics(A_mat, B_mat)
friendship_dynamics_t23 <- calculate_dynamics(B_mat, C_mat)

### Visualizations
# Plot networks with GGally
plot_network <- function(network, attribute, title) {
  ggnet2(network, 
         color = ifelse(network %v% attribute == 1, "steelblue", "tomato"),
         size = 4,
         legend.size = 10,
         legend.position = "bottom") + 
    ggtitle(title)
}

plot_network(ft1, "male", "Network at Time 1")
plot_network(ft2, "male", "Network at Time 2")
plot_network(ft3, "male", "Network at Time 3")

### Statistical Models
# Temporal Exponential Random Graph Models
stergm_model <- function(network_list, form_terms, dissolve_terms) {
  tergm(network_list ~ 
          Form(form_terms) + 
          Diss(dissolve_terms), 
        estimate = "CMLE")
}

model <- stergm_model(list(ft2, ft3), ~edges + mutual + gwesp(decay = 0.25, fixed = TRUE) + gwdsp(decay = 0.25, fixed = TRUE), 
                       ~edges + mutual + gwesp(decay = 0.25, fixed = TRUE) + gwdsp(decay = 0.25, fixed = TRUE))

summary(model)
