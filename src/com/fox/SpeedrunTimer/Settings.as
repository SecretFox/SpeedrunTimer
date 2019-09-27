import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.ASTextFormat;
import GUI.fox.aswing.DefaultListSelectionModel;
import GUI.fox.aswing.GridLayout;
import GUI.fox.aswing.Icon;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JCheckBox;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JList;
import GUI.fox.aswing.JPanel;
import GUI.fox.aswing.JScrollBar;
import GUI.fox.aswing.JScrollPane;
import GUI.fox.aswing.JTextField;
import GUI.fox.aswing.SoftBoxLayout;
import GUI.fox.aswing.border.BevelBorder;
import GUI.fox.aswing.border.LineBorder;
import com.GameInterface.DistributedValueBase;
import com.fox.SpeedrunTimer.Mod;
import com.fox.SpeedrunTimer.Uploader;
import flash.geom.Point;
import mx.utils.Delegate;

class com.fox.SpeedrunTimer.Settings extends JFrame {
	private var m_Mod:Mod;
	private var winPos:Point
	
	private var updateChecker:Uploader;
	
	private var scrollPane:JScrollPane;
	private var Listbox:JList;
	private var ListBoxContent:Object;
	
	private var AutoSetCheckBox:JCheckBox;
	private var AutoUploadCheckbox:JCheckBox;
	private var ZoneCheckbox:JCheckBox;
	private var DebugCheckBox:JCheckBox;
	private var IgnoreSides:JCheckBox;
	
	private var tf1:JTextField;
	private var FadeInterval:Number;
	
	private var UploadButton:JButton;
	private var UploadAllButton:JButton;
	private var ActivateButton:JButton;
	private var ShowButton:JButton;
	private var DeleteButton:JButton;
	private var UpdateCheckButton:JButton;
	
	public function Settings(that:Mod,pos:Point) {
		super("Speedrun");
		m_Mod = that;
	//window config
		winPos = pos;
		setLocation(pos.x, pos.y);
		setBorder(new BevelBorder(undefined, BevelBorder.RAISED, new ASColor(0xD8D8D8), new ASColor(0x7C7C7C), new ASColor(0x000000), new ASColor(0x373737), 3));
		var icon:Icon = new Icon();//Empty icon
		setIcon(icon);
		setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
	//content
		var content:JPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.Y_AXIS, 5));
	//scrolling
		scrollPane = new JScrollPane(GetListBox(),JScrollPane.SCROLLBAR_ALWAYS);
		scrollPane.setBorder(new LineBorder());
		content.append(scrollPane);
		
	//checkboxes
		var CheckboxPane:JPanel = new JPanel();
		
		CheckboxPane.append(GetDebugCheckBox());
		CheckboxPane.append(GetAutoSetCheckBox());
		CheckboxPane.append(GetAutoUploadCheckBox());
		CheckboxPane.append(GetZoneCheckBox());
		CheckboxPane.append(GetIgnoreSides());
		
		ZoneCheckbox.setSelected(m_Mod.DValAllZones.GetValue());
		DebugCheckBox.setSelected(m_Mod.DValDebug.GetValue());
		AutoSetCheckBox.setSelected(m_Mod.DValAutoSet.GetValue());
		AutoUploadCheckbox.setSelected(m_Mod.DValAutoUpload.GetValue());
		IgnoreSides.setSelected(m_Mod.DValIgnoreSides.GetValue());
		
		ZoneCheckbox.addActionListener(__ZoneChanged, this);
		DebugCheckBox.addActionListener(__DebugChanged, this);
		AutoSetCheckBox.addActionListener(__AutoSetChanged, this);
		AutoUploadCheckbox.addActionListener(__AutoUploadChanged, this);
		IgnoreSides.addActionListener(__IgnoreChanged, this);
		
		content.append(CheckboxPane);
	//text fields
		var FeedbackPane:JPanel = new JPanel();
		var textPane:JPanel = new JPanel();
		tf1 = new JTextField("", 30);
		var tf2:JTextField = new JTextField("", 3);
		tf2.setText(m_Mod.DValVisibleEntries.GetValue());
		tf2.setRestrict("0123456789");
		tf2.addEventListener(JTextField.ON_TEXT_CHANGED, __SplitChanged, this);
		tf2.setFocusable(false);

		var tf3:JTextField = new JTextField("Split times", -1);
		
		tf3.setHeight(50);
		//tf3.setToolTipText("Amount of previous AND next split times shown on the timer");
		//tf2.setToolTipText("Amount of previous AND next split times shown on the timer");
		
		tf3.setBorder(null);
		tf1.setBorder(null);
		tf1.setEditable(false);
		tf3.setEditable(false);
		tf3.setEnabled(false);
		tf1.setEnabled(false);
		
		var format:ASTextFormat = tf3.getTextFormat();
		format.setAlign(ASTextFormat.RIGHT);
		tf3.setTextFormat(format);
		format.setAlign(ASTextFormat.CENTER);
		tf2.setTextFormat(format);
		
		FeedbackPane.append(tf1);
		textPane.append(tf3);
		textPane.append(tf2);
		content.append(FeedbackPane);
	//buttons
		var ButtonPane:JPanel = new JPanel(new GridLayout(4,2,5,5));
		ButtonPane.append(GetActivateButton());
		ButtonPane.append(GetShowButton());
		ButtonPane.append(GetUploadButton());
		ButtonPane.append(GetUploadAllButton());
		ButtonPane.append(GetDeleteButton());
		ButtonPane.append(textPane);//split times text entry
		ButtonPane.append(GetUpdateCheckButton());
	//button actions
		ActivateButton.addActionListener(__Activate, this);
		ShowButton.addActionListener(__Show, this);
		UploadButton.addActionListener(__Upload, this);
		UploadAllButton.addActionListener(__UploadAll, this);
		DeleteButton.addActionListener(__Delete, this);
		UpdateCheckButton.addActionListener(__Update, this);
		
		content.append(ButtonPane);
		setContentPane(content);

		var scrollbar:JScrollBar = scrollPane.getVerticalScrollBar();
		scrollbar.addEventListener(ON_PRESS, __startDragThumb, this);
		scrollbar.addEventListener(ON_RELEASE, __stopDragThumb, this);
		scrollbar.addEventListener(ON_RELEASEOUTSIDE, __stopDragThumb, this);
	//show window
		show();
		pack();
		bringToTopDepth();
	
	}
	// Replaces the default tryToClose function
	// Mod.as will grab window position and then calls for dispose()
	public function tryToClose():Void{
		DistributedValueBase.SetDValue("Speedrun_Settings", !DistributedValueBase.GetDValue("Speedrun_Settings"));	
	}
	// Mod.as will close the window after getting the window position
	private function __CloseWindow(){
		DistributedValueBase.SetDValue("Speedrun_Settings", !DistributedValueBase.GetDValue("Speedrun_Settings"));
	}
	public function getPos(){
		return new Point(getX(), getY());
	}
	
//Helper func
	public function __SetText(text){
		tf1.setText(text);
		tf1.setAlpha(100);
		clearInterval(FadeInterval);
		FadeInterval = setInterval(Delegate.create(this,Fadeout), 100);
	}
	private function Fadeout(){
		var alpha = tf1.getAlpha();
		if (alpha > 0){
			tf1.setAlpha(alpha - 2);
		}
		else{
			clearInterval(FadeInterval);
			//repaint();
		}
	}
	//Todo; custom cell factory with tooltips
	public function SetListData(Data:Object){
		ListBoxContent = Data;
		var arr:Array = new Array();
		for (var i in Data){
			arr.push(i);
		}
		Listbox.setListData(arr);
		
	}
	//workaround for thumb drag not working(unless dragging from the border)
	private function __startDragThumb(){
		scrollPane.getVerticalScrollBar().getUI()["__startDragThumb"]();
	}
	private function __stopDragThumb(){
		scrollPane.getVerticalScrollBar().getUI()["__stopDragThumb"]();
	}
//Checkbox actions
	private function __ZoneChanged(checkbox:JCheckBox){
		m_Mod.DValAllZones.SetValue(checkbox.isSelected());
		SetListData(m_Mod.GetRunsAsList(checkbox.isSelected()));
	}
	private function __DebugChanged(checkbox:JCheckBox){
		m_Mod.DValDebug.SetValue(checkbox.isSelected());
		SetListData(m_Mod.GetRunsAsList(ZoneCheckbox.isSelected()));
	}
	private function __AutoSetChanged(checkbox:JCheckBox){
		m_Mod.DValAutoSet.SetValue(checkbox.isSelected());
	}
	private function __AutoUploadChanged(checkbox:JCheckBox){
		m_Mod.DValAutoUpload.SetValue(checkbox.isSelected());
	}
	private function __IgnoreChanged(checkbox:JCheckBox){
		m_Mod.DValIgnoreSides.SetValue(checkbox.isSelected());
	}
	private function __IgnoreChanged2(){
		IgnoreSides.setSelected(m_Mod.DValIgnoreSides.GetValue());
	}
//Button actions
	private function __Activate(button:JButton){
		var selected = Listbox.getSelectedValue();
		if (selected){
			m_Mod.DValSet.SetValue(ListBoxContent[selected].split("|").join(","));
			__SetText(selected + " set as active");
		}
		
	}
	private function __Show(){
		var selected = Listbox.getSelectedValue();
		if (selected) m_Mod.ShowRun(ListBoxContent[selected]);
	}
	private function __Upload(){
		var selected = Listbox.getSelectedValue();
		if (selected) m_Mod.UploadByKey(ListBoxContent[selected],selected)
	}
	private function __UploadAll(){
		m_Mod.UploadAll()
	}
	private function __Delete(){
		var selected = Listbox.getSelectedValue();
		if (selected) {
			m_Mod.DeleteKey(ListBoxContent[selected]);
			__ZoneChanged(ZoneCheckbox);
		}
	}
	private function __Update(){
		__SetText("Checking for updates")
		if (!updateChecker){
			updateChecker = Uploader.create();
			updateChecker.TimedOut.Connect(__TimedOut, this);
			updateChecker.StartedUpload.Connect(__SetText, this);
			updateChecker.Uploaded.Connect(__CloseUpdateChecker, this);
		}
		updateChecker.CheckForUpdates();
	}
	private function __TimedOut():Void {
		__SetText("Timed out");
		__CloseUpdateChecker();
	}
	private function __CloseUpdateChecker(text):Void {
		if (text) __SetText(text);
		updateChecker.TimedOut.Disconnect(__TimedOut, this);
		updateChecker.StartedUpload.Disconnect(__SetText, this);
		updateChecker.Uploaded.Disconnect(__CloseUpdateChecker, this);
		updateChecker.CloseBrowser();

		updateChecker = undefined;
	}
//Textfield action
	private function __SplitChanged(field:JTextField){
		var input:String = field.getText();
		if (input.length > 2){
			input = "99";
			field.setText(input);
		}
		else if (!input){
			input = "0";
		}
		m_Mod.DValVisibleEntries.SetValue(Number(input));
		
	}
//Element creation
	private function GetListBox(){
		if (Listbox == null){
			Listbox = new JList();
			Listbox.setVisibleCellWidth(375);
			Listbox.setVisibleRowCount(7);
			Listbox.setSelectionMode(DefaultListSelectionModel.SINGLE_SELECTION);
		}
		return Listbox;
	}
	private function GetZoneCheckBox(){
		if (ZoneCheckbox == null){
			ZoneCheckbox = new JCheckBox("All zones");
			//ZoneCheckbox.setToolTipText("Whether all missions or missions from current zone should be shown");
			ZoneCheckbox.setSelected(true);
		}
		return ZoneCheckbox;
	}
	private function GetAutoSetCheckBox(){
		if (AutoSetCheckBox == null){
			AutoSetCheckBox = new JCheckBox("AutoSet");
			//AutoSetCheckBox.setToolTipText("Automatically start speedrun whenever new quest is picked");
			AutoSetCheckBox.setSelected(false);
		}
		return AutoSetCheckBox;
	}
	private function GetAutoUploadCheckBox(){
		if (AutoUploadCheckbox == null){
			AutoUploadCheckbox = new JCheckBox("AutoUpload");
			//AutoUploadCheckbox.setToolTipText("Automatically upload new highscores");
			AutoUploadCheckbox.setSelected(true);
		}
		return AutoUploadCheckbox;
	}
	private function GetDebugCheckBox(){
		if (DebugCheckBox == null){
			DebugCheckBox = new JCheckBox("Debug");
			//DebugCheckBox.setToolTipText("Print information about progressed missions to system chat channel\nThese values can then be used in _Set command");
			DebugCheckBox.setSelected(false);
		}
		return DebugCheckBox;
	}
	private function GetIgnoreSides(){
		if (IgnoreSides == null){
			IgnoreSides = new JCheckBox("Ignore sides");
			//DebugCheckBox.setToolTipText("Dont start timer for side missions");
			IgnoreSides.setSelected(true);
			m_Mod.DValIgnoreSides.SignalChanged.Connect(__IgnoreChanged2, this);
		}
		return IgnoreSides;
	}
	private function GetActivateButton(){
		if (ActivateButton == null){
			ActivateButton = new JButton("Activate");
			//ActivateButton.setToolTipText("Set selected run as active, next time you pick up the mission timer will start automatically");
		}
		return ActivateButton;
	}
	private function GetShowButton(){
		if (ShowButton == null){
			ShowButton = new JButton("View");
			//ShowButton.setToolTipText("View selected run");
		}
		return ShowButton;
	}
	private function GetUploadButton(){
		if (UploadButton == null){
			UploadButton = new JButton("Upload");
			//UploadButton.setToolTipText("Upload selected run");
		}
		return UploadButton;
	}
	private function GetUploadAllButton(){
		if (UploadAllButton == null){
			UploadAllButton = new JButton("Upload All");
			//UploadAllButton.setToolTipText("Upload all runs");
		}
		return UploadAllButton;
	}
	private function GetDeleteButton(){
		if (DeleteButton == null){
			DeleteButton = new JButton("Delete");
			//DeleteButton.setToolTipText("Delete selected run");
		}
		return DeleteButton;
	}
	private function GetUpdateCheckButton(){
		if (UpdateCheckButton == null){
			UpdateCheckButton = new JButton("Check for updates");
			//UpdateCheckButton.setToolTipText("Checks for updates");
		}
		return UpdateCheckButton;
	}
}