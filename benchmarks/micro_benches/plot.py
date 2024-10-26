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
    # plt.grid(True)
    plt.gca().yaxis.set_major_formatter(ticker.StrMethodFormatter('{x:,.0f}')) # add commas to labels 
    # fig, ax = plt.subplots()
    plt.xticks(range(1, len(values) + 1))
    # ax.set_xticks(range(1, len(values) + 1))
    plt.grid(axis="y", linestyle="dotted")
    # ax.set_xticks(x + width, test_names, fontsize='9', horizontalalignment='right')
    # plt.xticks(rotation=45, ha='right', rotation_mode='anchor')
    # ax.legend(loc='upper left', ncols=1)
    # ax.grid(axis="y", linestyle="dotted")

    # Save the plot as a PDF
    plt.savefig(outputfile, format="pdf")

def generate_graph(test_names, build_testtimingsarray_map, outputFile):
    # test_names = ['astar', 'sightglass', 'coremark']
    # build_testtimingsarray_map = {
    #     "Normal"     : [18.35, 18.43, 14.98],
    #     "GuardPages" : [38.79, 48.83, 47.50],
    #     "Segue"      : [189.95, 195.82, 217.19],
    # }

    x = np.arange(len(test_names))  # the label locations
    width = 1 / (1+len(build_testtimingsarray_map.keys()))  # the width of the bars
    multiplier = 0

    plt.rcParams['pdf.fonttype'] = 42 # true type font
    plt.rcParams['font.size'] = '9'
    fig, ax = plt.subplots(figsize=(6.1, 2.4))
    # plt.tight_layout(pad=0)
    plt.subplots_adjust(left=0.08, right=0.99, top=0.99, bottom=0.3)
    plt.margins(0,0)

    plt.axhline(y=1.0, color='black', linestyle='dashed')

    # https://colorbrewer2.org/#type=diverging&scheme=Spectral&n=5
    colors = ['#D7191C', '#2B83BA', '#FDAE61', '#ABDDA4', '#FFFFBF']

    for idx,attribute in enumerate(build_testtimingsarray_map):
        measurement = build_testtimingsarray_map[attribute]
        offset = width * multiplier
        rects = ax.bar(x + offset, measurement, width, label=attribute, color=colors[idx], edgecolor="black")
        multiplier += 1


    # Add some text for labels, title and custom x-axis tick labels, etc.
    ax.set_ylabel('Norm. runtime')
    ax.set_xticks(x + width, test_names, fontsize='9', horizontalalignment='right')
    plt.xticks(rotation=45, ha='right', rotation_mode='anchor')
    ax.legend(loc='upper left', ncols=1)
    ax.grid(axis="y", linestyle="dotted")

    plt.savefig(outputFile, format="pdf")

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

    print(csw_map)
    print(tlb_l)

    generate_my_graph(csw_map, "csw_graph.pdf", "# context switches")
    generate_my_graph(tlb_map, "dtlb_graph.pdf", "# dTLB misses")

main()