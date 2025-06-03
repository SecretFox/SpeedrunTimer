import GUI.fox.aswing.ASWingUtils;
import GUI.fox.aswing.TswLookAndFeel;
import GUI.fox.aswing.UIManager;
import com.GameInterface.AccountManagement;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.Input;
import com.GameInterface.LogBase;
import com.GameInterface.Quest;
import com.GameInterface.QuestsBase;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.fox.SpeedrunTimer.Icon;
import com.fox.SpeedrunTimer.Settings;
import com.fox.SpeedrunTimer.Timer;
import com.fox.SpeedrunTimer.Uploader;
import flash.geom.Point;
import mx.utils.Delegate;

class com.fox.SpeedrunTimer.Mod
{
	private var m_swfroot:MovieClip;
	static var Instance:Mod;

	static var DValDebug:DistributedValue;
	static var DValSet:DistributedValue;
	static var DValVisibleEntries:DistributedValue;
	static var DValAutoSet:DistributedValue;
	static var DValAutoUpload:DistributedValue;
	static var DValAllZones:DistributedValue;
	static var DValSettingsVisible:DistributedValue;
	static var DValIgnoreSides:DistributedValue;
	static var RunArchive:DistributedValue;
	static var DValSave:DistributedValue;
	static var DValLog:DistributedValue;

	private var m_Timer:Timer;
	private var m_settingsRoot:MovieClip;
	private var m_settings:Settings;
	private var m_Icon:Icon;

	public var m_config:Archive;
	private var m_startTime:Number;
	private var m_startValue:String;
	private var m_otherQuests:Array;
	private var m_endValue:String;
	private var m_currentRun:Array;

	private var m_uploader:Uploader;
	private var m_taskFailed:Number = 0;
	private var m_previousTaskID:Number;
	private var logInterval:Number;
	private var heartbeatInterval:Number;

	// Time when player entered cutscene
	private var m_cutsceneStart:Number;
	// Time when player entered loading screen
	private var m_loadScreenStart:Number;

	static var CHALLENGES:Array = [3995, 3996, 3997, 3998, 3999, 3978, 3979, 3980, 3981, 3982];
	static var BLACKLISTED:Array = [3451, 4131, 4042, 4043, 4044]; //StoneHenge,NYR

	// Rogue Agent and Into Darkness have different quest and goalID's for different factions
	// This array converts between them so that any of the ID's will work for starting the speedrun
	// Quests will also be stored with illuminati ID
	static var IDCONVERT:Array = [
									 ["32751845911,3275","32731845711,3273","32741845811,3274"],
									 ["32681847011,3268","32641897011,3264","30951896911,3095"]
								 ];

	public static function main(swfRoot:MovieClip)
	{
		Instance = new Mod(swfRoot);
		swfRoot.onLoad = function() {Mod.Instance.Load()};
		swfRoot.onUnload = function() {Mod.Instance.Unload()};
		swfRoot.OnModuleActivated = function(config:Archive) { Mod.Instance.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return Mod.Instance.SaveConfig(); };
	}

	public function Mod(root)
	{
		m_swfroot = root;
		DValSet = DistributedValue.Create("Speedrun_Set");
		DValDebug = DistributedValue.Create("Speedrun_Debug");
		DValVisibleEntries = DistributedValue.Create("Speedrun_VisibleEntries");
		DValAllZones = DistributedValue.Create("Speedrun_AllZones");

		DValAutoSet = DistributedValue.Create("Speedrun_AutoSet");
		DValAutoUpload = DistributedValue.Create("Speedrun_AutoUpload");
		RunArchive = DistributedValue.Create("Archive_Speedrun");
		DValSettingsVisible = DistributedValue.Create("Speedrun_Settings");
		DValIgnoreSides = DistributedValue.Create("Speedrun_IgnoreSides");
		DValSave = DistributedValue.Create("Speedrun_Save");
		DValLog = DistributedValue.Create("Speedrun_LogProgress");
	}

	public function Load()
	{
		QuestsBase.SignalTaskAdded.Connect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Connect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Connect(SlotQuestCompleted, this);
		QuestsBase.SignalMissionRemoved.Connect(RemoveMission, this);
		QuestsBase.SignalTierFailed.Connect(TaskFailed, this);

		DValSet.SignalChanged.Connect(SlotSetChanged, this);
		DValVisibleEntries.SignalChanged.Connect(SetScroll, this);
		DValSettingsVisible.SignalChanged.Connect(DrawSettings, this);
		DValSave.SignalChanged.Connect(SaveProgress, this);
		DValLog.SignalChanged.Connect(SlotLog, this);

		var val = RunArchive.GetValue();
		if (!val) RunArchive.SetValue(new Archive());

		// used to substract time spent on cutscenes
		// alternative signals: UtilsBase.SignalSplashScreenActivated, GlobalSignal.SignalFadeScreen and  OnModuleActivated
		Camera.SignalCinematicActivated.Connect(CinematicActivated, this);
		// used to substract time spent on loading screens
		AccountManagement.GetInstance().SignalLoginStateChanged.Connect(LoginStateChanged, this);

		m_settingsRoot.removeMovieClip();
		m_settingsRoot = m_swfroot.createEmptyMovieClip("m_settingsRoot", m_swfroot.getNextHighestDepth());
		ASWingUtils.setRootMovieClip(m_settingsRoot);
		var laf:TswLookAndFeel = new TswLookAndFeel();
		UIManager.setLookAndFeel(laf);
		m_Icon = new Icon(m_swfroot);
		m_Icon.SignalMoved.Connect(SignalIconMoved, this);
		Input.RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Debug_PosToClipboard, "com.fox.SpeedrunTimer.Mod.Instance.PostLog", _global.Enums.Hotkey.eHotkeyDown);
	}

	public function Unload()
	{
		QuestsBase.SignalTaskAdded.Disconnect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Disconnect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Disconnect(SlotQuestCompleted, this);
		QuestsBase.SignalMissionRemoved.Disconnect(RemoveMission, this);
		QuestsBase.SignalTierFailed.Disconnect(TaskFailed, this);

		DValSet.SignalChanged.Disconnect(SlotSetChanged, this);
		DValDebug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		DValVisibleEntries.SignalChanged.Disconnect(SetScroll, this);
		DValSettingsVisible.SignalChanged.Disconnect(DrawSettings, this);
		DValSave.SignalChanged.Disconnect(SaveProgress, this);
		DValLog.SignalChanged.Disconnect(SlotLog, this);
		//GroupFinder.SignalClientStartedGroupFinderActivity.Disconnect(SlotJoinedGroupFinderBuffer, this);

		Camera.SignalCinematicActivated.Disconnect(CinematicActivated, this);
		AccountManagement.GetInstance().SignalLoginStateChanged.Disconnect(LoginStateChanged, this);

		m_uploader.TimedOut.Disconnect(TimedOut, this);
		m_uploader.Uploaded.Disconnect(UploaderFeedback, this);
		m_uploader = undefined;
		m_Icon.SignalMoved.Disconnect(SignalIconMoved, this);
		m_Icon.Unload();
		m_Icon = undefined;
		Input.RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Debug_PosToClipboard, "", _global.Enums.Hotkey.eHotkeyDown);
	}

	public function PostLog()
	{
		DValSave.SetValue(true);
	}

	public function SlotLog(dv:DistributedValue)
	{
		clearInterval(logInterval);
		if ( dv.GetValue() && m_Timer)
		{
			logInterval = setInterval(Delegate.create(this, LogProgress),2000);
		}
	}

	public function SignalIconMoved(pos:Point)
	{
		m_config.ReplaceEntry("iconPos", pos);
	}

	public function LoadConfig(config:Archive)
	{
		if ( !m_config )
		{
			m_config = config;

			if (!m_config.FindEntry("defaultsLoaded"))
			{
				// GUI defaults
				m_config.AddEntry("timerPos", new Point(
					DistributedValueBase.GetDValue("ScryTimerX"),
					DistributedValueBase.GetDValue("ScryTimerY")
				));
				m_config.AddEntry("iconPos", new Point(200, 50));

				// Some default suggestions for speedruns
				var archive = new Archive();
				var defaultRuns:Array = [
											"36052006511||3605",
											"38402084211||3840",
											"30851751811||3085",
											"30991760011||3099",
											"30921755111||3092",
											"30951896911||3095",
											"30721744411||3072",
											"34201926111||3420",
											"32741845811||3274"
										];
				for (var i in defaultRuns)
				{
					archive.AddEntry(defaultRuns[i],"Finished_99999999");
				}
				RunArchive.SetValue(archive);

				m_config.ReplaceEntry("defaultsLoaded", true);
			}

			m_startTime = Number(m_config.FindEntry("m_startTime"));
			m_startValue = m_config.FindEntry("Start", "38401914411");
			m_endValue = m_config.FindEntry("End", "3840");
			m_currentRun = m_config.FindEntryArray("m_currentRun") || new Array();
			m_otherQuests = m_config.FindEntryArray("m_otherQuests") || new Array();

			m_Icon.Activate(m_config.FindEntry("iconPos"));
			if (m_startTime && !m_Timer)
			{
				StartTimer();
				for (var i:Number = 0; i < m_currentRun.length; i++ )
				{
					var Entry = m_currentRun[i].split("_");
					m_Timer.SetTierTime(Entry[0], Entry[1]);
				}
			}
			DrawSettings();
		}
		if (m_Timer)
		{
			var found = false;
			var ActiveQuests = QuestsBase.GetAllActiveQuests();
			for (var i in ActiveQuests)
			{
				var m_Quest:Quest = ActiveQuests[i];
				if (InRun(m_Quest.m_ID))
				{
					found = true;
					m_Timer.SetTitle(string(m_Quest.m_ID));
					break
				}
			}
			if (!found)
			{
				SlotQuestCompleted(Number(m_startValue.slice(0, 4)));
			}
		}
		return;
	}

	public function SaveConfig()
	{
		m_config.DeleteEntry("m_currentRun");
		for (var i:Number = 0; i < m_currentRun.length; i++ )
		{
			m_config.AddEntry("m_currentRun", m_currentRun[i]);
		}
		return m_config
	}

	private function ManualSave()
	{
		var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("SpeedrunTimer");
		m_config.DeleteEntry("m_currentRun");
		for (var i:Number = 0; i < m_currentRun.length; i++ )
		{
			m_config.AddEntry("m_currentRun", m_currentRun[i]);
		}
		mod.StoreConfig(m_config);
	}

//Settings
	private function DrawSettings()
	{
		if (DValSettingsVisible.GetValue())
		{
			if (m_settings) m_settings.dispose();
			m_settings = new Settings(this, m_config.FindEntry("SettingsPos", new Point(100,100)));
			m_settings.SetListData(GetRunsAsList(DValAllZones.GetValue()));
		}
		else
		{
			if (m_settings)
			{
				m_config.ReplaceEntry("SettingsPos", m_settings.getPos());
				m_settings.dispose();
				m_settings = undefined;
			}
		}
	}

	public function DeleteKey(val:String)
	{
		var conf:Archive = RunArchive.GetValue();
		conf.DeleteEntry(val);
		RunArchive.SetValue(conf);
	}

	private function SlotSetChanged(dv:DistributedValue)
	{
		var val = dv.GetValue();
		if (val)
		{
			m_otherQuests = new Array();
			var values:Array = val.split(",");
			if (values.length == 1)
			{
				m_startValue = values[0];
				m_endValue = m_startValue.slice(0, 4);
			}
			else if (values.length == 2)
			{
				m_startValue = values[0];
				m_endValue = values[1];
			}
			else if (values.length > 2)
			{
				m_startValue = string(values.shift());
				m_endValue = string(values.pop());
				m_otherQuests = values;
			}
			var FactionTest = m_startValue + "," + m_endValue;
			for (var i = 0; i < IDCONVERT.length; i++)
			{
				for (var y = 0; y < IDCONVERT[i].length; y++)
				{
					if (IDCONVERT[i][y] == FactionTest)
					{
						var m_Player:Character = Character.GetClientCharacter();
						var m_Faction =  m_Player.GetStat(_global.Enums.Stat.e_PlayerFaction);
						m_startValue = IDCONVERT[i][m_Faction-1].split(",")[0];
						m_endValue = IDCONVERT[i][m_Faction-1].split(",")[1];
					}
				}
			}
			m_config.ReplaceEntry("Start", m_startValue);
			m_config.ReplaceEntry("End", m_endValue);
			m_config.DeleteEntry("m_otherQuests");
			for (var i:Number = 0; i < m_otherQuests.length; i++ )
			{
				m_config.AddEntry("m_otherQuests", m_otherQuests[i]);
			}
			Feedback(QuestsBase.GetQuest(Number(m_startValue.slice(0, 4))).m_MissionName + " set as active")
			dv.SetValue(false);
		}
	}
	private function SetScroll(dv:DistributedValue)
	{
		if (m_Timer)
		{
			if (m_Timer.m_entries[m_Timer.m_currentIndex - 1]) m_Timer.SetScroll(m_Timer.m_currentIndex - 1);
			else m_Timer.SetScroll(m_Timer.m_currentIndex);
		}
	}
	public function UploadAll()
	{
		if (!m_uploader)
		{
			m_uploader = Uploader.create();
			var m_Player:Character = Character.GetClientCharacter();
			m_uploader.PlayerID = m_Player.GetID().GetInstance();
			m_uploader.PlayerName = m_Player.GetName();
			m_uploader.PlayerFaction = m_Player.GetStat(_global.Enums.Stat.e_PlayerFaction);
			m_uploader.TimedOut.Connect(TimedOut, this);
			m_uploader.Uploaded.Connect(UploaderFeedback, this);
			m_uploader.StartedUpload.Connect(StartedUpload, this);
		}
		m_uploader.UploadQueue = new Array();
		var runs:Archive = RunArchive.GetValue();
		for (var i in runs["m_Dictionary"])
		{
			var entry = runs.FindEntry(i);
			if (entry == "Finished_99999999") continue;
			m_uploader.UploadQueue.push([i, entry]);
		}
		m_uploader.StartUpload();
	}
	private function StartedUpload(val)
	{
		var name = NameFromKey(val);
		if (m_settings) m_settings.__SetText("Uploading "+name);
	}
	public function UploadByKey(key, name)
	{
		var runs:Archive = RunArchive.GetValue();
		var entry = runs.FindEntry(key);
		if (entry == "Finished_99999999") return;
		if (entry)
		{
			if (name)
			{
				if (m_settings) m_settings.__SetText("Uploading " + name);
			}
			if (!m_uploader)
			{
				m_uploader = Uploader.create();
				var m_Player:Character = Character.GetClientCharacter();
				m_uploader.PlayerID = m_Player.GetID().GetInstance();
				m_uploader.PlayerName = m_Player.GetName();
				m_uploader.PlayerFaction = m_Player.GetStat(_global.Enums.Stat.e_PlayerFaction);
				m_uploader.TimedOut.Connect(TimedOut, this);
				m_uploader.Uploaded.Connect(UploaderFeedback, this);
			}
			m_uploader.UploadQueue = new Array();
			m_uploader.UploadQueue.push([key, entry])
			m_uploader.StartUpload();
		}
	}

	private function UploaderFeedback(feed:String)
	{
		if (feed.indexOf("Feed||") == 0)
		{
			Feedback(feed.split("Feed||")[1], true);
		}
		else if (m_settings) m_settings.__SetText(feed);
		else Feedback(feed, true);
	}

	private function TimedOut()
	{
		m_uploader = undefined;
		com.GameInterface.Chat.SignalShowFIFOMessage.Emit("Upload failed(Timed out)");
	}

	public function ShowRun(val)
	{
		if (m_Timer) RemoveTimer();
		var arc:Archive = RunArchive.GetValue();
		var entry = arc.FindEntry(val);
		if (entry != "Finished_99999999")
		{
			m_Timer = new Timer(m_swfroot, m_config.FindEntry("timerPos"));
			m_Timer.CreateTimer();
			m_Timer.SignalClear.Connect(RemoveTimer, this);
			var data:Array = entry.split("||");
			m_Timer.SetArchieve(data);
			m_Timer.SetTitle(val);
			m_Timer.StopTimer();
			m_Timer.DisplayFinalTime(data.pop().split("_")[1]);
		}
	}

	private function NameFromKey(key)
	{
		var runArray:Array = key.split("|");
		var Name = QuestsBase.GetQuest(Number(runArray[0].slice(0, 4))).m_MissionName;
		if (runArray[1] && runArray[2].slice(0, 4) == runArray[0].slice(0, 4)) Name += " (multi)";
		if (runArray[2].slice(0, 4) != runArray[0].slice(0, 4)) Name += " -> " + QuestsBase.GetQuest(Number(runArray[2].slice(0, 4))).m_MissionName;
		if (runArray[2].length > 4) Name += " (partial)";
		return Name
	}

	public function GetRunsAsList(all:Boolean)
	{
		var runs:Archive = RunArchive.GetValue();
		var runList:Array = new Array();
		var RegionQuests;
		if (!all)
		{
			var currentZone:String = LDBFormat.LDBGetText("Playfieldnames", Character.GetClientCharacter().GetPlayfieldID());
			RegionQuests = QuestsBase.GetAllCompletedQuestsByRegion()[currentZone];
		}
		for (var key in runs["m_Dictionary"])
		{
			if (!all)
			{
				var found:Boolean = false;;
				for (var y in RegionQuests)
				{
					if (RegionQuests[y].m_ID == key.slice(0, 4))
					{
						found = true;
					}
				}
				if (!found) continue;
			}
			var Name = NameFromKey(key);
			runList.push({Name:Name, Key:key})
		}
		runList.sortOn("Name");
		//overwrite missions with the same name
		var runObject:Object = new Object();
		for (var i = 0; i < runList.length; i++)
		{
			runObject[runList[i]["Name"]] = runList[i]["Key"];
		}
		return runObject
	}

	private function IgnoredQuest(QuestID:Number)
	{
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, false, true);
		if ((m_quest.m_MissionType == _global.Enums.MainQuestType.e_Item && DValIgnoreSides.GetValue()) ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_Item && m_quest.m_MissionIsNightmare ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_MetaChallenge ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_Scenario ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_AreaMission ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_Group ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_Raid ||
				m_quest.m_MissionType == _global.Enums.MainQuestType.e_PvP
		   ) return true;
		for (var i in CHALLENGES)
		{
			if (QuestID == CHALLENGES[i]) return true;
		}
		for (var i in BLACKLISTED)
		{
			if (QuestID == BLACKLISTED[i]) return true;
		}
		return false;
	}

	private function InRun(QuestID:Number)
	{
		if (m_startValue.indexOf(string(QuestID)) >= 0  || m_endValue.indexOf(string(QuestID)) >= 0) return true
					for (var i in m_otherQuests)
			{
				var entry = m_otherQuests[i];
				var m_QuestID = entry.slice(0, 4);
				if (Number(m_QuestID) == QuestID)
				{
					return true
				}
			}
		return false
	}

	//Replaces RunArchive entry if new time is faster
	private function CheckBestRun()
	{
		var arch:Archive = RunArchive.GetValue();
		var runArray:Array = arch.FindEntry(m_startValue +"|" + m_otherQuests.join(",") + "|" +m_endValue).split("||");
		var replace;
		var newEntry:Array = m_currentRun[m_currentRun.length-1].split("_");
		var LastEntry:Array;
		for (var i in runArray)
		{
			var Entry = runArray[i].split("_");
			if (!LastEntry || Number(Entry[1]) > Number(LastEntry[1]))
			{
				LastEntry = Entry;
			}
		}
		if (Number(newEntry[1]) <= Number(LastEntry[1]))
		{
			replace = true;
		}
		if (replace || !LastEntry || !newEntry)
		{
			arch.ReplaceEntry(m_startValue + "|" + m_otherQuests.join(",") + "|" + m_endValue, m_currentRun.join("||"));
			RunArchive.SetValue(arch);
			if (DValAutoUpload.GetValue())
			{
				UploadByKey(m_startValue + "|" + m_otherQuests.join(",") + "|" + m_endValue, m_currentRun.join("||"));
			}
		}
	}

	private function RemoveTimer()
	{
		m_currentRun = new Array();
		m_taskFailed = 0;
		m_startTime = undefined;
		clearInterval(logInterval);
		m_config.DeleteEntry("m_startTime");
		if (m_Timer)
		{
			m_config.ReplaceEntry("TimerPos", m_Timer.GetTimerPos());
			m_Timer.ClearTimer();
			m_Timer.SignalClear.Disconnect(RemoveTimer, this);
			m_Timer = undefined;
		}
		ManualSave();
	}

	private function StartTimer()
	{
		var arch:Archive = RunArchive.GetValue();
		if (m_Timer)
		{
			m_Timer.ClearTimer();
			m_Timer.SignalClear.Disconnect(RemoveTimer, this);
			m_Timer = undefined;
		}
		if ( DValLog.GetValue)
		{
			clearInterval(logInterval);
			logInterval = setInterval(Delegate.create(this, LogProgress),2000);
		}
		m_taskFailed = 0;
		m_Timer = new Timer(m_swfroot, m_config.FindEntry("timerPos"));
		m_Timer.SetTitle(m_startValue);
		m_Timer.CreateTimer();
		m_Timer.SignalClear.Connect(RemoveTimer, this);
		m_Timer.SetStartTime(m_startTime);
		m_Timer.SetArchieve(arch.FindEntry(m_startValue +"|" + m_otherQuests.join(",") + "|" + m_endValue).split("||"));
		m_Timer.SetTitle(m_startValue);
		ManualSave();
	}

	public function pad(n:Number):String
	{
		return (n < 10 ? "0" : "") + n;
	}

	public function GetLocalTime(timestamp)
	{
		var now:Date = new Date(timestamp);
		var hours:Number = now.getHours();
		var minutes:Number = now.getMinutes();
		var seconds:Number = now.getSeconds();
		return pad(hours) + ":" + pad(minutes) + ":" + pad(seconds);
	}

	public function RebaseTimer(diff)
	{
		Feedback("Adjusting timer by " + Math.floor(diff / 1000) + "seconds");
		m_startTime += diff;
		if ( m_Timer ) m_Timer.SetStartTime(m_startTime);
		m_config.ReplaceEntry("m_startTime", string(m_startTime));
	}

	private function GenerateRunKey(value:Number, username:String):String
	{
		return value + "_" + SimpleHash(value + username);
	}

	private function SimpleHash(str:String):String
	{
		var hash:Number = 0;
		for (var i:Number = 0; i < str.length; i++)
		{
			hash = ((hash << 5) - hash) + str.charCodeAt(i);
			hash &= 0xFFFFFFFF;
		}
		return hash.toString(16);
	}

	private function ValidateRunKey(input:String, username:String):Number
	{
		var parts:Array = input.split("_");
		if (parts.length != 2) return null;

		var value:Number = Number(parts[0]);
		var hash:String = parts[1];

		if (SimpleHash(value + username) == hash)
		{
			return value;
		}
		return null;
	}

	private function StringifyRun()
	{
		var val = "";
		for ( var i in m_Timer.m_entries)
		{
			val += String(m_Timer.m_entries[i].Goal.text).substr(0,2);
		}
		return val
	}

	public function LogProgress( val )
	{
		var duration = (new Date()).valueOf() - m_startTime;
		var key = GenerateRunKey(duration, Character.GetClientCharacter().GetName() + StringifyRun());
		LogBase.Error("Speedrun", val ? key + val : key);
	}

	public function SaveProgress(dv:DistributedValue)
	{
		var value = dv.GetValue();
		if (!value) return;

		if ( m_Timer )
		{
			if ( value == true || value == 1)
			{
				var duration = (new Date()).valueOf() - m_startTime;
				var key = GenerateRunKey(duration, Character.GetClientCharacter().GetName() + StringifyRun());
				Feedback("<Font color=\"gold\">Use <Font color=\"red\">/option Speedrun_Save \"" + key + "\"</font>    to restore timer</font>", true);
				ManualSave();
			}
			else
			{
				var validated = ValidateRunKey(value, Character.GetClientCharacter().GetName() + StringifyRun());
				if (validated)
				{
					var current = (new Date()).valueOf();
					m_startTime = current - validated;
					m_Timer.SetStartTime(m_startTime);
					m_config.ReplaceEntry("m_startTime", string(m_startTime));
					ManualSave();
				}
				else
				{
					Feedback("<Font color=\"red\">Failed to restore timer:\n -Character must be the same\n -The time must be unchanged\n -Quest progress must be the same</font>", true);
				}
			}
		}
		dv.SetValue(false);
	}

	// 13 = local teleport
	// 12 = inPlay
	// 14 = deep teleport
	// 9 = waiting to send in play
	// 10 = Waiting to receive in play
	// times how long player spends in loading screen
	private function LoginStateChanged(state)
	{
		if (!m_Timer.Running()) return;
		switch (state)
		{
			case _global.Enums.LoginState.e_LoginStateDeepTeleport:
			case _global.Enums.LoginState.e_LoginStateLocalTeleport:
				m_loadScreenStart = (new Date()).valueOf();
				m_Timer.PauseTimer();
				Feedback("Pausing timer due to teleport")
				break
			case _global.Enums.LoginState.e_LoginStateInPlay:
				if (m_loadScreenStart)
				{
					var diff = (new Date()).valueOf() - m_loadScreenStart;
					m_loadScreenStart = undefined;
					Feedback("Resuming timer")
					RebaseTimer(diff);
					m_Timer.SetStartTime(m_startTime);
					m_Timer.ResumeTimer();
					if (!m_Timer.m_currentIndex) m_Timer.SetTitle(m_startValue);
				}
				break
		}
	}

	// states 1/0
	// times how long cutscene takes
	private function CinematicActivated(state)
	{
		if (!m_Timer.Running()) return;
		if (state)
		{
			Feedback("Pausing timer due to cutscene")
			var date:Date = new Date();
			m_cutsceneStart = date.valueOf();
			m_Timer.PauseTimer();
		}
		else
		{
			if (m_cutsceneStart)
			{
				var date:Date = new Date();
				var diff = date.valueOf() - m_cutsceneStart;
				m_cutsceneStart = undefined;
				Feedback("Resuming timer due")
				RebaseTimer(diff);
				m_Timer.SetStartTime(m_startTime);
				m_Timer.ResumeTimer();
				if (!m_Timer.m_currentIndex) m_Timer.SetTitle(m_startValue);
			}
		}
	}

	private function FinishRun(Elapsed)
	{
		m_Timer.DisplayFinalTime(Elapsed);
		m_Timer.StopTimer();
		CheckBestRun();
		ManualSave();
		clearInterval(logInterval);
		m_currentRun = new Array();
		m_startTime = undefined;
		m_config.DeleteEntry("m_startTime");
		if ( m_settings ) m_settings.refreshRuns();
	}

	private function updateSplitTime(key:String, override)
	{
		var Elapsed;
		if (!override)
		{
			var current:Date = new Date();
			Elapsed = current.valueOf() - m_startTime;
		}
		else
		{
			Elapsed = override;
		}
		m_currentRun.push(key + "_" + Elapsed);
		m_Timer.SetTierTime(key, Elapsed);
		LogProgress( " ( " + m_Timer.m_entries[m_Timer.m_entries.length-1].Goal.text + " ) ");
		ManualSave();
	}
	//Feedback

	private function Feedback(str, override)
	{
		if (override || DValDebug.GetValue()) com.GameInterface.UtilsBase.PrintChatText(string(str));
	}
	private function PrintCurrentSettings(dv:DistributedValue)
	{
		Feedback("Current settings\n" + "Start " + m_startValue + "\n" +m_otherQuests.toString()+"\n"+ "End " + m_endValue);
	}
	//Mission Signals
	// When failing/restarting tier while at tier 1 the timer will restart, this should fix that.
	private function TaskFailed(TierID:Number)
	{
		m_taskFailed = TierID;
	}
	private function SlotTaskAdded(QuestID)
	{
		if (IgnoredQuest(QuestID)) return;
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, true, true);
		if (m_taskFailed == m_previousTaskID)
		{
			m_taskFailed = undefined;
			return
		}
		var ProgressStr = string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase;
		// start timer if the new tierID isn't previously failed tier
		if (ProgressStr == m_startValue)
		{
			m_currentRun = new Array();
			var date:Date = new Date();
			m_startTime = date.valueOf();
			m_config.ReplaceEntry("m_startTime", string(m_startTime));
			StartTimer();
		}
		else if (ProgressStr == m_endValue && m_Timer.Running())
		{
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - m_startTime;
			updateSplitTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		// Starts timer if no other timer is active,quest isn't side, and tier is 1
		else if (DValAutoSet.GetValue())
		{
			if (!m_Timer.Running() && m_quest.m_CurrentTask.m_Tier == 1)
			{
				DValSet.SetValue(string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase);
				m_currentRun = new Array();
				var date:Date = new Date();
				m_startTime = date.valueOf();
				m_config.ReplaceEntry("m_startTime", string(m_startTime));
				StartTimer();
			}
		}
		// compare this value against failed tier
		m_previousTaskID = m_quest.m_CurrentTask.m_ID;
		Feedback("Tier added for "+m_quest.m_MissionName+" \"" + ProgressStr+"\"");
	}

	private function SlotQuestProgressed(QuestID:Number, goalID:Number, SolvedTimes:Number, RepeatCount:Number )
	{
		if (IgnoredQuest(QuestID)) return;
		if (SolvedTimes != RepeatCount) return;
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, false, true);
		var ProgressStr = string(QuestID) + goalID  + SolvedTimes + RepeatCount;
		if (ProgressStr == m_startValue)
		{
			m_currentRun = new Array();
			var date:Date = new Date();
			m_startTime = date.valueOf();
			m_config.ReplaceEntry("m_startTime", string(m_startTime));
			StartTimer();
		}
		else if (ProgressStr == m_endValue && m_Timer.Running())
		{
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - m_startTime;
			updateSplitTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		else if ( InRun(QuestID) && m_Timer.Running())
		{
			updateSplitTime(ProgressStr);
		}
		Feedback("Quest progress on " + m_quest.m_MissionName + " " + "\"" + ProgressStr + "\"");
	}

	private function SlotQuestCompleted(QuestID)
	{
		if (IgnoredQuest(QuestID)) return;
		if (string(QuestID) == m_endValue && m_Timer.Running())
		{
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - m_startTime;
			updateSplitTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		Feedback("Quest completed  " + QuestID);
	}

	private function RemoveMission(QuestID:Number)
	{
		if (InRun(QuestID))
		{
			m_currentRun = new Array();
			m_startTime = undefined;
			m_config.DeleteEntry("m_startTime");
			ManualSave();
			RemoveTimer();
		}
	}
}