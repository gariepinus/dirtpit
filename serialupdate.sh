#!/bin/bash
VERSION=0.1

################################################################################
# serialupdate
#  [modify zonefile serials]
#
# by gariepinus <mail@gariepinus.de>
################################################################################
HELP="                                                      \n
serialupdate v$VERSION                                      \n
                                                            \n
  Usage: serialupdate [options] [zonefiles]                 \n
                                                            \n
Updates zonefile serials to current date (01). If a         \n
zonefiles serial is equivalent or ahead of this it's left   \n
unchanged.                                                  \n
                                                            \n
  OPTIONS:                                                  \n
\t   -i ........ increment serials by one if they are equal \n
\t   ........... or ahead instead of ignoring them.         \n
\t   -s SERIAL.. use SERIAL instead of current date (01) as \n
\t   ........... new serial.                                \n
\t   -f ........ force: overwrite all serials even if they  \n
\t   ........... are equal or ahead.                        \n
\t   -v ........ verbose                                    \n
\t   -V ........ display version information and exit.      \n
\t   -h ........ display this help message and exit.        \n
                                                            \n
  RETURN VALUES:                                            \n
\t   0 :: At least 1 serial was found and changed.          \n
\t   1 :: At least 1 serial was found, not all found        \n
\t   .... serials were changed.                             \n
\t   2 :: No serial was found.                              \n
\t   3 :: Execution aborted or unexpected results.          \n"
################################################################################
# LICENSE:
# > ----------------------------------------------------------------------------
# > 'THE BEER-WARE LICENSE' (Revision 42):
# > <mail@gariepinus.de> wrote this file. As long as you retain this notice you
# > can do whatever you want with this stuff. If we meet some day, and you think
# > this stuff is worth it, you can buy me a beer in return.
# > ----------------------------------------------------------------------------


### DEFAULTS ###
VERBOSE=false
INCREMENT=false
FORCE=false
NEWSERIAL="$(/bin/date +%Y%m%d)01"
PROCESSED=0
CHANGED=0


### FUNCTIONS ###
function error {
    echo -e $1 >&2
    exit 3
}

function verbose {
    if $VERBOSE
    then
	echo -e $1
    fi
}

function fileupdate {
    zonefile=$1
    zone=$(basename $zonefile)
    
    if ! [ -w $zonefile ] || [ -d $zonefile ]
    then
	echo "$zone: Not accessible"
    else
	serial=$(grep -ho -E '[0-9]{10}' $zonefile)

	if [ $? -ne 0 ]
	then
	    echo "$zone: No serial found"
	else
	    PROCESSED=$(($PROCESSED+1))
	    if [ $serial -ge $NEWSERIAL ] && ! $FORCE
	    then
		verbose "$zone: Current serial equivalent or ahead of new"
		if $INCREMENT
		then
		    increment=$(($serial+1))
		    fixed=$(cat $zonefile | sed "s/$serial/$increment/")
		    echo -e "$fixed" > $zonefile
		    verbose "$zone: Incremented serial"
		    CHANGED=$(($CHANGED+1))
		else
		    verbose "$zone: Not changed"
		fi
	    else
		fixed=$(cat $zonefile | sed "s/$serial/$NEWSERIAL/")
		echo -e "$fixed" > $zonefile
		verbose "$zone: Changed"
		CHANGED=$(($CHANGED+1))
	    fi
	fi
    fi
}


### OPTIONS ###
while getopts ":is:fvVh" option ; do
    case $option in
	i)
	    INCREMENT=true
	    ;;
	s)
	    NEWSERIAL=$OPTARG
	    echo $NEWSERIAL | grep -ho -E '[0-9]{10}' > /dev/null
	    if [ $? -ne 0 ]
	    then
		error "'$NEWSERIAL' is no valid serial"
	    fi
	    ;;
	v)
	    VERBOSE=true
	    ;;
	f)
	    FORCE=true
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
	    exit 3
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    echo "Try -h for more information."
	    exit 3
	    ;;
    esac
done


### EXEC ###
shift $((OPTIND-1))
args=($@)

# If no files given as params, check stdin
if [ ${#args[@]} -eq 0 ]
then
    while read input
    do
	if ! [ $input = "" ]
	then
	   fileupdate $input
	fi
    done
fi

for file in $@
do
    fileupdate $file
done

verbose "-----"
echo "Processed serials: $PROCESSED ($CHANGED changed)"


### RETURN VALUES ###
# 0 :: At least 1 serial was found and changed
# 1 :: At least 1 serial was found, not all found serials were changed
# 2 :: No serial was found
# 3 :: Execution aborted or unexpected results
if [ $PROCESSED -eq 0 ]
then
    exit 2
elif [ $PROCESSED -gt $CHANGED ]
then
    exit 1
elif [ $PROCESSED -eq $CHANGED ]
then
    exit 0
else
    error "Finished with unexpected results."
fi
