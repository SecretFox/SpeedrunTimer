﻿/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.AbstractButton;
import GUI.fox.aswing.Icon;
import GUI.fox.aswing.plaf.ButtonUI;
import GUI.fox.aswing.ToggleButtonModel;
import GUI.fox.aswing.UIManager;

/**
 * An implementation of a two-state button.  
 * The <code>JRadioButton</code> and <code>JCheckBox</code> classes
 * are subclasses of this class.
 * @author iiley
 */
class GUI.fox.aswing.JToggleButton extends AbstractButton{
	/**
     * JToggleButton(text:String, icon:Icon)<br>
     * JToggleButton(text:String)<br>
     * JToggleButton(icon:Icon)
     * <p>
	 */
	public function JToggleButton(text, icon:Icon){
		super(text, icon);
		setName("JToggleButton");
    	setModel(new ToggleButtonModel());
		updateUI();
	}
	
	public function updateUI():Void{
    	setUI(ButtonUI(UIManager.getUI(this)));
    }
    
	public function getUIClassID():String{
		return "ToggleButtonUI";
	}
	
	public function getDefaultBasicUIClass():Function{
    	return GUI.fox.aswing.plaf.asw.ASWingToggleButtonUI;
    }
}
