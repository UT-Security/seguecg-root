#!/usr/bin/env python3
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import numpy as np
import os

def generate_graph(test_x, testtimingsarray_map, outputFile):

    plt.rcParams['pdf.fonttype'] = 42 # true type font
    plt.rcParams['font.size'] = '10'

    fig, ax = plt.subplots(figsize=(5.5, 2.2))

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

def compute(multiproc_time, colorguard_time):
    assert(len(multiproc_time) == len(colorguard_time))
    jobs_per_process = 14582
    multiproc_throughput = []
    colorguard_throughput = []
    throughputinc = []

    for i in range(len(multiproc_time)):
        jobs = jobs_per_process * (i + 1)
        multiproc_throughput.append(jobs / multiproc_time[i])
        colorguard_throughput.append(jobs / colorguard_time[i])
        throughputinc.append(100 * (colorguard_throughput[i] - multiproc_throughput[i]) / multiproc_throughput[i])

    print("multiproc_throughput: " + str(multiproc_throughput))
    print("colorguard_throughput: " + str(colorguard_throughput))
    print("throughputdrop: " + str(throughputinc))

    return throughputinc

def main():
    test_x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

    multiproc_time_hash = [864, 1786, 2684, 3630, 4685, 5708, 6679, 7942, 8845, 10147, 11296, 12541, 13611, 14944, 16200,]
    colorguard_time_hash = [848, 1708, 2549, 3360, 4227, 5058, 5869, 6710, 7546, 8404, 9227, 10103, 10968, 11741, 12562,]

    print("Hash load-balance")
    print("------------------------")
    throughputinc_hash = compute(multiproc_time_hash, colorguard_time_hash)

    multiproc_time_regex = [1926, 3902, 5921, 8107, 10236, 12561, 14834, 17314, 19849, 22356, 24744, 27544, 30064, 32552, 35302,]
    colorguard_time_regex = [1900, 3738, 5609, 7468, 9309, 11174, 13011, 14845, 16683, 18570, 20380, 22277, 24124, 25905, 27738,]

    print("Regex filtering")
    print("------------------------")
    throughputinc_regex = compute(multiproc_time_regex, colorguard_time_regex)

    multiproc_time_html = [1773, 3682, 5670, 7710, 9884, 11965, 14197, 16384, 18928, 21301, 23676, 25806, 28180, 30877, 33214,]
    colorguard_time_html = [1758, 3534, 5276, 7049, 8818, 10551, 12322, 14084, 15866, 17654, 19476, 21221, 23147, 24918, 26949,]

    print("HTML templating")
    print("------------------------")
    throughputinc_html = compute(multiproc_time_html, colorguard_time_html)

    testtimingsarray_map = {
        "Hash load-balance" : throughputinc_hash,
        "Regex filtering"   : throughputinc_regex,
        "HTML templating"   : throughputinc_html
    }
    outputdir = os.path.dirname(os.path.realpath(__file__))
    benchfile = os.path.join(outputdir, "benchmarks", "faas-throughput.pdf")
    generate_graph(test_x, testtimingsarray_map, benchfile)

main()