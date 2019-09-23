﻿/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JPanel;
import GUI.fox.aswing.JSplitPane;

/**
 * @author iiley
 */
class test.SplitPaneTest extends JFrame {
	
	private var sp:JSplitPane;
	
	public function SplitPaneTest() {
		super("SplitPaneTest");
		
		sp = new JSplitPane();
		sp.setTopComponent(new JButton("Top"));
		//sp.setLeftComponent(new JButton("Left"));
		sp.setRightComponent(new JButton("Right"));
		//sp.setContinuousLayout(true);
		sp.setOrientation(JSplitPane.VERTICAL_SPLIT);
		sp.setOneTouchExpandable(true);
		getContentPane().append(sp, BorderLayout.CENTER);
		var pane:JPanel = new JPanel();
		pane.setPreferredSize(100, 100);
		getContentPane().append(pane, BorderLayout.SOUTH);
	}

   public static function main():Void{
       try{
           trace("try SplitPaneTest");
           var p:SplitPaneTest = new SplitPaneTest();
           p.setLocation(50, 50);
           p.setSize(400, 400);
           p.show();
           trace("done SplitPaneTest");
       }catch(e){
	       trace("error : " + e);
       }
   }
}