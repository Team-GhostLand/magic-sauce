#!/bin/sh
echo "===EXECUTED AT $(date)===";
echo "Will run:";
cat ./instances/*/export-my-stats.sh
sleep 5
echo "Running....";
eval "$(cat ./instances/*/export-my-stats.sh)";
sleep 3
echo "Done, waiting a minute until next run...";
sleep 60
exec "./statd.sh";
echo "IF YOU CAN SEE THIS LINE, SOMETHING WENT WRONG!";
exit 1;