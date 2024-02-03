NOTPARALLEL:

.DEFAULT_GOAL := build

SHELL := /bin/bash

CURR_USER=${USER}
CURR_PATH=${PATH}
CURR_TIME=$(shell date --iso=seconds)
PARALLEL_COUNT=$(shell nproc)
ROOT_PATH=$(shell realpath .)

DIRS=seguecg-libjpeg seguecg-wasm2c rlbox rlbox_wasm2c_sandbox wasmtime wamr seguecg-firefox

bootstrap: get_source
	echo "Bootstrapping"
	sudo apt install -y gcc g++ g++-12 libc++-dev clang make cmake nasm \
		python3 python3-dev python-is-python3 python3-pip \
		cpuset cpufrequtils curl gnuplot \
		build-essential g++-multilib libgcc-11-dev lib32gcc-11-dev ccache \
		python3.10-venv
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.73.0 -y
	rustup target add wasm32-unknown-unknown wasm32-wasi
	pip3 install simplejson matplotlib
	pip3 install --upgrade requests
	npm install autocannon
	# increase max mmap count for sandbox scaling test
	echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
	echo "vm.max_map_count=1128000" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p
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

# Get the rlbox repos from PLSysSec
fetch_rlbo%:
	if [ ! -e "./rlbo$*" ]; then \
		git clone --recursive git@github.com:PLSysSec/rlbo$*.git; \
	fi

fetch_wasmtime:
	git clone --recursive https://github.com/bytecodealliance/wasmtime
	cd wasmtime && git checkout -b fixed 220139b026d81f01a152c0bd9f0f0daa965bc75c

fetch_wamr:
	git clone --recursive https://github.com/bytecodealliance/wasm-micro-runtime wamr
	cd wamr && git checkout -b v1.3.2 2eb60060d8eb6556ebbe411b22ee7b15ba4f7ec1

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
	cd wamr/wamr-compiler \
		&& ./build_llvm.sh \
		&& mkdir -p build && cd build \
		&& cmake .. \
		&& $(MAKE) -j${PARALLEL_COUNT}
	cd wamr/product-mini/platforms/linux/ \
		&& mkdir -p build && cd build \
		&& cmake .. \
		&& $(MAKE) -j${PARALLEL_COUNT}
	if [ ! -e "./wamr/tests/benchmarks/coremark/build_complete.txt" ]; then \
		cd wamr/tests/benchmarks/coremark/ && ./build.sh && touch ./build_complete.txt; \
	fi
	if [ ! -e "./wamr/tests/benchmarks/dhrystone/build_complete.txt" ]; then \
		cd wamr/tests/benchmarks/dhrystone/ && ./build.sh && touch ./build_complete.txt; \
	fi
	if [ ! -e "./wamr/tests/benchmarks/jetstream/build_complete.txt" ]; then \
		cd wamr/tests/benchmarks/jetstream/ && ./build.sh && touch ./build_complete.txt; \
	fi
	if [ ! -e "./wamr/tests/benchmarks/polybench/build_complete.txt" ]; then \
		cd wamr/tests/benchmarks/polybench/ && ./build.sh && touch ./build_complete.txt; \
	fi
	if [ ! -e "./wamr/tests/benchmarks/sightglass/build_complete.txt" ]; then \
		cd wamr/tests/benchmarks/sightglass/ && ./build.sh && touch ./build_complete.txt; \
	fi

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

build: bootstrap get_source build_wasm2c_release build_wasmtime_release build_wamr_release build_libjpeg_release build_firefox_release
	echo "Build complete!"

build_debug: bootstrap get_source build_wasm2c_debug build_wasmtime_debug build_libjpeg_debug build_firefox_debug
	echo "Debug build complete!"

helper_disable_hyperthreading:
	sudo bash -c "echo off > /sys/devices/system/cpu/smt/control"

helper_restore_hyperthreading:
	sudo bash -c "echo on > /sys/devices/system/cpu/smt/control"

helper_disable_freqscaling:
	sudo cpufreq-set -c 1 -g performance
	sudo cpufreq-set -c 1 --min 2200MHz --max 2200MHz

helper_restore_freqscaling:
	POLICYINFO=($$(cpufreq-info -c 0 -p)) && \
	sudo cpufreq-set -c 1 -g $${POLICYINFO[2]} && \
	sudo cpufreq-set -c 1 --min $${POLICYINFO[0]}MHz --max $${POLICYINFO[1]}MHz

helper_shielding_on:
	sudo cset shield -c 1 -k on

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

benchmark_wamr_segue:
	cd $(ROOT_PATH)/wamr/tests/benchmarks/coremark/ && ./run.sh | tee $(ROOT_PATH)/benchmarks/wamr_segue_coremark_$(CURR_TIME).txt
	cd $(ROOT_PATH)/wamr/tests/benchmarks/dhrystone/ && ./run.sh | tee $(ROOT_PATH)/benchmarks/wamr_segue_dhrystone_$(CURR_TIME).txt
	cd $(ROOT_PATH)/wamr/tests/benchmarks/jetstream/ && ./run_aot.sh && mv ./report.txt $(ROOT_PATH)/benchmarks/wamr_segue_jetstream_$(CURR_TIME).txt
	cd $(ROOT_PATH)/wamr/tests/benchmarks/polybench/ && ./run_aot.sh && mv ./report.txt $(ROOT_PATH)/benchmarks/wamr_segue_polybench_$(CURR_TIME).txt
	cd $(ROOT_PATH)/wamr/tests/benchmarks/sightglass/ && ./run_aot.sh && mv ./report.txt $(ROOT_PATH)/benchmarks/wamr_segue_sightglass_$(CURR_TIME).txt

benchmark_graphite_segue:
	cd seguecg-firefox && ./testsRunBenchmark "../benchmarks/graphite_test_segue_$(CURR_TIME)" "graphite_perf_test" "stock segue"

benchmark_jpeg_segue:
	cd seguecg-firefox && ./testsRunBenchmark "../benchmarks/jpeg_test_segue_$(CURR_TIME)" "jpeg_perf" "stock segue"
	./seguecg-firefox/testsProduceImagePlotData.py ./benchmarks/jpeg_test_segue_$(CURR_TIME)/compare_stock_terminal_analysis.json.dat ./benchmarks/jpeg_test_segue_$(CURR_TIME)/jpeg_perf.plotdat
	gnuplot -e "inputfilename='./benchmarks/jpeg_test_segue_$(CURR_TIME)/jpeg_perf.plotdat';outputfilename='./benchmarks/jpeg_test_segue_$(CURR_TIME)/jpeg_perf.pdf'" ./seguecg-firefox/testsProduceImagePlot.gnu

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
		"spec_benchmarks/result/spec_results=seguecg_wasm2c_guardpages:GuardPage,seguecg_wasm2c_guardpages_fsgs:GuardPage + Segue,seguecg_wasm2c_boundschecks:BoundCheck,seguecg_wasm2c_boundschecks_fsgs:BoundCheck + Segue" \
		-n $(words $(SPEC_BUILDS)) --usePercent --baseline native_clang
	python3 spec_stats.py -i spec_benchmarks/result --filter  \
		"spec_benchmarks/result/spec_results_guard=seguecg_wasm2c_guardpages:GuardPage,seguecg_wasm2c_guardpages_fsgs:GuardPage + Segue" \
		-n $(words $(SPEC_BUILDS)) --usePercent --baseline native_clang
	python3 spec_stats.py -i spec_benchmarks/result --filter  \
		"spec_benchmarks/result/spec_results_bounds=seguecg_wasm2c_boundschecks:BoundCheck,seguecg_wasm2c_boundschecks_fsgs:BoundCheck + Segue" \
		-n $(words $(SPEC_BUILDS)) --usePercent --baseline native_clang
	./spec_file_size.sh | tee spec_benchmarks/result/spec_results_size.txt
	mv spec_benchmarks/result/ benchmarks/spec_$(CURR_TIME)

clean:
	echo "Done"