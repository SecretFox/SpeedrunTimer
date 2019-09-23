/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.ASColor;
import GUI.fox.aswing.ASWingUtils;
import GUI.fox.aswing.border.BevelBorder;
import GUI.fox.aswing.colorchooser.ColorRectIcon;
import GUI.fox.aswing.colorchooser.JColorSwatches;
import GUI.fox.aswing.FlowLayout;
import GUI.fox.aswing.geom.Point;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JColorChooser;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JWindow;
import GUI.fox.aswing.MouseManager;
import GUI.fox.aswing.util.Delegate;

/**
 * @author iiley
 */
class test.pallette.PalletteDemo extends JWindow {
	
	private var palletteButton:JButton;
	private var palletteIcon:ColorRectIcon;
	private var colorSwatchesWindow:JWindow;
	private var colorSwatches:JColorSwatches;
	private var colorMixerButton:JButton;
	
	private var chooserDialog:JFrame;
	private var colorChooser:JColorChooser;
	
	public function PalletteDemo(){
		super();
		palletteIcon = new ColorRectIcon(20, 20);
		palletteButton = new JButton(palletteIcon);
		
		getContentPane().setLayout(new FlowLayout());
		getContentPane().append(palletteButton);
		palletteButton.addActionListener(__openColorSwaches, this);
		
		colorMixerButton = new JButton(" M ");
		colorSwatches = new JColorSwatches();
		colorSwatches.setAlphaSectionVisible(false);
		colorSwatches.addComponentColorSectionBar(colorMixerButton);
		colorSwatchesWindow = new JWindow(this, false);
		colorSwatchesWindow.setBorder(new BevelBorder(null, BevelBorder.RAISED));
		colorSwatchesWindow.setContentPane(colorSwatches);
		colorSwatchesWindow.pack();
		
		colorChooser = new JColorChooser();
		colorChooser.addColorAdjustingListener(__colorAdjusting, this);
		//colorChooser.setAlphaSectionVisible(false);
		chooserDialog = JColorChooser.createDialog(colorChooser, this, "Chooser a color to test", 
			false, Delegate.create(this, __colorSelectedInDialog),  Delegate.create(this, __colorSeletionCanceldInDialog));
		//center it
		var location:Point = ASWingUtils.getScreenCenterPosition();
		location.x -= chooserDialog.getWidth()/2;
		location.y -= chooserDialog.getHeight()/2;
		location.x = Math.round(location.x);
		location.y = Math.round(location.y);
		chooserDialog.setLocation(location);
		
		colorMixerButton.addActionListener(__openColorMixer, this);
		
		colorSwatches.getModel().addChangeListener(__colorSelectionChanged, this);
		colorSwatches.setSelectedColor(null);
		colorSwatches.setNoColorSectionVisible(true);
		MouseManager.addEventListener(MouseManager.ON_MOUSE_DOWN, __onMouseDown, this);
	}
	
	private function __onMouseDown():Void{
		if(colorSwatchesWindow.isVisible()){
			if(!colorSwatchesWindow.hitTestMouse()){
				colorSwatchesWindow.hide();
			}
		}
	}
	
	private function __openColorSwaches():Void{
		var pos:Point = getMousePosition();
		pos.y += 10;
		colorSwatchesWindow.setLocation(pos);
		colorSwatchesWindow.show();
	}
	
	private function __openColorMixer():Void{
		colorSwatchesWindow.hide();
		var time:Number = getTimer();
		colorChooser.setSelectedColor(colorSwatches.getSelectedColor());
		//colorChooser.getTabbedPane().setSelectedIndex(0);
		trace("init time : " + (getTimer() - time));
		time = getTimer();
		chooserDialog.show();
		trace("show time : " + (getTimer() - time));
	}
	
	private function __colorSelectionChanged():Void{
		colorSwatchesWindow.hide();
		palletteIcon.setColor(colorSwatches.getSelectedColor());
		palletteButton.repaint();
	}
	
	private function __colorAdjusting(source, color:ASColor):Void{
		palletteIcon.setColor(color);
		palletteButton.repaint();
	}
	
	private function __colorSelectedInDialog(color:ASColor):Void{
		colorSwatches.setSelectedColor(color);
	}
	
	private function __colorSeletionCanceldInDialog():Void{
		palletteIcon.setColor(colorSwatches.getSelectedColor());
		palletteButton.repaint();
	}
	
	public static function main():Void {
		Stage.scaleMode = "noScale";
		try{
			var fj:PalletteDemo = new PalletteDemo();
			fj.setBounds(0, 0, 550, 400);
			fj.setVisible(true);
		}catch(e:Error){
			trace("Error : " + e);
		}
	}
}