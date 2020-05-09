#!/usr/bin/env bash

# is multipass installed?
which multipass  &> /dev/null && MULTIPASS_EXIT_CODE=${?} || MULTIPASS_EXIT_CODE=${?}
if [ "${MULTIPASS_EXIT_CODE}" == 1 ]
then
  echo "Multipass is not installed:"
  echo "https://multipass.run/docs"
  exit 1
fi

