/**
* ...
* @author Default
* @version 0.1
*/

package {
	import flash.display.Sprite;
	import Client.myClient;
	//import flash.events.ActivityEvent;
	//import flash.events.EventDispatcher;
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
	import flash.external.ExternalInterface;
	public class myHtmlPlayer extends Sprite {

		private var c:myClient;
		private var statusTimer:Timer;
		private var statesStr:String;
		private var ResultStr:String;
		private var debugtest:TextField;
		public function myHtmlPlayer() {
			//Set result status to INIT
			c=new myClient();
			initresult();
			var hello_tf:TextField=new TextField() ;
			hello_tf.x = 30;
			hello_tf.autoSize = TextFieldAutoSize.LEFT;
			hello_tf.text="CDS2.0 Automation Test Client";
			addChild(hello_tf);
			debugtest = new TextField();
			debugtest.autoSize = TextFieldAutoSize.LEFT;
			debugtest.x = 0;
			debugtest.y = 240;
			debugtest.text = "DEBUG";
			addChild(debugtest);
			ExternalInterface.addCallback("sendCmdToFlash", getCmdFromJavaScript);
			ExternalInterface.addCallback("sendCtrlToFlash", getCtrlFromJavaScript);
		}
		
		public function getCmdFromJavaScript(str:String):void {
			//Using the new parse,NetConnect Syntax:
			//protocol:[//host][:port]/appname[/instanceName]
			//So we only the stream name required, the other part should be Connect Parameter.
			//
			var parse_stream:RegExp = /\/([\w-:\s\?=.\&]+)$/;
			var result:Array = parse_stream.exec(str);
			trace(result.length);
			trace(result[0]);
			trace(result[1]);
			var mystreamname:String = result[1];
			var tmpindex:int = str.search(parse_stream);
			var myurl:String = str.substring(0,tmpindex);
			/*
			var parse1:RegExp = /:\/\//;
			var parse2:RegExp = /\/([\w-]+)\//;
			var tmpindex :int = str.search(parse1);
			// Protocol looks like rtmp, http, etc
			var myProtocol:String = str.substring(0,tmpindex);
			var tmpUrl:String = str.substring(tmpindex+3);
			var tmpResult:Array = parse2.exec(tmpUrl);
			var myAppName:String = tmpResult[1];
			tmpindex = tmpResult.index;// point to head of /vod/ or /live/
			var myurl:String = tmpUrl.substring(0,tmpindex);
			myurl = myurl + "/" + myAppName;
			var mystreamname:String = tmpUrl.substring(myurl.length+1);
			myurl = myProtocol+"://"+myurl;
			/*
			//myAppName looks like vod, live, etc
			
			// str looks like rtmp://somesite.com/vod/foo.flv
			//Get configuration info from JavaScript
/*			var parseStream:RegExp = /\/[\w-]+(\.flv$|\.mp3$)/g;
			var tmpindex :int= str.search(parseStream);
			var myurl:String = str.substring(0, tmpindex);
			var mystreamname:String = str.slice(tmpindex + 1);
			if(!parseStream.test(str)) {
				//no flv mp3 found
				debugtest.appendText("Enter live parse");
				var parseLiveStream:RegExp = /\/live\//g;
				tmpindex = str.search(parseLiveStream);
				myurl = str.substring(0, tmpindex+5);
				mystreamname = str.slice(tmpindex + 6);
			}
*/			//debugtest.appendText("Input str" + str + "tmpindex=" + tmpindex + "myurl=" + myurl + "mystreamname=" + mystreamname);
			debugtest.appendText(" Url= " + myurl + " Stream= " + mystreamname);
			c.addEventListener(myEvent.CLIENTEVENT,listenFun2);
			c.streamName=mystreamname;
			c.connect(myurl);
			var myvid:Video = new Video(320, 240);
			myvid.x = 0;
			myvid.y = 30;
			c.clientvideo=myvid;
			addChild(myvid);
			statusTimer = new Timer(1000);
			statusTimer.addEventListener(TimerEvent.TIMER,timerHandler);
			statusTimer.start();
		}
		public function getCtrlFromJavaScript(str:String):void {
			switch (str) {
				case "PLAY":
				c.stream.resume();
				break;
				case "PAUSE":
				c.stream.togglePause();
				break;
				case "STOP":
				//c.stream.pause();
				//c.stream.seek(0);
				c.stream.close();
				break;
				case "FF":
				//c.stream.pause();
				case "RW":
				break;
				default:
				break;
			}
			
		}
		private function sendStatusToJS():void {
			var result:Object = ExternalInterface.call("getTextFromFlash", statesStr);
		}
		private function sendResultToJS():void {
			var result:Object = ExternalInterface.call("getResultFromFlash", ResultStr);
		}
		
		private function listenFun2(evt:myEvent):void {
			trace("Event here=" + evt.type);
			switch(evt.ClientEvt) {
				case "ConnectionSuccess":
				c.stream.play(c.streamName);
				break;
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
		private function timerHandler(event:TimerEvent):void {
			if (c.streamStarted) {
				statesStr = "";
				trace("bytesTotal=" + c.stream.bytesTotal);
				trace("bytesLoaded=" + c.stream.bytesLoaded);
				trace("time=" + Math.round(c.stream.time));
				trace("bufferLength=" + c.stream.bufferLength);
				trace("bufferTime=" + c.stream.bufferTime);
				trace("FPS=" + c.stream.currentFPS);
				trace("liveDelay" + c.stream.liveDelay);
				statesStr = "BytesTotal=" + c.stream.bytesTotal + "\r\n" + "BytesLoaded=" + c.stream.bytesLoaded + "\r\n" +
				"Time=" + Math.round(c.stream.time) + "\r\n" + "BufferLength=" + c.stream.bufferLength + "\r\n" +
				"bufferTime=" + c.stream.bufferTime + "\r\n" +
				"FPS=" + c.stream.currentFPS + "\r\n" + "liveDelay=" + c.stream.liveDelay
				sendStatusToJS();
			} else {
				trace("stream stopped");
				//event.target.stop();
			}
		}
		private function uploadresult(res:String):void {
			ResultStr = "ClientID:"+c.id+"="+res;
			sendResultToJS();
		}
		private function initresult():void {
			uploadresult("INIT");
		}
	}
}