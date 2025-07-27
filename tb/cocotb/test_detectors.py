import os
import cocotb
import numpy as np
import plotly.graph_objects as go
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from plotly.subplots import make_subplots

# Resolve dataset path
DATASET_PATH = os.path.join(os.path.dirname(__file__), "../../test_files/20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt")

def load_data():
    if not os.path.exists(DATASET_PATH):
        raise FileNotFoundError(f"Dataset not found at {DATASET_PATH}")
    # Load data as integers
    return np.loadtxt(DATASET_PATH, dtype=np.int16)

@cocotb.test()
async def test_feature_extractor(dut):
    """
    Generic Feature Extractor Verification with Plotting
    """
    # Detect module name from the DUT
    try:
        module_name = dut._name.upper()
    except:
        module_name = "FEATURE_EXTRACTOR"

    dut._log.info(f"Starting {module_name} Simulation with Plotting")

    # Clock @ 100 MHz (10ns period)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Load input data
    input_signal = load_data()
    # Use a subset of data if it's too large to simulate quickly
    input_signal = input_signal[:20000] 
    
    n_samples = len(input_signal)
    dut._log.info(f"Loaded {n_samples} samples.")

    # Reset
    dut.rst.value = 1
    dut.data_in.value = 0
    await Timer(50, units="ns")
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut._log.info("Reset complete")

    # Arrays to store results
    # If wrapper, we monitor 4 outputs
    is_wrapper = (module_name == "DETECTORS_WRAPPER")
    
    output_spikes = {
        "NEO": [],
        "ADO": [],
        "ASO": [],
        "ED":  []
    }
    single_output = [] # For non-wrapper case
    
    # Simulation Loop
    for i, sample in enumerate(input_signal):
        dut.data_in.value = int(sample)
        await RisingEdge(dut.clk)
        
        if is_wrapper:
            output_spikes["NEO"].append(int(dut.spike_neo.value))
            output_spikes["ADO"].append(int(dut.spike_ado.value))
            output_spikes["ASO"].append(int(dut.spike_aso.value))
            output_spikes["ED"].append(int(dut.spike_ed.value))
        else:
            single_output.append(int(dut.spike_detected.value))

        if i % 5000 == 0:
            dut._log.info(f"[{module_name}] Processed {i}/{n_samples} samples")

    dut._log.info("Simulation complete. Generating plots...")

    # Time vector
    fs = 2000.0
    t = np.arange(n_samples) / fs

    # --- Plotting ---
    if is_wrapper:
        fig = make_subplots(
            rows=5, cols=1,
            shared_xaxes=True,
            subplot_titles=("Input Signal (LFP)", "NEO", "ADO", "ASO", "ED"),
            vertical_spacing=0.05
        )
        
        # Row 1: Input
        fig.add_trace(go.Scatter(x=t, y=input_signal, name="LFP Input", line=dict(color='blue', width=1)), row=1, col=1)
        
        # Row 2-5: Detectors
        detectors = ["NEO", "ADO", "ASO", "ED"]
        colors = ['red', 'green', 'orange', 'purple']
        
        for idx, det in enumerate(detectors):
            row_idx = idx + 2
            arr = np.array(output_spikes[det])
            fig.add_trace(
                go.Scatter(x=t, y=arr, name=f"{det} Detected", line=dict(color=colors[idx], width=1), fill='tozeroy'),
                row=row_idx, col=1
            )
            fig.update_yaxes(title_text="Logic", row=row_idx, col=1, range=[-0.1, 1.1], tickvals=[0, 1])

        title_str = "Comparison of Feature Extractors"
        
    else:
        # Single detector mode (legacy)
        fig = make_subplots(rows=2, cols=1, shared_xaxes=True, subplot_titles=("Input Signal (LFP)", f"{module_name} Spike Detection"), vertical_spacing=0.1)
        fig.add_trace(go.Scatter(x=t, y=input_signal, name="LFP Input", line=dict(color='blue', width=1)), row=1, col=1)
        output_array = np.array(single_output)
        fig.add_trace(go.Scatter(x=t, y=output_array, name="Spike Detected", line=dict(color='red', width=1), fill='tozeroy'), row=2, col=1)
        title_str = f"{module_name} Simulation Results"

    fig.update_layout(
        title=title_str,
        height=1000 if is_wrapper else 800,
        width=1200
    )

    # Save to HTML
    output_file = f"{module_name.lower()}_simulation_results.html"
    fig.write_html(output_file)
    dut._log.info(f"Plot saved to {os.path.abspath(output_file)}")
