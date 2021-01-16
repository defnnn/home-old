#!/usr/bin/env bash

function main {
  if [[ -d /j/.asdf ]]; then
    export ASDF_DATA_DIR=/j/.asdf
    source /j/.asdf/asdf.sh
  else
    source ~/.asdf/asdf.sh
  fi


  exec "$@"
}

main "$@"
