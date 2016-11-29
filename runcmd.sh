#!/bin/bash
VERSION=0.1

################################################################################
# runcmd
#  [modify zonefile serials]
#
# by gariepinus <mail@gariepinus.de>
################################################################################
HELP="                                                                          \n
runcmd v$VERSION                                                                \n
  USAGE:                                                                        \n
\t    runcmd [options] <command> <message>                                      \n
                                                                                \n
...                                                                             \n
                                                                                \n
  OPTIONS                                                                       \n
\t    -c ......... deactivate color output                                      \n
\t    -e EXPECT...                                                              \n
\t    -d ......... dryrun (only print command - don't execute it)               \n
\t    -v ......... verbose                                                      \n
\t    -h ......... display this help and exit                                   \n
\t    -V ......... display version information and exit                         \n"
################################################################################
# LICENSE:
# > ----------------------------------------------------------------------------
# > 'THE BEER-WARE LICENSE' (Revision 42):
# > <mail@gariepinus.de> wrote this file. As long as you retain this notice you
# > can do whatever you want with this stuff. If we meet some day, and you think
# > this stuff is worth it, you can buy me a beer in return.
# > ----------------------------------------------------------------------------


### DEFAULTS ###
EXPECT=0

# Check VERBOSE, COLOR and DRYRUN variables and set loc_'s
if [ -v VERBOSE ]
then
    loc_VERBOSE=$VERBOSE
else
    loc_VERBOSE=false
fi
if [ -v COLOR ]
then
    loc_COLOR=$COLOR
else
    loc_COLOR=true
fi
if [ -v DRYRUN ]
then
    loc_DRY=$DRYRUN
else
    loc_DRY=false
fi


### FUNCTIONS ###
function date {
    current=$(/bin/date +"%Y-%m-%d %T")
    if $loc_COLOR
    then
	echo -en "\e[35m$current\e[0m"
    else
	echo -en "$current"
    fi
}

### OPTIONS ###
while getopts ":e:cdvVh" option ; do
    case $option in
	e)
	    EXPECT=$OPTARG
	    ;;
	c)
	    loc_COLOR=false
	    ;;
	d)
	    loc_DRY=true
	    ;;
	v)
	    loc_VERBOSE=true
	    ;;
	V)
	    echo "Version: $VERSION"
	    exit 0
	    ;;
	h)
	    echo -e $HELP
	    exit 0
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    echo "Try -h for more information."
	    exit -1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    echo "Try -h for more information."
	    exit -1
	    ;;
    esac
done


### EXEC ###
shift $((OPTIND-1))
args=($@)

# Parameters
COMMAND="$1"
MESSAGE="$2"

# Color setup
if $loc_COLOR
then
    OK="\e[32mOk\e[0m"
    FAILED="\e[31mFailed\e[0m"
    HASH="\e[34m##\e[0m"
else
    OK="Ok"
    FAILED="Failed"
    HASH="##"
fi

# Step 1: Print message
echo -en "$(date): $MESSAGE... "

# Step 2: If verbose or dryrun print command
if $loc_VERBOSE || $loc_DRY
then
    echo -en "\n"
    echo -en "$HASH "
    if $loc_COLOR
    then
	echo -e "\e[96m$COMMAND\e[0m"
    else
	echo -e "$COMMAND"
    fi
fi
if $loc_DRY
then
    exit 0
fi

# Step 3: Unless dryrun, run command
if $loc_VERBOSE
then
    $COMMAND
else
    $COMMAND > /dev/null 2>&1
fi

# Step 4: Eval return code of COMMAND and react
if [ $? -eq $EXPECT ]
then
    if $loc_VERBOSE
    then
	echo -e "$HASH [$OK]\n"
    else
	echo -e $OK
    fi
    exit 0
else
    if $loc_VERBOSE
    then
	echo -e "$HASH [$FAILED]\n"
    else
	echo -e $FAILED
    fi
    exit 1
fi


### EXIT CODES ###
#
# -1 :: Execution aborted
#  0 :: Execution sucsess
#  1 :: Excecuted command not finished with expected code
#
