#!/bin/sh
echo "===EXECUTED AT $(date)===";
echo " --  Part one, snatching stats..."
echo "Will run:";
cat ./instances/*/export-my-stats.sh
sleep 5
echo "Running....";
eval "$(cat ./instances/*/export-my-stats.sh)";
sleep 3
echo " --  Part two, snatching the server status...";
cp -u "./gl_web_statusful/status.json" "./status_export/status.json"
echo "Done, waiting a minute until next run...";
sleep 60
exec "./statd.sh";
echo "IF YOU CAN SEE THIS LINE, SOMETHING WENT WRONG!";
exit 1;