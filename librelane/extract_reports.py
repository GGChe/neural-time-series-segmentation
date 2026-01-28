
import os
import json
import glob
import re
import sys
from pathlib import Path

def find_latest_run(runs_dir):
    runs = sorted(glob.glob(os.path.join(runs_dir, "RUN_*")))
    if not runs:
        return None
    return runs[-1]

def get_clock_period(run_dir):
    # Try resolved.json first
    resolved_json_path = os.path.join(run_dir, "resolved.json")
    if os.path.exists(resolved_json_path):
        try:
            with open(resolved_json_path, 'r') as f:
                data = json.load(f)
                return float(data.get("CLOCK_PERIOD", 0))
        except:
            pass
            
    # Fallback: Parse timing report (legacy logic, simplified)
    # ...
    return None

def get_synthesis_area(run_dir):
    stat_json_path = os.path.join(run_dir, "06-yosys-synthesis", "reports", "stat.json")
    if not os.path.exists(stat_json_path):
        print(f"Warning: {stat_json_path} not found.")
        return None

    try:
        with open(stat_json_path, 'r') as f:
            data = json.load(f)
            
        modules = data.get("modules", {})
        # Find the top module (heuristic: usually the one with the most cells or just the first one if only one)
        # Or usually the user knows the top module name.
        # We'll just take the first key that isn't empty, or iterate.
        
        for mod_name, mod_data in modules.items():
            # Yosys often prefixes with \
            clean_name = mod_name.replace('\\', '')
            area = mod_data.get("area")
            num_cells = mod_data.get("num_cells_by_type", {})
            total_cells = sum(num_cells.values())
            
            return {
                "module": clean_name,
                "area": area,
                "cell_count": total_cells
            }
    except Exception as e:
        print(f"Error parsing synthesis stats: {e}")
        return None

    return None

def get_signoff_area(run_dir):
    # Try the last step's state_out.json
    # Step 74 is report manufacturability
    state_out_path = os.path.join(run_dir, "74-misc-reportmanufacturability", "state_out.json")
    
    # Fallback to similar directories if 74 doesn't exist
    if not os.path.exists(state_out_path):
        potential_files = glob.glob(os.path.join(run_dir, "7*-*/state_out.json"))
        if potential_files:
            state_out_path = sorted(potential_files)[-1]
        else:
            print("Warning: Could not find a final state_out.json")
            return None

    try:
        with open(state_out_path, 'r') as f:
            data = json.load(f)
            metrics = data.get("metrics", {})
            return {
                "die_area": metrics.get("design__die__area"),
                "core_area": metrics.get("design__core__area"),
                "design__instance__area": metrics.get("design__instance__area"),
                
                # Additional metrics
                "utilization": metrics.get("design__instance__utilization"),
                "wire_length": metrics.get("route__wirelength"),
                "via_count": metrics.get("route__vias"),
                "pin_count": metrics.get("design__io"),
                "cell_count": metrics.get("design__instance__count")
            }
    except Exception as e:
        print(f"Error parsing signoff area: {e}")
        return None

def parse_power_report(power_rpt_path):
    if not os.path.exists(power_rpt_path):
        print(f"Warning: {power_rpt_path} not found.")
        return None
    
    power_data = {}
    try:
        with open(power_rpt_path, 'r') as f:
            lines = f.readlines()
            
        # Example format (OpenROAD):
        # Total ... 1.23e-3 ...
        # Sequential ...
        # Combinational ...
        # Macro ...
        # Pad ...
        #
        # Or:
        # Group                  Internal  Switching  Leakage    Total
        #                          Power     Power      Power      Power
        # ----------------------------------------------------------------
        # Sequential             ...
        # Combinational          ...
        # Macro                  ...
        # Pad                    ...
        # ----------------------------------------------------------------
        # Total                  ...       ...        ...        ...
        
        # We look for the "Total" line at the bottom
        for line in reversed(lines):
            if line.strip().startswith("Total"):
                parts = line.split()
                # Check column headers to be sure, but typically:
                # Internal, Switching, Leakage, Total
                # Let's look for the header line to map indices.
                break
        
        # Parse headers
        header_map = {}
        for i, line in enumerate(lines):
            if "Internal" in line and "Switching" in line and "Leakage" in line and "Total" in line:
                # This is the header row(s). OpenROAD sometimes splits headers across lines.
                # Simplified parsing: assume standard column order [Internal, Switching, Leakage, Total]
                # Total line: "Total    <int>    <switch>    <leak>    <total>"
                pass
        
        # Line: Total    <int>    <switch>    <leak>    <total>    <percent>
        for line in lines:
            if line.strip().startswith("Total") and len(line.split()) >= 5:
                parts = line.split()
                # Based on observed file content:
                # Total <int> <switch> <leak> <total_watts> <percent>
                # Index: 0, 1, 2, 3, 4, 5
                
                power_data["internal"] = parts[1]
                power_data["switching"] = parts[2]
                power_data["leakage"] = parts[3]
                power_data["total"] = parts[4]
                break
                
    except Exception as e:
        print(f"Error parsing power report: {e}")
        return None
        
    return power_data

def parse_timing_report(timing_rpt_path):
    if not os.path.exists(timing_rpt_path):
        print(f"Warning: {timing_rpt_path} not found.")
        return None
        
    timing_data = {}
    try:
        with open(timing_rpt_path, 'r') as f:
            lines = f.readlines()
            
        # We want Data Arrival, Data Required, Slack from the FIRST path (Path 1)
        # Format:
        # ...
        #   8.528255   data arrival time
        # ...
        #  20.476229   data required time
        # ...
        #  11.947974   slack (MET)
        
        found_arrival = False
        found_required = False
        found_slack = False
        
        for line in lines:
            if "data arrival time" in line and not found_arrival:
                parts = line.split()
                timing_data["arrival_time"] = parts[0]
                found_arrival = True
            elif "data required time" in line and not found_required:
                parts = line.split()
                timing_data["required_time"] = parts[0]
                found_required = True
            elif "slack" in line and not found_slack:
                parts = line.split()
                timing_data["slack"] = parts[0]
                found_slack = True
            
            if found_arrival and found_required and found_slack:
                break
                
    except Exception as e:
        print(f"Error parsing timing report: {e}")
        return None
        
    return timing_data

def main():
    # Detect run directory
    base_dir = os.path.dirname(os.path.abspath(__file__))
    runs_dir = os.path.join(base_dir, "runs")
    latest_run = find_latest_run(runs_dir)
    
    if not latest_run:
        print("No runs found in librelane/runs/")
        return

    output_lines = []
    def log(msg):
        print(msg)
        output_lines.append(msg)

    log(f"=== Report for Run: {os.path.basename(latest_run)} ===")
    log(f"Path: {latest_run}\n")

    # 1. Synthesis Stats
    synth_stats = get_synthesis_area(latest_run)
    log("--- Synthesis Statistics ---")
    if synth_stats:
        log(f"Module: {synth_stats['module']}")
        log(f"Area: {synth_stats['area']} um^2")
        log(f"Cell Count: {synth_stats['cell_count']}")
    else:
        log("N/A")
    log("")

    # 2. Signoff Stats
    signoff_stats = get_signoff_area(latest_run)
    log("--- Signoff Statistics (Physical) ---")
    if signoff_stats:
        log(f"Die Area: {signoff_stats['die_area']} um^2")
        log(f"Core Area: {signoff_stats['core_area']} um^2")
        log(f"Instance Area: {signoff_stats['design__instance__area']} um^2")
        
        util = signoff_stats.get('utilization', 0) * 100 if signoff_stats.get('utilization') else 0
        log(f"Utilization: {util:.2f}%")
        
        log(f"Wire Length: {signoff_stats.get('wire_length')} um")
        log(f"Via Count: {signoff_stats.get('via_count')}")
        log(f"Input/Output Pins: {signoff_stats.get('pin_count')}")
        log(f"Cell Count (Physical): {signoff_stats.get('cell_count')}") # Post-filling/buffering
    else:
        log("N/A")
    log("")

    # 3. Signoff Power (Typical Corner)
    # Looking for nom_tt_025C_1v80 or similar
    power_corner = "nom_tt_025C_1v80"
    power_rpt = os.path.join(latest_run, "54-openroad-stapostpnr", power_corner, "power.rpt")
    
    # Fallback search if exact corner folder name differs
    if not os.path.exists(power_rpt):
        corner_dirs = glob.glob(os.path.join(latest_run, "54-openroad-stapostpnr", "*"))
        # Prefer nom_tt
        for d in corner_dirs:
            if "nom_tt" in d:
                power_rpt = os.path.join(d, "power.rpt")
                power_corner = os.path.basename(d)
                break
        else:
            if corner_dirs:
                power_rpt = os.path.join(corner_dirs[0], "power.rpt")
                power_corner = os.path.basename(corner_dirs[0])

    log(f"--- Signoff Power ({power_corner}) ---")
    power_data = parse_power_report(power_rpt)
    if power_data:
        log(f"Total Power: {power_data.get('total')} W")
        log(f"Internal Power: {power_data.get('internal')} W")
        log(f"Switching Power: {power_data.get('switching')} W")
        log(f"Leakage Power: {power_data.get('leakage')} W")
    else:
        log("N/A")
    log("")

    # 4. Signoff Timing (Setup/Max)
    # Using same corner as power for consistency, or search for max.rpt
    max_rpt = os.path.join(os.path.dirname(power_rpt), "max.rpt")
    log(f"--- Signoff Timing (Setup/Max - {power_corner}) ---")
    timing_data = parse_timing_report(max_rpt)
    clock_period = get_clock_period(latest_run)
    
    # Heuristic fallback if parse failed or not found in report (check config?)
    if not clock_period:
        # Check if we can infer from required time?
        # Required time ~= clock period - setup... roughly.
        pass

    if timing_data:
        log(f"Data Arrival Time: {timing_data.get('arrival_time')} ns")
        log(f"Data Required Time: {timing_data.get('required_time')} ns")
        log(f"Slack: {timing_data.get('slack')} ns")
        
        # Calculate Fmax
        if clock_period:
            try:
                slack = float(timing_data.get('slack'))
                # Fmax = 1 / (T_period - T_slack)
                # If positive slack, T_min = T_period - Slack.
                # If negative slack, T_min = T_period + |Slack| = T_period - Slack.
                # Formula holds for both.
                
                min_period = clock_period - slack
                if min_period > 0:
                    fmax_mhz = (1.0 / min_period) * 1000.0
                    log(f"Clock Period: {clock_period} ns")
                    log(f"Max Frequency (Theoretical): {fmax_mhz:.2f} MHz")
                else:
                    log("Max Frequency: Undefined (Slack > Period?)")
            except ValueError:
                pass
    else:
        log("N/A")
    log("")
    
    # Export to file
    export_path = Path(__file__).parent / "report_manufacturability.txt"
    try:
        with open(export_path, 'w') as f:
            f.write("\n".join(output_lines))
        print(f"Report exported to: {export_path}")
    except Exception as e:
        print(f"Failed to export report: {e}")

if __name__ == "__main__":
    main()
