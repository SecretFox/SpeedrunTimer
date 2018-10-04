import GUI.fox.aswing.TswLookAndFeel;
import GUI.fox.aswing.ASWingUtils;
import GUI.fox.aswing.UIManager;
import com.GameInterface.AccountManagement;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.Quest;
import com.GameInterface.QuestsBase;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.fox.SpeedrunTimer.Icon;
import com.fox.SpeedrunTimer.Timer;
import com.fox.SpeedrunTimer.Uploader;
import com.fox.SpeedrunTimer.Settings;
import flash.geom.Point;

class com.fox.SpeedrunTimer.Mod {
	private var m_swfroot:MovieClip;
	
	private var m_settingsRoot:MovieClip;
	private var m_settings:Settings;
	private var m_Icon:Icon;
	

	private var StartTime:Number;
	private var StartValue:String;
	private var EndValue:String;
	private var CurrentRun:Array;
	private var RunArchieve:DistributedValue;

	private var m_Timer:Timer;
	private var TimerPos:Point;
	private var settingsPos:Point;

	public var DValSet:DistributedValue;
	private var OtherQuests:Array;
	public var DValDebug:DistributedValue;
	
	public var DValVisibleEntries:DistributedValue;
	public var DValAutoSet:DistributedValue;
	public var DValAutoUpload:DistributedValue;
	public var DValAllZones:DistributedValue;
	public var DValSettingsVisible:DistributedValue;
	
	private var m_uploader:Uploader;
	private var TaskWasFailed:Number = 0;
	private var PreviousTaskID:Number;

	// Time when player entered cutscene
	private var CutSceneStartTime:Number;
	// Time when player entered loading screen
	private var LoadingStartTime:Number;
	// TODO? save LoadingStartTime/CutSceneStartTime in case player crashes?

	// Total time spent on cutscene/loading, substracted from the timer
	private var Offset:Number = 0;

	static var CHALLENGES:Array = [3995, 3996, 3997, 3998, 3999, 3978, 3979, 3980, 3981, 3982];
	static var BLACKLISTED:Array = [3451, 4131, 4042, 4043, 4044]//StoneHenge,NYR

	public static function main(swfRoot:MovieClip) {
		var s_app:Mod = new Mod(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config:Archive) { s_app.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return s_app.SaveConfig(); };
	}

//Setup
	public function Mod(root) {
		m_swfroot = root;
		DValSet = DistributedValue.Create("Speedrun_Set");
		DValDebug = DistributedValue.Create("Speedrun_Debug");
		DValVisibleEntries = DistributedValue.Create("Speedrun_VisibleEntries");
		DValAllZones = DistributedValue.Create("Speedrun_AllZones");

		DValAutoSet = DistributedValue.Create("Speedrun_AutoSet");
		DValAutoUpload = DistributedValue.Create("Speedrun_AutoUpload");
		RunArchieve = DistributedValue.Create("RunArchieve_Speedrun");
		DValSettingsVisible = DistributedValue.Create("Speedrun_Settings");
		
	}

	public function Load() {
		QuestsBase.SignalTaskAdded.Connect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Connect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Connect(SloQuestCompleted, this);
		QuestsBase.SignalMissionRemoved.Connect(RemoveMission, this);
		QuestsBase.SignalTierFailed.Connect(TaskFailed, this);

		DValSet.SignalChanged.Connect(SlotSetChanged, this);
		DValVisibleEntries.SignalChanged.Connect(SetScroll, this);
		DValSettingsVisible.SignalChanged.Connect(DrawSettings, this);

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
	}

	public function Unload() {
		QuestsBase.SignalTaskAdded.Disconnect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Disconnect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Disconnect(SloQuestCompleted, this);
		QuestsBase.SignalMissionRemoved.Disconnect(RemoveMission, this);
		QuestsBase.SignalTierFailed.Disconnect(TaskFailed, this);

		DValSet.SignalChanged.Disconnect(SlotSetChanged, this);
		DValDebug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		DValVisibleEntries.SignalChanged.Disconnect(SetScroll, this);
		DValSettingsVisible.SignalChanged.Disconnect(DrawSettings, this);

		Camera.SignalCinematicActivated.Disconnect(CinematicActivated, this);
		AccountManagement.GetInstance().SignalLoginStateChanged.Disconnect(LoginStateChanged, this);

		m_uploader.TimedOut.Disconnect(TimedOut, this);
		m_uploader.Uploaded.Disconnect(UploaderFeedback, this);
		m_uploader = undefined;
		m_Icon.Unload();
		m_Icon = undefined;
	}

	public function LoadConfig(config:Archive) {
		StartTime = config.FindEntry("StartTime");
		StartValue = config.FindEntry("Start", "38401914411");
		EndValue = config.FindEntry("End", "3840");
		CurrentRun = config.FindEntryArray("CurrentRun");
		if (!Offset) {
			Offset = config.FindEntry("Offset", 0);
		}
		if (!CurrentRun) CurrentRun = new Array();

		OtherQuests = config.FindEntryArray("OtherQuests");
		if (!OtherQuests) OtherQuests = new Array();

		DValDebug.SetValue(config.FindEntry("Debug",false));
		DValVisibleEntries.SetValue(config.FindEntry("VisibleEntries", 2));
		DValAutoSet.SetValue(config.FindEntry("AutoSet", false));
		DValAutoUpload.SetValue(config.FindEntry("AutoUpload",false));
		DValAllZones.SetValue(config.FindEntry("AllZones", true));
		var icon_pos = config.FindEntry("IconPos", new Point(200, 50))
		m_Icon.Activate(icon_pos);
		TimerPos = config.FindEntry("m_TimerPos");
		settingsPos = config.FindEntry("settingsPos",new Point(100,100));
		var runArch = config.FindEntry("RunArchieves", undefined)
		if (!runArch){
			runArch = new Archive();
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
			for (var i in defaultRuns){
				runArch.AddEntry(defaultRuns[i],"Finished_99999999");
			}
		}
		RunArchieve.SetValue(runArch);
		
		if (!TimerPos) {
			var x = DistributedValueBase.GetDValue("ScryTimerX");
			var y = DistributedValueBase.GetDValue("ScryTimerY");
			TimerPos = new Point(x, y);
		}

		if (StartTime && !m_Timer) {
			StartTimer();
			for (var i:Number = 0; i < CurrentRun.length; i++ ) {
				var Entry = CurrentRun[i].split("_");
				m_Timer.SetTierTime(Entry[0], Entry[1]);
			}
		}
		if (m_Timer) {
			var ActiveQuests = QuestsBase.GetAllActiveQuests();
			for (var i in ActiveQuests) {
				var m_Quest:Quest = ActiveQuests[i];
				if (InRun(m_Quest.m_ID)) {
					m_Timer.SetTitle(string(m_Quest.m_ID));
					break
				}
			}
			m_Timer.Offset = Offset;
		}
		DrawSettings();
	}


	public function SaveConfig() {
		var config:Archive = new Archive();
		config.AddEntry("StartTime", StartTime);
		for (var i:Number = 0; i < CurrentRun.length; i++ ) {
			config.AddEntry("CurrentRun", CurrentRun[i]);
		}
		for (var i:Number = 0; i < OtherQuests.length; i++ ) {
			config.AddEntry("OtherQuests", OtherQuests[i]);
		}
		config.AddEntry("Offset", Offset);
		config.AddEntry("VisibleEntries", DValVisibleEntries.GetValue());
		config.AddEntry("Start", StartValue);
		config.AddEntry("End", EndValue);
		config.AddEntry("Debug", DValDebug.GetValue());
		config.AddEntry("AllZones", DValAllZones.GetValue());
		config.AddEntry("m_TimerPos", TimerPos);
		config.AddEntry("settingsPos", settingsPos);
		config.AddEntry("RunArchieves", RunArchieve.GetValue());

		config.AddEntry("AutoSet", DValAutoSet.GetValue());
		config.AddEntry("AutoUpload", DValAutoUpload.GetValue());
		config.AddEntry("IconPos", m_Icon.getPos());
		return config
	}

	private function ManualSave() {
		var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("SpeedrunTimer");
		var config:Archive = new Archive();
		config.AddEntry("StartTime", StartTime);
		for (var i:Number = 0; i < CurrentRun.length; i++ ) {
			config.AddEntry("CurrentRun", CurrentRun[i]);
		}
		for (var i:Number = 0; i < OtherQuests.length; i++ ) {
			config.AddEntry("OtherQuests", OtherQuests[i]);
		}
		config.AddEntry("Offset", Offset);
		config.AddEntry("Start", StartValue);
		config.AddEntry("VisibleEntries", DValVisibleEntries.GetValue());
		config.AddEntry("End", EndValue);
		config.AddEntry("Debug", DValDebug.GetValue());
		config.AddEntry("m_TimerPos", TimerPos);
		config.AddEntry("AllZones", DValAllZones.GetValue());
		config.AddEntry("RunArchieves", RunArchieve.GetValue());
		config.AddEntry("IconPos", m_Icon.getPos());
		config.AddEntry("settingsPos", settingsPos);
		config.AddEntry("AutoSet", DValAutoSet.GetValue());
		config.AddEntry("AutoUpload", DValAutoUpload.GetValue());
		mod.StoreConfig(config);
	}

//Settings
	
	private function DrawSettings(){
		if (DValSettingsVisible.GetValue()){
			if(m_settings) m_settings.dispose();
			m_settings = new Settings(this, settingsPos);
			m_settings.SetListData(GetRunsAsList(DValAllZones.GetValue()));
		}else{
			if (m_settings){
				settingsPos = m_settings.getPos();
				m_settings.dispose();
				m_settings = undefined;
			}
		}
	}
	public function DeleteKey(val:String){
		var conf:Archive = RunArchieve.GetValue();
		conf.DeleteEntry(val);
		RunArchieve.SetValue(conf);
		ManualSave();
	}
	private function SlotSetChanged(dv:DistributedValue) {
		var val = dv.GetValue();
		if (val) {
			OtherQuests = new Array();
			var values:Array = val.split(",");
			if (values.length == 1) {
				StartValue = values[0];
				EndValue = StartValue.slice(0, 4);
			} else if (values.length == 2) {
				StartValue = values[0];
				EndValue = values[1];
			} else if (values.length > 2) {
				StartValue = string(values.shift());
				EndValue = string(values.pop());
				OtherQuests = values;
			}
			Feedback(QuestsBase.GetQuest(Number(StartValue.slice(0,4))).m_MissionName + " set as active",true)
			dv.SetValue(false);
		}
	}
	private function SetScroll(dv:DistributedValue) {
		if (m_Timer){
			if (m_Timer.Entries[m_Timer.currentIndex - 1]) m_Timer.SetScroll(m_Timer.currentIndex - 1);
			else m_Timer.SetScroll(m_Timer.currentIndex);
		}
	}
	public function UploadAll() {
		if (!m_uploader) {
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
		var runs:Archive = RunArchieve.GetValue();
		for (var i in runs["m_Dictionary"]) {
			var entry = runs.FindEntry(i);
			if (entry == "Finished_99999999") continue;
			m_uploader.UploadQueue.push([i, entry]);
		}
		m_uploader.StartUpload();
	}
	private function StartedUpload(val){
		var name = NameFromKey(val);
		if (m_settings) m_settings.__SetText("Uploading "+name);
	}
	public function UploadByKey(key, name) {
		var runs:Archive = RunArchieve.GetValue();
		var entry = runs.FindEntry(key);
		if (entry == "Finished_99999999") return;
		if (entry) {
			if (name){
				if (m_settings) m_settings.__SetText("Uploading " + name);
			}
			if (!m_uploader) {
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
	private function UploaderFeedback(feed:String) {
		if (m_settings) m_settings.__SetText(feed);
		else Feedback(feed, true);
	}
	private function TimedOut() {
		m_uploader = undefined;
		com.GameInterface.Chat.SignalShowFIFOMessage.Emit("Upload failed(Timed out)");
	}
	public function ShowRun(val) {
		if (m_Timer) RemoveTimer();
		var arc:Archive = RunArchieve.GetValue();
		var entry = arc.FindEntry(val);
		if (entry != "Finished_99999999"){
			m_Timer = new Timer(m_swfroot, TimerPos);
			m_Timer.CreateTimer();
			m_Timer.SignalClear.Connect(RemoveTimer, this);
			m_Timer.SetArchieve(entry.split("||"));
			m_Timer.SetTitle(val);
			m_Timer.StopTimer();
			m_Timer.DisplayFinalTime();
		}
	}
	private function NameFromKey(key){
		var runArray:Array = key.split("|");
		var Name = QuestsBase.GetQuest(Number(runArray[0].slice(0, 4))).m_MissionName;
		if (runArray[1] && runArray[2].slice(0, 4) == runArray[0].slice(0, 4)) Name += " (multi)";
		if (runArray[2].slice(0, 4) != runArray[0].slice(0, 4)) Name += " -> " + QuestsBase.GetQuest(Number(runArray[2].slice(0, 4))).m_MissionName;
		if (runArray[2].length > 4) Name += " (partial)";
		return Name
		
	}
	public function GetRunsAsList(all:Boolean) {
		var runs:Archive = RunArchieve.GetValue();
		var runList = new Array();
		var RegionQuests;
		if(!all){
			var currentZone:String = LDBFormat.LDBGetText("Playfieldnames", Character.GetClientCharacter().GetPlayfieldID());
			RegionQuests = QuestsBase.GetAllCompletedQuestsByRegion()[currentZone];
		}
		for (var key in runs["m_Dictionary"]) {
			if(!all){
				var found:Boolean = false;;
				for (var y in RegionQuests) {
					if (RegionQuests[y].m_ID == key.slice(0, 4)) {
						found = true;
					}
				}
				if (!found) continue;
			}
			var Name = NameFromKey(key);
			runList.push({Name:Name, key:key})
		}
		runList.sortOn("Name");
		return runList
	}
// Helper func
	private function IgnoredQuest(QuestID:Number) {
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, false, true);
		if(	m_quest.m_MissionType == _global.Enums.MainQuestType.e_Item || 
			m_quest.m_MissionType == _global.Enums.MainQuestType.e_MetaChallenge || 
			m_quest.m_MissionType == _global.Enums.MainQuestType.e_AreaMission ||
			m_quest.m_MissionType == _global.Enums.MainQuestType.e_Group ||
			m_quest.m_MissionType == _global.Enums.MainQuestType.e_Raid ||
			m_quest.m_MissionType == _global.Enums.MainQuestType.e_PvP
		) return true;
		for (var i in CHALLENGES) {
			if (QuestID == CHALLENGES[i]) return true;
		}
		for (var i in BLACKLISTED){
			if (QuestID == BLACKLISTED[i]) return true;
		}
		return false;
	}
	private function InRun(QuestID:Number) {
		if (StartValue.indexOf(string(QuestID)) >= 0  || EndValue.indexOf(string(QuestID)) >= 0) return true
			for (var i in OtherQuests) {
				var entry = OtherQuests[i];
				var m_QuestID = entry.slice(0, 4);
				if (Number(m_QuestID) == QuestID) {
					return true
				}
			}
		return false
	}
	private function inCurrentRun(id:String) {
		for (var i in CurrentRun) {
			var Entry = CurrentRun[i].split("_");
			if (Entry[0] == id) return true;
		}
		return false;
	}

	//Replaces runArchieve entry if new time is faster
	private function CheckBestRun() {
		var arch:Archive = RunArchieve.GetValue();
		var runArray:Array = arch.FindEntry(StartValue +"|" + OtherQuests.join(",") + "|" +EndValue).split("||");
		var replace;
		var newEntry:Array = CurrentRun[CurrentRun.length-1].split("_");
		var LastEntry:Array;
		for (var i in runArray) {
			var Entry = runArray[i].split("_");
			if (!LastEntry || Number(Entry[1]) > Number(LastEntry[1])) {
				LastEntry = Entry;
			}
		}
		if (Number(newEntry[1]) <= Number(LastEntry[1])) {
			replace = true;
		}
		if (replace || !LastEntry || !newEntry) {
			arch.ReplaceEntry(StartValue +"|" + OtherQuests.join(",") + "|" +EndValue, CurrentRun.join("||"));
			RunArchieve.SetValue(arch);
			if (DValAutoUpload.GetValue()) {
				UploadByKey(StartValue +"|" + OtherQuests.join(",") + "|" +EndValue, CurrentRun.join("||"));
			}
		}
	}
//Timer
	private function RemoveTimer() {
		CurrentRun = new Array();
		TaskWasFailed = 0;
		StartTime = undefined;
		if (m_Timer) {
			TimerPos = m_Timer.getTimerPos();
			m_Timer.ClearTimer();
			m_Timer.SignalClear.Disconnect(RemoveTimer, this);
			m_Timer = undefined;
		}
		ManualSave();
	}
	private function StartTimer() {
		var arch:Archive = RunArchieve.GetValue();
		if (m_Timer) {
			m_Timer.ClearTimer();
			m_Timer.SignalClear.Disconnect(RemoveTimer, this);
			m_Timer = undefined;
		}
		TaskWasFailed = 0;
		m_Timer = new Timer(m_swfroot, TimerPos);
		m_Timer.SetTitle(StartValue);
		m_Timer.CreateTimer();
		m_Timer.SignalClear.Connect(RemoveTimer, this);
		m_Timer.SetStartTime(StartTime);
		m_Timer.SetArchieve(arch.FindEntry(StartValue +"|" + OtherQuests.join(",") + "|" + EndValue).split("||"));
		m_Timer.SetTitle(StartValue);
		ManualSave();
	}
	// 13 = local teleport
	// 12 = inPlay
	// 14 = deep teleport
	// 9 = waiting to send in play
	// 10 = Waiting to receive in play
	// times how long player spends in loading screen
	private function LoginStateChanged(state) {
		if (!m_Timer.running) return;
		switch (state) {
			case _global.Enums.LoginState.e_LoginStateDeepTeleport:
			case _global.Enums.LoginState.e_LoginStateLocalTeleport:
				var date:Date = new Date();
				LoadingStartTime = date.valueOf();
				m_Timer.pausetimer();
				break
			case _global.Enums.LoginState.e_LoginStateInPlay:
				if (LoadingStartTime) {
					var date:Date = new Date();
					Offset += date.valueOf() - LoadingStartTime;
					LoadingStartTime = undefined;
					m_Timer.Offset = Offset;
					m_Timer.resumetimer();
					if (!m_Timer.currentIndex) m_Timer.SetTitle(StartValue);
				}
				break
		}
	}
	// states 1/0
	// times how long cutscene takes
	private function CinematicActivated(state) {
		if (!m_Timer.running) return;
		if (state) {
			var date:Date = new Date();
			CutSceneStartTime = date.valueOf();
			m_Timer.pausetimer();
		} else {
			if (CutSceneStartTime) {
				var date:Date = new Date();
				Offset += date.valueOf() - CutSceneStartTime;
				CutSceneStartTime = undefined;
				m_Timer.Offset = Offset;
				m_Timer.resumetimer();
				if (!m_Timer.currentIndex) m_Timer.SetTitle(StartValue);
			}
		}
	}
	private function FinishRun(Elapsed) {
		m_Timer.DisplayFinalTime(Elapsed);
		m_Timer.StopTimer();
		CheckBestRun();
		ManualSave();
		CurrentRun = new Array();
		StartTime = undefined;
	}
	private function updateSplitTime(key:String, override) {
		var Elapsed;
		if (!override) {
			var current:Date = new Date();
			Elapsed = current.valueOf() - StartTime - Offset;
		} else {
			Elapsed = override;
		}
		CurrentRun.push(key + "_" + Elapsed);
		m_Timer.SetTierTime(key, Elapsed);
		ManualSave();
	}
//Feedback

	private function Feedback(str,override) {
		if (override || DValDebug.GetValue()) com.GameInterface.UtilsBase.PrintChatText(string(str));
	}
	private function PrintCurrentSettings(dv:DistributedValue) {
		Feedback("Current settings\n" + "Start " + StartValue + "\n" +OtherQuests.toString()+"\n"+ "End " + EndValue);
	}
//Mission Signals
	// When failing/restarting tier while at tier 1 the timer will restart, this should fix that.
	private function TaskFailed(TierID:Number) {
		TaskWasFailed = TierID;
	}
	private function SlotTaskAdded(QuestID) {
		if (IgnoredQuest(QuestID)) return;
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, true, true);
		if (TaskWasFailed == PreviousTaskID) {
			TaskWasFailed = undefined;
			return
		}
		var ProgressStr = string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase;
		// start timer if the new tierID isn't previously failed tier
		if (ProgressStr == StartValue) {
			CurrentRun = new Array();
			var date:Date = new Date();
			StartTime = date.valueOf();
			Offset = 0;
			StartTimer();
		} else if (ProgressStr == EndValue) {
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - StartTime - Offset;
			updateSplitTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		// Starts timer if no other timer is active,quest isn't side, and tier is 1
		else if (DValAutoSet.GetValue()) {
			if (!m_Timer.running && m_quest.m_CurrentTask.m_Tier == 1){
				DValSet.SetValue(string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase);
				CurrentRun = new Array();
				var date:Date = new Date();
				StartTime = date.valueOf();
				Offset = 0;
				StartTimer();
			}
		}
		// compare this value against failed tier
		PreviousTaskID = m_quest.m_CurrentTask.m_ID;
		Feedback("Tier added for "+m_quest.m_MissionName+" \"" + ProgressStr+"\"");
	}

	private function SlotQuestProgressed(QuestID:Number, goalID:Number, SolvedTimes:Number, RepeatCount:Number ) {
		if (IgnoredQuest(QuestID)) return;
		if (SolvedTimes != RepeatCount) return;
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, false, true);
		var ProgressStr = string(QuestID) + goalID  + SolvedTimes + RepeatCount;
		if (ProgressStr == StartValue) {
			CurrentRun = new Array();
			var date:Date = new Date();
			StartTime = date.valueOf();
			Offset = 0;
			StartTimer();
		} else if (ProgressStr == EndValue) {
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - StartTime - Offset;
			updateSplitTime("Finished", Elapsed);
			FinishRun(Elapsed);
		} else if ( InRun(QuestID) && m_Timer.running) {
			updateSplitTime(ProgressStr);
		}
		Feedback("Quest progress on " + m_quest.m_MissionName + " " + "\"" + ProgressStr + "\"");
	}

	private function SloQuestCompleted(QuestID) {
		if (IgnoredQuest(QuestID)) return;
		if (string(QuestID) == EndValue) {
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - StartTime - Offset;
			updateSplitTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		Feedback("Quest completed  " + QuestID);
	}

	private function RemoveMission(QuestID:Number) {
		if (InRun(QuestID)) {
			CurrentRun = new Array();
			StartTime = undefined;
			ManualSave();
			RemoveTimer();
		}
	}
}