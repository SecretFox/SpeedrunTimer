# SpeedrunTimer
![alt text](https://raw.githubusercontent.com/SecretFox/SpeedrunTimer/master/Example.png "Example")  

Mod settings can be access accessed through the clock icon on topbar.  
Icon can be moved while in GUI-Edit mode.  

**v2 Speedrun Coffeebreak edition**  
As of version 2, the mod can handle crashes and logouts, and will continue from where you left off.

**Mod Settings**  
Checkboxes  
* Debug: Prints some values on system chat channel when quests are progressed, these can be used to manually create a run with `/option Speedrun_Set` chat command
* Autoset: Automatically starts the timer whenever new quest is picked, assuming timer is already not running. 
* AutoUpload: Whenever you make a new personal record it will upload the data to https://secretfox.pythonanywhere.com/speedrun for leaderboards
* All zones: Whether to display quests from all zones or only current zone on the mission list.  

Buttons  
* Activate: Sets the selected speedrun as active, meaning the timer will start when you start that quest.
Not needed if using Autoset.
* View: Views best personal time for the selected quest
* Upload: Uploads the selected speedrun to https://secretfox.pythonanywhere.com/speedrun 
* Upload All: Uploads all quests to https://secretfox.pythonanywhere.com/speedrun 
* Delete: Deletes selected speedrun
* Split Times: Amount of previous AND next time to display on the timer
* Check for Updates: Checks if mod has any updates available

	
**Chat Commands**  
*`/option Speedrun_Set "123456789"` Used to manually set which mission to run, see Debug section
  * For multi mission runs separate values with commas `/option Speedrun_Set "123456789,1234,5678"`

**Additonal configuration**  
By default all runs are account wide, if you want to save them per character you will have to manually rename `LoginPrefs.xml` file to `CharPrefs.xml` and delete .bxml files from the folder.

**Debug mode**  
While debug mode is enabled you will see some values printed on system chat channel, e.g:
```  
Quest progress on A Ghoulish Feast "31161387411"
Tier added "31161836831"
Quest completed  3116
```

You can then use any of these values as start/end point in `Speedrun_Set` command.  
For example if you want to make "Sins of the Father" speedrun:  
* When you pick up the quest you should see `Task added "30721219611"` get printed on chat, we can use this as the starting value.
* For end point we can use quest completed number, which is always the first 4 numbers(3072) of the long number sequence. You can use any other value too though.
* After start and end values have been found you can just use `/option Speedrun_Set "30721219611,3072"` to configure the timer. **Quotes are necessary.**
  When using quest completion as end point you can also just omit the end value, so `/option Speedrun_Set "29921711511"` would work too.
* If there are more than two values middle values are used as additional missions in the run. Additional missions are optional and can be completed in any order.
  * `/option Speedrun_Set "38662090511,3867,2339,2489,3012,3001,3246,3248,3341,3262,3339,3340,3292,3267,3365,4020,3563,3585,3590,3592,3586,3584,3583,3582,3616,3617,3654,3653,3656,3658,3688,3691,3694,3701,3703,4067,4078,4094"` would be a speedrun from tutorial to end of New Dawn (it may be necessary to run this command on alt first, in order to start the timer as soon as tutorial starts)  

**Install:**
Unzip to `Secret World Legends\Data\Gui\Custom\Flash` folder. You can find downloads under "Releases".  
If you are updating the mod it might be necessary to remove old files first.
