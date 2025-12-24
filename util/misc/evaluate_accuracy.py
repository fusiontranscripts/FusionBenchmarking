#!/usr/bin/env python3

"""
Script to evaluate accuracy of fusion detection programs from .scored files.
Computes TP rate, FP rate, and F1 scores for each program.
Also computes F1 scores as a function of minimum read support and Precision-Recall curves with AUC.
"""

import argparse
import os
import random
import statistics
import sys
from collections import defaultdict
from pathlib import Path
from itertools import cycle
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import auc


def parse_scored_file(filepath):
    """
    Parse a .scored file and extract prediction results.
    
    Returns:
        list of dicts containing pred_result, prog, and SRs for each row
    """
    results = []
    
    with open(filepath, 'r') as f:
        header = f.readline().strip().split('\t')
        
        # Find column indices
        try:
            pred_idx = header.index('pred_result')
            prog_idx = header.index('prog')
            srs_idx = header.index('SRs')
        except ValueError as e:
            print(f"Warning: Could not find required columns in {filepath}: {e}")
            return results
        
        for line in f:
            line = line.strip()
            if not line:
                continue
                
            fields = line.split('\t')
            if len(fields) <= max(pred_idx, prog_idx, srs_idx):
                continue
            
            pred_result = fields[pred_idx]
            prog = fields[prog_idx]
            
            # Skip NA* rows
            if pred_result.startswith('NA'):
                continue
            
            # Parse SRs (supporting reads)
            try:
                srs = int(fields[srs_idx])
            except (ValueError, IndexError):
                srs = 0
            
            results.append({
                'pred_result': pred_result,
                'prog': prog,
                'SRs': srs
            })
    
    return results


def compute_metrics(data):
    """
    Compute TP, FP, FN counts and derived metrics for each program.
    
    Args:
        data: list of dicts with 'pred_result' and 'prog' keys
    
    Returns:
        dict with program names as keys and metrics as values
    """
    # Count TP, FP, FN for each program
    counts = defaultdict(lambda: {'TP': 0, 'FP': 0, 'FN': 0})
    
    for entry in data:
        prog = entry['prog']
        pred_result = entry['pred_result']
        
        if pred_result in ['TP', 'FP', 'FN']:
            counts[prog][pred_result] += 1
    
    # Calculate metrics for each program
    metrics = {}
    for prog, prog_counts in counts.items():
        tp = prog_counts['TP']
        fp = prog_counts['FP']
        fn = prog_counts['FN']
        
        # True Positive Rate (Recall/Sensitivity)
        tp_rate = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        
        # False Positive Rate
        # Note: FPR typically needs TN (true negatives), but in this context
        # we'll interpret FP rate as FP / (FP + TP) - the proportion of positive predictions that are false
        fp_rate = fp / (fp + tp) if (fp + tp) > 0 else 0.0
        
        # Precision
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        
        # F1 Score
        f1_score = 2 * (precision * tp_rate) / (precision + tp_rate) if (precision + tp_rate) > 0 else 0.0
        
        metrics[prog] = {
            'TP': tp,
            'FP': fp,
            'FN': fn,
            'TP_rate': tp_rate,
            'FP_rate': fp_rate,
            'Precision': precision,
            'F1_score': f1_score
        }
    
    return metrics


def format_prefix_from_directory(directory):
    """Create a safe prefix from the analyzed directory name."""
    dir_name = Path(os.path.abspath(directory.rstrip(os.sep))).name
    return dir_name.replace(' ', '_') if dir_name else ''


def make_output_path(output_dir, prefix, filename):
    prefix_part = f"{prefix}_" if prefix else ''
    return os.path.join(output_dir, f"{prefix_part}{filename}")


def process_directory(directory):
    """
    Process all .scored files in a directory and its subdirectories.
    
    Args:
        directory: path to the directory to scan
    
    Returns:
        list of all parsed results
    """
    all_data = []
    scored_files = []
    per_file_data = {}
    
    # Find all .scored files recursively
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.scored'):
                filepath = os.path.join(root, file)
                scored_files.append(filepath)
    
    print(f"Found {len(scored_files)} .scored files")
    
    # Parse each file
    for filepath in scored_files:
        print(f"Processing: {filepath}")
        data = parse_scored_file(filepath)
        per_file_data[filepath] = data
        all_data.extend(data)
    
    return all_data, per_file_data


def compute_per_file_metrics(per_file_data):
    """
    Compute metrics for each individual .scored file.

    Args:
        per_file_data: dict mapping file paths to parsed records

    Returns:
        dict mapping file paths to program metrics
    """
    per_file_metrics = {}
    for filepath, records in per_file_data.items():
        if not records:
            continue
        per_file_metrics[filepath] = compute_metrics(records)
    return per_file_metrics


def write_per_file_metrics_tsv(per_file_metrics, output_dir='.', prefix=''):
    """
    Write per-file accuracy metrics to TSV.
    """
    if not per_file_metrics:
        return

    output_file = make_output_path(output_dir, prefix, 'per_file_metrics.tsv')
    with open(output_file, 'w') as f:
        f.write('File\tProgram\tTP\tFP\tFN\tRecall\tPrecision\tF1_Score\n')
        for filepath in sorted(per_file_metrics.keys()):
            metrics = per_file_metrics[filepath]
            for prog, m in metrics.items():
                f.write(
                    f"{filepath}\t{prog}\t{m['TP']}\t{m['FP']}\t{m['FN']}\t"
                    f"{m['TP_rate']:.6f}\t{m['Precision']:.6f}\t{m['F1_score']:.6f}\n"
                )
    print(f"Per-file metrics saved to: {output_file}")


def print_per_file_metric_summary(per_file_metrics):
    """
    Print summary statistics (mean/median/min/max) of per-file F1 scores per program.
    """
    if not per_file_metrics:
        print("No per-file metrics available.")
        return

    program_f1 = defaultdict(list)
    for filepath, metrics in per_file_metrics.items():
        for prog, m in metrics.items():
            program_f1[prog].append(m['F1_score'])

    if not program_f1:
        print("No per-file program metrics to summarize.")
        return

    print("\n" + "="*80)
    print("PER-FILE F1 SCORE DISTRIBUTION BY PROGRAM")
    print("="*80)
    print(f"{'Program':<20} {'Files':>8} {'Mean':>10} {'Median':>10} {'Min':>10} {'Max':>10} {'StdDev':>10}")
    print("-"*80)

    stats_rows = []
    for prog, values in program_f1.items():
        mean_val = statistics.mean(values)
        stats_rows.append({
            'prog': prog,
            'count': len(values),
            'mean': mean_val,
            'median': statistics.median(values),
            'min': min(values),
            'max': max(values),
            'std': statistics.pstdev(values) if len(values) > 1 else 0.0
        })

    for row in sorted(stats_rows, key=lambda r: (r['mean'], r['median']), reverse=True):
        print(
            f"{row['prog']:<20} {row['count']:>8} {row['mean']:>10.4f} {row['median']:>10.4f} "
            f"{row['min']:>10.4f} {row['max']:>10.4f} {row['std']:>10.4f}"
        )

    print("="*80)


def run_sampling_iterations(per_file_data, sample_fraction, iterations=100, seed=None):
    """
    Randomly sample subsets of files and compute metrics (including PR AUC) to characterize variability.
    """
    if sample_fraction <= 0 or iterations <= 0 or not per_file_data:
        return []

    files = list(per_file_data.keys())
    if not files:
        return []

    sample_fraction = min(max(sample_fraction, 0.0), 1.0)
    sample_size = max(1, int(round(sample_fraction * len(files)))) if sample_fraction > 0 else len(files)
    sample_size = min(sample_size, len(files))
    rng = random.Random(seed)
    sampling_records = []

    for iter_idx in range(1, iterations + 1):
        subset = rng.sample(files, sample_size) if sample_size < len(files) else list(files)
        subset_data = []
        for filepath in subset:
            subset_data.extend(per_file_data.get(filepath, []))
        if not subset_data:
            continue

        base_metrics = compute_metrics(subset_data)
        pr_subset = compute_pr_data(subset_data, verbose=False)
        programs = set(base_metrics.keys()) | set(pr_subset.keys())

        for prog in programs:
            m = base_metrics.get(prog)
            auc_val = pr_subset.get(prog, {}).get('AUC', 0.0)
            sampling_records.append({
                'iteration': iter_idx,
                'program': prog,
                'sample_size': len(subset),
                'precision': m['Precision'] if m else 0.0,
                'recall': m['TP_rate'] if m else 0.0,
                'f1': m['F1_score'] if m else 0.0,
                'auc': auc_val,
                'tp': m['TP'] if m else 0,
                'fp': m['FP'] if m else 0,
                'fn': m['FN'] if m else 0
            })

    return sampling_records


def write_sampling_metrics_tsv(sampling_records, output_dir='.', prefix=''):
    """
    Write sampling iteration metrics to TSV.
    """
    if not sampling_records:
        return

    output_file = make_output_path(output_dir, prefix, 'sampling_metrics.tsv')
    with open(output_file, 'w') as f:
        f.write('Iteration\tProgram\tSample_Size\tTP\tFP\tFN\tRecall\tPrecision\tF1_Score\tPR_AUC\n')
        for record in sampling_records:
            f.write(
                f"{record['iteration']}\t{record['program']}\t{record['sample_size']}\t"
                f"{record['tp']}\t{record['fp']}\t{record['fn']}\t"
                f"{record['recall']:.6f}\t{record['precision']:.6f}\t{record['f1']:.6f}\t{record['auc']:.6f}\n"
            )
    print(f"Sampling metrics saved to: {output_file}")


def print_sampling_summary(sampling_records):
    """
    Print distribution summary of sampled metrics per program.
    """
    if not sampling_records:
        print("No sampling iterations were performed.")
        return

    program_auc = defaultdict(list)
    program_sample_sizes = defaultdict(list)
    for record in sampling_records:
        program = record['program']
        program_auc[program].append(record['auc'])
        program_sample_sizes[program].append(record['sample_size'])

    if not program_auc:
        print("Sampling produced no per-program metrics.")
        return

    print("\n" + "="*80)
    print("SAMPLED PR-AUC DISTRIBUTION BY PROGRAM")
    print("="*80)
    print(f"{'Program':<20} {'Samples':>8} {'Sample Size':>12} {'Mean AUC':>12} {'Median':>10} {'Min':>10} {'Max':>10} {'StdDev':>10}")
    print("-"*80)

    stats_rows = []
    for prog, values in program_auc.items():
        stats_rows.append({
            'prog': prog,
            'count': len(values),
            'sample_size': statistics.mean(program_sample_sizes.get(prog, [0])) if program_sample_sizes.get(prog) else 0.0,
            'mean': statistics.mean(values),
            'median': statistics.median(values),
            'min': min(values),
            'max': max(values),
            'std': statistics.pstdev(values) if len(values) > 1 else 0.0
        })

    for row in sorted(stats_rows, key=lambda r: (r['mean'], r['median']), reverse=True):
        print(
            f"{row['prog']:<20} {row['count']:>8} {row['sample_size']:>12.1f} {row['mean']:>12.4f} {row['median']:>10.4f} "
            f"{row['min']:>10.4f} {row['max']:>10.4f} {row['std']:>10.4f}"
        )

    print("="*80)


def compute_metrics_by_threshold(data, min_srs):
    """
    Compute TP, FP, FN counts for predictions with SRs >= min_srs.
    
    Args:
        data: list of dicts with 'pred_result', 'prog', and 'SRs' keys
        min_srs: minimum supporting reads threshold
    
    Returns:
        dict with program names as keys and metrics as values
    """
    # Filter data by threshold
    filtered_data = [d for d in data if d['SRs'] >= min_srs]
    
    # Count TP, FP for predictions meeting threshold
    counts = defaultdict(lambda: {'TP': 0, 'FP': 0})
    
    for entry in filtered_data:
        prog = entry['prog']
        pred_result = entry['pred_result']
        
        if pred_result in ['TP', 'FP']:
            counts[prog][pred_result] += 1
    
    # Total positives per program (TP + FN) define the truth set size
    total_positives = defaultdict(int)
    for entry in data:
        if entry['pred_result'] in ['TP', 'FN']:
            total_positives[entry['prog']] += 1
    
    # Calculate metrics for each program
    metrics = {}
    all_programs = set([d['prog'] for d in data])
    
    for prog in all_programs:
        tp = counts[prog]['TP']
        fp = counts[prog]['FP']
        # Any TP filtered out by the threshold becomes an FN
        fn = max(total_positives[prog] - tp, 0)
        
        # True Positive Rate (Recall/Sensitivity)
        tp_rate = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        
        # False Positive Rate (for ROC: FP / (FP + TN))
        # In this context, we'll use FP / (FP + TP) as a proxy
        # For proper FPR, we'd need the total negatives
        fpr = fp / (fp + tp) if (fp + tp) > 0 else 0.0
        
        # Precision
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        
        # F1 Score
        f1_score = 2 * (precision * tp_rate) / (precision + tp_rate) if (precision + tp_rate) > 0 else 0.0
        
        metrics[prog] = {
            'TP': tp,
            'FP': fp,
            'FN': fn,
            'TPR': tp_rate,  # True Positive Rate (Recall)
            'FPR': fpr,
            'Precision': precision,
            'F1_score': f1_score
        }
    
    return metrics


def compute_pr_data(data, verbose=True):
    """
    Compute Precision-Recall curve data for each program by varying SRs threshold.
    
    Args:
        data: list of dicts with 'pred_result', 'prog', and 'SRs' keys
    
    Returns:
        dict with program names as keys and PR curve data as values
    """
    programs = sorted(set([d['prog'] for d in data]))
    pr_data = {}
    
    if verbose:
        # Debug: print SRs distribution per program
        print("\nDEBUG: SRs value distribution by program:")
        for prog in programs:
            prog_srs = [d['SRs'] for d in data if d['prog'] == prog]
            unique_srs = sorted(set(prog_srs))
            print(f"  {prog}: {len(prog_srs)} total, {len(unique_srs)} unique SRs values")
            if len(unique_srs) <= 10:
                print(f"    Unique values: {unique_srs}")
            else:
                print(f"    Range: {min(unique_srs)} to {max(unique_srs)}")
        print()
    
    for prog in programs:
        prog_data = [d for d in data if d['prog'] == prog]
        
        # Get unique SRs values for this specific program
        prog_srs = sorted(set([d['SRs'] for d in prog_data]))
        
        # Add 0 to ensure we start from the beginning
        if 0 not in prog_srs:
            prog_srs = [0] + prog_srs
        
        recall_list = []
        precision_list = []
        f1_list = []
        threshold_list = []
        threshold_metrics = {}
        
        for threshold in prog_srs:
            metrics = compute_metrics_by_threshold(prog_data, threshold)
            if prog in metrics:
                recall = metrics[prog]['TPR']  # Recall is same as TPR
                precision = metrics[prog]['Precision']
                recall_list.append(recall)
                precision_list.append(precision)
                f1_list.append(metrics[prog]['F1_score'])
                threshold_list.append(threshold)
                threshold_metrics[threshold] = metrics[prog]
        
        # For Precision-Recall curves, sort by recall (ascending)
        # Combine all data points
        points = list(zip(threshold_list, recall_list, precision_list, f1_list))
        
        # Sort by recall ascending, then by precision descending
        points.sort(key=lambda x: (x[1], -x[2]))
        
        # Remove duplicate (recall, precision) pairs, keeping the one with lowest threshold
        unique_points = []
        seen_pairs = set()
        for point in points:
            recall_val = point[1]
            precision_val = point[2]
            pair = (recall_val, precision_val)
            if pair not in seen_pairs:
                unique_points.append(point)
                seen_pairs.add(pair)
        
        if not unique_points:
            pr_data[prog] = {
                'thresholds': [],
                'Recall': [],
                'Precision': [],
                'F1': [],
                'PR_thresholds': [],
                'TP': [],
                'FP': [],
                'FN': [],
                'AUC': 0.0
            }
            continue
        
        # Extract sorted lists
        thresholds_sorted = [p[0] for p in unique_points]
        recall_sorted = [p[1] for p in unique_points]
        precision_sorted = [p[2] for p in unique_points]
        f1_sorted = [p[3] for p in unique_points]
        
        # Store original threshold order for F1 plot (sorted by threshold descending)
        threshold_f1_points = list(zip(threshold_list, f1_list))
        threshold_f1_points.sort(key=lambda x: x[0], reverse=True)
        
        # Map thresholds and counts to the sorted recall values
        thresholds_for_pr = [p[0] for p in unique_points]
        tp_counts = [threshold_metrics.get(t, {'TP': None})['TP'] for t in thresholds_for_pr]
        fp_counts = [threshold_metrics.get(t, {'FP': None})['FP'] for t in thresholds_for_pr]
        fn_counts = [threshold_metrics.get(t, {'FN': None})['FN'] for t in thresholds_for_pr]

        # Build PR points (without boundaries)
        pr_points = []
        for idx, threshold in enumerate(thresholds_for_pr):
            pr_points.append({
                'threshold': threshold,
                'recall': recall_sorted[idx],
                'precision': precision_sorted[idx],
                'tp': tp_counts[idx],
                'fp': fp_counts[idx],
                'fn': fn_counts[idx]
            })

        pr_points_with_bounds = list(pr_points)

        # Helper to insert boundary point
        def make_boundary_point(name, recall_val, precision_val):
            return {
                'threshold': name,
                'recall': recall_val,
                'precision': precision_val,
                'tp': None,
                'fp': None,
                'fn': None
            }

        if not pr_points_with_bounds:
            pr_points_with_bounds = [
                make_boundary_point('boundary_start', 0.0, 1.0),
                make_boundary_point('boundary_end', 1.0, 0.0)
            ]
        else:
            first_point = pr_points_with_bounds[0]
            if first_point['recall'] > 0.0 or first_point['precision'] < 1.0:
                pr_points_with_bounds.insert(0, make_boundary_point('boundary_start', 0.0, 1.0))

            last_point = pr_points_with_bounds[-1]
            if last_point['recall'] < 1.0 or (last_point['recall'] == 1.0 and last_point['precision'] > 0.0):
                pr_points_with_bounds.append(make_boundary_point('boundary_end', 1.0, 0.0))

        recall_with_bounds = [p['recall'] for p in pr_points_with_bounds]
        precision_with_bounds = [p['precision'] for p in pr_points_with_bounds]

        # Calculate PR-AUC using trapezoidal rule on boundary-inclusive curve
        pr_auc = 0.0
        if len(recall_with_bounds) > 1:
            try:
                pr_auc = auc(recall_with_bounds, precision_with_bounds)
            except ValueError:
                print(f"Warning: Could not compute PR-AUC for {prog} using sklearn, computing manually")
                pr_auc = np.trapz(precision_with_bounds, recall_with_bounds)

        pr_data[prog] = {
            'thresholds': [p[0] for p in threshold_f1_points],
            'Recall': recall_with_bounds,
            'Precision': precision_with_bounds,
            'F1': [p[1] for p in threshold_f1_points],
            'PR_thresholds': [p['threshold'] for p in pr_points_with_bounds],
            'TP': [p['tp'] for p in pr_points_with_bounds],
            'FP': [p['fp'] for p in pr_points_with_bounds],
            'FN': [p['fn'] for p in pr_points_with_bounds],
            'AUC': abs(pr_auc)  # Take absolute value in case of negative
        }
    
    return pr_data


def plot_pr_curves(pr_data, output_dir='.', prefix=''):
    """
    Plot Precision-Recall curves for all programs.
    
    Args:
        pr_data: dict with program PR curve data
        output_dir: directory to save plots
    """
    plt.figure(figsize=(10, 8))
    marker_cycle = cycle(['o', 's', '^', 'v', 'D', 'P', 'X', '*', 'h', '<', '>'])
    
    for prog in sorted(pr_data.keys()):
        data = pr_data[prog]
        marker_style = next(marker_cycle)
        plt.plot(
            data['Recall'],
            data['Precision'],
            marker=marker_style,
            markersize=4.5,
            label=f"{prog} (AUC={data['AUC']:.3f})",
            linewidth=1.8,
            alpha=0.8,
            markerfacecolor='white',
            markeredgewidth=1.0,
        )
    
    plt.xlabel('Recall (Sensitivity)', fontsize=12)
    plt.ylabel('Precision', fontsize=12)
    plt.title('Precision-Recall Curves by Program', fontsize=14, fontweight='bold')
    plt.legend(loc='best')
    plt.grid(True, alpha=0.3)
    plt.xlim([0.0, 1.05])
    plt.ylim([0.0, 1.05])
    plt.tight_layout()
    
    output_file = make_output_path(output_dir, prefix, 'precision_recall_curves.png')
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\nPrecision-Recall curve saved to: {output_file}")
    plt.close()


def write_pr_data_to_tsv(pr_data, output_dir='.', prefix=''):
    """
    Write Precision-Recall curve data points to TSV file.
    
    Args:
        pr_data: dict with program PR curve data
        output_dir: directory to save TSV file
    """
    output_file = make_output_path(output_dir, prefix, 'precision_recall_data.tsv')
    
    with open(output_file, 'w') as f:
        # Write header
        f.write("Program\tMin_Read_Support\tTP\tFP\tFN\tRecall\tPrecision\tF1_Score\n")
        
        # Write data for each program
        for prog in sorted(pr_data.keys()):
            data = pr_data[prog]
            
            recall_vals = data['Recall']
            precision_vals = data['Precision']
            thresholds = data['PR_thresholds']
            tp_vals = data['TP']
            fp_vals = data['FP']
            fn_vals = data['FN']
            
            for i in range(len(recall_vals)):
                recall = recall_vals[i]
                precision = precision_vals[i]
                threshold = thresholds[i]
                tp = tp_vals[i]
                fp = fp_vals[i]
                fn = fn_vals[i]

                def fmt_val(val):
                    return val if val is not None else 'NA'

                # Calculate F1 from precision and recall
                f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0
                f.write(
                    f"{prog}\t{threshold}\t{fmt_val(tp)}\t{fmt_val(fp)}\t{fmt_val(fn)}\t"
                    f"{recall:.6f}\t{precision:.6f}\t{f1:.6f}\n"
                )
    
    print(f"Precision-Recall data saved to: {output_file}")


def plot_f1_by_threshold(pr_data, output_dir='.', prefix=''):
    """
    Plot F1 scores as a function of minimum read support threshold.
    
    Args:
        pr_data: dict with program PR curve data
        output_dir: directory to save plots
    """
    plt.figure(figsize=(12, 8))
    
    for prog in sorted(pr_data.keys()):
        data = pr_data[prog]
        plt.plot(data['thresholds'], data['F1'], marker='o', markersize=3,
                label=prog, linewidth=2)
    
    plt.xlabel('Minimum Supporting Reads (SRs)', fontsize=12)
    plt.ylabel('F1 Score', fontsize=12)
    plt.title('F1 Score vs. Minimum Read Support Threshold', fontsize=14, fontweight='bold')
    plt.legend(loc='best')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    output_file = make_output_path(output_dir, prefix, 'f1_by_threshold.png')
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"F1 vs threshold plot saved to: {output_file}")
    plt.close()


def print_metrics(metrics):
    """
    Print metrics in a formatted table.
    
    Args:
        metrics: dict of program metrics
    """
    print("\n" + "="*100)
    print("ACCURACY METRICS BY PROGRAM (All Data)")
    print("="*100)
    print(f"{'Program':<20} {'TP':>6} {'FP':>6} {'FN':>6} {'TP Rate':>10} {'FP Rate':>10} {'Precision':>10} {'F1 Score':>10}")
    print("-"*100)
    
    # Sort by best F1 first
    for prog in sorted(metrics.keys(), key=lambda p: (metrics[p]['F1_score'], metrics[p]['Precision']), reverse=True):
        m = metrics[prog]
        print(f"{prog:<20} {m['TP']:>6} {m['FP']:>6} {m['FN']:>6} "
              f"{m['TP_rate']:>10.4f} {m['FP_rate']:>10.4f} {m['Precision']:>10.4f} {m['F1_score']:>10.4f}")
    
    print("="*100)


def print_pr_summary(pr_data):
    """
    Print Precision-Recall AUC summary table.
    
    Args:
        pr_data: dict with program PR curve data
    """
    print("\n" + "="*60)
    print("PRECISION-RECALL AUC BY PROGRAM")
    print("="*60)
    print(f"{'Program':<30} {'PR-AUC':>10} {'Max F1':>10}")
    print("-"*60)
    
    # Sort by AUC descending
    sorted_progs = sorted(pr_data.keys(), key=lambda p: pr_data[p]['AUC'], reverse=True)
    
    for prog in sorted_progs:
        data = pr_data[prog]
        max_f1 = max(data['F1']) if data['F1'] else 0.0
        print(f"{prog:<30} {data['AUC']:>10.4f} {max_f1:>10.4f}")
    
    print("="*60)


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description='Evaluate fusion detection accuracy metrics.')
    parser.add_argument('directory', help='Path to directory containing .scored files')
    parser.add_argument('output_dir', nargs='?', default='.', help='Optional output directory for reports/plots')
    parser.add_argument('--sample-frac', type=float, default=0.5,
                        help='Fraction (0-1] of .scored files to sample per iteration (0 disables sampling)')
    parser.add_argument('--sample-iterations', type=int, default=100,
                        help='Number of random sampling iterations to run when sampling is enabled')
    parser.add_argument('--sample-seed', type=int, default=None, help='Random seed for sampling reproducibility')
    return parser.parse_args()


def main():
    """
    Main function to execute the analysis.
    """
    args = parse_arguments()
    directory = args.directory
    output_dir = args.output_dir
    sample_frac = args.sample_frac
    sample_iterations = args.sample_iterations
    sample_seed = args.sample_seed
    
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory")
        sys.exit(1)
    
    if not os.path.isdir(output_dir):
        os.makedirs(output_dir, exist_ok=True)
    
    print(f"Analyzing .scored files in: {directory}")
    print(f"Output directory: {output_dir}")
    output_prefix = format_prefix_from_directory(directory)
    
    # Process all files
    all_data, per_file_data = process_directory(directory)
    
    if not all_data:
        print("No data found in .scored files")
        sys.exit(1)
    
    print(f"\nTotal records processed: {len(all_data)}")
    
    # Compute basic metrics (no threshold)
    metrics = compute_metrics(all_data)
    
    # Print basic results
    print_metrics(metrics)
    
    # Compute PR curve data (metrics as function of SRs threshold)
    print("\nComputing Precision-Recall curves and F1 scores by read support threshold...")
    pr_data = compute_pr_data(all_data)
    
    # Print PR summary
    print_pr_summary(pr_data)
    
    # Generate plots
    print("\nGenerating plots...")
    plot_pr_curves(pr_data, output_dir, output_prefix)
    plot_f1_by_threshold(pr_data, output_dir, output_prefix)
    
    # Write PR data to TSV
    write_pr_data_to_tsv(pr_data, output_dir, output_prefix)

    # Per-file metrics and summaries
    per_file_metrics = compute_per_file_metrics(per_file_data)
    write_per_file_metrics_tsv(per_file_metrics, output_dir, output_prefix)
    print_per_file_metric_summary(per_file_metrics)

    # Sampling-based variability analysis
    if sample_frac > 0 and per_file_data:
        print("\nRunning sampling-based accuracy analysis...")
        sampling_records = run_sampling_iterations(per_file_data, sample_frac, sample_iterations, sample_seed)
        write_sampling_metrics_tsv(sampling_records, output_dir, output_prefix)
        print_sampling_summary(sampling_records)
    
    print("\nAnalysis complete!")


if __name__ == "__main__":
    main()
