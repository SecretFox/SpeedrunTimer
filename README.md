# SpeedrunTimer
Secret world legends mod to help time speedruns.  
![alt text](https://raw.githubusercontent.com/SecretFox/SpeedrunTimer/master/Example.png "Example")  
(Ignore the last section time entry, it's from older version of the mod).  
	
By default this mod is configured for "In the Dusty Dark" mission, timer will appear when you approach the first torch and stops on mission completion.  
To change the mission you can use any of the chat commands below,or create your own.
`/option Speedrun_Set "30711313811"` The girl who kicked the vampires nest  
`/option Speedrun_Set "38401914411"` In the Dusty Dark  
`/option Speedrun_Set "30851751921"` Cost of Magic  
`/option Speedrun_Set "30721744411"` Sins of the Father  
`/option Speedrun_Set "34641947611"` I Walk Into Empty  
`/option Speedrun_Set "34531941011,3462,3463,3464"` Tyler Freeborn, whole chain  

**Command**  
*`/option Speedrun_Debug true` Enables debug mode, more about this later  
*`/option Speedrun_Set "123456789"` Used to set mission to run, more about this later  
*`/option Speedrun_Default true` Resets _Set command to default value(In the Dusty Dark)  
*`/option Speedrun_AutoSet false` If enabled each started mission will automatically start the timer, assuming it is already not running. Timer will stop on quest completion.  
*`/option Speedrun_Upload true` Uploads all runs to http://secretfox.pythonanywhere.com/ , Eventually ill use this data to create leaderboards, for now though im just collecting the data for later processing  
*`/option Speedrun_AutoUpload true`  Automatically uploads all new records to http://secretfox.pythonanywhere.com/ 
*`/option Speedrun_VisibleEntries 2` Amount of previos AND next entries to show on section times  
*`/option Speedrun_ResetData true` Deletes all previous runs from the preference files, this may be needed if the file starts to get too big.  
*`/option Speedrun_WarningTreshold 100` Once this many runs has been reaches warning will be printed as FIFO(FadeIn/FadeOut) and chat message. To be honest i have no idea how many runs can be saved without issues, 100 is probably perfectly fine. Increase this value if you get tired of nagging,or run ResetData command  
*`/option Speedrun_Enabled true` Can be used to turn mod on/off  
*`/option Speedrun_List true` Lists all completed runs and creates clickable links for setting them as active  
*`/option Speedrun_ListByRegion true` Same as previous,but only lists quests from current region  
*`/option Speedrun_Show X` Shows section times for completed run(same format as _Set command)  


**Additonal configuration**  
By default all runs are account wide,if you want to save them per character you will have to rename `LoginPrefs.xml` file to `CharPrefs.xml`  
By default timer will render on top of cutscenes and splashscreens, to change this you will have change this line:  
`criteria    = "Speedrun_Enabled &amp;&amp; (guimode &amp; (GUIMODEFLAGS_INPLAY | GUIMODEFLAGS_ENABLEALLGUI | GUIMODEFLAGS_CINEMATICS | GUIMODEFLAGS_SPLASHSCREEN))"`  
in `modules.xml` to:  
`criteria    = "Speedrun_Enabled &amp;&amp; (guimode &amp; (GUIMODEFLAGS_INPLAY | GUIMODEFLAGS_ENABLEALLGUI))"`  


**Debug mode**  
Once debug mode has been enabled you should see some numbers get printed on system chat channel;  
```  
Quest progress on A Ghoulish Feast "31161387411"
Tier added "31161836831"
Quest completed  3116
```

You can then use any of these values as start/end point in `Speedrun_Set` command.  
For example if you want to make "Sins of the Father" speedrun:  
* When you pick up the quest you should see `Task added "30721219611"` get printed on chat, we can use this as the starting value.
* For end point we can use quest completed value, which is always the first 4 numbers(3072) of the long number sequence, so we don't actually need to progress the quest any further.  We are also still in tier one, so by pausing the mission we can still start it from the beginning.  Sometimes it may be necessary to run the quest once before you can get a good end and start points.  
* Afte start and end values have been found you can just use `/option Speedrun_Set "30721219611,3072"` to configure the timer.
  When using quest completion as end point you can also just omit the end value, so `/option Speedrun_Set "29921711511"` would work too.  

**Install:**
Unzip to `Secret World Legends\Data\Gui\Custom\Flash` folder. You can find downloads under "Releases".  
it may be necessary to remove older versions of the mod first, as i have changed the folder/file names a bit.
