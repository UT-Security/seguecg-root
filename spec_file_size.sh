#!/bin/bash

ROOT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo -n "bziptwo: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/401.bzip2/build/build_base_seguecg_wasm2c_guardpages.0000/bzip2" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "mcf: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/429.mcf/build/build_base_seguecg_wasm2c_guardpages.0000/mcf" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "milc: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/433.milc/build/build_base_seguecg_wasm2c_guardpages.0000/milc" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "namd: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/444.namd/build/build_base_seguecg_wasm2c_guardpages.0000/namd" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "gobmk: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/445.gobmk/build/build_base_seguecg_wasm2c_guardpages.0000/gobmk" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "sjeng: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/458.sjeng/build/build_base_seguecg_wasm2c_guardpages.0000/sjeng" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "libquantum: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/462.libquantum/build/build_base_seguecg_wasm2c_guardpages.0000/libquantum" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "htwosixfourref: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/464.h264ref/build/build_base_seguecg_wasm2c_guardpages.0000/h264ref" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "lbm: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/470.lbm/build/build_base_seguecg_wasm2c_guardpages.0000/lbm" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "astar: "; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/473.astar/build/build_base_seguecg_wasm2c_guardpages.0000/astar" | cut -f1 | tr -d '\n'; echo " KB"

echo ""

echo -n "bziptwo + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/401.bzip2/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/bzip2" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "mcf + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/429.mcf/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/mcf" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "milc + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/433.milc/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/milc" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "namd + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/444.namd/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/namd" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "gobmk + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/445.gobmk/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/gobmk" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "sjeng + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/458.sjeng/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/sjeng" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "libquantum + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/462.libquantum/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/libquantum" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "htwosixfourref + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/464.h264ref/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/h264ref" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "lbm + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/470.lbm/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/lbm" | cut -f1 | tr -d '\n'; echo " KB"
echo -n "astar + Segue:"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/473.astar/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/astar" | cut -f1 | tr -d '\n'; echo " KB"

echo ""

echo -n "\newcommand\bziptwoSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/401.bzip2/build/build_base_seguecg_wasm2c_guardpages.0000/bzip2" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\mcfSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/429.mcf/build/build_base_seguecg_wasm2c_guardpages.0000/mcf" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\milcSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/433.milc/build/build_base_seguecg_wasm2c_guardpages.0000/milc" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\namdSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/444.namd/build/build_base_seguecg_wasm2c_guardpages.0000/namd" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\gobmkSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/445.gobmk/build/build_base_seguecg_wasm2c_guardpages.0000/gobmk" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\sjengSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/458.sjeng/build/build_base_seguecg_wasm2c_guardpages.0000/sjeng" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\libquantumSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/462.libquantum/build/build_base_seguecg_wasm2c_guardpages.0000/libquantum" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\htwosixfourrefSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/464.h264ref/build/build_base_seguecg_wasm2c_guardpages.0000/h264ref" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\lbmSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/470.lbm/build/build_base_seguecg_wasm2c_guardpages.0000/lbm" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\astarSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/473.astar/build/build_base_seguecg_wasm2c_guardpages.0000/astar" | cut -f1 | tr -d '\n'; echo " KB\xspace}"

echo ""

echo -n "\newcommand\bziptwoSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/401.bzip2/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/bzip2" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\mcfSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/429.mcf/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/mcf" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\milcSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/433.milc/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/milc" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\namdSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/444.namd/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/namd" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\gobmkSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/445.gobmk/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/gobmk" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\sjengSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/458.sjeng/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/sjeng" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\libquantumSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/462.libquantum/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/libquantum" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\htwosixfourrefSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/464.h264ref/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/h264ref" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\lbmSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/470.lbm/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/lbm" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
echo -n "\newcommand\astarSegueSize{"; du -k "$ROOT_PATH/spec_benchmarks/benchspec/CPU2006/473.astar/build/build_base_seguecg_wasm2c_guardpages_fsgs.0000/astar" | cut -f1 | tr -d '\n'; echo " KB\xspace}"
