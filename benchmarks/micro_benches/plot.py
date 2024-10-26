#!/usr/bin/env python3
import csv
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import matplotlib.ticker as ticker
import numpy as np
import argparse
import statistics
import sys

def generate_my_graph(data, outputfile, y_axis_label):
    plt.rcParams['pdf.fonttype'] = 42 # true type font
    plt.rcParams['font.size'] = '9'
    colors = ['#d53e4f', '#fc8d59', "#fee08b", "#800020", "#99d594", "#3288bd"]
    red = colors[0]
    orange = colors[1]
    yellow = colors[2]
    burgundy = colors[3]
    green = colors[4]
    blue = colors[5]

    # Plot each series
    plt.figure(figsize=(10, 6))

    for (label, values) in data.items():
        if label == "regex_baseline":
            color = green
            marker = 'x'
        elif label == "load_balancing_baseline":
            color = burgundy 
            marker = 'x'
        elif label == "templating_baseline":
            color = yellow
            marker = 'x'
        elif label == "regex_cg":
            color = blue    
            marker = 'o'
        elif label == "load_balancing_cg":
            color = red     
            marker = 'o'
        elif label == "templating_cg":
            color = orange
            marker = 'o'
        else:
            assert(false)     

        plt.plot(range(1, len(values) + 1), values, color=color, marker=marker, label=label)

    # Labeling the plot
    plt.xlabel('# of Processes')
    plt.ylabel(y_axis_label)
    plt.legend()
    plt.gca().yaxis.set_major_formatter(ticker.StrMethodFormatter('{x:,.0f}')) # add commas to labels 
    plt.xticks(range(1, len(values) + 1))
    plt.grid(axis="y", linestyle="dotted")

    # Save the plot as a PDF
    plt.savefig(outputfile, format="pdf")

def parse_to_lists(filename):
    with open(filename, mode ='r')as f:
        csvread = csv.reader(f, delimiter='\t', skipinitialspace=True)
        lines = [line for line in csvread]

    header_line = lines[0]
    benchmark_name = header_line[0]
    test_names = header_line[1:]
    data = lines[1:]

    csw_l = []
    tlb_l = []
    for line in data:
        csw_l.append(int(line[1].replace(',', '')))
        tlb_l.append(int(line[2].replace(',', '')))

    return (csw_l,tlb_l)


def main():
    inputs = sys.argv[1:]

    csw_map = {}
    tlb_map = {}
    for filename in inputs:
        (csw_l,tlb_l) = parse_to_lists(filename)
        csw_map[filename.rstrip(".tsv")] = csw_l
        tlb_map[filename.rstrip(".tsv")] = tlb_l

    generate_my_graph(csw_map, "csw_graph.pdf", "# context switches")
    generate_my_graph(tlb_map, "dtlb_graph.pdf", "# dTLB misses")

main()