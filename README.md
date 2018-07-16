# SpeedrunTimer
Secret world legends mod to help time speedruns.   
By default it is configured for "In the Dusty Dark" mission, timer will start when you approach the first torch and stops on mission completion.  

While speedrun is in progress timer will be displayed where you would usually see the scenario timer, you can also move it by dragging it. 
Additionally elapsed time will get printed on "System" chat channel on  each quest update along with the tier description.  
You can also find these messages at ClientLog.Txt file in base install directory (search for "SpeedRun").  

Once the run has been completed final time will get printed and the timer will fade out.  
You can abort the run by Ctrl+Right clicking the timer.  
Example output```
```
Acquire a light source 3s
Light the torch at a wall brazier 3s
Explore the pyramid 30s
Solve the puzzle to open the door 33s
Explore the pyramid 76s
Cross the pit 116s
Explore the pyramid 145s
Escape the boulder 165s
Cross the bottomless pit 168s
Escape the mummies 179s
Explore the pyramid 197s
Make it past the traps 217s
Explore the pyramid 238s
Cross the bottomless pit 481s
Explore the pyramid 525s
Enable the jump pad 577s
Cross the bottomless pit 583s
Explore the pyramid 645s
Explore the labyrinth 661s
Navigate the labyrinth 911s
Investigate the strange room 936s
Finished at 936.119s
```


To configure the mod for other missions you first need to enable debug with `/option Speedrun_Debug true`.  
After enabling the debug you should see some numbers get printed on system chat channel. e.g:  
`Quest progress on A Ghoulish Feast "31161387411"`  
`Task added "31161836831"`  
`Quest completed  3116`  

You can then use any of these values as start/end point in `Speedrun_Start` and `Speedrun_Stop` commands.  
For example you can set start to `/option Speedrun_Start "29921711511"`(Mission added) and end to `/option Speedrun_End "2992"`(Mission completed) for running The Black House.  
Quotes are necessary for long number sequences.  
If you want the run to end at quest completion you can just use 4 first numbers from the long number sequence.  
To set both values at the same time use either command with values separated by cooma e.g `/option Speedrun_Start "29921711511,2992"`

To restore default settings you can use `/option Speedrun_Default true`


**Install:**
Unzip to `Secret World Legends\Data\Gui\Custom\Flash` folder. You can find downloads under "Releases".
