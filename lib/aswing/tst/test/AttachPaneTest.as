import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.border.LineBorder;
import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.Component;
import GUI.fox.aswing.FlowLayout;
import GUI.fox.aswing.JAttachPane;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JLabel;
import GUI.fox.aswing.JLoadPane;
import GUI.fox.aswing.JPanel;
import GUI.fox.aswing.util.Delegate;
/**
 * @author iiley
 */
class test.AttachPaneTest extends JFrame{
	private var topPane:JAttachPane;
	private var centerPane:JAttachPane;
	private var statusLabel:JLabel;
	private var jpgs:Array;
	private var jpgIndex:Number;
	
	public function AttachPaneTest() {
		super("AttachPaneTest");
		jpgIndex = 0;
		jpgs = ["pic1","pic2","pic3", "fds"];
		
		topPane = new JAttachPane("pic1");
		topPane.setPreferredSize(500, 40);
		topPane.setScaleMode(JLoadPane.SCALE_STRETCH_PANE);
		topPane.setLayout(new FlowLayout(FlowLayout.CENTER));
		topPane.append(new JButton("a button on animation swf"));
		centerPane = new JAttachPane(jpgs[0], JLoadPane.PREFER_SIZE_BOTH);
		centerPane.setLayout(new FlowLayout(FlowLayout.CENTER));
		//centerPane.setScaleImage(true);
		centerPane.setHorizontalAlignment(JLoadPane.CENTER);
		centerPane.setVerticalAlignment(JLoadPane.CENTER);
		centerPane.setBorder(new LineBorder(null, ASColor.BLACK, 2));
		
		getContentPane().append(topPane, BorderLayout.NORTH);
		getContentPane().append(centerPane, BorderLayout.CENTER);
		
		var preButton:JButton = new JButton("prev");
		preButton.addActionListener(Delegate.create(this, changePic, -1));
		preButton.setLocation(5, 100);
		preButton.setSize(preButton.getPreferredSize());
		//preButton.setIcon(new LoadIcon("1.jpg", 100, 20));
		var nexButton:JButton = new JButton("next");
		nexButton.addActionListener(Delegate.create(this, changePic, 1));
		nexButton.setLocation(5, 130);
		nexButton.setSize(nexButton.getPreferredSize());
		
		centerPane.append(preButton);
		centerPane.append(nexButton);
		
		statusLabel = new JLabel("not loaded any thing yet");
		var bottomPane:JPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
		bottomPane.append(statusLabel);
		getContentPane().append(bottomPane, BorderLayout.SOUTH);
	}
	
	private function changePic(source:Component, dir:Number):Void{
		jpgIndex += dir;
		jpgIndex = (jpgIndex + jpgs.length)%jpgs.length;
		centerPane.setPath(jpgs[jpgIndex]);
		pack();
	}
	
	public static function main():Void{
		Stage.scaleMode = "noScale";
		try{
			trace("try AttachPaneTest");
			var p:AttachPaneTest = new AttachPaneTest();
			p.setSize(400, 400);
			p.show();
			trace("done AttachPaneTest");
		}catch(e){
			trace("error : " + e);
		}
	}
	
}