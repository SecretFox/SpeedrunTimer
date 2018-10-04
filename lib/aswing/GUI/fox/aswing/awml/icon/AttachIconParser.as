﻿/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.AttachIcon;
import GUI.fox.aswing.awml.core.CreatableObjectParser;
import GUI.fox.aswing.Icon;

/**
 *  Parses {@link GUI.fox.aswing.AttachIcon} element.
 * 
 * @author Igor Sadovskiy
 */
class GUI.fox.aswing.awml.icon.AttachIconParser extends CreatableObjectParser {
	
	private static var ATTR_LINKAGE:String = "linkage";
	private static var ATTR_WIDTH:String = "width";
	private static var ATTR_HEIGHT:String = "height";
	private static var ATTR_SCALE:String = "scale";
	
	/**
	 * Constructor.
	 */
	public function AttachIconParser(Void) {
		super();
	}
	
	public function parse(awml:XMLNode):Icon {
		
		var icon:Icon = create(awml);
		
		// process super
		super.parse(awml);
	
		return icon;
	}

    private function getClass(Void):Function {
    	return AttachIcon;	
    }
    
    private function getArguments(awml:XMLNode):Array {
    	
		// init properties
		var linkage:String = getAttributeAsString(awml, ATTR_LINKAGE, null);
		var width:Number = getAttributeAsNumber(awml, ATTR_WIDTH, null);
		var height:Number = getAttributeAsNumber(awml, ATTR_HEIGHT, null);
		var scale:Boolean = getAttributeAsBoolean(awml, ATTR_SCALE, null);
    	
    	return [linkage, width, height, scale];	
    }

}