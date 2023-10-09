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
		cpuset cpufrequtils
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
	cmake -S seguecg-wasm2c -B seguecg-wasm2c/build_release -DCMAKE_BUILD_TYPE=Release
	cd seguecg-wasm2c/build_release && make -j${PARALLEL_COUNT}

build-wasm2c-debug:
	cmake -S seguecg-wasm2c -B seguecg-wasm2c/build_debug -DCMAKE_BUILD_TYPE=Debug
	cd seguecg-wasm2c/build_debug && make -j${PARALLEL_COUNT}

build-libjpeg-release:
	cd seguecg-libjpeg/benchmark && make

build-libjpeg-debug:
	cd seguecg-libjpeg/benchmark && DEBUG=1 make

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

clean:
	echo "Done"