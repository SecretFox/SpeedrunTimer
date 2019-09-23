import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JPanel;
import GUI.fox.aswing.JPopup;
import GUI.fox.aswing.SoftBoxLayout;
/*
 Copyright aswing.org, see the LICENCE.txt.
*/

/**
 * @author iiley
 */
class test.PopupTest {
	
	private static var popup:JPopup;
	
	public static function main():Void{
		popup = new JPopup();
		var panel:JPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.Y_AXIS));
		panel.append(new JButton("Popup"));
		popup.append(panel);
		popup.pack();
		popup.setVisible(true);
	}
	
}