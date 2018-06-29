import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Character;
import com.GameInterface.LogBase;
import com.GameInterface.Quest;
import com.GameInterface.QuestsBase;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.fox.ST.Timer;
import flash.geom.Point;
import mx.utils.Delegate;

class com.fox.ST.Main {
	private var StartTime;
	private var PrintInterval;
	private var m_Player:Character;
	private var StartCondition:DistributedValue;
	private var CompleteCondition:DistributedValue;
	private var m_Start:String;
	private var m_End:String;
	private var Debug:DistributedValue;
	private var m_swfroot:MovieClip;
	private var m_Timer:Timer;
	public var m_TimerPos:Point;
	private var SetDefaults:DistributedValue;
	static var CHALLENGES:Array = [3995,3996,3997,3998,3999,3978,3979,3980,3981,3982]

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
		m_Player = Character.GetClientCharacter();
		StartCondition = DistributedValue.Create("Speedrun_Start");
		CompleteCondition = DistributedValue.Create("Speedrun_Stop");
		Debug = DistributedValue.Create("Speedrun_Debug");
		SetDefaults = DistributedValue.Create("Speedrun_Default");
	}
	public function LoadConfig(config:Archive) {
		StartTime = config.FindEntry("StartTime");
		m_Start = config.FindEntry("Start", "38401914411");
		m_End = config.FindEntry("End", "3840");
		Debug.SetValue(config.FindEntry("Debug"), false);
		m_TimerPos = config.FindEntry("m_TimerPos");
		if (!m_TimerPos) {
			var x = DistributedValueBase.GetDValue("ScryTimerX");
			var y = DistributedValueBase.GetDValue("ScryTimerY");
			m_TimerPos = new Point(x, y);
		}

		if (Debug.GetValue()) Feedback("Current settings\n" + "Start " + m_Start + "\n" + "End " + m_End);

		if (StartTime && !m_Timer) {
			StartTimer(undefined, StartTime);
		}
	}
	public function SaveConfig() {
		var config:Archive = new Archive();
		config.AddEntry("StartTime", StartTime);
		config.AddEntry("Start", m_Start);
		config.AddEntry("End", m_End);
		config.AddEntry("Debug", Debug.GetValue());
		config.AddEntry("m_TimerPos", m_TimerPos);
		return config
	}
	private function ManualSave() {
		var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("DustyTimer");
		var config:Archive = new Archive();
		config.AddEntry("StartTime", StartTime);
		config.AddEntry("Start", m_Start);
		config.AddEntry("End", m_End);
		config.AddEntry("Debug", Debug.GetValue());
		config.AddEntry("m_TimerPos", m_TimerPos);
		mod.StoreConfig(config);
	}

	public function Load() {
		QuestsBase.SignalTaskAdded.Connect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Connect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Connect(SloQuestCompleted, this);
		StartCondition.SignalChanged.Connect(SlotStartConditionChanged, this);
		CompleteCondition.SignalChanged.Connect(SlotStopConditionChanged, this);
		Debug.SignalChanged.Connect(PrintCurrentSettings, this);
		SetDefaults.SignalChanged.Connect(SetDefaultValues, this);
	}

	public function Unload() {
		QuestsBase.SignalTaskAdded.Disconnect(SlotTaskAdded, this);
		QuestsBase.SignalGoalProgress.Disconnect(SlotQuestProgressed, this);
		QuestsBase.SignalMissionCompleted.Disconnect(SloQuestCompleted, this);
		StartCondition.SignalChanged.Disconnect(SlotStartConditionChanged, this);
		CompleteCondition.SignalChanged.Disconnect(SlotStopConditionChanged, this);
		Debug.SignalChanged.Disconnect(PrintCurrentSettings, this);
		SetDefaults.SignalChanged.Disconnect(SetDefaultValues, this);
	}
//Settings
	private function SlotStartConditionChanged(dv:DistributedValue) {
		if (dv.GetValue()) {
			m_Start = string(dv.GetValue());
		}
	}
	private function SlotStopConditionChanged(dv:DistributedValue) {
		if (dv.GetValue()) {
			m_End = string(dv.GetValue());
		}
	}
	private function PrintCurrentSettings(dv:DistributedValue) {
		if (dv.GetValue()) {
			Feedback("Current settings\n" + "Start " + m_Start + "\n" + "End " + m_End);
		}
	}
	private function SetDefaultValues(dv:DistributedValue) {
		if (dv.GetValue()) {
			StartCondition.SetValue("38401914411");
			CompleteCondition.SetValue("3840");
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

//Timer Start & Stop
	private function StartTimer(QuestID:Number, override) {
		if (!m_Timer) {
			m_Timer = new Timer(m_swfroot, m_TimerPos);
			m_Timer.CreateTimer();
			m_Timer.SignalClear.Connect(RemoveTimer, this);
		}
		if (!override) {
			var date:Date = new Date();
			var start = date.valueOf();
			StartTime = start;

		} else {
			StartTime = override;
		}
		var TimerClip = m_Timer.GetTimer();
		TimerClip.onPress = Delegate.create(this, OnPress);
		TimerClip.onPressAux = Delegate.create(this, OnPressAux);
		TimerClip.onRelease = Delegate.create(this, OnRelease);
		TimerClip.onReleaseOutside = Delegate.create(this, OnRelease);
		m_Timer.SetStartTime(StartTime);
		ManualSave();

	}
	private function OnPress() {
		m_Timer.m_Timer.startDrag();
	}
	private function OnPressAux() {
		if (Key.isDown(Key.CONTROL)) {
			m_TimerPos = m_Timer.RemoveTimer();
			m_Timer = undefined;
			StartTime = undefined;
			ManualSave();
		}
	}
	private function OnRelease() {
		m_Timer.m_Timer.stopDrag();
		m_TimerPos.x = m_Timer.m_Timer._x;
		m_TimerPos.y = m_Timer.m_Timer._y;

	}
	private function ClearTimer() {
		if (m_Timer) {
			m_Timer.StopTimer();
			m_TimerPos = m_Timer.ClearTimer();
		}
	}
	private function RemoveTimer() {
		m_Timer = undefined;
	}
	private function FinishRun() {
		ClearTimer();
		var Final:Date = new Date();
		var FinalTime = Final.valueOf();
		var Elapsed = (FinalTime-StartTime) / 1000;
		Feedback("Finished at " + Elapsed + "s");
		StartTime = undefined;
		ManualSave();
	}

//Feedback
	private function Feedback(str) {
		com.GameInterface.UtilsBase.PrintChatText(string(str));
		LogBase.Error("SpeedRun", str);
	}
	private function PrintTime(Goal:String) {
		var current:Date = new Date();
		var currentTime = current.valueOf();
		var Elapsed = (currentTime-StartTime) / 1000;
		Elapsed = Math.round(Elapsed) ;
		if (Goal) {
			if (Elapsed) Feedback(Goal + " " +string(Elapsed) + "s");
			else Feedback(Goal);
		} else Feedback(string(Elapsed) + "s");
	}

//Mission Signals
	private function SlotTaskAdded(QuestID) {
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, true, true);
		if (IsChallenge(QuestID)) return;
		var Str = string(QuestID) + m_quest.m_CurrentTask.m_ID + m_quest.m_CurrentTask.m_Tier + m_quest.m_CurrentTask.m_CurrentPhase;
		if (Str == m_Start) {
			StartTimer(QuestID);
		}
		if (Debug.GetValue()) {
			Feedback("Task added \"" + Str+"\"");
		}
	}
	private function SlotQuestProgressed(QuestID:Number, goalID:Number, SolvedTimes:Number, RepeatCount:Number ) {
		var ProgressStr = string(QuestID) + goalID + SolvedTimes + RepeatCount;
		var m_quest:Quest = QuestsBase.GetQuest(QuestID, false, true);
		if (IsChallenge(QuestID)) return;
		if (ProgressStr == m_Start) {
			StartTimer(QuestID);
		} else if (m_Start.indexOf(string(QuestID)) != 1 && m_Start && QuestID) {
			PrintTime(LDBFormat.LDBGetText(50304, goalID));
		}
		if (ProgressStr == m_End) {
			FinishRun();
		}
		if (Debug.GetValue()) {
			Feedback("Quest progress on "+m_quest.m_MissionName+" " +"\""+ProgressStr+"\"");
		}
	}
	private function SloQuestCompleted(QuestID) {
		if (IsChallenge(QuestID)) return;
		if (string(QuestID) == m_End) {
			FinishRun();
		}
		if (Debug.GetValue()) {
			Feedback("Quest completed  " + QuestID);
		}
	}
}