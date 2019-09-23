/*
 Copyright aswing.org, see the LICENCE.txt.
*/

import GUI.fox.aswing.BorderLayout;
import GUI.fox.aswing.JButton;
import GUI.fox.aswing.JFrame;
import GUI.fox.aswing.JPanel;
import GUI.fox.aswing.JScrollPane;
import GUI.fox.aswing.JTree;

/**
 * @author iiley
 */
class test.tree.TreeTest extends JFrame {
	private var tree:JTree;
	
	public function TreeTest() {
		super("TreeTest");
		var pane:JPanel = new JPanel(new BorderLayout());
		tree = new JTree();
		tree.setEditable(true);
		tree.setRowHeight(20);
		//tree.setFixedCellWidth(80);
		pane.append(new JScrollPane(tree), BorderLayout.CENTER);
		var button:JButton = new JButton("Expand");
		pane.append(button, BorderLayout.SOUTH);
		setContentPane(pane);
		//button.addActionListener(__repaintTree, this);
	}
	
	private function __repaintTree():Void{
		tree.expandPath(tree.getPathForRow(1));
		tree.expandPath(tree.getPathForRow(0));
	}
	
	public static function main():Void {
		try{
			var myWindow1:TreeTest = new TreeTest ();
			myWindow1.setLocation (0, 0);
			myWindow1.setSize (200, 200);
			myWindow1.show();
		}catch(e:Error){
			trace("Catched a error : " + e);
		}
	}
}