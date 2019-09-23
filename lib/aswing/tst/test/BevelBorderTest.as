import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.border.BevelBorder;
import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.Container;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JPanel;

/**
 * @author iiley
 */
class test.BevelBorderTest extends JFrame {
	
	public function BevelBorderTest() {
		super("LevelBorderTest");
		
		var pane:Container = getContentPane();
		pane.setLayout(new BorderLayout(5, 5));
		pane.append(new JButton("---"), BorderLayout.NORTH);
		pane.append(new JButton("---"), BorderLayout.SOUTH);
		pane.append(new JButton("|\n|\n|"), BorderLayout.EAST);
		pane.append(new JButton("|\n|\n|"), BorderLayout.WEST);
		
		var center:JPanel = new JPanel();
		center.setBorder(new BevelBorder(null, BevelBorder.LOWERED));
		center.setBackground(ASColor.GRAY);
		pane.append(center, BorderLayout.CENTER);
	}

	public static function main():Void{
		Stage.scaleMode = "noScale";
		Stage.align = "T";
		try{
			trace("try LevelBorderTest");
			
			var p:BevelBorderTest = new BevelBorderTest();
			p.setLocation(50, 50);
			p.setSize(400, 400);
			p.show();
			trace("done LevelBorderTest");
		}catch(e){
			trace("error : " + e);
		}
	}

}