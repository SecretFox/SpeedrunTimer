import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.Component;
import GUI.fox.aswing.graphics.Graphics;
import GUI.fox.aswing.graphics.SolidBrush;
import GUI.fox.aswing.Icon;

/**
 * @author iiley
 */
class test.CircleIcon implements Icon {
	
	private var color:ASColor;
	private var width:Number;
	private var height:Number;
	
	public function CircleIcon(color:ASColor, width:Number, height:Number){
		this.color = color;
		this.width = Math.round(width);
		this.height = Math.round(height);
	}
	
	public function getIconWidth() : Number {
		return width;
	}

	public function getIconHeight() : Number {
		return height;
	}

	public function paintIcon(com : Component, g : Graphics, x : Number, y : Number) : Void {
		g.fillEllipse(new SolidBrush(color), x, y, width, height);
	}

	public function uninstallIcon(com : Component) : Void {
	}

}