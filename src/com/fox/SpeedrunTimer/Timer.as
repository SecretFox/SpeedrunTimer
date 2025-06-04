import com.GameInterface.DistributedValueBase;
import com.GameInterface.QuestsBase;
import com.GameInterface.Tooltip.TooltipUtils;
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
class com.fox.SpeedrunTimer.Timer
{
	static var SECTION_FORMAT:TextFormat = new TextFormat("_StandardFont", 14, 0xFFFFFF, false, false, false, null, null, "left");
	static var HEADER_FORMAT:TextFormat = new TextFormat("_StandardFont", 14, 0xFFFFFF, false, false, false, null, null, "center");
	static var SPLIT_FORMAT:TextFormat = HEADER_FORMAT;
	

	private var m_swfRoot:MovieClip;

	private var m_Timer:MovieClip;
	private var m_TimerContent:MovieClip;
	private var m_SectionClip:MovieClip;
	private var m_pos:Point;

	private var m_running:Boolean;
	private var m_startTime:Number;
	private var m_counter:TextField;
	public var m_currentIndex:Number;
	public var m_entries:Array;
	private var m_updateInterval:Number;

	public var SignalClear:Signal;
	public var SignalMoved:Signal;

	public function Timer(root:MovieClip, pos:Point)
	{
		m_pos = pos;
		m_swfRoot = root;
		SignalClear = new Signal();
		SignalMoved = new Signal();
		Mouse.addListener(this);
	}

	public function onMouseWheel(delta:Number)
	{
		var newScroll = delta < 0 ? m_currentIndex : m_currentIndex - 2;
		if (m_entries[newScroll]) SetScroll(newScroll);
	}

	public function SetTitle(val:String, overrideval:String)
	{
		if (!overrideval)
		{
			if (val.length > 4) val = val.slice(0, 4);
			m_TimerContent.Title.text = QuestsBase.GetQuest(Number(val), false, true).m_MissionName;
		}
		else
		{
			m_TimerContent.Title.text = overrideval;
		}
	}

	public function CreateTimer()
	{
		if (m_Timer)
		{
			clearInterval(m_updateInterval);
			m_Timer.removeMovieClip();
		}
		m_entries = new Array();
		m_currentIndex = 0;
		m_Timer = m_swfRoot.createEmptyMovieClip("m_Timer", m_swfRoot.getNextHighestDepth());
		var bg = m_Timer.createEmptyMovieClip("BG", m_Timer.getNextHighestDepth());
		m_TimerContent = m_Timer.createEmptyMovieClip("m_TimerContent", m_Timer.getNextHighestDepth());
		var Closebutton:MovieClip = m_Timer.attachMovie("src.assets.CloseButton.png", "Close", m_Timer.getNextHighestDepth());

		Closebutton._alpha = 80;
		m_TimerContent._x = 5;
		m_TimerContent._y = 5;
		m_Timer._x = m_pos.x;
		m_Timer._y = m_pos.y;

		m_counter = m_TimerContent.createTextField("m_counter", m_TimerContent.getNextHighestDepth(), 0, 6, 150, 60);
		var format:TextFormat = new TextFormat("_TimerFont", 34, 0xFFFFFF, false, false, false, null, null, "center");
		m_counter.setTextFormat(format);
		m_counter.setNewTextFormat(format);
		m_counter.selectable = false;
		m_counter.embedFonts = true;
		m_counter.autoFit = true;
		m_counter.text = "00:00";

		bg.onPress = Delegate.create(this, OnPress);
		bg.onRelease = Delegate.create(this, OnRelease);
		bg.onReleaseOutside = Delegate.create(this, OnRelease);

		Closebutton.onPress = Delegate.create(this, function()
		{
			this.SignalClear.Emit();
		});
		RedrawBG();
		var Title:TextField = m_TimerContent.createTextField("Title", m_TimerContent.getNextHighestDepth(), m_counter._x + m_counter._width + 10, m_counter._y + 5, 200, 60);
		Title.embedFonts = true;
		Title.multiline = true;
		Title.autoSize = "left";
		Title.wordWrap = true;
		Title.selectable = false;
		Title.setNewTextFormat(SECTION_FORMAT);
		CreateHeader();
		CheckOverFlow();
	}

	private function OnPress()
	{
		m_Timer.startDrag();
	}
	private function OnRelease()
	{
		m_Timer.stopDrag();
		CheckOverFlow();
		m_pos.x = m_Timer._x;
		m_pos.y = m_Timer._y;
		SignalMoved.Emit(m_pos);
	}

	public function GetTimer() {return m_Timer};

	private function DrawDivider(id:String, clip1:TextField, clip2:TextField )
	{
		var div:MovieClip = m_SectionClip.Header.Dividers;
		div[id].removeMovieClip();
		var Div:MovieClip =  div.createEmptyMovieClip(id, div.getNextHighestDepth());
		Div.lineStyle(2, 0xFFFFFF, 80);
		var startX = clip2._x - 10;
		Div.moveTo(startX, clip1._y);
		Div.lineTo(startX,m_SectionClip.m_entries._height);
	}

	private function CreateHeader()
	{
		m_SectionClip = m_TimerContent.createEmptyMovieClip("SectionTimes", m_TimerContent.getNextHighestDepth());
		var Header:MovieClip = m_SectionClip.createEmptyMovieClip("Header", m_SectionClip.getNextHighestDepth());
		var EntryClips:MovieClip = m_SectionClip.createEmptyMovieClip("m_entries", m_SectionClip.getNextHighestDepth());

		var Goal:TextField = Header.createTextField("Goal", Header.getNextHighestDepth(),0,0,50,20);
		var Time:TextField  = Header.createTextField("Time", Header.getNextHighestDepth(),200,0,60,20);
		var BestTime:TextField  = Header.createTextField("BestTime", Header.getNextHighestDepth(),270,0,60,20);
		var Diff:TextField  = Header.createTextField("Diff", Header.getNextHighestDepth(), 340, 0,60,20);

		Goal.embedFonts = true;
		Time.embedFonts = true;
		BestTime.embedFonts = true;
		Diff.embedFonts = true;

		Goal.setNewTextFormat(SECTION_FORMAT);
		Time.setNewTextFormat(HEADER_FORMAT);
		BestTime.setNewTextFormat(HEADER_FORMAT);
		Diff.setNewTextFormat(HEADER_FORMAT);

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

		Header._y = m_counter._y + m_counter._height;
		EntryClips._y = Header._y + Header._height + 5;
	}

	private function FormatTime(milliseconds: Number): String
	{
		var totalSeconds:Number = Math.floor(milliseconds / 1000);
		var hours:Number = Math.floor(totalSeconds / 3600);
		var minutes:Number = Math.floor((totalSeconds % 3600) / 60);
		var seconds:Number = totalSeconds % 60;

		var hourStr:String = hours > 0 ? (hours < 10 ? "0" : "") + hours + ":" : "";
		var minStr:String = (minutes < 10 ? "0" : "") + minutes;
		var secStr:String = (seconds < 10 ? "0" : "") + seconds;

		return hourStr + minStr + ":" + secStr;
	}

	private function CreateSectionEntry(key:String, newEntry:Boolean)
	{
		var QuestKey = key.split("_")[0];
		var time = key.split("_")[1];

		var m_QuestID = QuestKey.slice(0, 4);// always 4
		var m_QuestGoalID:String = QuestKey.slice(4, -2);// Last two are SolvedCount/RepeatTimes
		if (m_QuestGoalID.length > 5) m_QuestGoalID = m_QuestGoalID.slice(0, -2); // double digit SolvedCount/RepeatTimes. QuestGoalID should always be 4 or 5 numbers
		var TierText:String;
		TierText = LDBFormat.LDBGetText("QuestGoalNames", Number(m_QuestGoalID));
		if (!TierText) TierText = key.split("_")[0];

		var m_entriesBase:MovieClip = m_SectionClip.m_entries;
		var Entry:MovieClip = m_entriesBase.createEmptyMovieClip(QuestKey, m_entriesBase.getNextHighestDepth());
		Entry.msTime = time;
		Entry._y = m_entries.length * 20;

		var Goal:TextField  = Entry.createTextField("Goal", Entry.getNextHighestDepth(), 0, 0, 200, 20);
		var Time:TextField  = Entry.createTextField("Time", Entry.getNextHighestDepth(), 200, 0, 70, 20);
		var Best:TextField  = Entry.createTextField("Best", Entry.getNextHighestDepth(), 270, 0, 70, 20);
		var Diff:TextField  = Entry.createTextField("Diff", Entry.getNextHighestDepth(), 340, 0, 70, 20);

		Goal.embedFonts = true;
		Goal.setNewTextFormat(SECTION_FORMAT);
		Goal.selectable = false;
		Goal.text = TierText;

		var BG:MovieClip = Entry.createEmptyMovieClip("BG", Entry.getNextHighestDepth());
		Draw.DrawRectangle(BG, Goal._x, Goal._y, 390, 20, 0xFFFFFF, 20,[2,2,2,2]);
		BG._visible = false;

		Time.embedFonts = true;
		Time.setNewTextFormat(HEADER_FORMAT);
		Time.selectable = false;
		if (newEntry) Time.text = FormatTime(time);

		Best.embedFonts = true;
		Best.setNewTextFormat(HEADER_FORMAT);
		Best.selectable = false;
		Best.text = FormatTime(time);

		Diff.embedFonts = true;
		Diff.setNewTextFormat(HEADER_FORMAT);
		Diff.selectable = false;
		if (newEntry) Diff.text = " 00:00";
		m_entries.push(Entry);
		RedrawBG();
		TooltipUtils.AddTextTooltip(Entry, Goal.text, Goal.textWidth, undefined, true);
	}

	public function DisplayFinalTime(time:Number)
	{
		if (time)
		{
			var TimeString = FormatTime(time);
			m_TimerContent.Title.text += "\n" + TimeString +" (" + time / 1000 + "s)";
			m_counter.text = TimeString;
		}
		else
		{
			time = m_entries[m_entries.length - 1].msTime;
			var TimeString = FormatTime(time);
			m_TimerContent.Title.text += "\n" + TimeString +" (" + time / 1000 + "s)";
			m_counter.text = TimeString;
		}
		RedrawBG();
	}

	private function RedrawBG()
	{
		m_Timer.BG.clear();
		var height = 0;
		for (var i in m_entries)
		{
			if (m_entries[i]._visible) height += 20;
		}
		if (height) Draw.DrawRectangle(m_Timer.BG, 0, 0,  m_TimerContent._width + 10, height + 115, 0x000000, 40, [5, 5, 5, 5], 3);
		else Draw.DrawRectangle(m_Timer.BG, 0, 0,  420, 100, 0x000000, 40, [5, 5, 5, 5], 3);

		m_Timer.Close._x = m_Timer.BG._width - 20;
		m_Timer.Close._y = m_Timer.BG._y +5;
		CheckOverFlow();
	}

	public function CheckOverFlow()
	{
		var newPos:Point = Common.getOnScreen(m_Timer);
		m_Timer._x = newPos.x;
		m_Timer._y = newPos.y;
	}

	public function SetArchieve(Data:Array)
	{
		for (var i in m_entries)
		{
			m_entries[i].removeMovieClip();
		}
		m_entries = new Array();
		var SortedList:Array = new Array();
		for (var i:Number = 0; i < Data.length; i++)
		{
			var Entry = Data[i].split("_");
			if (Entry[0] != "Finished")	SortedList.push({Tier:Entry[0],Time:Entry[1]});
		}
		SortedList.sortOn("Time", Array.NUMERIC);
		for (var i:Number = 0; i < SortedList.length; i++)
		{
			CreateSectionEntry(SortedList[i]["Tier"]+"_"+SortedList[i]["Time"]);
		}
		SetScroll(0);
	}

	public function SetScroll(indexs:Number)
	{
		var index = m_entries[indexs + 1] ? indexs + 1:indexs;
		m_currentIndex = index;
		for (var i = 0; i < m_entries.length; i++)
		{
			m_entries[i]._visible = false;
			m_entries[i]._y = 0;
		}
		var m_entriesShown = DistributedValueBase.GetDValue("Speedrun_VisibleEntries");
		if (isNaN(m_entriesShown))
		{
			m_entriesShown = 2;
			DistributedValueBase.SetDValue("Speedrun_VisibleEntries", 2);
			return
		}
		m_entries[index]._visible = true;
		for (var i = 1; i <= m_entriesShown; i++ )
		{
			var clip:MovieClip = m_entries[index - i];
			if (!clip)
			{
				for (var y = 1; y <= m_entriesShown; y++)
				{
					clip =  m_entries[index + m_entriesShown + y];
					if (!clip._visible)
					{
						clip._visible = true;
						break
					}
				}
			}
			clip._visible = true;
			clip = m_entries[index + i];
			if (!clip)
			{
				for (var y = 1; y <= m_entriesShown; y++)
				{
					clip =  m_entries[index - m_entriesShown - y];
					if (!clip._visible)
					{
						clip._visible = true;
						break
					}
				}
			}
			clip._visible = true;
		}

		var yPos = 0;
		var ActiveSet;
		for (var i = 0; i < m_entries.length; i++)
		{
			m_entries[i].BG._visible = false;
			if (!m_entries[i].Time.text && !ActiveSet)
			{
				m_entries[i].BG._visible = true;
				ActiveSet = true;
			}
			if (m_entries[i]._visible)
			{
				m_entries[i]._y = yPos;
				yPos += 20;
			}
		}
		RedrawBG();
	}

	public function SetTierTime(key, time)
	{
		if (key == "Finished") return;
		var Found;
		for (var i = 0; i < m_entries.length; i++)
		{
			var Entry:MovieClip = m_entries[i];
			if (Entry._name == key)
			{
				Found = i;
				Entry.Time.text = FormatTime(time);
				if (Entry.Time.text && Entry.Best.text)
				{
					var difference = Math.round((Entry.msTime-time) / 1000);
					if (difference > 0)
					{
						Entry.Diff.textColor = 0x00C60F;
						Entry.Diff.text = "-" + FormatTime(difference);
					}
					else if (difference < 0)
					{
						Entry.Diff.textColor = 0xC60000;
						Entry.Diff.text = "+" + FormatTime(difference);
					}
					else
					{
						Entry.Diff.textColor = 0xFFFFFF;
						Entry.Diff.text = " 00:00";
					}
				}
			}
		}
		if (Found == undefined)
		{
			CreateSectionEntry(key + "_" + time, true);
			Found = m_entries.length - 1;
		}

		SetScroll(Number(Found));
		SetTitle(key);
		RedrawBG();
	}

	public function SetStartTime(value:Number)
	{
		m_startTime = value;
		clearInterval(m_updateInterval);
		m_updateInterval = setInterval(Delegate.create(this, UpdateTime), 500);
		m_running = true;
		Mouse.addListener(this);
		UpdateTime();
	}

	public function Running() : Boolean
	{
		return m_running;
	}

	private function UpdateTime():Void
	{
		var current:Date = new Date();
		var currentTime:Number = current.valueOf();
		var elapsed:Number = currentTime - m_startTime;
		m_counter.text = FormatTime(elapsed)
	}

	public function PauseTimer()
	{
		clearInterval(m_updateInterval);
		SetTitle(undefined, "Paused");
	}
	public function ResumeTimer()
	{
		clearInterval(m_updateInterval);
		m_updateInterval = setInterval(Delegate.create(this, UpdateTime), 500);
		SetTitle(m_entries[m_currentIndex]._name);
	}
	public function StopTimer()
	{
		clearInterval(m_updateInterval);
		Mouse.removeListener(this);
		m_running = false;
		for (var i = 0; i < m_entries.length; i++)
		{
			m_entries[i]._visible = true;
			m_entries[i]._y = i * 20;
		}
		RedrawBG();
	}

	public function ClearTimer()
	{
		clearInterval(m_updateInterval);
		m_running = false;
		m_Timer.removeMovieClip();
	}
}