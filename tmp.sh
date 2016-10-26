#! /bin/bash
VERSION=0.2


HELP="\n
################################################################################\n
# tmp v$VERSION                                                                 \n
#  [quick and dirty string exchange]                                            \n
#                                                                               \n
# by gariepinus <mail@gariepinus.de>                                            \n
################################################################################\n
                                                                                \n
 USAGE:                                                                         \n
    tmp [options] [command|string]                                              \n
                                                                                \n
 tmp takes one parameter which can be either a string you want to store         \n
 or a command. Without this parameter tmp prints the content of your tmp-store  \n
 and exits.                                                                     \n
                                                                                \n
 COMMANDS:                                                                      \n
    tmp <string>. store string                                                  \n
    tmp stdin.... store input from stdin instead of parameter                   \n
    tmp put...... send ~/.tmp to server                                         \n
    tmp get...... receive ~/.tmp from server                                    \n
    tmp help..... display this message                                          \n
                                                                                \n
 OPTIONS:                                                                       \n
    - p ...... print path to tmp-store and exit                                 \n
    - a ...... append to tmp store instead of overwriteting                     \n
    - H HOST.. use HOST for get/pull instead of default server                  \n
    - v ...... verbose                                                          \n
    - V ...... dispay version information and exit                              \n
    - h ...... display help message and exit                                    \n
                                                                                \n
                                                                                \n
  LICENSE:                                                                      \n
>>                                                                              \n
 > ---------------------------------------------------------------------------- \n
 > 'THE BEER-WARE LICENSE' (Revision 42):                                       \n
 > <mail@gariepinus.de> wrote this file. As long as you retain this notice you  \n
 > can do whatever you want with this stuff. If we meet some day, and you think \n
 > this stuff is worth it, you can buy me a beer in return.                     \n
 > ---------------------------------------------------------------------------- \n
 <<                                                                             \n
                                                                                \n"

### DEFAULTS ###
SERVER="spock"
VERBOSE=false
APPEND=false
STORE=""
REMOTE=""


### FUNCTIONS ###
function error {
    echo -e $1 >&2
    exit 1
}

function verbose {
    if $VERBOSE
    then
	echo -e $1
    fi
}

function findstore {
    if [ -d $HOME/tmp/ ] && [ -x $HOME/tmp/ ]
    then
	verbose "'$HOME/tmp/' accessible."
    localtmp=true
    else
	verbose "'$HOME/tmp/' NOT accessible."
	localtmp=false
    fi
    if [ -d /tmp/ ] && [ -x /tmp/ ]
    then
	verbose "'/tmp/' accessible"
	globaltmp=true
    else
	verbose "'/tmp/' NOT accessible"
	globaltmp=false
    fi    
    
    if ! $localtmp && ! $globaltmp
    then
	error "Neither '/tmp/' nor '$HOME/tmp/' accessible!"
    elif $localtmp
    then
	if [ -e $HOME/tmp/tmp-store ]
	then
	    localtmp=true
	    globaltmp=false
	elif [ -e /tmp/tmp-store-$USER ]
	then
	    localtmp=false
	    globaltmp=true
	else
	    localtmp=true
	    globaltmp=false
	fi
    else
	localtmp=false
	globaltmp=true
    fi
    
    if $localtmp
    then
	STORE=$HOME/tmp/tmp-store
    else
	STORE=/tmp/tmp-store-$USER
    fi

    if ! [ -e $STORE ]
    then
	touch $STORE
	verbose "'$STORE' created"
    fi
}

function findremote {
    REMOTE=$(ssh $SERVER tmp -p)
    verbose "Remote path: '$REMOTE'"
}


### OPTIONS ###
while getopts ":paHvVh" option ; do
    case $option in
	p)
	    findstore
	    echo $STORE
	    exit 0
	    ;;
	a)
	    APPEND=true
	    ;;
	H)
	    SERVER=$OPTARG
	    ;;
	v)
	    VERBOSE=true
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
	    echo "Try $0 -h for more information."
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    echo "Try $0 -h for more information."
	    exit 1
	    ;;
    esac
done


### EXEC ###
shift $((OPTIND-1))
args=($@)
findstore
	
# If no param was given, print content of tmp-store and exit
if [ ${#args[@]} -eq 0 ]
then
    cat $STORE
    exit 0
fi

# If more than one param present exit with error
if [ ${#args[@]} -ne 1 ]
then
    echo "Usage: tmp [options] [command|string]"
    error "Too many parameters present, try 'tmp help'"
fi

# Eval command
if [ ${args[0]} == "help" ]
then
    echo -e $HELP
    exit 0
elif [ ${args[0]} == "put" ]
then
    findremote
    scp $STORE $SERVER:$REMOTE
    exit 0
elif [ ${args[0]} == "get" ]
then
    findremote
    scp $SERVER:$REMOTE $STORE
    exit 0
elif [ ${args[0]} == "stdin" ]
then
    read input
    if $APPEND
    then
	echo $input >> $STORE
    else
	echo $input > $STORE
    fi
    exit 0
else
    # If no command present, treat param as string to store
    if $APPEND
    then
	echo ${args[0]} >> $STORE
    else
	echo ${args[0]} > $STORE
    fi
    exit 0
fi
