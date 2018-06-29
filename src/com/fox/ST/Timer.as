import com.GameInterface.Chat;
import com.Utils.Draw;
import com.Utils.Signal;
import flash.geom.Point;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */
class com.fox.ST.Timer {
	private var m_swfRoot:MovieClip;
	public var m_Timer:MovieClip;
	private var m_timerPos:Point;
	private var StartTime:Number;
	private var Counter:TextField;
	private var Update;
	private var Fadeout;
	public var SignalClear:Signal;

	public function Timer(root:MovieClip, pos:Point) {
		m_timerPos = pos;
		m_swfRoot = root;
		SignalClear = new Signal();
	}

	public function CreateTimer() {
		m_Timer = m_swfRoot.createEmptyMovieClip("m_Timer", m_swfRoot.getNextHighestDepth());
		m_Timer._x = m_timerPos.x;
		m_Timer._y = m_timerPos.y;
		var bg = m_Timer.createEmptyMovieClip("BG", m_Timer.getNextHighestDepth());
		Draw.DrawRectangle(bg, 0, 0, 120, 60, 0x000000, 80, [10, 10, 10, 10], 3, 0xFFFFFF, 80, true);
		Counter = m_Timer.createTextField("Counter", m_Timer.getNextHighestDepth(), 0, 6, 120, 60);
		var format:TextFormat = new TextFormat("src.asset.Russell Square Regular.ttf", 34, 0xFFFFFF, false, false, false, null, null, "center");
		Counter.setTextFormat(format);
		Counter.setNewTextFormat(format);
		Counter.selectable = false;
		Counter.embedFonts = true;
		Counter.autoFit = true;
		Counter.text = "00:00";
		setTimeout(Delegate.create(this, ShowFIFO), 5000);
	}

	private function ShowFIFO() {
		Chat.SignalShowFIFOMessage.Emit("Speed run started, Ctrl+R.Click timer to cancel", 0);
	}

	public function GetTimer() {return m_Timer};

	public function SetStartTime(value:Number) {
		StartTime = value;
		clearInterval(Update);
		Update = setInterval(Delegate.create(this, UpdateTime), 1000);
	}

	private function  UpdateTime() {
		var current:Date = new Date();
		var currentTime = current.valueOf();
		var Elapsed = (currentTime-StartTime) / 1000;
		var minuteNumber = Math.floor(Elapsed / 60);
		var minutes = string(minuteNumber);
		if (minutes.length == 1) minutes = "0" + minutes;
		var seconds:String = string(Math.round(Elapsed % 60));
		if (seconds.length == 1) seconds = "0" + seconds;
		Counter.text = minutes + ":" + seconds;
		if (minuteNumber > 59) {
			ClearTimer();
		}
	}

	public function StopTimer() {
		clearInterval(Update);
	}

	private function FadeOut() {
		m_Timer._alpha -= 1;
		if (m_Timer._alpha < 1) {
			clearInterval(Fadeout);
			m_Timer.removeMovieClip();
			SignalClear.Emit();
		}
	}

	public function RemoveTimer() {
		m_Timer.removeMovieClip();
		return m_timerPos;
	}

	public function ClearTimer() {
		clearInterval(Fadeout);
		Fadeout = setInterval(Delegate.create(this, FadeOut), 100);
		return m_timerPos;
	}

}