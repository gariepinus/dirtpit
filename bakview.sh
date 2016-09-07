#! /bin/bash
VERSION=0.1

HELP="\n
###############################################################################\n
# bakview $VERSION                                                             \n
#  [view current state of your rdiff-backups]                                  \n
#                                                                              \n
# by gariepinus <mail@gariepinus.de>                                           \n
###############################################################################\n
                                                                               \n
  USAGE:                                                                       \n
\t    bakview [options] [path]                                                 \n
                                                                               \n
Without any options given bakview uses ‘rdiff-backup -l’ on every directory    \n
found in ‘/srv/backup/’ and views a summary of the obtained information.       \n
                                                                               \n
bakview expects every directory in ‘/srv/backup/’ to represent one host and    \n
to be named after this machine.                                                \n
                                                                               \n
You can provide a path for the command to be used instead of ‘/srv/backup/’.   \n
                                                                               \n
  OPTIONS:                                                                     \n
\t    -v......... shows much more verbose information for each host            \n
\t    -l......... print a simple list of the obtained information instead of   \n
\t    ........... the fancy column view                                        \n
\t    -H HOST.... only show information for the given host                     \n
\t    -i IGNORE.. ignore every diretory inside ‘/srv/backup/’ that             \n
\t    ........... machtes IGNORE                                               \n
\t    -u......... determinine file space usage (can be very slow)              \n
\t    -h......... display this help and exit                                   \n
\t    -V......... output version information and exit                          \n
                                                                               \n
                                                                               \n
  LICENSE:                                                                     \n
 > --------------------------------------------------------------------------- \n
 > 'THE BEER-WARE LICENSE' (Revision 42):                                      \n
 > <mail@gariepinus.de> wrote this file. As long as you retain this notice you \n
 > can do whatever you want with this stuff. If we meet some day, and you think\n
 > this stuff is worth it, you can buy me a beer in return.                    \n
 > --------------------------------------------------------------------------- \n"


## DEFAULTS ##
BAKPATH=/srv/backup
VERBOSE=false
HOST=""
LIST=false
IGNORE=""
FAST=true


## PATHES ##
ECHO="/bin/echo -e"
esc=$(printf '\033')


### OPTIONS ###
while getopts ":H:li:uvVh" option ; do
    case $option in
	H)
	    HOST=$OPTARG
	    ;;
	l)
	    LIST=true
	    ;;
	i)
	    IGNORE=$OPTARG
	    ;;
	u)
	    FAST=false
	    ;;
	v)
	    VERBOSE=true
	    ;;
	V)
	    $ECHO "Version: $VERSION"
	    exit 0
	    ;;
	h)
	    $ECHO -e $HELP
	    exit 0
	    ;;
	\?)
	    $ECHO "Invalid option: -$OPTARG" >&2
	    $ECHO "Try $0 -h for more information."
	    exit 1
	    ;;
	:)
	    $ECHO "Option -$OPTARG requires an argument." >&2
	    $ECHO "Try $0 -h for more information."
	    exit 1
	    ;;
    esac
done


## EXEC ##

# Check if BAKPATH was given as parameter
shift $((OPTIND-1))
args=($@)
if [ ${#args[@]} -eq 1 ]
then
    BAKPATH=$1
elif [ ${#args[@]} -gt 1 ]
then
    $ECHO "Usage: $0 [options] [path]"  >&2
    $ECHO "Try $0 -h for more information."
    exit 1
fi
#remove trailing slash
BAKPATH=$(echo -n $BAKPATH | sed "s,/$,,")

# Check if we can access BACKPATH
if ! [ -d $BAKPATH ]
then
    $ECHO "‘$BAKPATH’ not a directory." >&2
    exit 1
fi
if ! [ -x $BAKPATH ] 
then
    $ECHO "‘$BAKPATH’ not accessible." >&2
    exit 1
fi

LINES=""
SWITCH=1
# Circle thourgh backup-dirs and gather information
for host in $(ls -p $BAKPATH | grep /); do

    # Check if directory should be ignored
    if [[ $IGNORE != "" && $host == *"$IGNORE"* ]]
    then
	continue
    fi
    # if HOST param was given: ignore all non-matching dirs
    if [[ $HOST != "" &&  $host != *"$HOST"* ]]
    then
	continue
    fi

    # For formatting only
    if $LIST
    then
	background=""
	SWITCH=0
    elif [[ $SWITCH -eq 1 ]]
    then
	SWITCH=2
	background="\e[39m"
    else
	SWITCH=1
	background="\e[40m"
    fi
    
    host_info=$(rdiff-backup -l $BAKPATH/$host > /dev/null 2>&1)
    rval=$?

    host=$(echo -n $host | sed "s,/$,,")
    if [ $rval -eq 0 ]
    then
	host_long="\e[4m\e[32m\e[1m$host\e[0m\e[21m\e[24m"
	host_short="\e[32m\e[1m$(echo $host | cut -d"." -f1)\e[39m\e[21m"
    else
	host_long="\e[4m\e[31m\e[1m$host\e[0m\e[21m\e[24m"
	host_short="\e[31m\e[1m$(echo $host | cut -d"." -f1)\e[39m\e[21m"
    fi
    
    if $VERBOSE
    then
	$ECHO "\n\e[34m## $host_long\n"
	rdiff-backup --list-increment-sizes $BAKPATH/$host | sed "s,-,${esc}[34m&${esc}[0m,g" | sed "s,(current mirror),${esc}[95m&${esc}[0m,g" | sed "s,Time,${esc}[36m&${esc}[0m,g" | sed "s,Size,${esc}[36m&${esc}[0m,g" | sed "s,Cumulative size,${esc}[36m&${esc}[0m,g"
	$ECHO -n "\n"
    else
	if ! $FAST
	then
	    size="\e[2m$(du -sh $BAKPATH/$host | cut -f1);"
	else
	    size=""
	fi
	
	if [ $rval -eq 0 ]
	then
	    host_date=$(date -d "$(rdiff-backup -l $BAKPATH/$host | grep 'Current' | sed -e 's/Current mirror: //')" +"%Y-%m-%d %R")
	    LINES="$LINES$background$host_short; \e[2m\e[4mCurrent:\e[22m\e[24m\e[36m $host_date\e[39m; $(rdiff-backup -l $BAKPATH/$host | grep increments | cut -d' ' -f2,3 | sed -e 's/://'); $size\e[0m\n"
	else
	    LINES="$LINES$background$host_short; \e[2m\e[4mCurrent:\e[22m\e[24m \e[1mNONE\e[21m;0 increments;$size\e[0m\n"
	fi
    fi
done

if $LIST
then
    $ECHO $LINES
else
    $ECHO -n "\n"
    $ECHO $LINES | column -t -s';'
    $ECHO -n "\n"
fi
