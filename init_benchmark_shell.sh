#!/bin/bash
# CURR_DIR=$(dirname "$0")
function set-title() {
  if [[ -z "$ORIG" ]]; then
    ORIG=$PS1
  fi
  TITLE="\[\e]2;$*\a\]"
  PS1=${ORIG}${TITLE}
}

(taskset -c 2 echo "testing benchmark shell..." > /dev/null 2>&1 && echo "benchmark shell running!") || (echo "Not running in benchmark shell. Soemthing went wrong!" && sudo cset shield --reset && exit 1)
taskset -pc $$
set-title "Benchmark shell"
echo $$ > ./benchmark_shell.pid
