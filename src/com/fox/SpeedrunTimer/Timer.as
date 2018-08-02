import com.GameInterface.QuestsBase;
import com.Utils.Draw;
import com.Utils.LDBFormat;
import com.Utils.Signal;
import com.fox.Utils.Common;
import flash.geom.Point;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */
class com.fox.SpeedrunTimer.Timer {
	private var m_swfRoot:MovieClip;
	public var m_Timer:MovieClip;
	private var m_TimerContent:MovieClip;
	private var TimerPos:Point;
	private var StartTime:Number;
	private var Counter:TextField;
	private var UpdateInterval;
	public var SignalClear:Signal;
	private var SectionFormat:TextFormat;
	private var HeaderFormat:TextFormat;
	private var m_SectionClip:MovieClip;
	private var Entries:Array;
	private var EndValue:String;
	public var running:Boolean;

	public function Timer(root:MovieClip, pos:Point,end:String) {
		TimerPos = pos;
		m_swfRoot = root;
		SignalClear = new Signal();
		SectionFormat = new TextFormat("src.asset.FuturaMD_BT.ttf", 14, 0xFFFFFF, false, false, false, null, null, "left");
		HeaderFormat = new TextFormat("src.asset.FuturaMD_BT.ttf", 14, 0xFFFFFF, false, false, false, null, null, "center");
		EndValue = end;
	}

	public function SetTitle(val:String) {
		if (val.length > 4) val = val.slice(0, 4);
		m_TimerContent.Title.text = QuestsBase.GetQuest(Number(val), false, true).m_MissionName;
	}

	public function CreateTimer() {
		if (m_Timer) {
			clearInterval(UpdateInterval);
			m_Timer.removeMovieClip();
		}
		Entries = new Array();
		m_Timer = m_swfRoot.createEmptyMovieClip("m_Timer", m_swfRoot.getNextHighestDepth());
		var bg = m_Timer.createEmptyMovieClip("BG", m_Timer.getNextHighestDepth());
		m_TimerContent = m_Timer.createEmptyMovieClip("m_TimerContent", m_Timer.getNextHighestDepth());
		var Closebutton:MovieClip = m_Timer.attachMovie("src.asset.CloseButton.png", "Close", m_Timer.getNextHighestDepth());

		Closebutton._alpha = 80;
		m_TimerContent._x = 5;
		m_TimerContent._y = 5;
		m_Timer._x = TimerPos.x;
		m_Timer._y = TimerPos.y;

		Counter = m_TimerContent.createTextField("Counter", m_TimerContent.getNextHighestDepth(), 0, 6, 140, 60);
		var format:TextFormat = new TextFormat("src.asset.Russell Square Regular.ttf", 34, 0xFFFFFF, false, false, false, null, null, "center");
		Counter.setTextFormat(format);
		Counter.setNewTextFormat(format);
		Counter.selectable = false;
		Counter.embedFonts = true;
		Counter.autoFit = true;
		Counter.text = "00:00";

		bg.onPress = Delegate.create(this, OnPress);
		bg.onRelease = Delegate.create(this, OnRelease);
		bg.onReleaseOutside = Delegate.create(this, OnRelease);

		Closebutton.onPress = Delegate.create(this, function() {
			this.SignalClear.Emit();
		});
		RedrawBG();
		var Title:TextField = m_TimerContent.createTextField("Title", m_TimerContent.getNextHighestDepth(), Counter._x + Counter._width + 10, Counter._y + 5, 200, 60);
		Title.embedFonts = true;
		Title.multiline = true;
		Title.autoSize = "left";
		Title.wordWrap = true;
		Title.selectable = false;
		Title.setNewTextFormat(SectionFormat);
		SetTitle(EndValue);
		CreateHeader();
		CheckOverFlow();
	}

	private function OnPress() {
		m_Timer.startDrag();
	}
	private function OnRelease() {
		m_Timer.stopDrag();
		CheckOverFlow();
		TimerPos.x = m_Timer._x;
		TimerPos.y = m_Timer._y;
	}

	public function GetTimer() {return m_Timer};

	private function DrawDivider(id:String, clip1:TextField, clip2:TextField ) {
		var div:MovieClip = m_SectionClip.Header.Dividers;
		div[id].removeMovieClip();
		var Div:MovieClip =  div.createEmptyMovieClip(id, div.getNextHighestDepth());
		Div.lineStyle(2, 0xFFFFFF, 80);
		var startX = clip2._x - 10;
		Div.moveTo(startX, clip1._y);
		Div.lineTo(startX,m_SectionClip.Entries._height);
	}

	private function CreateHeader() {
		m_SectionClip = m_TimerContent.createEmptyMovieClip("SectionTimes", m_TimerContent.getNextHighestDepth());
		var Header:MovieClip = m_SectionClip.createEmptyMovieClip("Header", m_SectionClip.getNextHighestDepth());
		var EntryClips:MovieClip = m_SectionClip.createEmptyMovieClip("Entries", m_SectionClip.getNextHighestDepth());

		var Goal:TextField = Header.createTextField("Goal", Header.getNextHighestDepth(),0,0,50,20);
		var Time:TextField  = Header.createTextField("Time", Header.getNextHighestDepth(),200,0,50,20);
		var BestTime:TextField  = Header.createTextField("BestTime", Header.getNextHighestDepth(),250,0,50,20);
		var Diff:TextField  = Header.createTextField("Diff", Header.getNextHighestDepth(), 300, 0,50,20);

		Goal.embedFonts = true;
		Time.embedFonts = true;
		BestTime.embedFonts = true;
		Diff.embedFonts = true;

		Goal.setNewTextFormat(SectionFormat);
		Time.setNewTextFormat(HeaderFormat);
		BestTime.setNewTextFormat(HeaderFormat);
		Diff.setNewTextFormat(HeaderFormat);

		Goal.selectable = false;
		Time.selectable = false;
		BestTime.selectable = false;
		Diff.selectable = false;

		Goal.text = "Goal";
		Time.text = "Time";
		BestTime.text = "Best";
		Diff.text = "+/-";

		Header.lineStyle(2, 0xFFFFFF, 80);
		Header.moveTo(Goal._x, Goal._y+Goal._height+3);
		Header.lineTo(Diff._x + Diff._width,  Goal._y + Goal._height + 3);

		Header._y = Counter._y + Counter._height;
		EntryClips._y = Header._y + Header._height + 5;
	}

	private function CreateSectionEntry(key:String, newEntry:Boolean) {
		var m_QuestID = key.slice(0, 4);
		var m_TierID = key.slice(4, 9);
		var TierText:String;
		TierText = LDBFormat.LDBGetText("QuestGoalNames", Number(m_TierID));
		if (!TierText) {
			m_TierID = key.slice(4, 8);
			TierText = LDBFormat.LDBGetText("QuestGoalNames", m_TierID);
		}
		if (!TierText) TierText = key.split("_")[0];
		var time = key.split("_")[1];

		var EntriesBase:MovieClip = m_SectionClip.Entries;
		var Entry:MovieClip = EntriesBase.createEmptyMovieClip(key.split("_")[0], EntriesBase.getNextHighestDepth());
		Entry.msTime = time;
		Entry._y = Entries.length * 20;

		var Goal:TextField  = Entry.createTextField("Goal", Entry.getNextHighestDepth(), 0, 0, 180, 20);
		var Time:TextField  = Entry.createTextField("Time", Entry.getNextHighestDepth(), 200, 0, 60, 20);
		var Best:TextField  = Entry.createTextField("Best", Entry.getNextHighestDepth(), 250, 0, 60, 20);
		var Diff:TextField  = Entry.createTextField("Diff", Entry.getNextHighestDepth(), 300, 0, 60, 20);

		Goal.embedFonts = true;
		Goal.setNewTextFormat(SectionFormat);
		Goal.selectable = false;
		Goal.text = TierText;
		
		var BG:MovieClip = Entry.createEmptyMovieClip("BG", Entry.getNextHighestDepth());
		Draw.DrawRectangle(BG, Goal._x, Goal._y, 360, 20, 0xFFFFFF, 20,[2,2,2,2]);
		BG._visible = false;

		Time.embedFonts = true;
		Time.setNewTextFormat(SectionFormat);
		Time.selectable = false;
		if (newEntry) Time.text = com.Utils.Format.Printf( "%02.0f:%02.0f", Math.floor(time / 60000), Math.floor(time / 1000) % 60);

		Best.embedFonts = true;
		Best.setNewTextFormat(SectionFormat);
		Best.selectable = false;
		Best.text =  com.Utils.Format.Printf( "%02.0f:%02.0f", Math.floor(time / 60000), Math.floor(time / 1000) % 60 );

		Diff.embedFonts = true;
		Diff.setNewTextFormat(SectionFormat);
		Diff.selectable = false;
		if (newEntry) Diff.text = " 00:00";
		Entries.push(Entry);
		RedrawBG();
	}

	public function DisplayFinalTime(time:Number) {
		var TimeString = com.Utils.Format.Printf( "%02.0f:%02.0f", Math.floor(time / 60000), Math.floor(time / 1000) % 60 );
		m_TimerContent.Title.text += "\n"+TimeString +" (" + time/1000+"s)";
		RedrawBG();
	}

	private function RedrawBG() {
		m_Timer.BG.clear();
		var height = 0;
		for (var i in Entries){
			if (Entries[i]._visible) height += 20;
		}
		if (height) Draw.DrawRectangle(m_Timer.BG, 0, 0,  m_TimerContent._width + 10, height + 115, 0x000000, 40, [5, 5, 5, 5], 3);
		else Draw.DrawRectangle(m_Timer.BG, 0, 0,  370, 100, 0x000000, 40, [5, 5, 5, 5], 3);

		m_Timer.Close._x = m_Timer.BG._width -20;
		m_Timer.Close._y = m_Timer.BG._y +5;
		CheckOverFlow();
	}

	public function CheckOverFlow() {
		var newPos:Point = Common.getOnScreen(m_Timer);
		m_Timer._x = newPos.x;
		m_Timer._y = newPos.y;
	}

	public function SetArchieve(Data:Array) {
		for (var i in Entries){
			Entries[i].removeMovieClip();
		}
		var SortedList:Array = new Array();
		for (var i:Number = 0; i < Data.length; i++) {
			var Entry = Data[i].split("_");
			if(Entry[0] != "Finished")	SortedList.push({Tier:Entry[0],Time:Entry[1]});
		}
		SortedList.sortOn("Time", Array.NUMERIC);
		for (var i:Number = 0; i < SortedList.length; i++) {
			CreateSectionEntry(SortedList[i]["Tier"]+"_"+SortedList[i]["Time"]);
		}
		SetScroll(0);
		RedrawBG();
	}
	
	private function SetScroll(index){
		var Changed;
		for (var i = 0; i < Entries.length; i++){
			if (i + 2 < index || i > index + 4){
				Changed = true;
				Entries[i]._visible = false;
				// so that CheckOverFlow() doesn't freak out:
				Entries[i]._y = 0;
			}
			else if(!Entries[i]._visible){
				Changed = true;
				Entries[i]._visible = true;
			}
		}
		if (Changed){
			var yPos = 0;
			var ActiveSet;
			for (var i = 0; i < Entries.length; i++){
				if (i == index + 1 && !ActiveSet){
					Entries[i].BG._visible = true;
				}
				else if (index == 0 && i == 0 && !ActiveSet) {
					if (!Entries[i].Diff.text){
						Entries[i].BG._visible = true;
						ActiveSet = true;
					}else{
						Entries[i].BG._visible = false;
					}
				}
				else Entries[i].BG._visible = false;
				
				if (Entries[i]._visible){
					Entries[i]._y = yPos;
					yPos += 20;
				}
			}
		}
	}

	public function SetTierTime(key, time) {
		if(key == "Finished") return
		var Found;
		for (var i in Entries) {
			var Entry:MovieClip = Entries[i];
			if (Entry._name == key) {
				Found = i;
				Entry.Time.text = com.Utils.Format.Printf( "%02.0f:%02.0f", Math.floor(time / 60000), Math.floor(time / 1000) % 60);
				if (Entry.Time.text && Entry.Best.text) {
					var difference = Math.floor((Entry.msTime-time) / 1000);
					if (difference > 0) {
						Entry.Diff.textColor = 0x00C60F;
						Entry.Diff.text = "-"+com.Utils.Format.Printf( "%02.0f:%02.0f", Math.floor(difference / 60), Math.floor(difference % 60));
					} else if (difference < 0) {
						Entry.Diff.textColor = 0xC60000;
						Entry.Diff.text = "+"+com.Utils.Format.Printf( "%02.0f:%02.0f", Math.abs(difference / 60), Math.floor(Math.abs(difference) % 60));
					} else {
						Entry.Diff.textColor = 0xFFFFFF;
						Entry.Diff.text = " 00:00";
					}
				}
			}
		}
		if (!Found) {
			CreateSectionEntry(key + "_" + time, true);
			Found = Entries.length - 1;
		}
		SetScroll(Number(Found));
		SetTitle(key);
		RedrawBG();
	}

	public function SetStartTime(value:Number) {
		Entries = new Array();
		StartTime = value;
		clearInterval(UpdateInterval);
		UpdateInterval = setInterval(Delegate.create(this, UpdateTime), 500);
		running = true;
	}

	private function  UpdateTime() {
		var current:Date = new Date();
		var currentTime = current.valueOf();
		var Elapsed = currentTime-StartTime;
		Counter.text = com.Utils.Format.Printf( "%02.0f:%02.0f", Math.floor(Elapsed / 60000), Math.floor(Elapsed/1000) % 60 );
	}

	public function StopTimer() {
		clearInterval(UpdateInterval);
		running = false;
		for (var i = 0; i < Entries.length; i++){
			Entries[i]._visible = true;
			Entries[i]._y = i*20;
		}
		RedrawBG();
	}

	public function ClearTimer() {
		StopTimer();
		m_Timer.removeMovieClip();
	}

	public function getTimerPos() {
		return TimerPos;
	}

}