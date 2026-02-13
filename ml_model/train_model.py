"""
Expense Prediction Model Training Script
Trains a TFLite model for predicting monthly expenses by category.
"""

import os
import numpy as np
import tensorflow as tf
import json

# Set random seed for reproducibility
np.random.seed(42)
tf.random.set_seed(42)

print("TensorFlow version:", tf.__version__)

# Output paths (relative to project root)
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TFLITE_PATH = os.path.join(PROJECT_ROOT, 'assets', 'models', 'expense_predictor.tflite')
NORM_PARAMS_PATH = os.path.join(PROJECT_ROOT, 'assets', 'models', 'norm_params.json')

# Ensure output directory exists
os.makedirs(os.path.dirname(TFLITE_PATH), exist_ok=True)


# ==================== DATA GENERATION ====================
def generate_synthetic_data(n_samples=1000):
    """
    Generate synthetic expense data for training.
    Features: [last_month_expense, two_months_ago, avg_3_months, month_number, day_of_month]
    Target: next_month_expense
    """
    X = []
    y = []

    for _ in range(n_samples):
        base = np.random.uniform(100, 1000)
        trend = np.random.uniform(-0.2, 0.3)

        month_1 = base * np.random.uniform(0.8, 1.2)
        month_2 = month_1 * (1 + trend + np.random.normal(0, 0.1))
        month_3 = month_2 * (1 + trend + np.random.normal(0, 0.1))
        next_month = month_3 * (1 + trend + np.random.normal(0, 0.1))

        avg_3_months = (month_1 + month_2 + month_3) / 3
        month_num = np.random.randint(1, 13)
        day = np.random.randint(1, 29)

        X.append([month_3, month_2, avg_3_months, month_num, day])
        y.append(next_month)

    return np.array(X, dtype=np.float32), np.array(y, dtype=np.float32)


print("\n[1/6] Generating training data...")
X_train, y_train = generate_synthetic_data(800)
X_test, y_test = generate_synthetic_data(200)
print(f"Training: {len(X_train)}, Test: {len(X_test)}, Features: {X_train.shape[1]}")

# Normalize
print("\n[2/6] Normalizing data...")
X_mean = X_train.mean(axis=0)
X_std = X_train.std(axis=0)

X_train_norm = (X_train - X_mean) / (X_std + 1e-8)
X_test_norm = (X_test - X_mean) / (X_std + 1e-8)

norm_params = {'mean': X_mean.tolist(), 'std': X_std.tolist()}
with open(NORM_PARAMS_PATH, 'w') as f:
    json.dump(norm_params, f)
print(f"Saved normalization params to: {NORM_PARAMS_PATH}")

# ==================== MODEL ====================
print("\n[3/6] Building model...")

model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(5,)),
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(1, activation='linear'),
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='mse',
    metrics=['mae'],
)

model.summary()

# ==================== TRAINING ====================
print("\n[4/6] Training model...")

history = model.fit(
    X_train_norm, y_train,
    validation_data=(X_test_norm, y_test),
    epochs=100,
    batch_size=32,
    callbacks=[
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss', patience=20, restore_best_weights=True
        )
    ],
    verbose=1,
)

print("\n[5/6] Evaluating model...")
test_loss, test_mae = model.evaluate(X_test_norm, y_test, verbose=0)
print(f"Test MAE: ${test_mae:.2f}")

# ==================== CONVERT TO TFLITE ====================
print("\n[6/6] Converting to TFLite...")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open(TFLITE_PATH, 'wb') as f:
    f.write(tflite_model)

print(f"\nModel saved to: {TFLITE_PATH}")
print(f"Model size: {len(tflite_model) / 1024:.2f} KB")

# ==================== TEST INFERENCE ====================
print("\n[TEST] Running inference test...")

interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

test_input = X_test_norm[0:1]
actual = y_test[0]

interpreter.set_tensor(input_details[0]['index'], test_input)
interpreter.invoke()
prediction = interpreter.get_tensor(output_details[0]['index'])[0][0]

print(f"Sample prediction: ${prediction:.2f}")
print(f"Actual value: ${actual:.2f}")
print(f"Error: ${abs(prediction - actual):.2f}")

print("\n" + "=" * 60)
print(" MODEL TRAINING COMPLETE!")
print("=" * 60)
print(f"\nFiles created:")
print(f"   {TFLITE_PATH}")
print(f"   {NORM_PARAMS_PATH}")
print("=" * 60)
