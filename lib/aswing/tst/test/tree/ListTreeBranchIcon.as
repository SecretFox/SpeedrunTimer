/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.Component;
import GUI.fox.aswing.graphics.Graphics;
import GUI.fox.aswing.graphics.SolidBrush;
import GUI.fox.aswing.Icon;

/**
 * @author iiley
 */
class test.tree.ListTreeBranchIcon implements Icon {
	
	public function ListTreeBranchIcon(){
	}

	public function getIconWidth() : Number {
		return 10;
	}

	public function getIconHeight() : Number {
		return 10;
	}

	public function paintIcon(com : Component, g : Graphics, x : Number, y : Number) : Void {
		g.fillRectangle(new SolidBrush(ASColor.RED), x, y, 10, 10);
	}

	public function uninstallIcon(com : Component) : Void {
	}
}