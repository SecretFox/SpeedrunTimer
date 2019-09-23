/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.ASWingUtils;
import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.geom.Point;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JColorChooser;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JScrollPane;
import GUI.fox.aswing.JTextArea;
import GUI.fox.aswing.util.Delegate;

/**
 * @author iiley
 */
class test.ColorChooserTest extends JFrame {
	
	private var infoText:JTextArea;
	private var chooserDialog:JFrame;
	
	public function ColorChooserTest(){
		super("ColorChooserTest");
		
		var button:JButton = new JButton("Choose Color");
		button.addActionListener(__openColorChooserDialog, this);
		
		getContentPane().append(button, BorderLayout.NORTH);
		
		infoText = new JTextArea();
		getContentPane().append(new JScrollPane(infoText), BorderLayout.CENTER);
		
		chooserDialog = JColorChooser.createDialog(new JColorChooser(), this, "Chooser a color to test", 
			false, Delegate.create(this, __colorSelected), 
			Delegate.create(this, __colorCanceled));
		//center it
		var location:Point = ASWingUtils.getScreenCenterPosition();
		location.x -= chooserDialog.getWidth()/2;
		location.y -= chooserDialog.getHeight()/2;
		chooserDialog.setLocation(location);
	}
	
	private function __openColorChooserDialog():Void{
		chooserDialog.show();
	}
	
	private function __colorSelected(color:ASColor):Void{
		infoText.appendText("Selected Color : " + color + "\n");
	}
	private function __colorCanceled():Void{
		infoText.appendText("Selecting canceled!\n");
	}
	
	public static function main():Void {
		Stage.scaleMode = "noScale";
		try{
			var fj:ColorChooserTest = new ColorChooserTest();
			fj.setBounds(100, 100, 400, 400);
			fj.setVisible(true);
		}catch(e:Error){
			trace("Error : " + e);
		}
	}
}