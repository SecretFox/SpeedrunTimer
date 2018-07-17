import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Character;
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
	private var RunArchieve:Archive;

	private var PlayerCharacter:Character;
	private var m_Timer:Timer;
	private var TimerPos:Point;

	private var DValStart:DistributedValue;
	private var DValStop:DistributedValue;
	private var DValDebug:DistributedValue;
	private var DValDefaults:DistributedValue;

	static var CHALLENGES:Array = [3995, 3996, 3997, 3998, 3999, 3978, 3979, 3980, 3981, 3982];

	public static function main(swfRoot:MovieClip) {
		var s_app:Main = new Main(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config:Archive) { s_app.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return s_app.SaveConfig(); };
	}

//Startup
	public function Main(root) {
		m_swfroot = root;
		PlayerCharacter = Character.GetClientCharacter();
		DValStart = DistributedValue.Create("Speedrun_Start");
		DValStop = DistributedValue.Create("Speedrun_Stop");
		DValDebug = DistributedValue.Create("Speedrun_Debug");
		DValDefaults = DistributedValue.Create("Speedrun_Default");

	}
	public function LoadConfig(config:Archive) {
		StartTime = config.FindEntry("StartTime");
		StartValue = config.FindEntry("Start", "38401914411");
		EndValue = config.FindEntry("End", "3840");
		CurrentRun = config.FindEntryArray("CurrentRun");
		if (!CurrentRun) CurrentRun = new Array();
		DValDebug.SetValue(config.FindEntry("Debug"), false);
		TimerPos = config.FindEntry("m_TimerPos");
		RunArchieve = config.FindEntry("RunArchieve",new Archive());
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
	}
	public function SaveConfig() {
		var config:Archive = new Archive();
		config.AddEntry("StartTime", StartTime);
		for (var i:Number = 0; i < CurrentRun.length; i++ ) {
			config.AddEntry("CurrentRun", CurrentRun[i]);
		}
		config.AddEntry("Start", StartValue);
		config.AddEntry("End", EndValue);
		config.AddEntry("Debug", DValDebug.GetValue());
		config.AddEntry("m_TimerPos", TimerPos);
		config.AddEntry("RunArchieve", RunArchieve);
		return config
	}
	private function ManualSave() {
		var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("SpeedrunTimer");
		var config:Archive = new Archive();
		config.AddEntry("StartTime", StartTime);
		for (var i:Number = 0; i < CurrentRun.length; i++ ) {
			config.AddEntry("CurrentRun", CurrentRun[i]);
		}
		config.AddEntry("Start", StartValue);
		config.AddEntry("End", EndValue);
		config.AddEntry("Debug", DValDebug.GetValue());
		config.AddEntry("m_TimerPos", TimerPos);
		config.AddEntry("RunArchieve", RunArchieve);
		mod.StoreConfig(config);
	}

	public function Load() {
		QuestsBase.SignalTaskAdded.Connect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Connect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Connect(SloQuestCompleted, this);
		DValStart.SignalChanged.Connect(SlotStartConditionChanged, this);
		DValStop.SignalChanged.Connect(SlotStopConditionChanged, this);
		DValDebug.SignalChanged.Connect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Connect(SetDefaultValues, this);
	}

	public function Unload() {
		QuestsBase.SignalTaskAdded.Disconnect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Disconnect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Disconnect(SloQuestCompleted, this);
		DValStart.SignalChanged.Disconnect(SlotStartConditionChanged, this);
		DValStop.SignalChanged.Disconnect(SlotStopConditionChanged, this);
		DValDebug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Disconnect(SetDefaultValues, this);
	}
//Settings
	private function SlotStartConditionChanged(dv:DistributedValue) {
		var val:String = string(dv.GetValue());
		if (val) {
			if (val.indexOf(",") > 0) {
				var values:Array = val.split(",");
				StartValue = values[0];
				EndValue = values[1];
			} else {
				StartValue = val;
			}
		}
	}
	private function SlotStopConditionChanged(dv:DistributedValue) {
		var val:String = string(dv.GetValue());
		if (val) {
			if (val.indexOf(",") > 0) {
				var values:Array = val.split(",");
				StartValue = values[0];
				EndValue = values[1];
			} else {
				EndValue = val;
			}
		}
	}
	private function SetDefaultValues(dv:DistributedValue) {
		if (dv.GetValue()) {
			DValStart.SetValue("38401914411");
			DValStop.SetValue("3840");
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

//Timer
	private function StartTimer() {
		if (!m_Timer) {
			m_Timer = new Timer(m_swfroot, TimerPos, EndValue);
			m_Timer.CreateTimer();
			m_Timer.SignalClear.Connect(RemoveTimer, this);
		}
		m_Timer.SetStartTime(StartTime);
		m_Timer.SetArchieve(RunArchieve.FindEntryArray(StartValue + EndValue));
		ManualSave();
	}

	private function RemoveTimer() {
		TimerPos = m_Timer.getTimerPos();
		CurrentRun = new Array();
		StartTime = undefined;
		m_Timer.ClearTimer();
		m_Timer = undefined;
		ManualSave();
	}

	private function Checkbestrun() {
		var runArray:Array = RunArchieve.FindEntryArray(StartValue + EndValue);
		var found;
		var replace;
		var LastEntry:Array;
		for (var i in CurrentRun) {
			var entry:Array = CurrentRun[i].split("_");
			if (entry[0] == EndValue) {
				LastEntry = entry;
				break
			}
		}
		for (var i in runArray) {
			var entry:Array = runArray[i].split("_");
			if (entry[0] == LastEntry[0]) {
				found = true;
				if (entry[1] > LastEntry[1]) {
					replace = true;
				}
				break
			}
		}
		if (replace || !found || !LastEntry) {
			RunArchieve.DeleteEntry(StartValue + EndValue);
			for (var i:Number = 0; i < CurrentRun.length; i++) {
				RunArchieve.AddEntry(StartValue + EndValue, CurrentRun[i]);
			}
		}
	}
	private function FinishRun() {
		var Final:Date = new Date();
		var FinalTime = Final.valueOf();
		var Elapsed = FinalTime - StartTime;
		CurrentRun.push(EndValue + "_" + Elapsed);
		updateSectionTime(EndValue, Elapsed);
		m_Timer.DisplayFinalTime(Elapsed);
		m_Timer.StopTimer();
		Checkbestrun();
		ManualSave();
	}
	private function updateSectionTime(key:String) {
		var current:Date = new Date();
		var currentTime = current.valueOf();
		var Elapsed = currentTime - StartTime;
		CurrentRun.push(key + "_" + Elapsed);
		var runArray:Array = RunArchieve.FindEntryArray(StartValue + EndValue);
		if (runArray) {
			var Found;
			for (var i in runArray) {
				var entry = runArray[i].split("_");
				var id = entry[0];
				var time = entry[1];
				if (id == key) {
					Found = true;
					break
				}
			}
			if (!Found) {
				RunArchieve.AddEntry(StartValue+EndValue, key +"_" + Elapsed);
			}
		} else {
			RunArchieve.AddEntry(StartValue + EndValue,  key + "_" + Elapsed);
		}
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
		var Str = string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase;
		if (Str == StartValue) {
			var date:Date = new Date();
			var start = date.valueOf();
			StartTime = start;
			StartTimer(QuestID);
		}
		if (DValDebug.GetValue()) {
			Feedback("Task added \"" + Str+"\"");
		}
	}
	private function SlotQuestProgressed(QuestID:Number, goalID:Number, SolvedTimes:Number, RepeatCount:Number ) {
		if (IsChallenge(QuestID)) return;
		var ProgressStr = string(QuestID) + goalID; // + SolvedTimes + RepeatCount; Gets too long with lots of collection tasks
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, false, true);
		if (ProgressStr + SolvedTimes + RepeatCount == StartValue) {
			var date:Date = new Date();
			StartTime = date.valueOf();
			StartTimer();
		} else if ((StartTime && StartValue.indexOf(string(QuestID)) >= 0) || (EndValue && EndValue.indexOf(string(QuestID)) >= 0)) {
			// TODO, add support for multiple quests in speedrun
			// Currently this should still work for multiple quests, but section times will only get updated for quests that have same id as Start or End Value.
			updateSectionTime(ProgressStr);
		}
		if (ProgressStr + SolvedTimes + RepeatCount == EndValue) {
			FinishRun();
		}
		if (DValDebug.GetValue()) {
			Feedback("Quest progress on " + m_quest.m_MissionName + " " + "\"" + ProgressStr + SolvedTimes + RepeatCount + "\"");
		}
	}
	private function SloQuestCompleted(QuestID) {
		if (IsChallenge(QuestID)) return;
		if (string(QuestID) == EndValue) {
			FinishRun();
		}
		if (DValDebug.GetValue()) {
			Feedback("Quest completed  " + QuestID);
		}
	}
}