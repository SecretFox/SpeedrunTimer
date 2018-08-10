import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
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

	private var m_Timer:Timer;
	private var TimerPos:Point;

	private var DValSet:DistributedValue;
	private var OtherQuests:Array;
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

//Setup
	public function Main(root) {
		m_swfroot = root;
		DValSet = DistributedValue.Create("Speedrun_Set");
		DValDebug = DistributedValue.Create("Speedrun_Debug");
		DValDefaults = DistributedValue.Create("Speedrun_Default");

	}
	public function LoadConfig(config:Archive) {
		StartTime = config.FindEntry("StartTime");
		StartValue = config.FindEntry("Start", "38401914411");
		EndValue = config.FindEntry("End", "3840");
		
		CurrentRun = config.FindEntryArray("CurrentRun");
		if (!CurrentRun) CurrentRun = new Array();
		
		OtherQuests = config.FindEntryArray("OtherQuests");
		if (!OtherQuests) OtherQuests = new Array();
		
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
		if(m_Timer){
			var ActiveQuests = QuestsBase.GetAllActiveQuests();
			for (var i in ActiveQuests){
				var m_Quest:Quest = ActiveQuests[i];
				if (InRun(m_Quest.m_ID)){
					m_Timer.SetTitle(string(m_Quest.m_ID));
					break
				}
			}
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
		for (var i:Number = 0; i < OtherQuests.length; i++ ) {
			config.AddEntry("OtherQuests", OtherQuests[i]);
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
		DValSet.SignalChanged.Connect(SlotSetChanged, this);
		DValDebug.SignalChanged.Connect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Connect(SetDefaultValues, this);
	}

	public function Unload() {
		QuestsBase.SignalTaskAdded.Disconnect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Disconnect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Disconnect(SloQuestCompleted, this);
		DValSet.SignalChanged.Disconnect(SlotSetChanged, this);
		DValDebug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		DValDefaults.SignalChanged.Disconnect(SetDefaultValues, this);
	}
//Settings
	private function SlotSetChanged(dv:DistributedValue) {
		var val:String = string(dv.GetValue());
		OtherQuests = undefined;
		if (val) {
			var values:Array = val.split(",");
			if (values.length == 1){
				StartValue = values[0];
				EndValue = StartValue.slice(0, 4);
			}
			else if (values.length == 2){
				StartValue = values[0];
				EndValue = values[1];
			}
			else if (values.length > 2){
				StartValue = string(values.shift());
				EndValue = string(values.pop());
				OtherQuests = values;
			}
		}
	}
	private function SetDefaultValues(dv:DistributedValue) {
		if (dv.GetValue()) {
			DValSet.SetValue("38401914411,3840");
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
	private function InRun(QuestID:Number){
		if(StartValue.indexOf(string(QuestID)) >= 0  || EndValue.indexOf(string(QuestID)) >= 0) return true
		for (var i in OtherQuests){
			var entry = OtherQuests[i];
			var m_QuestID = entry.slice(0, 4);
			if (Number(m_QuestID) == QuestID){
				return true
			}
		}
		return false
	}
	private function inCurrentRun(id:String){
		for (var i in CurrentRun){
			var Entry = CurrentRun[i].split("_");
			if (Entry[0] == id) return true;
		}
		return false;
	}
	
	private function CheckBestRun() {
		var runArray:Array = RunArchieve.FindEntryArray(StartValue + OtherQuests.join("") + EndValue);
		var replace;
		var newEntry:Array = CurrentRun[CurrentRun.length-1].split("_");
		var LastEntry:Array;
		for (var i in runArray){
			var Entry = runArray[i].split("_");
			if (!LastEntry || Number(Entry[1]) > Number(LastEntry[1])){
				LastEntry = Entry;
			}
		}
		if (Number(newEntry[1]) <= Number(LastEntry[1])) {
			replace = true;
		}
		if (replace || !LastEntry || !newEntry) {
			RunArchieve.DeleteEntry(StartValue + OtherQuests.join("") + EndValue);
			for (var i:Number = 0; i < CurrentRun.length; i++) {
				RunArchieve.AddEntry(StartValue + OtherQuests.join("") + EndValue, CurrentRun[i]);
			}
		}
	}
//Timer
	private function StartTimer() {
		m_Timer.ClearTimer();
		m_Timer = undefined;
		m_Timer = new Timer(m_swfroot, TimerPos, EndValue);
		m_Timer.CreateTimer();
		m_Timer.SignalClear.Connect(RemoveTimer, this);
		m_Timer.SetStartTime(StartTime);
		m_Timer.SetArchieve(RunArchieve.FindEntryArray(StartValue + OtherQuests.join("") + EndValue));
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

	//Replaces runArchieve entry if new time is faster
	private function FinishRun(Elapsed) {
		m_Timer.DisplayFinalTime(Elapsed);
		m_Timer.StopTimer();
		CheckBestRun();
		ManualSave();
		CurrentRun = new Array();
		StartTime = undefined;
	}
	
	// Replaces currentrun entry with new time if key is the same
	// Key can be same because it does not use SolvedTimes / RepeatCount
	// This should save some space in Prefs file,and make section times listing shorter.
	private function AddToCurrentRun(key, Elapsed){
		var Found:String;
		for (var i in CurrentRun){
			var Entry = CurrentRun[i].split("_");
			if (Entry[0] == key) Found = i;
		}
		if (Found != undefined){
			CurrentRun[Found] = key + "_" + Elapsed;
		}else{
			CurrentRun.push(key + "_" + Elapsed);
		}
		
	}
	private function updateSectionTime(key:String, override) {
		var Elapsed
		if(!override){
			var current:Date = new Date();
			Elapsed = current.valueOf() - StartTime;
		}else{
			Elapsed = override;
		}
		AddToCurrentRun(key, Elapsed);
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
			CurrentRun = new Array();
			StartTime = date.valueOf();
			StartTimer();
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
			CurrentRun = new Array();
			var date:Date = new Date();
			StartTime = date.valueOf();
			StartTimer();
		} 
		else if (ProgressStr + SolvedTimes + RepeatCount == EndValue) {
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - StartTime;
			updateSectionTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		else if ( InRun(QuestID) && m_Timer.running) {
			updateSectionTime(ProgressStr);
		}
		
		if (DValDebug.GetValue()) {
			Feedback("Quest progress on " + m_quest.m_MissionName + " " + "\"" + ProgressStr + SolvedTimes + RepeatCount + "\"");
		}
	}
	private function SloQuestCompleted(QuestID) {
		if (IsChallenge(QuestID)) return;
		if (string(QuestID) == EndValue) {
			var Final:Date = new Date();
			var FinalTime = Final.valueOf();
			var Elapsed = FinalTime - StartTime;
			updateSectionTime("Finished", Elapsed);
			FinishRun(Elapsed);
		}
		if (DValDebug.GetValue()) {
			Feedback("Quest completed  " + QuestID);
		}
	}
}