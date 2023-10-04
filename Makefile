NOTPARALLEL:

.PHONY: build pull pull_subrepos clean

.DEFAULT_GOAL := build

SHELL := /bin/bash

CURR_USER=${USER}
CURR_PATH=${PATH}
CURR_TIME=$(shell date --iso=seconds)
PARALLEL_COUNT=$(shell nproc)
ROOT_PATH=$(shell realpath .)

DIRS=seguecg-libjpeg

bootstrap:
	echo "Bootstrapping"
	sudo apt install -y make gcc g++ clang cmake \
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
	git --recursive git@github.com:UT-Security/%.git

get_source: $(addprefix fetch_,$(DIRS)) wasi-sdk

autopull_%:
	cd $* && git pull --rebase --autostash

pull_subrepos: $(addprefix autopull_,$(DIRS))

pull:
	git pull --rebase --autostash
	$(MAKE) pull_subrepos

build: bootstrap
	echo "Running build"

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
	sudo cset shield --reset

benchmark_shell:
	if [ ! -e "./benchmark_shell.pid" ]; then \
		$(MAKE) helper_shielding_on; \
		sudo cset shield -e sudo -- -u ${CURR_USER} env "PATH=${CURR_PATH}" bash --init-file ${ROOT_PATH}/init_benchmark_shell.sh; \
	else \
		echo "Shielded shell already running. Close existing shielded shell first."; \
	fi

benchmark_shell_close:
	if ! ps -p $(shell cat ./benchmark_shell.pid) > /dev/null; then \
		echo "Removing stale benchmark_shell.pid"; \
		rm ./benchmark_shell.pid; \
	fi
	if [ ! -e "./benchmark_shell.pid" ]; then \
		$(MAKE) helper_restore_hyperthreading; \
		$(MAKE) helper_restore_freqscaling; \
		$(MAKE) helper_shielding_off; \
	else \
		echo "Shielded shell already running. Close existing shielded shell first."; \
	fi

clean:
	echo "Done"