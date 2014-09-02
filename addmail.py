#!/usr/bin/python
"""this script adds one or more new entries to an abook style addresbook file"""
import re
import sys

contacts = "~/.abook/addressbook"
version = "0.1"

hstring = """
################################################################################
# addmail """ + version + """
#   [for abook and mutt]
# 
# by gariepinus <mail@gariepinus.de>
################################################################################

 USAGE:
    addmail [-m|-h|-v] [mailaddress(es)]

 Without any options or arguments given addmail prompts for
 an e-mail address, name and nickname and than will appand that 
 infomation as a new entry to the addressbook file.

 Without any options given addmail takes each argument for an e-mail
 address and tries to build addressbook entries for each one.

 Whenever addmail prompts for an input you can quit the script by
 entering:
    q|quit|bye

 OPTIONS:
    -m|--mutt ......'muttmode'. Addmail parses stdin for a line with 
                    the keyword 'FROM:'. It will than build an
                    addressbook entry for the senders e-mail.

    -h|--help ......display usage message and exit.

    -v|--version ...return version string.

 FILES:
    """ + __file__  + """
       -- the addmail executable
    """ + contacts + """ 
       -- the abook addressbook file where addmail will store new entries


 LICENSE:
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <mail@gariepinus.de> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.
 * ----------------------------------------------------------------------------
 */
"""



def count(fn):
    """count existing contact entries in file fn"""

    num = 0
    f = open(fn)
    output = []
    for line in f:
        if "name=" in line:
            num = num + 1
    f.close()
    return num



def quitcheck(inp):
    """check if a given input was a quit signal and exit if yes"""
    if (inp.lower() == "q" or inp.lower() == "quit" or inp.lower() == "bye"):
        exit(0)



def save (fn, lines):
    """ask for affermation and append lines to file fn"""

    aff = raw_input("save " + str(lines[1:4]) +  " to " + fn  + "? [Y/n]: ")
    quitcheck(aff)

    if (aff == "" or aff.lower() == "y" or aff.lower() == "yes"):
        #if answer is positive, appand lines to file
        f = open (fn, 'a')
        f.writelines(lines)
        f.close()
        return(0)
    if (aff.lower() == "n" or aff.lower() == "no"):
        #if negative answer return without saving
        return(0)
    
    #if unspecified answer, ask again
    save(fn, lines)
    return(0)



def makeline (keyword, val):
    """build an addressbook compatible line:

    'keyword'='val'\\n"""
    return keyword + "=" + val + "\n"


    
def buildEntry(email="", defname=""):
    """get e-mail, name and nick and build addresbook entry"""
    
    if (email == ""): #if mailaddress was not given as parameter prompt for it
        email = raw_input("add e-mail: ")
        quitcheck(email)
    else:
        print "abook entry for <" + email + ">"
    
    if (email == "" or "@" not in email): #stop if no valid address was given
        print "[" + email + "] No address...\n"
        return(0)


    #if default name suggestion not given as a param, try to build one
    if (defname == ""):
        defname = email.split('@')[0] #use address without domain to build defname
        delimiter = re.compile(r'\.|_|-') #use common name delimiters to split defname
        defname = filter(None, delimiter.split(defname))
        
        if (len(defname) > 1): 
            defname = defname[0].capitalize() + " " + defname[1].capitalize()
        else:
            defname = defname[0].capitalize()

    
    name = raw_input("Realname " + "[" + defname + "]: ")
    quitcheck(name)

    if (name == ""):
        name = defname


    defnick = name.split(" ") #split first and surname to build alias
    if (len(defnick) == 1):
        defnick = defnick[0].lower()
    else:
        defnick = defnick[0][0].lower() + defnick[1].lower()

    if(len(defnick) > 10): #shorten defnick if necessary
        defnick = defnick[:9]

    alias = raw_input("abook alias [" + defnick + "]: ")
    quitcheck(alias)

    if (alias == ""):
        alias = defnick


    #use makeline to build a list with the addressbook lines for the new entry
    output = []
    output.append("[" + str(count(contacts)) + "]\n") #index number
    output.append(makeline("email", email))
    output.append(makeline("name", name))
    output.append(makeline("nick", alias))
    output.append("\n") #trailing double newline


    #appand the new entry to the addressbook
    save(contacts,output)
    return(0)



def muttmode():
    """if the first commandline parameter is '-m' or '--mutt' addmail uses muttmode.

    muttmode parses an email piped to it and tries to build an addressbook entry for the 'FROM:' address"""

    fline = ""
    email = ""
    fname = ""
    lname = ""

    for line in sys.stdin: #get the from-line from stdin
            if "From: " in line:
                fline = line
                break;
    sys.stdin.close() #close and reopen stdin to reanable promting
    sys.stdin = open('/dev/tty', 'r')

    if fline == "": #exit if no line was found
        print "No 'From:' found..."
        return(0)

    # split the line and try to find address, firstname and lastname
    fline = fline.split(" ")
    for word in fline:
        if "@" in word:
            email = word
        if word[0] == "\"":
            fname = word
        if word[len(word)-1] == "\"":
            lname = word
    
    if email == "": #exit if no mail was found
        print "No address found..."
        return(0)

    #if first- and lastname are present build name
    name = ""
    if (fname != "" and lname != ""):
        name = fname + " " + lname

    #strip decorations
    email = email.strip("\"\'<>\n\w")
    name = name.strip("\"\'<>\n")

    #build addressbook entry
    buildEntry(email,name)
    return(0)



if (len(sys.argv) == 1): #if no arguments, prompt for one address
    buildEntry("")
    exit(0)

if (sys.argv[1] == "-h" or sys.argv[1] == "--help"): #display help
    print hstring
    exit(0)

if (sys.argv[1] == "-v" or sys.argv[1] == "--version"): #display help
    exit(version)

if (sys.argv[1] == "-m" or sys.argv[1] == "--mutt"): #enter muttmode
    muttmode()
    exit(0)

for arg in sys.argv[1:]: #treat each arg as email and try building entries
    buildEntry(arg)

exit(0)
