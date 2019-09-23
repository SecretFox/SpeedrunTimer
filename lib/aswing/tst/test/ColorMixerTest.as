/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.colorchooser.AbstractColorChooserPanel;
import GUI.fox.aswing.colorchooser.JColorMixer;
import GUI.fox.aswing.colorchooser.JColorSwatches;
import GUI.fox.aswing.Container;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JPanel;
import GUI.fox.aswing.JScrollPane;
import GUI.fox.aswing.JTextArea;

/**
 * @author iiley
 */
class test.ColorMixerTest extends JFrame {
	
	private var infoText:JTextArea;
	
	public function ColorMixerTest(){
		super("test.ColorMixerTest");
		
		var p:Container = new JPanel();
		var cm:JColorMixer = new JColorMixer();
		cm.addChangeListener(__colorChanged, this);
		cm.setNoColorSectionVisible(true);
		p.append(cm);		
		var cs:JColorSwatches = new JColorSwatches();
		cs.addChangeListener(__colorChanged, this);
		cs.setNoColorSectionVisible(true);
		//p.append(cs);
		
		getContentPane().append(p, BorderLayout.NORTH);
		
		infoText = new JTextArea("");
		getContentPane().append(new JScrollPane(infoText), BorderLayout.CENTER);
	}
	
	private function __colorChanged(cp:AbstractColorChooserPanel):Void{
		infoText.appendText(cp.getSelectedColor() + "\n");
	}
	
	public static function main():Void {
		Stage.scaleMode = "noScale";
		trace("ColorMixerTest");
		try{
			var fj:ColorMixerTest = new ColorMixerTest();
			fj.setBounds(100, 100, 400, 400);
			fj.setVisible(true);
		}catch(e:Error){
			trace("Error : " + e);
		}
	}
}