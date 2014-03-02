PATH=""

DF="/bin/df"
CUT="/usr/bin/cut"
WC="/usr/bin/wc"



# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

print_revision() {
    echo "$REVISION $AUTHOR"
}

print_usage() {
    echo "Usage: $PROGNAME -d|--dirname <path> [-w|--warning <warn>] [-c|--critical <crit>] [-f|--perfdata]"
    echo "Usage: $PROGNAME -h|--help"
    echo "Usage: $PROGNAME -V|--version"
    echo ""
    echo "<warn> and <crit> must be expressed in KB"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    echo "Directory size monitor plugin for Nagios"
    echo ""
    print_usage
    echo ""
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

# Grab the command line arguments

thresh_warn=""
thresh_crit=""
perfdata=0
exitstatus=$STATE_WARNING #default
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $STATE_OK
            ;;
        -h)
            print_help
            exit $STATE_OK
            ;;
        --version)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        -V)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        --dirname)
            dirpath=$2
            shift
            ;;
        -d)
            dirpath=$2
            shift
            ;;
        --warning)
            thresh_warn=$2
            shift
            ;;
        -w)
            thresh_warn=$2
            shift
            ;;
        --critical)
            thresh_crit=$2
            shift
            ;;
        -c)
            thresh_crit=$2
            shift
            ;;
        -f)
            perfdata=1
            ;;
        -perfdata)
            perfdata=1
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

##### Get size of specified directory

error=""
duresult=`$DF -h $dirpath | /bin/awk '{ print $4; }' | /bin/sed 's/%//g'` 2>&1 || error="Error"

if [ ! "$error" = "" ]; then
    errtext=`echo $duresult`
    echo "$error:$errtext"
    exit $STATE_UNKNOWN
fi


dirsize=`echo $duresult | /bin/awk '{ print $2; }'`
result="ok"
exitstatus=$STATE_OK

##### Compare with thresholds

if [ "$thresh_warn" != "" ]; then
    if [ $dirsize -ge $thresh_warn ]; then
        result="warning"
        exitstatus=$STATE_WARNING
    fi
fi
if [ "$thresh_crit" != "" ]; then
    if [ $dirsize -ge $thresh_crit ]; then
        result="critical"
        exitstatus=$STATE_CRITICAL
    fi
fi
if [ $perfdata -eq 1 ]; then
    result="$result|'size'=${dirsize}%;${thresh_warn};${thresh_crit}"
fi

echo "$dirsize % - $result"
exit $exitstatus
