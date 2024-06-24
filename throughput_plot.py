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
    ax.set_ylabel('Throughput gain (%)')

    for idx,attribute in enumerate(testtimingsarray_map):
        measurement = testtimingsarray_map[attribute]
        print(attribute)
        plt.plot(test_x, measurement, label=attribute, color=colors[idx], marker='o')

    plt.xticks(np.arange(min(test_x), max(test_x)+1, 1))
    plt.yticks(np.arange(0, 30, 5))
    ax.legend(loc='upper left', ncols=1)
    ax.grid(axis="y", linestyle="dotted")
    ax.yaxis.set_major_formatter(mtick.FormatStrFormatter('%.0f%%'))
    ax.yaxis.set_label_coords(-0.09,0.45)
    plt.subplots_adjust(left=0.11, right=1, top=0.99, bottom=0.23)

    plt.savefig(outputFile, format="pdf")

def main():
    test_x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

    multiproc_time_hash = [864, 1786, 2684, 3630, 4685, 5708, 6679, 7942, 8845, 10147, 11296, 12541, 13611, 14944, 16200]
    colorguard_time_hash = [848, 1708, 2549, 3360, 4227, 5058, 5869, 6710, 7546, 8404, 9227, 10103, 10968, 11741, 12562]
    assert(len(multiproc_time_hash) == len(colorguard_time_hash))

    jobs_per_process = 14582
    multiproc_throughput_hash = []
    colorguard_throughput_hash = []
    throughputinc_hash = []

    for i in range(len(multiproc_time_hash)):
        jobs = jobs_per_process * (i + 1)
        multiproc_throughput_hash.append(jobs / multiproc_time_hash[i])
        colorguard_throughput_hash.append(jobs / colorguard_time_hash[i])
        throughputinc_hash.append(100 * (colorguard_throughput_hash[i] - multiproc_throughput_hash[i]) / multiproc_throughput_hash[i])

    print("Hash-based load-balance")
    print("------------------------")
    print("multiproc_throughput_hash: " + str(multiproc_throughput_hash))
    print("colorguard_throughput_hash: " + str(colorguard_throughput_hash))
    print("throughputdrop_hash: " + str(throughputinc_hash))

    testtimingsarray_map = {
        "Hash-based load-balance" : throughputinc_hash,
        # "HTML templating"         : [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    }
    outputdir = os.path.dirname(os.path.realpath(__file__))
    benchfile = os.path.join(outputdir, "benchmarks", "faas-throughput.pdf")
    generate_graph(test_x, testtimingsarray_map, benchfile)

main()