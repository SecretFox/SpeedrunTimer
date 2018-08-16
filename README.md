# SpeedrunTimer
Secret world legends mod to help time speedruns.  
![alt text](https://i.imgur.com/AeQbVol.png "Example")  
(Ignore the last section time entry,old pic).  
	
By default this mod is configured for "In the Dusty Dark" mission, timer will appear when you approach the first torch and stops on mission completion.  
To change the mission you can use any of the chat commands below,or create your own.
`/option Speedrun_Set "30711313811"` The girl who kicked the vampires nest  
`/option Speedrun_Set "38401914411"` In the Dusty Dark  
`/option Speedrun_Set "30851751921"` Cost of Magic  
`/option Speedrun_Set "30721744411"` Sins of the Father  
`/option Speedrun_Set "34641947611"` I Walk Into Empty  
`/option Speedrun_Set "34531941011,3453,3462,3463,3464"` Tyler Freeborn, whole chain  

**Commands and usage**   
You can use `/option Speedrun_Debug true` to enable debug mode, while in debug mode you should see some numbers get printed on system chat channel;
```  
Quest progress on A Ghoulish Feast "31161387411"
Task added "31161836831"
Quest completed  3116
```

You can then use any of these values as start/end point in `Speedrun_Set` command.  
For example if you want to make "Sins of the Father" speedrun:  
* When you pick up the quest you should see `Task added "30721219611"` get printed on chat, we can use this as the starting value.
* For end point we can use quest completed value, which is always the first 4 numbers(3072) of the long number sequence, so we don't actually need to progress the quest any further.  We are also still in tier one, so by pausing the mission we can still start it from the beginning.  Sometimes it may be necessary to run the quest once before you can get a good end and start points.  
* Afte start and end values have been found you can just use `/option Speedrun_Set "30721219611,3072"` to configure the timer.
  When using quest completion as end point you can also just omit the end value, so `/option Speedrun_Set "29921711511"` would work too.


To restore mission back to In the Dusty Dark you can use `/option Speedrun_Default true` command  

*Other commands*  
This mod has to store lots of data in order to remember all previous runs. In case user preference files become too large you can use `/option Speedrun_ResetData true` command to purge all the old runs from your preference files, it's probably not necessary though.  

You can use `/option Speedrun_VisibleEntries x` to change how many previous AND next section entries are shown on the timer window. Default value is two (5total).  

Whole mod can be turned off with `/option Speedrun_Enabled true/false` command.  

**Install:**
Unzip to `Secret World Legends\Data\Gui\Custom\Flash` folder. You can find downloads under "Releases".  
it may be necessary to remove older versions of the mod first, as i have changed the folder/file names a bit.