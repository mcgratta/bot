#!/bin/bash

#*** Linux parameters

intel_mpi_version_linux=20u1
#intel_mpi_version_linux=oneapi
mpi_version_linux=INTEL

#*** OSX parameters

intel_mpi_version_osx=19u4
mpi_version_osx=3.1.2
#intel_mpi_version_osx=oneapi
#mpi_version_osx=3.1.6

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script builds a bundle using applications built by firebot, FDS pubs"
echo "built by firebot, Smokeview pubs built by smokebot and other files found"
echo "in the fds, smv and bot repos."
echo ""
echo "Options:"
echo "Parameters specifying where pubs are built"
echo "-p - host containing pubs [default: $pub_host]"
echo "-F - home directory containing FDS pubs [default: $fds_pub_home]"
echo "-S - home directory containing Smokeview pubs [default: $smv_pub_home]"
echo ""
echo "Parameters specifying branch used to build the bundle"
echo "-b branch_name - use branch named branch_name to make the bundle [default: $BRANCH]"
echo "-r - use a branch named release"
echo "-t - use a branch named test"
echo ""
echo "Other parmeters"
echo "-c - use apps and pubs previously copied to $HOME/.bundle/apps "
echo "     and $HOME/.bundle/pubs directories by firebot and smokebot"
echo "-d dir - directory containing bundle generated by this script"
echo "     [default: $bundle_dir]"
echo "-f - force this script to run"
echo "-g - upload installer file to a google drive directory with id found in the"
echo "     file $HOME/.bundle/GOOGLE_DIR_ID"
echo "-h - display this message"
echo "-v - show parameters used to build bundle (the bundle is not generated)"
echo "-w - overwrite bundle (if it already exists) "
echo "-x fds_revision - fds revision"
echo "-y smv_revision - smv revision"
echo "   The -x and -y options are only used with the -R cloning option"
exit 0
}

#define default home directories for apps and pubs
app_home=$HOME
if [ -e $HOME/.bundle/bundle_config.sh ]; then
  source $HOME/.bundle/bundle_config.sh
else
  echo ***error: configuration file $HOME/.bundle/bundle_config.sh is not defined
  exit 1
fi
fds_pub_home=$bundle_firebot_home
smv_pub_home=$bundle_smokebot_home

# define default host where pubs are found
pub_host=`hostname`
if [ "$PUB_HOST" != "" ]; then
  pub_host=$PUB_HOST
fi

# define default host where apps are found

showparms=
ECHO=
bundle_dir=$HOME/.bundle/bundles
USE_CACHE=
OVERWRITE=
UPLOAD_GOOGLE=
FORCE=
GOOGLE_DIR_ID_FILE=$HOME/.bundle/GOOGLE_DIR_ID
CURDIR=`pwd`
OUTPUT_DIR=$CURDIR/output
SYNC_REVS=
BRANCH=master
BUNDLE_PREFIX="tst"
FDS_REVISION=
SMV_REVISION=

while getopts 'b:cd:fF:ghp:rS:tvwx:y:' OPTION
do
case $OPTION  in
  b)
   BRANCH=$OPTARG
   ;;
  c)
   USE_CACHE=1
   app_home=$HOME
   pub_host=`hostname`
   fds_pub_home=$HOME
   smv_pub_home=$HOME
   ;;
  d)
   bundle_dir=$OPTARG
   ;;
  f)
   FORCE="1"
   ;;
  F)
   fds_pub_home=$OPTARG
   ;;
  g)
   UPLOAD_GOOGLE=1
   ;;
  h)
   usage;
   ;;
  p)
   pub_host=$OPTARG
   ;;
  r)
   BRANCH=release
   ;;
  S)
   smv_pub_home=$OPTARG
   ;;
  t)
   BRANCH=test
   ;;
  v)
   showparms=1
   ECHO=echo
   ;;
  w)
   OVERWRITE=1
   ;;
  x)
   FDS_REVISION=$OPTARG
   ;;
  y)
   SMV_REVISION=$OPTARG
   ;;
esac
done
shift $(($OPTIND-1))

# prevent more than one instance of the make_bundle.sh script from running
# at the same time

LOCK_FILE=$HOME/.bundle/make_bundle_lock
if [ "$FORCE" == "" ]; then
if [ -e $LOCK_FILE ]; then
  echo "***error: another instance of the bundlebot script is running."
  echo "          If this is not the case re-run using the -f option."
  exit 1
fi
fi
touch $LOCK_FILE

if [ "$shoparms" == "" ]; then
  if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
  fi
  rm -f $OUTPUT_DIR/*
fi

# determine platform script is running on

if [ "`uname`" == "Darwin" ]; then
  intel_mpi_version=$intel_mpi_version_osx
  mpi_version=$mpi_version_osx
  platform=osx
else
  intel_mpi_version=$intel_mpi_version_linux
  mpi_version=$mpi_version_linux
  platform=lnx
fi

BUNDLE_PREFIX_FILE=${BUNDLE_PREFIX}_
if [ "$BRANCH" == "release" ]; then
  BUNDLE_PREFIX=null
  BUNDLE_PREFIX_FILE=
fi
BRANCHDIR=$BRANCH
if [ "$BRANCH" != "release" ]; then
  BRANCHDIR=
fi

if [ "$showparms" == "1" ]; then
  echo ""
  echo " Parameters"
  echo " ----------"
  echo "              MPI version: $mpi_version"
  echo "            Intel version: $intel_mpi_version"
  if [ "$USE_CACHE" == "1" ]; then
    APPDIR=.bundle
    FDS_PUBDIR=.bundle
    SMV_PUBDIR=.bundle
  else
    APPDIR=.firebot
    FDS_PUBDIR=.firebot/
    SMV_PUBDIR=.smokebot
  fi
  echo "    fds/smv app directory: $app_home/$APPDIR/$BRANCHDIR/apps on this computer"
  pub_hostlabel="on this computer"
  if [[ "$pub_host" != "`hostname`" ]] && [[ "$pub_host" != "LOCAL" ]]; then
    pub_hostlabel="on $pub_host"
  fi
  if [ "$USE_CACHE" == "1" ]; then
    echo "    fds/smv pub directory: $fds_pub_home/$FDS_PUBDIR/$BRANCHDIR/pubs $pub_hostlabel"
  else
    echo "        fds pub directory: $fds_pub_home/$FDS_PUBDIR/$BRANCHDIR/pubs $pub_hostlabel"
    echo "        smv pub directory: $smv_pub_home/$SMV_PUBDIR/$BRANCHDIR/pubs $pub_hostlabel"
  fi
    echo "         bundle directory: $bundle_dir"
  if [ "$UPLOAD_GOOGLE" == "1" ]; then
    if [ -e $GOOGLE_DIR_ID_FILE ]; then
    echo "Google Drive directory ID: `cat $GOOGLE_DIR_ID_FILE`"
    else
    echo "***warning: Google Drive directory ID file, $GOOGLE_DIR_ID_FILE, does not exist"
    fi
  fi
    if [ "$OVERWRITE" == "1" ]; then
      echo "         overwrite bundle: yes"
    else
      echo "         overwrite bundle: no"
    fi
  echo ""
GOOGLE_DIR_ID_FILE=$HOME/.bundle/GOOGLE_DIR_ID
fi

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR
DIR=`pwd`

return_code=0
if [ "$USE_CACHE" == "" ]; then
if [ "$showparms" == "" ]; then
  error_log=/tmp/error_log.$$
  rm -f $HOME/.bundle/pubs/*
  ./copy_pubs.sh fds $fds_pub_home/.firebot/$BRANCHDIR/pubs         $pub_host $error_log || return_code=1
  ./copy_pubs.sh smv $smv_pub_home/.smokebot/$BRANCHDIR/pubs        $pub_host $error_log || return_code=1

  rm -f $HOME/.bundle/apps/*
  ./copy_apps.sh fds $app_home/.firebot/$BRANCHDIR/apps             $error_log || return_code=1
  ./copy_apps.sh smv $app_home/.firebot/$BRANCHDIR/apps             $error_log || return_code=1
 
  if [ "$return_code" == "1" ]; then
    cat $error_log
    echo ""
    echo "bundle generation aborted"
    rm $error_log
    rm -f $LOCK_FILE
    exit 1
  fi
fi
fi

# get fds and smv repo revision used to build apps

FDSREV=$FDS_REVISION
if [ "$FDS_REVISION" == "" ]; then
  if [ -e $HOME/.bundle/apps/FDS_REVISION ]; then
    FDSREV=`cat $HOME/.bundle/apps/FDS_REVISION`
  else
    FDSREV=fdstest
  fi
fi

SMVREV=$SMV_REVISION
if [ "$SMV_REVISION" == "" ]; then
  if [ -e $HOME/.bundle/apps/SMV_REVISION ]; then
    SMVREV=`cat $HOME/.bundle/apps/SMV_REVISION`
  else
    SMVREV=smvtest
  fi
fi

installer_base=${FDSREV}_${SMVREV}
installer_base_platform=${FDSREV}_${SMVREV}_${BUNDLE_PREFIX_FILE}$platform
if [ "$showparms" == "" ]; then
if [ "$OVERWRITE" == "" ]; then
  installer_file=$bundle_dir/${installer_base_platform}.sh
  if [ -e $installer_file ]; then
    echo "***warning: the installer file $installer_file exists."
    echo "             Use the -w option to overwrite it."
    rm -f $LOCK_FILE
    exit 1
  fi
fi
fi

cd $DIR
if [ "$showparms" == "" ]; then
  echo ""
  echo "building installer"
  $ECHO ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version $bundle_dir $BUNDLE_PREFIX > $OUTPUT_DIR/stage1
  if [ "$UPLOAD_GOOGLE" == "1" ]; then
    if [ -e $HOME/.bundle/$GOOGLE_DIR_ID ]; then
      echo ""
      echo "uploading installer"
      if [ "$platform" == "lnx" ]; then
        ./upload_bundle.sh $bundle_dir $installer_base_platform $BUNDLE_PREFIX $platform               > $OUTPUT_DIR/stage2
      else
        ./ssh_upload_bundle.sh         $installer_base_platform $BUNDLE_PREFIX $platform               > $OUTPUT_DIR/stage2
      fi
    else
      echo "***warning: the file $HOME/.bundle/GOOGLE_DIR_ID containing the"
      echo "            google drive upload directory ID does not exist."
      echo "            Upload to google drive aborted"
    fi
  fi
fi
if [ "$ECHO" == "" ]; then
  rm -f $bundle_dir/${installer_base_platform}.tar.gz
  rm -rf $bundle_dir/${installer_base_platform}
fi
rm -f $LOCK_FILE
exit 0
