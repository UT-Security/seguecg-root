NOTPARALLEL:

.DEFAULT_GOAL := build

SHELL := /bin/bash

CURR_USER=${USER}
CURR_PATH=${PATH}
CURR_TIME=$(shell date --iso=seconds)
PARALLEL_COUNT=$(shell nproc)
ROOT_PATH=$(shell realpath .)

DIRS=seguecg-libjpeg seguecg-wasm2c rlbox rlbox_wasm2c_sandbox

bootstrap:
	echo "Bootstrapping"
	sudo apt install -y gcc g++ g++-12 libc++-dev clang make cmake nasm \
		python3 python3-dev python-is-python3 python3-pip \
		cpuset cpufrequtils curl
	curl https://wasmtime.dev/install.sh -sSf | bash
	pip3 install simplejson matplotlib
	pip3 install --upgrade requests
	npm install autocannon
	# increase max mmap count for sandbox scaling test
	echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
	echo "vm.max_map_count=1128000" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p
	touch ./$@

wasi-sdk-20.0.threads-linux.tar.gz:
	wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20%2Bthreads/wasi-sdk-20.0.threads-linux.tar.gz

wasi-sdk: wasi-sdk-20.0.threads-linux.tar.gz
	mkdir -p $@
	tar -zxf $< -C $@ --strip-components 1

fetch_%:
	if [ ! -e "./$*" ]; then \
		git clone --recursive git@github.com:UT-Security/$*.git; \
	fi

# Get the rlbox repos from PLSysSec
fetch_rlbo%:
	if [ ! -e "./rlbo$*" ]; then \
		git clone --recursive git@github.com:PLSysSec/rlbo$*.git; \
	fi

get_source: $(addprefix fetch_,$(DIRS)) wasi-sdk
	touch ./get_source

autopull_%:
	cd $* && git pull --rebase --autostash

pull_subrepos: $(addprefix autopull_,$(DIRS))

pull:
	git pull --rebase --autostash
	$(MAKE) pull_subrepos

build-wasm2c-release:
	cmake -S seguecg-wasm2c -B seguecg-wasm2c/build_release -DWITH_WASI=ON -DCMAKE_BUILD_TYPE=Release
	cd seguecg-wasm2c/build_release && $(MAKE) -j${PARALLEL_COUNT}

build-wasm2c-debug:
	cmake -S seguecg-wasm2c -B seguecg-wasm2c/build_debug -DWITH_WASI=ON -DCMAKE_BUILD_TYPE=Debug
	cd seguecg-wasm2c/build_debug && $(MAKE) -j${PARALLEL_COUNT}

build-libjpeg-release:
	cd seguecg-libjpeg/benchmark && $(MAKE) -j${PARALLEL_COUNT}

build-libjpeg-debug:
	cd seguecg-libjpeg/benchmark && DEBUG=1 $(MAKE) -j${PARALLEL_COUNT}

build-libjpeg-mpx-release:
	cd seguecg-libjpeg/benchmark && $(MAKE) build_mpx -j${PARALLEL_COUNT}

build-libjpeg-mpx-debug:
	cd seguecg-libjpeg/benchmark && DEBUG=1 $(MAKE) build_mpx -j${PARALLEL_COUNT}

build: bootstrap get_source build-wasm2c-release build-libjpeg-release
	echo "Build complete!"

build-debug: bootstrap get_source build-wasm2c-debug build-libjpeg-debug
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

#### Keep Spec stuff separate so we can easily release other artifacts
 # wasm_hfi_wasm2c_masking
SPEC_BUILDS=wasm_seguecg_wasm2c_guardpages wasm_seguecg_wasm2c_boundschecks wasm_seguecg_wasm2c_guardpages_fsgs wasm_seguecg_wasm2c_boundschecks_fsgs

spec_benchmarks:
	git clone --recursive git@github.com:PLSysSec/hfi_spec.git $@
	cd $@ && SPEC_INSTALL_NOCHECK=1 SPEC_FORCE_INSTALL=1 sh install.sh -f

clean_spec:
	cd spec_benchmarks && source shrc &&  cd config && \
	echo "Cleaning dirs..." && \
	for spec_build in $(SPEC_BUILDS); do \
		runspec --config=$$spec_build.cfg --action=clobber --define cores=1 --iterations=1 --noreportable --size=ref wasmint 2&>1 > /dev/null; \
	done

build_spec: spec_benchmarks build-wasm2c-release clean_spec
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
		"spec_benchmarks/result/spec_results=seguecg_wasm2c_boundschecks:BoundsChecks,seguecg_wasm2c_boundschecks_fsgs:BoundsChecksSegue,seguecg_wasm2c_guardpages:GuardPages,seguecg_wasm2c_guardpages_fsgs:GuardPagesSegue" -n $(words $(SPEC_BUILDS)) --usePercent
	mv spec_benchmarks/result/ benchmarks/spec_$(CURR_TIME)

clean:
	echo "Done"