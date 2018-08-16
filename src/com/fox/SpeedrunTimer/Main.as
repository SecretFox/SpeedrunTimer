import com.GameInterface.AccountManagement;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Camera;
import com.GameInterface.LogBase;
import com.GameInterface.Quest;
import com.GameInterface.QuestsBase;
import com.Utils.Archive;
import com.fox.SpeedrunTimer.Timer;
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
		RunArchieve = DistributedValue.Create("RunArchieve_Speedrun");
	}

	public function Load() {
		QuestsBase.SignalTaskAdded.Connect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Connect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Connect(SloQuestCompleted, this);
		DValSet.SignalChanged.Connect(SlotSetChanged, this);
		DValDebug.SignalChanged.Connect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Connect(SetDefaultValues, this);
		DValResetData.SignalChanged.Connect(ResetData, this);
		DValVisibleEntries.SignalChanged.Connect(SetScroll, this);
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
		DValSet.SignalChanged.Disconnect(SlotSetChanged, this);
		DValDebug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Disconnect(SetDefaultValues, this);
		DValResetData.SignalChanged.Disconnect(ResetData, this);
		DValVisibleEntries.SignalChanged.Disconnect(SetScroll, this);
		Camera.SignalCinematicActivated.Disconnect(CinematicActivated, this);
		AccountManagement.GetInstance().SignalLoginStateChanged.Disconnect(LoginStateChanged, this);
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

		DValVisibleEntries.SetValue(config.FindEntry("VisibleEntries",2));
		TimerPos = config.FindEntry("m_TimerPos");
		RunArchieve.SetValue(config.FindEntry("RunArchieves",new Archive()));
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
			Feedback("All saved runs wiped");
		}
	}
	private function SetScroll(dv:DistributedValue) {
		if (m_Timer) m_Timer.SetScroll(m_Timer.currentIndex);
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
		}
		
	}
//Timer
	private function RemoveTimer() {
		CurrentRun = new Array();
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
		if (m_Timer){
			m_Timer.ClearTimer();
			m_Timer.SignalClear.Disconnect(RemoveTimer, this);
			m_Timer = undefined;
		}
		m_Timer = new Timer(m_swfroot, TimerPos);
		m_Timer.SetTitle(StartValue);
		m_Timer.CreateTimer();
		m_Timer.SignalClear.Connect(RemoveTimer, this);
		m_Timer.SetStartTime(StartTime);
		m_Timer.SetArchieve(arc.FindEntry(StartValue +"|" + OtherQuests.join(",") + "|" + EndValue).split("||"));
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
		var Elapsed
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

	private function Feedback(str) {
		com.GameInterface.UtilsBase.PrintChatText(string(str));
		LogBase.Error("SpeedRun", str);
	}
	private function PrintCurrentSettings(dv:DistributedValue) {
		if (dv.GetValue()) {
			Feedback("Current settings\n" + "Start " + StartValue + "\n" + "End " + EndValue);
		}
	}
//Mission Signals
	private function SlotTaskAdded(QuestID) {
		if (IsChallenge(QuestID)) return;
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, true, true);
		var ProgressStr = string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase;
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
		if (DValDebug.GetValue()) {
			Feedback("Task added \"" + ProgressStr+"\"");
		}
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

		if (DValDebug.GetValue()) {
			Feedback("Quest progress on " + m_quest.m_MissionName + " " + "\"" + ProgressStr + "\"");
		}
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
		if (DValDebug.GetValue()) {
			Feedback("Quest completed  " + QuestID);
		}
	}
}