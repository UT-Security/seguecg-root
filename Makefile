NOTPARALLEL:

.DEFAULT_GOAL := build

SHELL := /bin/bash

CURR_USER=${USER}
CURR_PATH=${PATH}
CURR_TIME=$(shell date --iso=seconds)
PARALLEL_COUNT=$(shell nproc)
ROOT_PATH=$(shell realpath .)

# contact zyedidia for spec2017 download password
SPEC17_PASSWORD=

DIRS=seguecg-libjpeg seguecg-wasm2c rlbox rlbox_wasm2c_sandbox wasmtime seguecg-wamr seguecg-firefox mte_benchmarks colorguard_benchmarks

bootstrap: get_source
	echo "Bootstrapping"
	sudo apt install -y gcc g++ g++-12 libc++-dev clang make cmake nasm \
		python3 python3-dev python-is-python3 python3-pip \
		cpuset cpufrequtils curl gnuplot \
		build-essential g++-multilib libgcc-11-dev lib32gcc-11-dev ccache \
		python3.10-venv jq peg ldc
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.73.0 -y
	rustup target add wasm32-unknown-unknown wasm32-wasi
	pip3 install simplejson matplotlib
	pip3 install --upgrade requests
	npm install autocannon
	# increase max mmap count for sandbox scaling test
	echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
	echo "vm.max_map_count=1128000" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p
	wget https://github.com/sharkdp/hyperfine/releases/download/v1.18.0/hyperfine_1.18.0_amd64.deb
	sudo dpkg -i hyperfine_1.18.0_amd64.deb
	cd seguecg-firefox/mybuild && $(MAKE) bootstrap
	touch ./$@

wasi-sdk-20.0.threads-linux.tar.gz:
	wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20%2Bthreads/wasi-sdk-20.0.threads-linux.tar.gz

wasi-sdk: wasi-sdk-20.0.threads-linux.tar.gz
	mkdir -p $@
	tar -zxf $< -C $@ --strip-components 1
	sudo cp -r $@ /opt/wasi-sdk

fetch_%:
	if [ ! -e "./$*" ]; then \
		git clone --recursive git@github.com:UT-Security/$*.git; \
	fi

# Get the rlbox, colorguard-bench repos from PLSysSec
fetch_rlbo%:
	if [ ! -e "./rlbo$*" ]; then \
		git clone --recursive git@github.com:PLSysSec/rlbo$*.git; \
	fi

fetch_colorguard_benchmarks:
	if [ ! -e "./colorguard_benchmarks" ]; then \
		git clone --recursive git@github.com:PLSysSec/colorguard_benchmarks.git; \
	fi

fetch_wasmtime:
	git clone --recursive https://github.com/bytecodealliance/wasmtime
	cd wasmtime && git checkout -b fixed 220139b026d81f01a152c0bd9f0f0daa965bc75c

fetch_lfi:
	git clone --recursive https://github.com/zyedidia/lfi
	git checkout seguecg-pinned

fetch_spec17:
	wget --user=protected --password=$(SPEC17_PASSWORD) https://stanford.edu/~zyedidia/protected/cpu2017-1.1.0.iso.zip
	unzip cpu2017-1.1.0.iso.zip
	sudo mount -t iso9660 -o ro,exec,loop cpu2017-1.1.0.iso /mnt
	mkdir -p $(ROOT_PATH)/segue-lfi
	cd /mnt && ./install.sh -d $(ROOT_PATH)/segue-lfi/spec2017

# must have lfi downloaded already
setup_spec17:
	cd $(ROOT_PATH)/segue-lfi/spec2017 && cp $(ROOT_PATH)/lfi/specinvoke/bench/segue/bench.sh .
	cd $(ROOT_PATH)/segue-lfi/spec2017/config && cp $(ROOT_PATH)/lfi/specinvoke/config/segue/*.cfg .
	cd $(ROOT_PATH)/segue-lfi/spec2017 && $(ROOT_PATH)/lfi/specinvoke/patches/apply.sh
	cd lfi/specinvoke && go build
	cd $(ROOT_PATH)/segue-lfi/spec2017/bin && mv specinvoke specinvoke.orig && mv $(ROOT_PATH)/lfi/specinvoke/specinvoke .
	cd $(ROOT_PATH)/segue-lfi/spec2017 && mv version.txt version.txt.old && echo "0.0.0" > version.txt

get_source: $(addprefix fetch_,$(DIRS)) wasi-sdk
	touch ./get_source

autopull_%:
	cd $* && git pull --rebase --autostash

pull_subrepos: $(addprefix autopull_,$(DIRS))

pull:
	git pull --rebase --autostash
	$(MAKE) pull_subrepos


build_wasmtime_release:
	cd wasmtime && cargo build --release &&  cargo build --release --benches

build_wasmtime_debug:
	cd wasmtime && cargo build

build_wamr_release:
	cd seguecg-wamr/wamr-compiler \
		&& ./build_llvm.sh \
		&& mkdir -p build && cd build \
		&& cmake .. \
		&& $(MAKE) -j${PARALLEL_COUNT}
	cd seguecg-wamr/product-mini/platforms/linux/ \
		&& mkdir -p build && cd build \
		&& cmake .. \
		&& $(MAKE) -j${PARALLEL_COUNT}
	cd seguecg-wamr/tests/benchmarks/coremark/ && ./build.sh
	cd seguecg-wamr/tests/benchmarks/dhrystone/ && ./build.sh
	cd seguecg-wamr/tests/benchmarks/polybench/ && ./build.sh
	cd seguecg-wamr/tests/benchmarks/sightglass/ && ./build.sh

build_wasm2c_release:
	cmake -S seguecg-wasm2c -B seguecg-wasm2c/build_release -DWITH_WASI=ON -DCMAKE_BUILD_TYPE=Release
	cd seguecg-wasm2c/build_release && $(MAKE) -j${PARALLEL_COUNT}

build_wasm2c_debug:
	cmake -S seguecg-wasm2c -B seguecg-wasm2c/build_debug -DWITH_WASI=ON -DCMAKE_BUILD_TYPE=Debug
	cd seguecg-wasm2c/build_debug && $(MAKE) -j${PARALLEL_COUNT}

build_libjpeg_release:
	cd seguecg-libjpeg/benchmark && $(MAKE) -j${PARALLEL_COUNT}

build_libjpeg_debug:
	cd seguecg-libjpeg/benchmark && DEBUG=1 $(MAKE) -j${PARALLEL_COUNT}

build_libjpeg_mpx_release:
	cd seguecg-libjpeg/benchmark && $(MAKE) build_mpx -j${PARALLEL_COUNT}

build_libjpeg_mpx_debug:
	cd seguecg-libjpeg/benchmark && DEBUG=1 $(MAKE) build_mpx -j${PARALLEL_COUNT}

build_firefox_release:
	cd seguecg-firefox/mybuild && $(MAKE) build

build_firefox_debug:
	cd seguecg-firefox/mybuild && $(MAKE) build-debug

build_lfi:
	cd lfi/lfi-leg && ./build.sh
	cd lfi/liblfi && ./build.sh
	cd lfi/lfi-veribdd && ./build.sh
	cd lfi/lfi-run && ./build.sh
	mkdir -p $(ROOT_PATH)/segue-lfi/bin
	mv lfi/lfi-run/lfi-run $(ROOT_PATH)/segue-lfi/bin
	mv lfi/lfi-leg/lfi-leg $(ROOT_PATH)/segue-lfi/bin
	LFIFLAGS="--cfi=bundle32" PATH="$(ROOT_PATH)/segue-lfi/bin:$(CURR_PATH)" cd lfi/toolchain/lfi-gcc && ./install-toolchain.sh $(ROOT_PATH)/lfi-amd64 x86_64 && rm -rf build-gcc build-binutils
	LFIFLAGS="--cfi=bundle32 --no-segue" PATH="$(ROOT_PATH)/segue-lfi/bin:$(CURR_PATH)" cd lfi/toolchain/lfi-gcc && ./install-toolchain.sh $(ROOT_PATH)/lfi-amd64-baseline x86_64 && rm -rf build-gcc build-binutils
	LFIFLAGS="--sandbox=none" PATH="$(ROOT_PATH)/segue-lfi/bin:$(CURR_PATH)" cd lfi/toolchain/lfi-gcc && ./install-toolchain.sh $(ROOT_PATH)/native-gcc x86_64 && rm -rf build-gcc build-binutils
	sudo mv $(ROOT_PATH)/lfi-amd64 /opt
	sudo mv $(ROOT_PATH)/lfi-amd64-baseline /opt
	sudo mv $(ROOT_PATH)/native-gcc /opt

build: bootstrap get_source build_wasm2c_release build_wasmtime_release build_wamr_release build_libjpeg_release build_firefox_release
	echo "Build complete!"

build_debug: bootstrap get_source build_wasm2c_debug build_wasmtime_debug build_libjpeg_debug build_firefox_debug
	echo "Debug build complete!"

helper_disable_hyperthreading:
	sudo bash -c "echo off > /sys/devices/system/cpu/smt/control"

helper_restore_hyperthreading:
	sudo bash -c "echo on > /sys/devices/system/cpu/smt/control"

helper_disable_freqscaling:
	sudo cpufreq-set -c 2 -g performance
	sudo cpufreq-set -c 2 --min 2200MHz --max 2200MHz

helper_restore_freqscaling:
	POLICYINFO=($$(cpufreq-info -c 0 -p)) && \
	sudo cpufreq-set -c 2 -g $${POLICYINFO[2]} && \
	sudo cpufreq-set -c 2 --min $${POLICYINFO[0]}MHz --max $${POLICYINFO[1]}MHz

helper_shielding_on:
	sudo cset shield -c 2 -k on

helper_shielding_off:
	sudo cset shield --reset || echo "Done"

benchmark_shell:
	if [ ! -e "./benchmark_shell.pid" ]; then \
		$(MAKE) helper_shielding_on; \
		sudo cset shield -e sudo -- -u ${CURR_USER} env "PATH=${CURR_PATH}" bash --init-file ${ROOT_PATH}/init_benchmark_shell.sh; \
	else \
		echo "Shielded shell already running. Close existing shielded shell first and then run make benchmark_shell_close."; \
	fi

benchmark_shell_close: helper_restore_hyperthreading helper_restore_freqscaling helper_shielding_off
	if [ -e "./benchmark_shell.pid" ]; then \
		echo "Removing stale benchmark_shell.pid"; \
		CURR_PID=$(shell cat ./benchmark_shell.pid) && rm ./benchmark_shell.pid && kill -SIGKILL $$CURR_PID; \
	fi

benchmark_jpeg:
	cd seguecg-libjpeg/benchmark && $(MAKE) -s test | tee $(ROOT_PATH)/benchmarks/jpeg_benchmark_$(CURR_TIME).txt

benchmark_jpeg_all:
	cd seguecg-libjpeg/benchmark && $(MAKE) -s test | tee $(ROOT_PATH)/benchmarks/jpeg_benchmark_$(CURR_TIME).txt
	cd seguecg-libjpeg/benchmark && $(MAKE) -s tests_old | tee -a $(ROOT_PATH)/benchmarks/jpeg_benchmark_$(CURR_TIME).txt

benchmark_jpeg_mpx:
	cd seguecg-libjpeg/benchmark && $(MAKE) -s test_mpx | tee $(ROOT_PATH)/benchmarks/jpeg_benchmark_mpx_$(CURR_TIME).txt

benchmark_wasmtime_transitions:
	cd wasmtime && cargo bench -- 'sync-pool/no-hook/core .+ nop$$' | tee $(ROOT_PATH)/benchmarks/wasmtime_transitions_$(CURR_TIME).txt
	echo -e "-------MPK--------\n"  | tee -a $(ROOT_PATH)/benchmarks/wasmtime_transitions_$(CURR_TIME).txt
	cd wasmtime && WASMTIME_TEST_FORCE_MPK=1 cargo bench -- 'sync-pool/no-hook/core .+ nop$$' | tee -a $(ROOT_PATH)/benchmarks/wasmtime_transitions_$(CURR_TIME).txt

benchmark_wasmtime_scaling:
	cd wasmtime && cargo run --release --example mpk -- --memory-size 408MiB | tee $(ROOT_PATH)/benchmarks/wasmtime_scaling_$(CURR_TIME).txt

benchmark_wamr_segue:
	mkdir -p $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)
	cd $(ROOT_PATH)/seguecg-wamr/tests/benchmarks/coremark/ && ./run.sh | grep -E "(Run\s|\stime\s)" | tee $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/coremark.txt
	cd $(ROOT_PATH)/seguecg-wamr/tests/benchmarks/dhrystone/ && ./run.sh | tee $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/dhrystone.txt
	cd $(ROOT_PATH)/seguecg-wamr/tests/benchmarks/polybench/ && ./run_aot.sh && mv ./report.txt $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/polybench.txt
	cd $(ROOT_PATH)/seguecg-wamr/tests/benchmarks/sightglass/ && ./run_aot.sh && mv ./report.txt $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.txt
	./tsv_to_plot.py "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/polybench.txt" "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/polybench.pdf" -s "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/polybench.stats" -r "iwasm-aot:GuardPage" -r "iwasm-aot-segue:GuardPage + Segue" -b native -f "native" -f "iwasm-aot-segue-store" -f "iwasm-aot-segue-load" -g
	./tsv_to_plot.py "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.txt" "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.pdf" -s "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.stats"  -r "iwasm-aot:Wamr" -r "iwasm-aot-segue:Wamr with Segue" -f "iwasm-aot-segue-store" -r "iwasm-aot-segue-load:Wamr with Segue on Loads" -b native -f native -kr -p

benchmark_wamr_segue_coremark:
	mkdir -p $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)
	cd $(ROOT_PATH)/seguecg-wamr/tests/benchmarks/coremark/ && ./run.sh | grep -E "(Run\s|\stime\s)" | tee $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/coremark.txt

benchmark_wamr_segue_sightglass:
	mkdir -p $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)
	cd $(ROOT_PATH)/seguecg-wamr/tests/benchmarks/sightglass/ && ./run_aot.sh && mv ./report.txt $(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.txt
	./tsv_to_plot.py "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.txt" "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.pdf" -s "$(ROOT_PATH)/benchmarks/wamr_segue_$(CURR_TIME)/sightglass.stats"  -r "iwasm-aot:Wamr" -r "iwasm-aot-segue:Wamr with Segue" -f "iwasm-aot-segue-store" -r "iwasm-aot-segue-load:Wamr with Segue on Loads" -b native -f native -kr -p

benchmark_graphite_segue:
	cd seguecg-firefox && ./testsRunBenchmark "../benchmarks/graphite_test_segue_$(CURR_TIME)" "graphite_perf_test" "native stock segue"

# benchmark_jpeg_segue:
# 	cd seguecg-firefox && ./testsRunBenchmark "../benchmarks/jpeg_test_segue_$(CURR_TIME)" "jpeg_perf" "stock segue"
# 	./seguecg-firefox/testsProduceImagePlotData.py ./benchmarks/jpeg_test_segue_$(CURR_TIME)/compare_stock_terminal_analysis.json.dat ./benchmarks/jpeg_test_segue_$(CURR_TIME)/jpeg_perf.plotdat
# 	gnuplot -e "inputfilename='./benchmarks/jpeg_test_segue_$(CURR_TIME)/jpeg_perf.plotdat';outputfilename='./benchmarks/jpeg_test_segue_$(CURR_TIME)/jpeg_perf.pdf'" ./seguecg-firefox/testsProduceImagePlot.gnu

#### Keep Spec stuff separate so we can easily release other artifacts
SPEC_BUILDS=native_clang wasm_seguecg_wasm2c_guardpages wasm_seguecg_wasm2c_boundschecks wasm_seguecg_wasm2c_guardpages_fsgs wasm_seguecg_wasm2c_boundschecks_fsgs

spec_benchmarks:
	git clone --recursive git@github.com:PLSysSec/hfi_spec.git $@
	cd $@ && SPEC_INSTALL_NOCHECK=1 SPEC_FORCE_INSTALL=1 sh install.sh -f

clean_spec:
	cd spec_benchmarks && source shrc &&  cd config && \
	echo "Cleaning dirs..." && \
	for spec_build in $(SPEC_BUILDS); do \
		runspec --config=$$spec_build.cfg --action=clobber --define cores=1 --iterations=1 --noreportable --size=ref wasmint 2&>1 > /dev/null; \
	done

build_spec: spec_benchmarks build_wasm2c_release clean_spec
	cd spec_benchmarks && source shrc &&  cd config && \
	for spec_build in $(SPEC_BUILDS); do \
		echo "Building $$spec_build"; \
		runspec --config=$$spec_build.cfg --action=build --define cores=1 --iterations=1 --noreportable --size=ref wasmint | grep "Build "; \
	done

benchmark_spec:
	cd spec_benchmarks && source shrc && cd config && \
	for spec_build in $(SPEC_BUILDS); do \
		runspec --config=$$spec_build.cfg --action=run --define cores=1 --iterations=1 --noreportable --size=ref wasmint; \
	done
	python3 spec_stats.py -i spec_benchmarks/result --filter  \
		"spec_benchmarks/result/spec_results=seguecg_wasm2c_guardpages:GuardPage,seguecg_wasm2c_guardpages_fsgs:Wasm2c,seguecg_wasm2c_boundschecks:BoundCheck,seguecg_wasm2c_boundschecks_fsgs:BoundCheck + Segue" \
		-n $(words $(SPEC_BUILDS)) --usePercent --baseline native_clang
	python3 spec_stats.py -i spec_benchmarks/result --filter  \
		"spec_benchmarks/result/spec_results_guard=seguecg_wasm2c_guardpages:GuardPage,seguecg_wasm2c_guardpages_fsgs:Wasm2c" \
		-n $(words $(SPEC_BUILDS)) --usePercent --baseline native_clang
	python3 spec_stats.py -i spec_benchmarks/result --filter  \
		"spec_benchmarks/result/spec_results_bounds=seguecg_wasm2c_boundschecks:BoundCheck,seguecg_wasm2c_boundschecks_fsgs:Wasm2c with Segue" \
		-n $(words $(SPEC_BUILDS)) --usePercent --baseline native_clang
	./spec_file_size.sh | tee spec_benchmarks/result/spec_results_size.txt
	mv spec_benchmarks/result/ benchmarks/spec_$(CURR_TIME)

rerun_graphs:
	python3 spec_stats.py -i benchmarks/spec_2024-02-03T05:40:36-06:00 --filter  \
		"benchmarks/spec_2024-02-03T05:40:36-06:00/spec_results_guard=seguecg_wasm2c_guardpages:Wasm2c,seguecg_wasm2c_guardpages_fsgs:Wasm2c with Segue" \
		-n 5 --usePercent --baseline native_clang
	python spec_stats.py -i "benchmarks/lfispec_2024-06-23T02:27:08-05:00" --spec2017 --filter \
		"benchmarks/lfispec_2024-06-23T02:27:08-05:00/spec17_results_32=lfi-gcc-baseline-32-m64:LFI,lfi-gcc-32-m64:LFI with Segue" \
		-n 5 --usePercent --baseline gcc-m64
	cp benchmarks/lfispec_2024-06-23T02:27:08-05:00/spec17_results_32.pdf ../seguecg-full-paper/figures/lfi.pdf
	cp benchmarks/spec_2024-02-03T05:40:36-06:00/spec_results_guard.pdf ../seguecg-full-paper/figures/spec/spec_results_guard.pdf
	./throughput_plot.py && cp ./benchmarks/faas-throughput.pdf ../seguecg-full-paper/figures/faas-throughput.pdf
	./tsv_to_plot.py "$(ROOT_PATH)/benchmarks/wamr_segue_2024-02-09T01:10:32-06:00/sightglass.txt" "$(ROOT_PATH)/benchmarks/wamr_segue_2024-02-09T01:10:32-06:00/sightglass.pdf" -s "$(ROOT_PATH)/benchmarks/wamr_segue_2024-02-09T01:10:32-06:00/sightglass.stats" -r "iwasm-aot:Wamr" -r "iwasm-aot-segue:Wamr with Segue" -f "iwasm-aot-segue-store" -r "iwasm-aot-segue-load:Wamr with Segue on Loads" -b native -f native -kr -p
	cp benchmarks/wamr_segue_2024-02-09T01:10:32-06:00/sightglass.pdf ../seguecg-full-paper/figures/wamr/sightglass.pdf

tt:
	cd ./benchmarks/micro_benches && python ../../throughput_micros_plot.py regex_baseline.tsv load_balancing_baseline.tsv templating_baseline.tsv regex_cg.tsv load_balancing_cg.tsv templating_cg.tsv
	cp ./benchmarks/micro_benches/csw_graph.pdf ../seguecg-full-paper/figures/csw_graph.pdf
	cp ./benchmarks/micro_benches/dtlb_graph.pdf ../seguecg-full-paper/figures/dtlb_graph.pdf

build_lfisegue_spec:
	PATH=$(ROOT_PATH)/segue-lfi/bin:$(PATH) \
	cd segue-lfi/spec2017 && \
		export SPEC_NOCHECK=1 && \
		source shrc && \
		./build.sh

benchmark_lfisegue_spec:
	export PATH=$(ROOT_PATH)/segue-lfi/bin:$(PATH) &&
	if [ -e "segue-lfi/spec2017/result/" ]; then \
		mv segue-lfi/spec2017/result/ benchmarks/old_lfispec_$(CURR_TIME); \
	fi
	cd segue-lfi/spec2017 && \
		export SPEC_NOCHECK=1 && \
		source shrc && \
		taskset -c 2 ./bench.sh
	mv segue-lfi/spec2017/result/ benchmarks/lfispec_$(CURR_TIME)
	# overheads comparing run 001 (LFI) to run 003 (native)
	# overheads comparing run 002 (LFI-baseline) to run 003 (native)
	cd benchmarks/lfispec_$(CURR_TIME) && \
	$(ROOT_PATH)/segue-lfi/lfi-bench/bin/spec-data ./CPU2017.001.intrate.refrate.csv ./CPU2017.001.fprate.refrate.csv ./CPU2017.005.intrate.refrate.csv ./CPU2017.005.fprate.refrate.csv | tee ./lfisegue_overheads.txt && \
	$(ROOT_PATH)/segue-lfi/lfi-bench/bin/spec-data ./CPU2017.002.intrate.refrate.csv ./CPU2017.002.fprate.refrate.csv ./CPU2017.005.intrate.refrate.csv ./CPU2017.005.fprate.refrate.csv | tee ./lfi_overheads.txt && \
	$(ROOT_PATH)/segue-lfi/lfi-bench/bin/spec-data ./CPU2017.003.intrate.refrate.csv ./CPU2017.003.fprate.refrate.csv ./CPU2017.005.intrate.refrate.csv ./CPU2017.005.fprate.refrate.csv | tee ./lfisegue_overheads_32.txt && \
	$(ROOT_PATH)/segue-lfi/lfi-bench/bin/spec-data ./CPU2017.004.intrate.refrate.csv ./CPU2017.004.fprate.refrate.csv ./CPU2017.005.intrate.refrate.csv ./CPU2017.005.fprate.refrate.csv | tee ./lfi_overheads_32.txt
	python spec_stats.py -i "benchmarks/lfispec_$(CURR_TIME)" --spec2017 --filter \
		"benchmarks/lfispec_2024-06-23T02:27:08-05:00/spec17_results_16=lfi-gcc-baseline-m64:LFI,lfi-gcc-m64:LFI with Segue" \
		-n 5 --usePercent --baseline gcc-m64
	python spec_stats.py -i "benchmarks/lfispec_$(CURR_TIME)" --spec2017 --filter \
		"benchmarks/lfispec_2024-06-23T02:27:08-05:00/spec17_results_32=lfi-gcc-baseline-32-m64:LFI,lfi-gcc-32-m64:LFI with Segue" \
		-n 5 --usePercent --baseline gcc-m64

clean:
	echo "Done"
