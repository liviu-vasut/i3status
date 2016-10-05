# i3status.sh
bash wrapper script for i3status’s JSON output. (see the [i3status man page](https://i3wm.org/i3status/manpage.html) - the section *"External scripts/programs with i3status"*)

# Description
wrapper script for i3status’s JSON output. The script reads pairs of key-values from
standard input and writes the status json to standard output. Each key is a module name and each value is
the text to be shown.

# Features:
- colors can be set for each item/module
- colors can be dynamicaly decided based on the text content by writing custom functions
- multiple values can be updated but the i3 status bar is only updated once

# Example usages:
1) use a file as input, for example /tmp/status.txt
   - in i3 config:

    ```
    set $statusfile "/tmp/status.txt"
    bar {
       status_command touch $statusfile && tail -f $statusfile 2>/dev/null | ~/bin/i3status.sh
    }
    ```
   - a cron job can be set to write the time to the input stream of the script like this:
   
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
   - a cron job can be set to write the time to the input stream of the script like this:
   
   ```
     * * * * * /usr/bin/date "+clock \%Y-\%m-\%d \%H:\%M" | ncat localhost 3333
   ```
   - or, from a remote host:
   
   ```
     echo -e "state\tRunning" | ncat mydesktop 3333
   ```
 
Check out the sample configuration file - i3statusrc. You can easily test your setup by running the script and typing key/value pairs separated by TAB, one pair per line.
