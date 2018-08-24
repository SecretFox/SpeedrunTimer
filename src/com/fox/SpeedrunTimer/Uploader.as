import com.GameInterface.Browser.Browser;
import com.Utils.Signal;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */
class com.fox.SpeedrunTimer.Uploader {

	public var UploadQueue:Array;
	private static var UploadAddress:String = "https://secretfox.pythonanywhere.com/";
	private static var ApiAddress:String = "api";
	static var sep:String = "&v=";
	static var key:String = "?k=Speedrun";
	static var ModVersion:String = "1.3.0";
	public var PlayerID:Number;
	public var PlayerName:String;
	public var PlayerFaction:Number;
	private var m_TimeOut:Number;
	private var StartString:String;
	private var m_Browser:Browser;
	public var TimedOut:Signal;
	public var Uploaded:Signal;

	public function Uploader() {
		TimedOut = new Signal();
		Uploaded = new Signal();
	}

	public function StartUpload() {
		if (UploadQueue.length > 0) {
			if (!m_Browser) m_Browser = new Browser(51, 500, 500);
			StartString = UploadAddress + ApiAddress + [key, PlayerID, PlayerName, PlayerFaction, ModVersion].join(sep);
			m_Browser.SignalBrowserShowPage.Connect(PageLoaded,  this);
			m_Browser.SignalStartLoadingURL.Connect(StartLoading, this);

			Upload();
		}

	}

	private function Upload() {
		var uploadString = StartString +sep +  UploadQueue.pop().join(sep);
		m_Browser.OpenURL(uploadString);
		clearTimeout(m_TimeOut);
		m_TimeOut = setTimeout(Delegate.create(this, Timeout), 10000);
	}

	private function StartLoading(url) {
		var returnString = url.split(UploadAddress + ApiAddress + "/").join("");
		Uploaded.Emit(unescape(returnString));
	}

	private function PageLoaded() {
		if (UploadQueue.length > 0) {
			Upload();
		} else {
			clearTimeout(m_TimeOut);
			m_Browser.SignalBrowserShowPage.Disconnect(PageLoaded,  this);
			m_Browser.Stop();
			m_Browser.CloseBrowser();
			m_Browser = undefined;
		}
	}

	private function Timeout() {
		clearTimeout(m_TimeOut);
		m_Browser.SignalBrowserShowPage.Disconnect(PageLoaded,  this);
		m_Browser.Stop();
		m_Browser.CloseBrowser();
		m_Browser = undefined;
		TimedOut.Emit();
	}
}