import GUI.fox.aswing.ASFont;
import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JLabel;

/**
 * @author iiley
 */
class test.CenterLabel extends JFrame {
	
	public function CenterLabel() {
		super("CenterLabel");
		
		var label:JLabel = new JLabel("Centered T");
		var font:ASFont = new ASFont("华文彩云", 24, false);
		//font.setEmbedFonts(true);
		label.setFont(font);
		label.setVerticalAlignment(JLabel.CENTER);
		label.setVerticalTextPosition(JLabel.CENTER);
		getContentPane().append(label, BorderLayout.WEST);
	}

	public static function main():Void{
		try{
			trace("try CenterLabel");
			
			var p:CenterLabel = new CenterLabel();
			p.setClosable(false);
			
			p.setLocation(50, 50);
			p.setSize(400, 200);
			p.show();
			
			trace("done CenterLabel");
		}catch(e){
			trace("error : " + e);
		}
	}
}