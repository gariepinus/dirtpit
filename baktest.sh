#!/bin/bash
VERSION="0.1"

HELP="\n
################################################################################\n
# baktest $VERSION                                                              \n
#  [create and modify a file to see if you can restore it]                      \n
#                                                                               \n
# by gariepinus <mail@gariepinus.de>                                            \n
################################################################################\n
                                                                                \n
  USAGE:                                                                        \n
\t    baktest [options] [path]                                                  \n
                                                                                \n
Without any options given baktest creates a file named ‘baktest.txt’            \n
in the current directory and modifies it three times with intervals of          \n
24 hours between each action than removes the file and exits.                   \n
                                                                                \n
  OPTIONS:                                                                      \n
\t    -p......... print testfile content to the terminal after each action      \n
\t    -v......... verbose (gets ignored when -q is used)                        \n
\t    -q......... run quiet (-p ignores this option)                            \n
\t    -i INTERVAL use INTERVAL instead of 24h as time between actions (give a   \n
\t    ........... NUMBER[SUFFIX] combination suitable for the sleep command)    \n
\t    -m MODIFIES specify how many times the testfile will get modified         \n
\t    -f FILENAME choose the name for your testfile                             \n
\t    -d......... don't remove testfile after the last modification             \n
\t    -w......... wait for a final interval after the file was removed before   \n
\t    ........... the script exits (gets ignored when -d is used)               \n
\t    -h......... display this help and exit                                    \n
\t    -V......... output version information and exit                           \n
                                                                                \n
                                                                                \n
  LICENSE:                                                                      \n
 > ---------------------------------------------------------------------------- \n
 > 'THE BEER-WARE LICENSE' (Revision 42):                                       \n
 > <mail@gariepinus.de> wrote this file. As long as you retain this notice you  \n
 > can do whatever you want with this stuff. If we meet some day, and you think \n
 > this stuff is worth it, you can buy me a beer in return.                     \n
 > ---------------------------------------------------------------------------- \n
                                                                                \n"


### Default values ###
PRINTFILE=false
VERBOSE=false
NOTQUIET=true
INTERVAL="24h"
MODIFIES=3
FILENAME="baktest.txt"
DELETE=true
FINALWAIT=false


### bin pathes ###
DATE="/bin/date +%Y-%m-%d_%T"
ECHO="/bin/echo"
CAT="/bin/cat"
RM="/bin/rm"
SLEEP="/bin/sleep"
TOUCH="/usr/bin/touch"
FILE="/usr/bin/file"
HEAD="/usr/bin/head"


### Parameters and options ###
while getopts ":pvqi:m:f:dwVh" option ; do
    case $option in
	p)
	    PRINTFILE=true
	    ;;
	v)
	    VERBOSE=true
	    ;;
	q)
	    NOTQUIET=false
	    ;;
	i)
	    INTERVAL=$OPTARG
	    ;;
	m)
	    MODIFIES=$OPTARG
	    ;;
	f)
	    FILENAME=$OPTARG
	    ;;
	d)
	    DELETE=false
	    ;;
	w)
	    FINALWAIT=true
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

### Functions ###
function msg {
    if $NOTQUIET
    then
	$ECHO -e $2 "$($DATE): $1"
    fi
}

function wait {
    if $VERBOSE
    then
	msg "sleeping for $INTERVAL..."
    fi
    $SLEEP $INTERVAL > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
	$ECHO "Invalid time interval" >&2
	exit 1
    fi
}

function view {
    if $PRINTFILE
    then
	$ECHO -en "\n"
	$CAT $FILEPATH
	$ECHO -en "\n"
    fi
}

function addline {
    if ! [ -w $FILEPATH ]
    then
	$ECHO "‘$FILEPATH’ not accessible" >&2
	exit 1
    fi
    CONTENT=$($HEAD -n -1 $FILEPATH) #remove EOF line
    $ECHO -e "$CONTENT" > $FILEPATH
    $ECHO -en "+ Modified at: $($DATE)\n## EOF ##\n" >> $FILEPATH
    msg "line added"
}


### Exec ###
shift $((OPTIND-1))
FILEPATH="$1$FILENAME"

## Check if file aready exists or create it
if [ -e $FILEPATH ]
then
    
    msg "file ‘$FILEPATH’ already exists. Overide it [y/N]: " "-n"
    read answer
    case $answer in
	y)
	    ;;
	*)
	    exit 0
	    ;;
    esac
    
    if ! [ -w $FILEPATH ]
    then
	$ECHO "‘$FILEPATH’ not accessible" >&2
	exit 1
    fi
    
else
    
    $TOUCH $FILEPATH > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
	$ECHO "‘$FILEPATH’ not accessible" >&2
	exit 1
    else
	msg "created ‘$FILEPATH’"
    fi
    
fi

# Write header to file
$ECHO -en "## BACKUP TEST FILE ## \n+ Started  at: $($DATE)\n## EOF ##\n" > $FILEPATH
view
wait

## Add lines till modifiercount reaches 0
until [ $MODIFIES -lt 1 ]; do
    addline
    let MODIFIES-=1
    view
    wait
done

## Remove file
if $DELETE
then
    msg "$($RM -v $FILEPATH)"
    if $FINALWAIT
    then
	wait
    fi
fi

## Farewell
msg "\e[32mdone\e[0m"
if $NOTQUIET
then
    $ECHO -e "
########################################
# If you are able to restore all
# different versions of the file your
# backup is propably ok.
########################################"
fi

exit 0
