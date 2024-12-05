# Romance-matters
This repository contains scripts and data for analyzing friendship networks over three-time points, including imputations for missing attributes and visualization of network dynamics.

## File Structure
- `data/raw/`: Raw input files.
- `data/processed/`: Processed data files.
- `scripts/`: R scripts for analysis and visualization.

## Usage
1. Install required R packages:
```
install.packages(c("psych", "mice", "network", "GGally"))
```
2. Run scripts in order:
- `01_data_preparation.R`
- `02_network_analysis.R`
- `03_visualization.R`
  
