#!/usr/bin/env python3
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import numpy as np
import os

def generate_graph(test_x, testtimingsarray_map, outputFile):

    plt.rcParams['pdf.fonttype'] = 42 # true type font
    plt.rcParams['font.size'] = '10'

    fig, ax = plt.subplots(figsize=(5.5, 1.8))

    # https://colorbrewer2.org/#type=diverging&scheme=Spectral&n=5
    colors = ['#D7191C', '#2B83BA', '#FDAE61', '#ABDDA4', '#FFFFBF']

    ax.set_xlabel('Number of processes')
    ax.set_ylabel('Throughput drop (%)')

    for idx,attribute in enumerate(testtimingsarray_map):
        measurement = testtimingsarray_map[attribute]
        print(attribute)
        plt.plot(test_x, measurement, label=attribute, color=colors[idx], marker='o')

    plt.xticks(np.arange(min(test_x), max(test_x)+1, 1))
    ax.legend(loc='upper left', ncols=1)
    ax.grid(axis="y", linestyle="dotted")
    ax.yaxis.set_major_formatter(mtick.FormatStrFormatter('%.0f%%'))
    plt.subplots_adjust(left=0.11, right=1, top=0.99, bottom=0.2)


    plt.savefig(outputFile, format="pdf")

def main():
    test_x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    testtimingsarray_map = {
        "Hash-based load-balance" : [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30],
        "HTML templating"         : [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    }
    outputdir = os.path.dirname(os.path.realpath(__file__))
    benchfile = os.path.join(outputdir, "benchmarks", "faas-throughput.pdf")
    generate_graph(test_x, testtimingsarray_map, benchfile)

main()