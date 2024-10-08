#!/bin/bash

if [ -e $HOME/.clusterbot/clusterbot_email_list.sh ]; then
  source ~/.clusterbot/clusterbot_email_list.sh
fi
EMAIL=$mailToCLUSTERBOT
Copt=
fopt=
nopt=
Nopt=
NOEMAIL=
QOPT=
qopt=
uopt=
Popt=
Uopt=
FORCE_UNLOCK=
NCASES_PER_QUEUE=20
while getopts 'CfHhm:n:MNP:q:Q:uU:' OPTION
do
case $OPTION  in
  C)
   Copt="-C"
   ;;
  f)
   fopt="-f"
   FORCE_UNLOCK=1
   ;;
  H)
   ./clusterbot_usage.sh run_clusterbot.sh $NCASES_PER_QUEUE 1 $EMAIL
   exit
   ;;
  h)
   ./clusterbot_usage.sh run_clusterbot.sh $NCASES_PER_QUEUE 1 $EMAIL
   exit
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  M)
   NOEMAIL=1
   ;;
  N)
   Nopt="-N"
   ;;
  n)
   NCASES="$OPTARG"
   re='^[0-9]+$'
   if ! [[ $NCASES =~ $re ]] ; then
     echo "***error: -n $NCASES not a number"
     exit
   fi
   NCASES_PER_QUEUE=$NCASES
   ;;
  P)
   Popt="-P $OPTARG"
   ;;
  Q)
   QOPT="-Q $OPTARG"
   ;;
  q)
   qopt="-q $OPTARG"
   ;;
  u)
   uopt="-u"
   ;;
  U)
   Uopt="-U $OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))
   
nopt="-n $NCASES_PER_QUEUE"

LOCK_FILE=$HOME/.clusterbot/lockfile
if [[ "$FORCE_UNLOCK" == "" ]] && [[ -e $LOCK_FILE ]]; then
  echo "***error: another instance of clusterbot.sh is running"
  echo "          If this is not the case, rerun using the -f option"
  exit
fi
rm -f $LOCK_FILE

CURDIR=`pwd`

BINDIR=$CURDIR/`dirname "$0"`
cd $BINDIR
BINDIR=`pwd`
cd $CURDIR

if [ ! -d $HOME/.clusterbot ]; then
  mkdir $HOME/.clusterbot
fi
OUTPUT=$HOME/.clusterbot/clusterbot.out
ERRORS=$HOME/.clusterbot/clusterbot.err
HEADER=$HOME/.clusterbot/clusterbot.hdr
LOGFILE=$HOME/.clusterbot/clusterbot.log
rm -f $OUTPUT

cd $BINDIR

not_have_git=`git describe --dirty --long |& grep fatal | wc -l`
if [ "$not_have_git" == "0" ]; then
  echo updating bot repo
  git fetch origin        &> /dev/null
  git merge origin/master &> /dev/null
fi

echo > $OUTPUT
START_TIME=`date`
./clusterbot.sh $Copt $fopt $Nopt $nopt $Popt $QOPT $qopt $uopt $Uopt | tee  $OUTPUT
STOP_TIME=`date`

nerrors=`grep '\*\*\*error'     $OUTPUT | wc -l`
nwarnings=`grep '\*\*\*warning' $OUTPUT | wc -l`

echo ""                                                          > $HEADER
echo "   start: $START_TIME"                                    >> $HEADER
echo "    stop: $STOP_TIME"                                     >> $HEADER
echo "    $nerrors errors, $nwarnings warnings"                 >> $HEADER

HAVE_ERRWARN=
rm -f $ERRORS
touch $ERRORS
if [ $nerrors -gt 0 ]; then
  echo ""                                                       >> $ERRORS
  echo "--------------------- Errors ------------------------"  >> $ERRORS
  grep '\*\*\*error' $OUTPUT                                    >> $ERRORS
  echo "-----------------------------------------------------"  >> $ERRORS
  HAVE_ERRWARN=1
fi
if [ $nwarnings -gt 0 ]; then
  echo ""                                                       >> $ERRORS
  echo "--------------------- Warnings ----------------------"  >> $ERRORS
  grep '\*\*\*warning' $OUTPUT                                  >> $ERRORS
  echo "-----------------------------------------------------"  >> $ERRORS
  HAVE_ERRWARN=1
fi
echo ""                                                         >> $ERRORS

# don't send an email if there are no errors and warnings and if the -M option was used
if [[  "$HAVE_ERRWARN" == "" ]] && [[ "$NOEMAIL" == "1" ]]; then
  EMAIL=
fi

if [ ! -e $LOGFILE ]; then
 cp $ERRORS $LOGFILE
fi 

LOGDATE=`ls -l $LOGFILE | awk '{print $6" "$7" "$8}'`

nlogdiff=`diff $LOGFILE $ERRORS | wc -l`
if [ $nlogdiff -gt 0 ]; then
 cp $ERRORS $LOGFILE
fi

ERRS=
if [ "$nerrors" == "1" ]; then
  ERRS="$nerrors Error"
fi
if [ $nerrors -gt 1 ]; then
  ERRS="$nerrors Errors"
fi

WARNS=
if [ "$nwarnings" == "1" ]; then
  WARNS="$nwarnings Warning"
fi
if [ $nwarnings -gt 1 ]; then
  WARNS="$nwarnings Warnings"
fi
COMMA=
if [[ "$WARNS" != "" ]] && [[ "$ERRS" != "" ]]; then
  COMMA=", "
fi

MESSAGE2=
if [ "$WARNS" != "" ]; then
  MESSAGE2="( $ERRS$COMMA$WARNS )"
fi
if [ "$ERRS" != "" ]; then
  MESSAGE2="( $ERRS$COMMA$WARNS )"
fi

if [ $nlogdiff -eq 0 ]; then
  echo "   $CB_HOSTS status since $LOGDATE: $ERRS$COMMA$WARNS"
else
  echo "   $CB_HOSTS status has changed: $ERRS$COMMA$WARNS"
fi
echo ""
cat $HEADER $ERRORS 
if [ "$EMAIL" != "" ]; then
  MESSAGE=
  if [ $nerrors -gt 0 ]; then
    MESSAGE="Clusterbot failure on "
    if [ $nwarnings -gt 0 ]; then
    MESSAGE="Clusterbot failure with warnings on "
    fi
  else
    MESSAGE="Clusterbot success on "
    if [ $nwarnings -gt 0 ]; then
      MESSAGE="Clusterbot success with warnings on "
    fi
  fi
  echo emailing results to $EMAIL
  
  cat $HEADER $ERRORS $OUTPUT | mail -s "$MESSAGE on $CB_HOSTS $MESSAGE2 " $EMAIL
fi

cd $CURDIR
