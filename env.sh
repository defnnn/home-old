#!/usr/bin/env bash

function main {
  export ASDF_DATA_DIR=/j/.asdf

  source /j/.asdf/asdf.sh

  exec "$@"
}

main "$@"
