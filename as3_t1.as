/**
* ...
* @author Default
* @version 0.1
*/

package {
	import flash.display.Sprite;
	import Client.myClient;
	import flash.events.ActivityEvent;
	import flash.events.EventDispatcher;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.*;
	import flash.events.*;
	import Client.myEvent;
	//import flash.events.TimerEvent;
	import org.flashdevelop.utils.FlashConnect;
	public class as3_t1 extends Sprite {
		public function trace(str:*):void {
			FlashConnect.trace(str.toString());
		}
		private var c:myClient;
		private var actionList:Array;
		private var ActionIdx:int = 0;
		private var statusTimer:Timer;
		private static var cfgUrl:String = "automation_cfg/sample.xml";
		public function as3_t1() {
			//Set result status to INIT
			c=new myClient();
			initresult();
			ActionIdx = 0;
			var hello_tf:TextField=new TextField() ;
			hello_tf.x = 300;
			hello_tf.autoSize = TextFieldAutoSize.LEFT;
			hello_tf.text="CDS2.0 Automation Test Client";
			addChild(hello_tf);
			trace("Initlization Client ...");
			var loader:URLLoader=new URLLoader();
			loader.dataFormat=URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE,loadComplete);
			loader.load(new URLRequest(cfgUrl));
		}
		private function loadComplete(evt:Event):void {
			
				var sample:XML=new XML(evt.target.data);
				trace(sample);
				trace(sample.TestCase.TestCaseID);
				var myurl:String=sample.TestCase.TestSetup.@url;
				var mystreamname:String=sample.TestCase.TestSetup.@stream_name;
				trace("uri==" + sample.TestCase.TestSetup.@url);
				trace("streamname==" + sample.TestCase.TestSetup.@stream_name);
				trace("actionlist==" + sample.TestCase.Actions.@actionlist);
				trace("interval==" + sample.TestCase.Actions.@interval);
				//var myInterval:Number= int(sample.TestCase.Actions.@interval);
				var myIntervals:Array = (sample.TestCase.Actions.@interval).split(" ");
				actionList = (sample.TestCase.Actions.@actionlist).split(" ");
				//trace("length="+actionList.length);
				for each (var tmp:String in actionList) {
					trace("action="+tmp);
				}
				//c=new myClient();
				c.addEventListener(myEvent.CLIENTEVENT,listenFun2);
				c.streamName=mystreamname;
				c.connect(myurl);
				var myvid:Video=new Video(160,120);
				c.clientvideo=myvid;
				addChild(myvid);
				statusTimer = new Timer(1000);
				statusTimer.addEventListener(TimerEvent.TIMER,timerHandler);
				statusTimer.start();
				if(actionList[ActionIdx]!="PLAY_TO_END") {
					for each (var interval:String in myIntervals) {
						var myInterval:int = int(interval);
						trace("Interval:"+myInterval);
						var t2:Timer = new Timer(myInterval*1000,1);
						t2.addEventListener(TimerEvent.TIMER,sendActions);
						t2.start();
					}
				}else {
					trace("Using Play to End");
				}
			
		}
		
		private function listenFun2(evt:myEvent):void {
			trace("Event here=" + evt.type);
			switch(evt.ClientEvt) {
				case "StreamStopped":
				statusTimer.stop();
				trace("pass");
				uploadresult("PASS");
				break;
				case "StreamStarted":
				trace("Started");
				uploadresult("STAT");
				break;
				case "ConnectionClosed":
				//uploadresult("CLOSE");
				statusTimer.stop();
				c.connection.close();
				break;
				case "ConnectionFailed":
				trace("FAIL");
				statusTimer.stop();
				uploadresult("FAIL");
				c.connection.close();
				break;
				default:
				trace("Unknown Event");
				break;
			}
		}
		private function sendActions(evt:TimerEvent):void {
			//
			trace("length="+actionList.length);
			//PLAY PLAY_TO_END FWD BWD PAUSE STOP
			if(ActionIdx<actionList.length) {
				trace("DEBUG Sending actions:ActionIdx="+actionList[ActionIdx]);
			switch (actionList[ActionIdx]) {
				case "PLAY" :
				c.resume();
				//c.stream.resume();
				trace("play");
				break;
				case "PLAY_TO_END" :
				break;
				case "FWD" :
				c.seek(2);
				trace("fwd");
				break;
				case "BWD" :
				c.seek(c.stream.time-2);
				trace("bwd");
				break;
				case "PAUSE" :
				c.stream.togglePause();
				trace("pause");
				case "STOP" :
				c.stream.pause();
				c.seek(0);
				break;
				default:
				trace("Unkown Action");
				break;
			}
			ActionIdx++;
			} else {
				trace("should stop");
				evt.target.stop();
				
			}
			
		}
		private function timerHandler(event:TimerEvent):void {
			if (c.streamStarted) {
				trace("bytesTotal=" + c.stream.bytesTotal);
				trace("bytesLoaded=" + c.stream.bytesLoaded);
				trace("time=" + Math.round(c.stream.time));
				trace("bufferLength=" + c.stream.bufferLength);
				trace("bufferTime=" + c.stream.bufferTime);
				trace("FPS=" + c.stream.currentFPS);
				trace("liveDelay" + c.stream.liveDelay);
			} else {
				trace("stream stopped");
				//event.target.stop();
			}
		}
		private function uploadresult(res:String):void {
			var resultXML:XML = 
				<CDS-Automation>
					<TestCase>12345</TestCase>
					<ClientSessionID>{c.id}</ClientSessionID>
					<Result>{res}</Result>
				</CDS-Automation>;
			var request:URLRequest =  new URLRequest("cgi-bin/uploadresult.pl");
			request.contentType = "text/xml";
			request.data = resultXML.toXMLString();
			request.method = URLRequestMethod.POST;
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE,completeHandler);
			try {
				trace("loading");
				loader.load(request);
			}
			catch (error:ArgumentError)
			{ 
				trace("arg error");
			}
			catch (error:SecurityError)
			{
				trace("sec eror");
			}
		}
		private function initresult():void {
			uploadresult("INIT");
		}
		private function completeHandler(evt:Event):void {
			trace("Upload result OK");
		}
	}
}