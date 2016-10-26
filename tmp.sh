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
\t    tmp [options] [command|string]                                            \n
                                                                                \n
 tmp takes one parameter which can be either a string you want to store         \n
 or a command. Without this parameter tmp prints the content of your tmp-store  \n
 and exits.                                                                     \n
                                                                                \n
 COMMANDS:                                                                      \n
\t    tmp <STRING>. store STRING                                                \n
\t    tmp stdin.... store input from stdin instead of parameter                 \n
\t    tmp put...... send tmp-store to server                                    \n
\t    tmp get...... receive tmp-store from server                               \n
\t    tmp help..... display this message                                        \n
                                                                                \n
 OPTIONS:                                                                       \n
\t    -p ...... print content of tmp-store after command finished               \n
\t    -P ...... print path to tmp-store and exit                                \n
\t    -a ...... append to tmp store instead of overwriting                      \n
\t    -H HOST.. use HOST for get/pull instead of default server                 \n
\t    -v ...... verbose                                                         \n
\t    -V ...... dispay version information and exit                             \n
\t    -h ...... display help message and exit                                   \n
                                                                                \n
 CLIPBOARD OPTIONS:                                                             \n
\t    -c ...... copy content of tmp-store to clipboard and exit                 \n
\t    -C ...... copy content of clipboard to tmp-store and exit                 \n
                                                                                \n
 xclip must be installed or these options will fail!                            \n
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
TMPTOCLIP=false
CLIPTOTMP=false
PRINTCONT=false


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
    REMOTE=$(ssh $SERVER tmp -P)
    verbose "Remote path: '$REMOTE'"
}

function fin {
    if $PRINTCONT
    then
	tmp
    fi
    exit 0
}


### OPTIONS ###
while getopts ":cCpPaHvVh" option ; do
    case $option in
	c)
	    TMPTOCLIP=true
	    ;;
	C)
	    CLIPTOTMP=true
	    ;;
	p)
	    PRINTCONT=true
	    ;;
	P)
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

# Clipboard operations
if $CLIPTOTMP
then
    if $APPEND
    then
	xclip -o | tmp -a stdin
	echo "Appended clipboad content to tmp-store"
    else
	xclip -o | tmp stdin
	echo "Wrote clipboad content to tmp-store"
    fi
    fin
fi
if $TMPTOCLIP
then
    echo -n "$(tmp)" | xclip -i
    echo "Copied tmp-store to clipboard"
    fin
fi

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
    fin
elif [ ${args[0]} == "get" ]
then
    findremote
    scp $SERVER:$REMOTE $STORE
    fin
elif [ ${args[0]} == "stdin" ]
then
    read input
    if $APPEND
    then
	echo $input >> $STORE
    else
	echo $input > $STORE
    fi
    fin
else
    # If no command present, treat param as string to store
    if $APPEND
    then
	echo ${args[0]} >> $STORE
    else
	echo ${args[0]} > $STORE
    fi
    fin
fi
