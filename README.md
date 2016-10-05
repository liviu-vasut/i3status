# i3status.sh
alternative implementation of the i3status using pure bash. (see [i3status](https://i3wm.org/i3status/manpage.html)). This is **not** a wrapper script to add new modules to the existing i3status JSON output, but rather a standalone script.

# Description
The script reads pairs of key-values from standard input and writes the status json to standard output. Each key is a module name and each value is the text to be shown. Configuration is as simple as specifying the item and the color:
```
color "clock" "#cccccc"
color "bugsFound" "#ff0000"
```

# Features:
- colors can be configured for each item/module
- colors can be set at runtime based on the module content by adding custom functions
- multiple values can be updated but the i3 status bar is only refreshed once

# Example usages:
First check out the sample configuration file - i3statusrc.

1) use a file as input, for example /tmp/status.txt
   - in i3 config:

    ```
    set $statusfile "/tmp/status.txt"
    bar {
       status_command touch $statusfile && tail -f $statusfile 2>/dev/null | ~/bin/i3status.sh
    }
    ```
   - a cron job can be set to write the time every minute to the file read by the script like this:
   
    ```
     * * * * * /usr/bin/date "+clock \%Y-\%m-\%d \%H:\%M" > /tmp/status.txt
    ```
   - or one could just do
   
   ```
   echo -e "bugsFound\t0" > /tmp/status.txt
   ```

2) listening on a port (one could receive status updates from local processes and/or a remote service)
   - in i3 config:
   
   ```
     bar {
       status_command ncat -k --recv-only -l 3333 | ~/bin/i3status.sh
     }
   ```
   - a cron job can be set to write the time every minute to the input stream of the script like this:
   
   ```
     * * * * * /usr/bin/date "+clock \%Y-\%m-\%d \%H:\%M" | ncat localhost 3333
   ```
   - or, from a remote host:
   
   ```
     echo -e "state\tRunning" | ncat mydesktop 3333
   ```
 
# Test/Debug
You can easily test your setup by manualy running the script and typing key/value pairs separated by TAB, one pair per line.
