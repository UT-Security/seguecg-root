#!/usr/bin/env python3
import csv
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import numpy as np
import argparse
import statistics

def replace(val, replacements):
    val = val.strip()
    for (k, v) in replacements:
        if k == val:
            return v
    return val

def first_or_none(a):
    return a[0] if a else None

def generate_graph(test_names, build_testtimingsarray_map, keyright, percent, outputFile):
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

    if percent:
        ax.yaxis.set_major_formatter(FuncFormatter(lambda y, _: '{:.0%}'.format(y)))

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
    if keyright:
        ax.legend(loc='upper right', bbox_to_anchor=(0.825, 1.02), ncols=1)
    else:
        ax.legend(loc='upper left', ncols=1)
    ax.grid(axis="y", linestyle="dotted")

    plt.savefig(outputFile, format="pdf")

def write_stat(f, name, func, build_testtimingsarray_map):
    f.write(name + ". ")
    for build, timings in build_testtimingsarray_map.items():
        curr_stat = round(func(timings), 2)
        f.write(build + ": " + str(curr_stat) + " ")
    f.write("\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('inputFile', help='input csv file')
    parser.add_argument('outputFile', help='output pdf file')
    parser.add_argument('-b',  dest='baseline', help='column to be used as baseline')
    parser.add_argument('-g',  dest='add_geomean', help='specify if you want the geomean to be included', default=False, action='store_true')
    parser.add_argument('-r',  dest='replacements', default=[], action='append', type=lambda s: ( s.split(':', 1)[0], s.split(':', 1)[1] ), help='replacements of the form abc:def where name abc is replaced with def in the data. You can specify this flag multiple times for multiple replacements')
    parser.add_argument('-f',  dest='filter', default=[], action='append', help='filter data from particular builds. You can specify this flag multiple times for multiple filters')
    parser.add_argument('-s',  dest='statsfile', help='output stats file')
    parser.add_argument('-kr', dest='keyright', help='put the key on the right', default=False, action='store_true')
    parser.add_argument('-p', dest='percent', help='convert the data to percent', default=False, action='store_true')

    args = parser.parse_args()

    with open(args.inputFile, mode ='r')as f:
        csvread = csv.reader(f, delimiter='\t', skipinitialspace=True)
        lines = [line for line in csvread]

    header_line = lines[0]
    builds = [replace(el, args.replacements) for el in header_line[1:] if el]
    print("Builds: " + str(builds))

    if args.baseline:
        baselinecol = first_or_none([i + 1 for i in range(len(builds)) if builds[i] == args.baseline])
        if baselinecol is None:
            raise Exception("Could not find the baseline")
        print("baselinecol:" + str(baselinecol))
    else:
        baselinecol = None

    build_testtimingsarray_map = {}
    for build in builds:
        if build not in args.filter:
            build_testtimingsarray_map[build] = []

    test_names = []

    for row in lines[1:]:
        name = replace(row[0], args.replacements)

        divisor = 1 if baselinecol is None else float(row[baselinecol])
        if divisor == 0:
            print("Skipping row with zero value")
        else:
            testdata = [ round(float(el) / divisor, 2) for el in row[1:] ]
            # if args.percent:
            # else:
            #     testdata = [ round(100 * float(el) / divisor, 2) for el in row[1:] ]

            assert len(testdata) == len(builds)

            test_names.append(name)

            for (build, val) in zip(builds, testdata):
                if build not in args.filter:
                    build_testtimingsarray_map[build].append(val)


    if args.statsfile:
        with open(args.statsfile, mode ='w')as f:
            write_stat(f, "Geomean", statistics.geometric_mean, build_testtimingsarray_map)
            write_stat(f, "Median", statistics.median, build_testtimingsarray_map)
            write_stat(f, "Mean", statistics.mean, build_testtimingsarray_map)
            write_stat(f, "Min", min, build_testtimingsarray_map)
            write_stat(f, "Max", max, build_testtimingsarray_map)

    if args.add_geomean:
        test_names.append("Geomean")

        for build in builds:
            if build not in args.filter:
                curr_geomean = round(statistics.geometric_mean(build_testtimingsarray_map[build]), 2)
                build_testtimingsarray_map[build].append(curr_geomean)

    print("test_names: " + str(test_names))
    print("build_testtimingsarray_map: " + str(build_testtimingsarray_map))

    generate_graph(test_names, build_testtimingsarray_map, args.keyright, args.percent, args.outputFile)

main()