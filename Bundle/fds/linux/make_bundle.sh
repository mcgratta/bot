#!/bin/bash

source ../scripts/GET_ENV.sh

export fds_smvroot=$linux_svn_root
export bundlebase=${fds_version}-${smv_version}_linux64
export fdshost=$linux_hostname
export smvhost=$linux_hostname
export MPI_VERSION=$linux_mpi_version

export INSTALLDIR=FDS6

~/$fds_smvroot/bot/Bundle/fds/scripts/bundle_generic.sh
