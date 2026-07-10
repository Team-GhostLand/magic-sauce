#!/bin/sh
echo "===EXECUTED AT $(date)===";
EXECUTE=$(./local-gen.py stats)
echo "Will run:";
echo "$EXECUTE";
echo "Running....";
eval "$EXECUTE";
echo "Done, waiting a minute until next run...";
sleep 60
exec "./statd.sh";
echo "IF YOU CAN SEE THIS LINE, SOMETHING WENT WRONG!";
exit 1;