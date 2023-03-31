# Important Note

These cronjobs have components that require information about your current display to display notifications correctly.

When you add them as cronjobs, I recommend you precede the command with commands as those below:

```
* * * * *	export DISPLAY=:0.0;  then_command_goes_here
```

This ensures that notifications will display, xdotool commands will function and environmental variables will work as well.
