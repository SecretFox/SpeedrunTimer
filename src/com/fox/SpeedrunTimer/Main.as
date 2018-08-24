import com.GameInterface.AccountManagement;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.Quest;
import com.GameInterface.QuestsBase;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.fox.SpeedrunTimer.Timer;
import com.fox.SpeedrunTimer.Uploader;
import flash.geom.Point;
/**
 * ...
 * @author fox
 */
class com.fox.SpeedrunTimer.Main {
	private var m_swfroot:MovieClip;

	private var StartTime:Number;
	private var StartValue:String;
	private var EndValue:String;
	private var CurrentRun:Array;
	private var RunArchieve:DistributedValue;

	private var m_Timer:Timer;
	private var TimerPos:Point;

	private var DValSet:DistributedValue;
	private var OtherQuests:Array;
	private var DValDebug:DistributedValue;
	private var DValDefaults:DistributedValue;
	private var DValResetData:DistributedValue;
	private var DValVisibleEntries:DistributedValue;

	private var DValAutoSet:DistributedValue;
	private var DValUpload:DistributedValue;
	private var DValAutoUpload:DistributedValue;
	private var DvalListRuns:DistributedValue;
	private var DvalListRunsByRegion:DistributedValue;

	private var DvalShowOld:DistributedValue;
	private var m_uploader:Uploader;

	private var DValWarningTreshold:DistributedValue;

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

	public static function main(swfRoot:MovieClip) {
		var s_app:Main = new Main(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config:Archive) { s_app.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return s_app.SaveConfig(); };
	}

//Setup
	public function Main(root) {
		m_swfroot = root;
		DValSet = DistributedValue.Create("Speedrun_Set");
		DValDebug = DistributedValue.Create("Speedrun_Debug");
		DValDefaults = DistributedValue.Create("Speedrun_Default");
		DValResetData = DistributedValue.Create("Speedrun_ResetData");
		DValVisibleEntries = DistributedValue.Create("Speedrun_VisibleEntries");

		DValAutoSet = DistributedValue.Create("Speedrun_AutoSet");
		DValUpload = DistributedValue.Create("Speedrun_Upload");
		DValAutoUpload = DistributedValue.Create("Speedrun_AutoUpload");
		DValWarningTreshold = DistributedValue.Create("Speedrun_WarningTreshold");

		DvalListRuns = DistributedValue.Create("Speedrun_List");
		DvalListRunsByRegion = DistributedValue.Create("Speedrun_ListByRegion");

		DvalShowOld = DistributedValue.Create("Speedrun_Show");

		RunArchieve = DistributedValue.Create("RunArchieve_Speedrun");
	}

	public function Load() {
		QuestsBase.SignalTaskAdded.Connect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Connect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Connect(SloQuestCompleted, this);
		QuestsBase.SignalMissionRemoved.Connect(RemoveMission, this);
		QuestsBase.SignalTierFailed.Connect(TaskFailed, this);

		DValSet.SignalChanged.Connect(SlotSetChanged, this);
		DValDebug.SignalChanged.Connect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Connect(SetDefaultValues, this);
		DValResetData.SignalChanged.Connect(ResetData, this);
		DValVisibleEntries.SignalChanged.Connect(SetScroll, this);
		DValUpload.SignalChanged.Connect(UploadRuns, this);
		DvalListRuns.SignalChanged.Connect(ListRuns, this);
		DvalListRunsByRegion.SignalChanged.Connect(ListRunsByRegion, this);
		DvalShowOld.SignalChanged.Connect(ShowRun, this);

		// used to substract time spent on cutscenes
		// alternative signals: UtilsBase.SignalSplashScreenActivated, GlobalSignal.SignalFadeScreen and  OnModuleActivated
		Camera.SignalCinematicActivated.Connect(CinematicActivated, this);
		// used to substract time spent on loading screens
		AccountManagement.GetInstance().SignalLoginStateChanged.Connect(LoginStateChanged, this);

	}

	public function Unload() {
		QuestsBase.SignalTaskAdded.Disconnect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Disconnect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Disconnect(SloQuestCompleted, this);
		QuestsBase.SignalMissionRemoved.Disconnect(RemoveMission, this);
		QuestsBase.SignalTierFailed.Disconnect(TaskFailed, this);

		DValSet.SignalChanged.Disconnect(SlotSetChanged, this);
		DValDebug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Disconnect(SetDefaultValues, this);
		DValResetData.SignalChanged.Disconnect(ResetData, this);
		DValVisibleEntries.SignalChanged.Disconnect(SetScroll, this);
		DValUpload.SignalChanged.Disconnect(UploadRuns, this);
		DvalListRuns.SignalChanged.Disconnect(ListRuns, this);
		DvalListRunsByRegion.SignalChanged.Disconnect(ListRunsByRegion, this);
		DvalShowOld.SignalChanged.Disconnect(ShowRun, this);

		Camera.SignalCinematicActivated.Disconnect(CinematicActivated, this);
		AccountManagement.GetInstance().SignalLoginStateChanged.Disconnect(LoginStateChanged, this);

		m_uploader.TimedOut.Disconnect(TimedOut, this);
		m_uploader.Uploaded.Disconnect(UploaderFeedback, this);
		m_uploader = undefined;
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

		DValDebug.SetValue(config.FindEntry("Debug"), false);
		DValVisibleEntries.SetValue(config.FindEntry("VisibleEntries", 2));
		DValAutoSet.SetValue(config.FindEntry("AutoSet"), false);
		DValUpload.SetValue(config.FindEntry("Upload"), false);
		DValAutoUpload.SetValue(config.FindEntry("AutoUpload"), false);
		DValWarningTreshold.SetValue(config.FindEntry("Warning"), 100);
		TimerPos = config.FindEntry("m_TimerPos");
		RunArchieve.SetValue(config.FindEntry("RunArchieves",new Archive()));
		if (!TimerPos) {
			var x = DistributedValueBase.GetDValue("ScryTimerX");
			var y = DistributedValueBase.GetDValue("ScryTimerY");
			TimerPos = new Point(x, y);
		}
		var RunArrayLength = 0;
		for (var i in RunArchieve.GetValue()["m_Dictionary"]) RunArrayLength += 1;
		if (RunArrayLength > DValWarningTreshold.GetValue()) {
			Feedback(	"You have over " + DValWarningTreshold.GetValue() +
						" speedruns saved\nTo clear all saved runs you can use  \"/option Speedrun_ResetData true\"\n" +
						"To get rid of the warning you can use \"/option Speedrun_WarningTreshold X\" command [default is 100]",
						true
					);
			Chat.SignalShowFIFOMessage.Emit("Large amount of saved runs detected, Please see systems chat channel");
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
		config.AddEntry("m_TimerPos", TimerPos);
		config.AddEntry("RunArchieves", RunArchieve.GetValue());

		config.AddEntry("AutoSet", DValAutoSet.GetValue());
		config.AddEntry("Upload", DValUpload.GetValue());
		config.AddEntry("AutoUpload", DValAutoUpload.GetValue());
		config.AddEntry("Warning", DValWarningTreshold.GetValue());
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
		config.AddEntry("RunArchieves", RunArchieve.GetValue());

		config.AddEntry("AutoSet", DValAutoSet.GetValue());
		config.AddEntry("Upload", DValUpload.GetValue());
		config.AddEntry("AutoUpload", DValAutoUpload.GetValue());
		config.AddEntry("Warning", DValWarningTreshold.GetValue());
		mod.StoreConfig(config);
	}

//Settings
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
	private function SetDefaultValues(dv:DistributedValue) {
		if (dv.GetValue()) {
			DValSet.SetValue("38401914411,3840");
			dv.SetValue(false);
		}
	}
	private function ResetData(dv:DistributedValue) {
		if (dv.GetValue()) {
			RunArchieve.SetValue(new Archive());
			dv.SetValue(false);
			Feedback("All saved runs wiped", true);
		}
	}
	private function SetScroll(dv:DistributedValue) {
		if (m_Timer) m_Timer.SetScroll(m_Timer.currentIndex);
	}
	private function UploadRuns(dv:DistributedValue) {
		if (dv.GetValue()) {
			if (!m_uploader) {
				m_uploader = new Uploader();
				var m_Player:Character = Character.GetClientCharacter();
				m_uploader.PlayerID = m_Player.GetID().GetInstance();
				m_uploader.PlayerName = m_Player.GetName();
				m_uploader.PlayerFaction = m_Player.GetStat(_global.Enums.Stat.e_PlayerFaction);
				m_uploader.TimedOut.Connect(TimedOut, this);
				m_uploader.Uploaded.Connect(UploaderFeedback, this);
			}
			m_uploader.UploadQueue = new Array();
			var runs:Archive = RunArchieve.GetValue();
			for (var i in runs["m_Dictionary"]) {
				m_uploader.UploadQueue.push([i,runs.FindEntry(i)])
			}
			m_uploader.StartUpload();
			dv.SetValue(false);
		}
	}
	private function AutoUpload(key) {
		var arch:Archive = RunArchieve.GetValue();
		var runString:Array = arch.FindEntry(key);
		if (runString) {
			if (!m_uploader) {
				m_uploader = new Uploader();
				var m_Player:Character = Character.GetClientCharacter();
				m_uploader.PlayerID = m_Player.GetID().GetInstance();
				m_uploader.PlayerName = m_Player.GetName();
				m_uploader.PlayerFaction = m_Player.GetStat(_global.Enums.Stat.e_PlayerFaction);
				m_uploader.TimedOut.Connect(TimedOut, this);
				m_uploader.Uploaded.Connect(UploaderFeedback, this);
			}
			m_uploader.UploadQueue = new Array();
			m_uploader.UploadQueue.push([key, runString])
			m_uploader.StartUpload();
		}
	}
	private function UploaderFeedback(feed:String) {
		Feedback(feed,true);
	}
	private function TimedOut() {
		m_uploader.TimedOut.Disconnect(TimedOut, this);
		m_uploader = undefined;
		com.GameInterface.Chat.SignalShowFIFOMessage.Emit("Upload failed(Timed out)");
	}
	private function ShowRun(dv:DistributedValue) {
		var val = dv.GetValue();
		if (val) {
			if (m_Timer) RemoveTimer();
			var other = new Array();
			var start:String;
			var end:String;
			var values:Array = val.split(",");
			if (values.length == 1) {
				start = values[0];
				end = start.slice(0, 4);
			} else if (values.length == 2) {
				start = values[0];
				end = values[1];
			} else if (values.length > 2) {
				start = string(values.shift());
				end = string(values.pop());
				other = values;
			}
			var arc:Archive = RunArchieve.GetValue();
			m_Timer = new Timer(m_swfroot, TimerPos);
			m_Timer.SetTitle(start);
			m_Timer.CreateTimer();
			m_Timer.SignalClear.Connect(RemoveTimer, this);
			m_Timer.SetArchieve(arc.FindEntry(start +"|" + other.join(",") + "|" + end).split("||"));
			m_Timer.SetTitle(start);
			m_Timer.StopTimer();
			m_Timer.DisplayFinalTime();
			dv.SetValue(false);
		}
	}
	private function ListRuns(dv:DistributedValue) {
		if (dv.GetValue()) {
			var runs:Archive = RunArchieve.GetValue();
			var runList = new Array();
			for (var i in runs["m_Dictionary"]) {
				var runArray:Array = i.split("|");
				var clickyString:String = runArray[0];
				if (runArray[1]) clickyString += "," + runArray[1];
				if (runArray[2] != runArray[0].slice(0, 4) ) clickyString += "," + runArray[2];

				var PrintStr = QuestsBase.GetQuest(Number(runArray[0].slice(0, 4))).m_MissionName;
				if (runArray[1]) {
					PrintStr += "\n";
					var other = runArray[1].split(",");
					for (var y in other) {
						PrintStr += QuestsBase.GetQuest(Number(other[y])).m_MissionName + "\n";
					}
				}
				if (runArray[2].slice(0, 4) != runArray[0].slice(0, 4)) PrintStr += QuestsBase.GetQuest(Number(runArray[2].slice(0, 4))).m_MissionName + "\n";
				if (runArray[2].length>4) PrintStr += " (partial)";

				clickyString = "  <a href=\"text://<a href=\'chatcmd:///option Speedrun_Set &quot;" + clickyString + "&quot;\'><font face=HEADLINE>Click here to set as active</font></a>\n\n<a href=\'chatcmd:///option Speedrun_Show &quot;" + clickyString + "&quot;\'><font face=HEADLINE>Click here to show</font></a>\">" + PrintStr + "</a>\n--";
				runList.push({Name:PrintStr, Content:clickyString})
			}

			runList.sortOn("Name");
			for ( var i = 0; i < runList.length; i++) {
				Feedback(runList[i].Content,true);
			}
			dv.SetValue(false);
		}
	}
	private function ListRunsByRegion(dv:DistributedValue) {
		if (dv.GetValue()) {
			var runs:Archive = RunArchieve.GetValue();
			var runList = new Array();
			var currentZone:String = LDBFormat.LDBGetText("Playfieldnames", Character.GetClientCharacter().GetPlayfieldID());
			var RegionQuests = QuestsBase.GetAllCompletedQuestsByRegion()[currentZone];
			for (var i in runs["m_Dictionary"]) {
				var runArray:Array = i.split("|");
				var found:Boolean = false;;
				for (var y in RegionQuests) {
					if (RegionQuests[y].m_ID == runArray[0].slice(0, 4)) {
						found = true;
					}
				}
				if (!found) continue;
				var clickyString:String = runArray[0];
				if (runArray[1]) clickyString += "," + runArray[1];
				if (runArray[2] != runArray[0].slice(0, 4) ) clickyString += "," + runArray[2];

				var PrintStr = QuestsBase.GetQuest(Number(runArray[0].slice(0, 4))).m_MissionName;
				if (runArray[1]) {
					PrintStr += "\n";
					var other = runArray[1].split(",");
					for (var y in other) {
						PrintStr += QuestsBase.GetQuest(Number(other[y])).m_MissionName + "\n";
					}
				}
				if (runArray[2].slice(0, 4) != runArray[0].slice(0, 4)) PrintStr += QuestsBase.GetQuest(Number(runArray[2].slice(0, 4))).m_MissionName + "\n";
				if (runArray[2].length>4) PrintStr += " (partial)";

				clickyString = "  <a href=\"text://<a href=\'chatcmd:///option Speedrun_Set &quot;" + clickyString + "&quot;\'><font face=HEADLINE>Click here to set as active</font></a>\n\n<a href=\'chatcmd:///option Speedrun_Show &quot;" + clickyString + "&quot;\'><font face=HEADLINE>Click here to show</font></a>\">" + PrintStr + "</a>\n--";
				runList.push({Name:PrintStr, Content:clickyString})
			}
			runList.sortOn("Name");
			for ( var i = 0; i < runList.length; i++) {
				Feedback(runList[i].Content,true);
			}
			dv.SetValue(false);
		}
	}
// Helper func
	private function IsChallenge(QuestID:Number) {
		for (var i in CHALLENGES) {
			if (QuestID == CHALLENGES[i]) return true;
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
				AutoUpload(StartValue +"|" + OtherQuests.join(",") + "|" +EndValue, CurrentRun.join("||"));
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
		var arc:Archive = RunArchieve.GetValue();
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
		m_Timer.SetArchieve(arc.FindEntry(StartValue +"|" + OtherQuests.join(",") + "|" + EndValue).split("||"));
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
	private function updateSectionTime(key:String, override) {
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
		if (IsChallenge(QuestID)) return;
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
			updateSectionTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		// Starts timer if no other timer is active,quest isn't side, and tier is 1
		else if (DValAutoSet.GetValue()) {
			if (!m_Timer.running && m_quest.m_MissionType != _global.Enums.MainQuestType.e_Item && m_quest.m_MissionType != _global.Enums.MainQuestType.e_MetaChallenge && m_quest.m_MissionType != _global.Enums.MainQuestType.e_AreaMission && m_quest.m_CurrentTask.m_Tier == 1 ) {
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
		if (IsChallenge(QuestID)) return;
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
			updateSectionTime("Finished", Elapsed);
			FinishRun(Elapsed);
		} else if ( InRun(QuestID) && m_Timer.running) {
			updateSectionTime(ProgressStr);
		}
		Feedback("Quest progress on " + m_quest.m_MissionName + " " + "\"" + ProgressStr + "\"");
	}

	private function SloQuestCompleted(QuestID) {
		if (IsChallenge(QuestID)) return;
		if (string(QuestID) == EndValue) {
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - StartTime - Offset;
			updateSectionTime("Finished", Elapsed);
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