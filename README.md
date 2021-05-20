# kill_for_loginnode.sh
Kills users' processes if they exceed limits

You can use this script to keep loginnode is always accessible. Users can run cpu or memory demanding programs at login node. This script kills them, but only if they exceed limits which you define.

Set crontab to start script at every minute:

```
* * * * * root /uhem-bin/kill_for_loginnode.sh
```

Note: please first check the user list at KILLREASON lines for users which will not be killed. The current list for our Centos 7 server. For other distributions, probably you should modify the list
