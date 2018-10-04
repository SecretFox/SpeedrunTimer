import com.GameInterface.Browser.Browser;
import com.Utils.Signal;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 * 
 * Bit messy,but functional
 */
class com.fox.SpeedrunTimer.Uploader {

	private static var UploaderID = 51;
	private static var UploadAddress:String = "https://secretfox.pythonanywhere.com/";
	private static var ApiAddress:String = "api";
	static var sep:String = "&v=";
	static var key:String = "?k=Speedrun";
	static var ModVersion:String = "1.4.1";
	
	private var ID;
	public var UploadQueue:Array;
	public var PlayerID:Number;
	public var PlayerName:String;
	public var PlayerFaction:Number;
	private var m_TimeOut:Number;
	private var StartString:String;
	private var m_Browser:Browser;
	public var TimedOut:Signal;
	public var Uploaded:Signal;
	public var StartedUpload:Signal;

	//Advances browser ID by one and returns a new instance
	public static function create() {
		var inst:Uploader = new Uploader(UploaderID++);
		return inst;
	}
	
	public function Uploader(id){
		ID = id;
		TimedOut = new Signal();
		Uploaded = new Signal();
		StartedUpload = new Signal();
	}
	
	private function Timeout() {
		clearTimeout(m_TimeOut);
		m_Browser.Stop();
		m_Browser.CloseBrowser();
		m_Browser = undefined;
		TimedOut.Emit();
	}
	
	public function CloseBrowser(){
		clearTimeout(m_TimeOut);
		m_Browser.Stop();
		m_Browser.CloseBrowser();
		m_Browser = undefined;
	}

	//Creates the browser and sets URL start
	public function StartUpload() {
		if (UploadQueue.length > 0) {
			if (m_Browser) CloseBrowser();
			m_Browser = new Browser(ID, 500, 500);
			StartString = UploadAddress + ApiAddress + [key, PlayerID, PlayerName, PlayerFaction, ModVersion].join(sep);
			m_Browser.SignalBrowserShowPage.Connect(PageLoaded,  this);
			m_Browser.SignalStartLoadingURL.Connect(StartLoading, this);
			Upload();
		}
		else{
			CloseBrowser();
			Uploaded.Emit("Upload done");
		}
	}
	
	//Combines start url with data and starts upload
	private function Upload() {
		var runData = UploadQueue.pop();
		var uploadString = StartString + sep +  runData.join(sep);
		StartedUpload.Emit(runData[0]);
		clearTimeout(m_TimeOut);
		m_TimeOut = setTimeout(Delegate.create(this, Timeout), 10000);
		m_Browser.OpenURL(uploadString);
	}
	//Page loaded,move to next data
	private function PageLoaded() {
		if (UploadQueue.length > 0) {
			Upload();
		} else {
			CloseBrowser();
			Uploaded.Emit("Upload done");
		}
	}
	
	//Emits url content on page load
	private function StartLoading(url) {
		var returnString = url.split(UploadAddress + ApiAddress + "/").join("");
		Uploaded.Emit(unescape(returnString));
	}

	//Update checker
	public function CheckForUpdates(feedback:Function){
		if (m_Browser) CloseBrowser();
		m_Browser = new Browser(ID, 500, 500);
		m_Browser.SignalBrowserShowPage.Connect(CloseBrowser,  this);
		m_Browser.SignalStartLoadingURL.Connect(StartLoading, this);
		clearTimeout(m_TimeOut);
		m_TimeOut = setTimeout(Delegate.create(this, Timeout), 10000);
		var Url = UploadAddress + ApiAddress + "?k=UpdateChecker" + sep + "Speedrun" + sep + ModVersion;
		m_Browser.OpenURL(Url);
	}
}