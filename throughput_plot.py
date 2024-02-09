#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import os

def generate_graph(test_x, testtimingsarray_map, outputFile):

    plt.rcParams['pdf.fonttype'] = 42 # true type font
    plt.rcParams['font.size'] = '8'

    fig, ax = plt.subplots(figsize=(5.5, 2.6))

    # https://colorbrewer2.org/#type=diverging&scheme=Spectral&n=5
    colors = ['#D7191C', '#2B83BA', '#FDAE61', '#ABDDA4', '#FFFFBF']

    ax.set_xlabel('IO delay (milliseconds)')
    ax.set_ylabel('Throughput (instances/sec)')

    for idx,attribute in enumerate(testtimingsarray_map):
        measurement = testtimingsarray_map[attribute]
        print(attribute)
        plt.plot(test_x, measurement, label=attribute, color=colors[idx])

    plt.xticks(np.arange(min(test_x), max(test_x)+1, 1))
    ax.legend(loc='lower left', ncols=1)
    ax.grid(axis="y", linestyle="dotted")
    plt.subplots_adjust(left=0.1, right=1, top=0.99, bottom=0.15)


    plt.savefig(outputFile, format="pdf")

def main():
    test_x = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    testtimingsarray_map = {
        "Without Colorguard" : [18.35, 18.43, 18.98, 18.43, 18.98, 18.35, 18.43, 18.98, 12, 7, 2],
        "With Colorguard"    : [18.30, 18.40, 18.90, 18.40, 18.90, 18.30, 18.40, 18.90, 18, 18, 18],
    }
    outputdir = os.path.dirname(os.path.realpath(__file__))
    benchfile = os.path.join(outputdir, "benchmarks", "faas-throughput.pdf")
    generate_graph(test_x, testtimingsarray_map, benchfile)

main()