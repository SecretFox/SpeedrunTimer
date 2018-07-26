# SpeedrunTimer
Secret world legends mod to help time speedruns.  
![alt text](https://i.imgur.com/AeQbVol.png "Example")  
	
By default this mod is configured for "In the Dusty Dark" mission, timer will appear when you approach the first torch and stops on mission completion.  


To configure the mod for other missions you first need to enable debug with `/option Speedrun_Debug true`.  
After enabling the debug you should see some numbers get printed on system chat channel. e.g:  
`Quest progress on A Ghoulish Feast "31161387411"`  
`Task added "31161836831"`  
`Quest completed  3116`  

You can then use any of these values as start/end point in `Speedrun_Set` command.  
For example if you want to make "Cost of Magic" speedrun;  
* You could start the run on quest pickup, but cutscenes could take longer to skip on slower PC's,  luckily quest also updates when you examine the notebook, so we can use that as the starting point; "30851751921"
* For end point we can use quest completed value, which is always the first 4 numbers(3085) of the long number sequence, so we don't actually need to progress the quest any further.
  We are also still in tier one, so by pausing the mission we can still start it fresh, after configuring the timer, without having to wait for cooldown.
  Sometimes it may be necessary to run the quest once before you can get a good end and start points.
* Afte start and end values have been found you can just use `/option Speedrun_Set "30851751921,3085"` to config the timer.
  When using quest completion as end point you can also just omit the end value, so `/option Speedrun_Set "29921711511"` would work too.


To restore default settings you can use `/option Speedrun_Default true`  
Some other missions you can run:  
`/option Speedrun_Set "30711313811"` The girl who kicked the vampires nest  
`/option Speedrun_Set "38401914411"` In the Dusty Dark  
`/option Speedrun_Set "30851751921"` Cost of Magic  
`/option Speedrun_Set "30721744411"` Sins of the Father  
`/option Speedrun_Set "34641947611"` The Vanishing of Tyler Freeborn  
`/option Speedrun_Set "34641947611"` I Walk Into Empty


**Install:**
Unzip to `Secret World Legends\Data\Gui\Custom\Flash` folder. You can find downloads under "Releases".  
it may be necessary to remove older versions of the mod first,as i have changed the folder/file names a bit.