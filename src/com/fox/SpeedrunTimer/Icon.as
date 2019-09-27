import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.fox.Utils.Common;
import flash.geom.Point;
import mx.utils.Delegate;
import com.Utils.GlobalSignal;

class com.fox.SpeedrunTimer.Icon {
	private var m_swfRoot:MovieClip;
	private var m_Icon:MovieClip;
	private var DValIgnoreSides:DistributedValue;
	private var m_pos:Point;
	

	public function Icon(swfRoot: MovieClip) {
		m_swfRoot = swfRoot;
		DValIgnoreSides = DistributedValue.Create("Speedrun_IgnoreSides");
		DValIgnoreSides.SignalChanged.Connect(Tint, this);
	}
	
	public function Activate(pos:Point){
		m_pos = pos;
		if (!m_Icon) CreateTopIcon();
	}
	public function Unload(){
		m_Icon.removeMovieClip();
	}
	public function getPos(){
		return m_pos;
	}
	//Ghetto Guiedit
	private function GuiEdit(state:Boolean) {
		if (state) {
			m_Icon.onPress = Delegate.create(this,function ():Void {
				this.m_Icon.startDrag();
			});
			m_Icon.onRelease = Delegate.create(this,function ():Void {
				this.m_Icon.stopDrag();
			});
			m_Icon.onReleaseOutside = Delegate.create(this,function ():Void {
				this.m_Icon.stopDrag();
			});
		} else {
			m_Icon.stopDrag();
			m_Icon.onPress = Delegate.create(this, Toggle);
			m_Icon.onRelease = undefined;
			m_Icon.onReleaseOutside = undefined;
			m_pos = Common.getOnScreen(m_Icon);
			m_Icon._x = m_pos.x;
			m_Icon._y = m_pos.y;
		}
	}
	private function Toggle(){
		if (Key.isDown(Key.CONTROL)){
			DValIgnoreSides.SetValue(!DValIgnoreSides.GetValue());
			DValIgnoreSides.GetValue() ? Chat.SignalShowFIFOMessage.Emit("Ignoring side missions", 0) : Chat.SignalShowFIFOMessage.Emit("Timing side missions", 0);
		}else{
			DistributedValueBase.SetDValue("Speedrun_Settings", !DistributedValueBase.GetDValue("Speedrun_Settings"));
		}
		
	}
	private function Tint(dv:DistributedValue){
		dv.GetValue() ? m_Icon.gotoAndStop(1) : m_Icon.gotoAndStop(2);
	}
	private function CreateTopIcon():Void {
		m_Icon = m_swfRoot.attachMovie("modIcon", "m_Icon", m_swfRoot.getNextHighestDepth(), {_x:m_pos.x, _y:m_pos.y, _width:20, _height:20});
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		GuiEdit(false);
		Tint(DValIgnoreSides);
	}
}