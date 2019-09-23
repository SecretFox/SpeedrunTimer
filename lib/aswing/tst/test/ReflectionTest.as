import GUI.fox.aswing.util.Reflection;
import GUI.fox.aswing.geom.Point;
import GUI.fox.aswing.ASColor;
/**
 * @author Igor Sadovskiy
 */
class test.ReflectionTest {
	
	public static function main() : Void {
		var t = new ReflectionTest();
	}
	
	public function ReflectionTest() {
		var a:Date = Reflection.createInstance(ASColor, [0xFFFFFF, 50]);
		trace("a = " + a.toString());	
	}
}