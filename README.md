# SpeedrunTimer
Secret world legends mod to help time speedruns.   
![alt text](https://i.imgur.com/AeQbVol.png "Example")  
	
By default this mod is configured for "In the Dusty Dark" mission, timer will start when you approach the first torch and stops on mission completion.  

To configure the mod for other missions you first need to enable debug with `/option Speedrun_Debug true`.  
After enabling the debug you should see some numbers get printed on system chat channel. e.g:  
`Quest progress on A Ghoulish Feast "31161387411"`  
`Task added "31161836831"`  
`Quest completed  3116`  


You can then use any of these values as start/end point in `Speedrun_Start` and `Speedrun_Stop` commands.  
For example you can set start to `/option Speedrun_Start "29921711511"`(Mission added) and end to `/option Speedrun_Stop "2992"`(Mission completed) for running The Black House.  
If you want the run to end at quest completion you can just use 4 first numbers from the long number sequence.  
To set both values at the same time use either command with values separated by comma e.g `/option Speedrun_Start "29921711511,2992"`  

To restore default settings you can use `/option Speedrun_Default true`

Some example values:  
"307115058,3071" The girl who kicked the vampires nest  
"38401914411,3840" In the Dusty Dark  
"308512797,3085" Cost of Magic  
"30721744411,3072" Sins of Father  


**Install:**
Unzip to `Secret World Legends\Data\Gui\Custom\Flash` folder. You can find downloads under "Releases".
