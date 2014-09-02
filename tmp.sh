#! /bin/bash
args=($@)
server="minsk:.tmp"

help="\n
################################################################################\n
# tmp                                                                           \n
#  [quick and dirty string exchange]                                            \n
#                                                                               \n
# by gariepinus <mail@gariepinus.de>                                            \n
################################################################################\n
                                                                                \n
 USAGE:                                                                         \n
    tmp [command|string]                                                        \n
                                                                                \n
 Without any arguments given tmp prints the content of ~/.tmp to stdout.        \n
                                                                                \n
 tmp takes one argument which can be either a string you want to store          \n
 or a command.                                                                  \n
                                                                                \n
 COMMANDS:                                                                      \n
    tmp <string>..store string                                                  \n
    tmp add.......append to ~/.tmp                                              \n
    tmp stdin.....store piped input                                             \n
    tmp put.......send ~/.tmp to server                                         \n
    tmp get.......receive ~/.tmp from server                                    \n
    tmp help......display this message                                          \n
                                                                                \n
  FILES:                                                                        \n
    ~/.tmp -- your information gets stored here                                 \n
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

if [ ${#args[@]} -eq 0 ]
then
    cat ~/.tmp
    exit 0
fi

if [ ${#args[@]} -eq 1 ]
then
    if [ ${args[0]} == "put" ]
    then
	scp ~/.tmp $server
	exit 0
    fi
    if [ ${args[0]} == "get" ]
    then
	scp $server ~/.tmp
	cat ~/.tmp
	exit 0
    fi
    if [ ${args[0]} == "help" ]
    then
	echo -e $help
	exit 0
    fi
    if [ ${args[0]} == "add" ]
    then
	read input
	echo $input >> ~/.tmp
	cat ~/.tmp
	exit 0
    fi
    if [ ${args[0]} == "stdin" ]
    then
	read input
	echo $input > ~/.tmp
	cat ~/.tmp
	exit 0
    fi

    
    echo ${args[0]} > ~/.tmp
    cat ~/.tmp
    exit 0
fi

printf "[Error] *** Too many command line arguments\n\n"
echo -e $help
exit 1
