# Spike Detection & Time Series Segmentation for Neural Implants

This repository contains the implementation and experimental data supporting our publication on efficient, on-device spike detection and time-series segmentation for high-density neural implants.

## Overview

We propose a lightweight algorithm for detecting epileptic spikes in multichannel neural recordings using:
- Outlier-based peak detection (e.g. Z-score, NEO, ADO)
- A heuristic rule-based event classifier
- A multichannel consensus mechanism to improve robustness

The system is designed for real-time deployment on implantable hardware (tested on Pynq-Z2 / Zynq 7020 SoC), achieving:
- 95% accuracy
- 98% sensitivity
- 0.05 false detection rate

## Data Contents

| File | Description |
|------|-------------|
| `all_sessions_combined.csv` | Raw data across all sessions |
| `concatenated_overall_results.csv` | Combined output from all detectors |
| `compiled_detector_results.xlsx` | Summary of all detection outputs |
| `experiments_summary_per_detector.xlsx` | Metrics grouped by detection method |
| `experiments_summary_per_session.xlsx` | Metrics grouped by session |
| `grouped_by_detector.xlsx` | Detection outputs by detector |
| `grouped_by_session.xlsx` | Detection outputs by session |
| `ml_model_report.txt` | ML model training log |
| `ml_model_results.xlsx` | ML model performance metrics |
| `paper_results_table.xlsx` | Final results table for the publication |

