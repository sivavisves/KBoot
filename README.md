# KBoot

[![Runtests](https://github.com/sivavisves/KBoot/actions/workflows/runtests.yml/badge.svg)](https://github.com/sivavisves/KBoot/actions/workflows/runtests.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![GitHub last commit](https://img.shields.io/github/last-commit/snvisves/KBoot)


<div align="center">
    <div class="img-sizer" style="width: 500px">
        <img src="https://github.com/sivavisves/KBoot/blob/main/Images/kboot%20logo.png">
    </div>
</div>

# KBOOT: KNN-Bootstrapping Method for Scenario Generation

## Introduction

KBOOT, short for KNN-Bootstrapping, is an innovative method developed for scenario generation in stochastic programming. This method is particularly valuable for energy systems incorporating renewable resources. By merging k-Nearest Neighbors (KNN) and bootstrapping techniques, KBOOT generates realistic and diverse scenarios using historical data, offering significant insights for energy systems planning and analysis.

## How KBOOT Works

### Data Preparation
- **Historical Data**: Start with historical datasets of wind, solar, and load values.
- **Quantile Conversion**: Transform these actual values into quantiles, potentially using linear interpolation, to yield a time series of quantiles for each dataset.

### Block Formation
- **Creating Blocks**: Segment the historical quantile data into overlapping blocks (e.g., 48 hours each), sliding by a predetermined step size (e.g., 12 hours). This approach captures distinct historical patterns in each block.

### KNN Sampling
- **Reference Point**: Choose a reference point (like the first hour) for the day of interest and identify its quantile value as the "current point."
- **KNN Application**: Use KNN to locate the k historical blocks whose start aligns closely with the "current point." This ensures that the generated scenarios are quasi-conditional based on the current system state.

### Block Bootstrapping
- **Scenario Formation**: Bootstrap entire blocks from the identified k blocks to create scenarios. Each bootstrapped block represents a potential future trajectory, grounded in past data.

### Conversion to Actual Values
- **Final Transformation**: Convert the bootstrapped quantile scenarios back to actual values using forecasted marginal distributions. This aligns the scenarios with the expected statistical features of the forecast day.

## Benefits of KBOOT
- **Temporal Dependency Awareness**: By utilizing block bootstrapping, KBOOT maintains the temporal dependencies inherent in the historical data.
- **Flexibility**: The method is versatile, suitable for different data types and forecasting needs, and not limited to specific stochastic processes or distributions.
- **Conditional Sampling**: KBOOT's KNN component enables scenario generation that is quasi-conditional on recent observations, enhancing relevance to the current state of the system.
- **Diverse Scenarios**: The bootstrapping process ensures a wide array of scenarios, representing various potential future trajectories based on historical patterns.

---

