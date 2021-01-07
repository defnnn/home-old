#!/usr/bin/env bash

function main {
  export ASDF_DATA_DIR=/asdf/.asdf

  source /asdf/.asdf/asdf.sh

  exec "$@"
}

main "$@"
