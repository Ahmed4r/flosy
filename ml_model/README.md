# Expense Prediction ML Model

## Setup & Training

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Train the model:
   ```bash
   python train_model.py
   ```

3. This will generate:
   - `assets/models/expense_predictor.tflite` (the model)
   - `ml_model/norm_params.json` (normalization parameters)

## Model Architecture

- **Input**: 5 features
  - Last month expense
  - Two months ago expense
  - 3-month average
  - Month number (1-12)
  - Day of month

- **Output**: Predicted next month expense

- **Architecture**: 
  - Dense(32) + ReLU + Dropout(0.2)
  - Dense(16) + ReLU + Dropout(0.2)
  - Dense(8) + ReLU
  - Dense(1) + Linear

## Model Performance

The model is trained on synthetic data for demonstration.
Replace with real transaction data for production use.

