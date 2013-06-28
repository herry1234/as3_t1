/**
* ...
* @author Default
* @version 0.1
*/

package {
	import flash.display.Shape;
	import flash.display.SimpleButton;
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
	import flash.external.ExternalInterface;
	public class testClient extends Sprite {
	
		private var c:myClient;
		private var actionList:Array;
		private var ActionIdx:int = 0;
		private var statusTimer:Timer;
		private var statesStr:String;
		private var ResultStr:String;
		private var debugtest:TextField;
		private var StreamList:Array;
		private var myDuration:int = 20;
		private var AppType:Number = -2;
		private var isDVR:Boolean = false;
		private var seeklock:Boolean = true;
		private var StreamIndex:Number = 0;
		public function testClient() {
			//Set result status to INIT
			c=new myClient();
			ActionIdx = 0;
			var hello_tf:TextField=new TextField();
			hello_tf.x = 50;
			hello_tf.autoSize = TextFieldAutoSize.LEFT;
			hello_tf.text="CDS2.x Automation FMS Test Client";
			addChild(hello_tf);
			debugtest = new TextField();
			debugtest.autoSize = TextFieldAutoSize.LEFT;
			debugtest.wordWrap = true;
			debugtest.x = 0;
			debugtest.y = 60;
			debugtest.text = "DEBUG";
			addChild(debugtest);
			trace("Initlization Client ...");
			ExternalInterface.addCallback("sendCmdToFlash", getCmdFromJavaScript);
			ExternalInterface.addCallback("sendCtrlToFlash", getCtrlFromJavaScript);
		}
		private function sendStatusToJS(statesStr:String):void {
			var result:Object = ExternalInterface.call("getTextFromFlash", statesStr);
		}
		private function sendResultToJS(ResultStr:String):void {
			var result:Object = ExternalInterface.call("getResultFromFlash", ResultStr);
		}
		public function getListFromJavaScript(str:String):void {
			
		}
		public function getCtrlFromJavaScript(str:String,...args):void {
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
				c.stream.seek(c.stream.time + 3);
				break;
				case "RW":
				c.stream.seek(c.stream.time - 3);
				uploadresult("Player" + "RW");
				break;
				case "SWITCH":
				uploadresult("args[0]" + args[0] + "arg1" + args[1]);
				switch_switch(args[0], args[1]);
				break;
				case "SWAP":
				uploadresult("args[0]" + args[0] + "arg1" + args[1]);
				switch_swap(args[0], args[1]);
				break;
				default:
				uploadresult("unknow ctrl command");
				break;
			}
			
		}
		public function getCmdFromJavaScript(str:String,mystreamlist:String,streamType:String = "VOD"):void {
			//Using the new parse,NetConnect Syntax:
			//protocol:[//host][:port]/appname[/instanceName]
			//So we only the stream name required, the other part should be Connect Parameter.
			//
			//var parse_stream:RegExp = /\/([\w-:\s\?=.\&\+]+)$/; 
			var UrlStr:String = str;
			var SignedStr:String = "";
			var index_querystring:int = str.indexOf("?");
			if (index_querystring != -1) {
				//we have '?' in the URL
				UrlStr = str.substr(0, index_querystring);
				SignedStr = str.substr(index_querystring);
				debugtest.appendText(" Url= " + UrlStr + " Signed= " + SignedStr);
			}
			var parse_stream:RegExp = /\/([\w-:\s.]+)$/;
			var result:Array = parse_stream.exec(UrlStr);
			var mystreamname:String = result[1];
			var tmpindex:int = UrlStr.search(parse_stream);
			var myurl:String = UrlStr.substring(0, tmpindex);
			mystreamname = UrlStr.substr(tmpindex + 1);
			mystreamname += SignedStr;
			debugtest.appendText(" Url= " + myurl + " Stream= " + mystreamname + "StreamList" + mystreamlist);
			switch(streamType) {
				case "VOD": AppType = 0; break;
				case "LIVE": AppType = -1; break;
				case "DVR": AppType = 0; isDVR = true; break;
				default : AppType = -2; break;
			}
		
			c.addEventListener(myEvent.CLIENTEVENT,listenFun2);
			c.streamName = mystreamname;
			StreamList = new Array();
			if(mystreamname == "USINGPLAYLIST") {
				StreamList = mystreamlist.split(",");
			}
			c.connect(myurl);
			var myvid:Video = new Video(320, 240);
			myvid.x = 0;
			myvid.y = 80;
			c.clientvideo=myvid;
			addChild(myvid);
			statusTimer = new Timer(1000);
			statusTimer.addEventListener(TimerEvent.TIMER,timerHandler);
			statusTimer.start();

		}
		private function switch_swap(oldStreamName:String,newStreamName:String):void {
			c.playStream2(oldStreamName, newStreamName, 1, 30);
		}
		private function switch_switch(oldStreamName:String,newStreamName:String):void {
			c.playStream2(oldStreamName, newStreamName, 2, 30);
		}
		private function doPlayStream():void {
			if (StreamList.length == 0) {
				if (isDVR) {
					uploadresult("using DVR");
					
					c.DVRSubscribe(c.streamName);
					c.getDVRMetadata(c.streamName);
					return;
				}
				c.stream.bufferTime = 3;
				c.playStream(c.streamName,AppType,-1,1);
			} else {
				trace("Using Play list");
				c.stream.bufferTime = 3;
				if (isDVR) {
					uploadresult("using DVR");
					for (var j:int = 0; j < StreamList.length; j++) {
						c.streamName = StreamList[j];
						c.DVRSubscribe(StreamList[j]);
						c.getDVRMetadata(StreamList[j]);
					}
					return;
				}
				for (var i:int = 0; i < StreamList.length; i++) {
					c.playStream(StreamList[i], AppType, 30, 0);
				}
				
			}
		}
		private function listenFun2(evt:myEvent):void {
			trace("Event--" + evt.type + " Event info: " + evt.ClientEvt + " Desc: " + evt.ClientEvtInfo);
			//var myeventstr:String = "Event--" + evt.type + " Event info: " + evt.ClientEvt + " Desc: " + evt.ClientEvtInfo + "\r\n";
			//uploadresult(myeventstr);
			switch(evt.ClientEvt) {
				case "ConnectionSuccess":
					uploadresult("Connect Success");
					doPlayStream();
				break;
				case "Connection302":
					uploadresult("Connection Redirect to: " + evt.ClientEvtInfo);
				break;
				case "StreamStopped":
					statusTimer.stop();
					uploadresult("Stream Stopped");
				break;
				case "StreamStarted":
					trace("Started");

					statusTimer.start();
					uploadresult("Stream Started");
				break;
				case "DVRStreamInfo":
					uploadresult("DVRInfo" + evt.ClientEvtInfo);	
					if (evt.ClientEvtInfo == "DVRStreamInfoRetry") {
						// try again
						c.getDVRMetadata(c.streamName);
					} else if (evt.ClientEvtInfo == "DVRStreamInfoSuccess") {
						if (StreamList.length > 1) {
							StreamIndex ++;
							var seek_sec :Number = 0;
							var str : String = evt.GetsMsg();
							var msgList : Array = str.split(',');
							uploadresult(msgList[0]);
							uploadresult(msgList[1]);
							uploadresult(msgList[2]);
							c.playStream(msgList[2], AppType, 30, 0);
							if (msgList[1] == "0") {
								
								seek_sec  = Number(msgList[0]);
								seek_sec -= 40;
								
								if (StreamIndex == StreamList.length) {
									uploadresult("seekiiiiing ");
									uploadresult(String(seek_sec));
									c.stream.seek(seek_sec);
									seeklock = false;
								}
							}else {
								c.stream.seek(0);
							}
						} else {
							c.playStream(c.streamName, AppType, -1, 1);
							c.stream.seek(c.dvrDuration);
						}
					}
				break;
				case "DVRSubscribe":
					uploadresult("handling DVRSubscribe");			
					if (evt.ClientEvtInfo == "DVRSubscribeSuccess") {
						c.stream.seek(c.dvrDuration);
					}else {
						uploadresult("handling NO DVRSubscribeSuccess");	
					}
				break;
				case "ConnectionClosed":
					statusTimer.stop();
					c.connection.close();
					uploadresult("Connection Closed");
				break;
				case "ConnectionFailed":
					uploadresult("Connection Failed");
					statusTimer.stop();
					c.connection.close();
				break;
				default:
					uploadresult("UnHandled Event "+evt.type+evt.ClientEvt+evt.ClientEvtInfo);
				break;
			}
		}

		private function timerHandler(event:TimerEvent):void {
			if (c.streamStarted) {
				trace("bytesTotal= " + c.stream.bytesTotal);
				trace("bytesLoaded= " + c.stream.bytesLoaded);
				trace("time= " + Math.round(c.stream.time));
				trace("bufferLength= " + c.stream.bufferLength);
				trace("bufferTime= " + c.stream.bufferTime);
				trace("FPS= " + c.stream.currentFPS);
				trace("liveDelay= " + c.stream.liveDelay);
				//trace("Info= " + c.stream.info.toString() + "***");
				
				var statesStr:String = "BytesTotal=" + c.stream.bytesTotal + "\r\n" + "BytesLoaded=" + c.stream.bytesLoaded + "\r\n" +
				"Time=" + Math.round(c.stream.time) + "\r\n" + "BufferLength=" + c.stream.bufferLength + "\r\n" +
				"bufferTime=" + c.stream.bufferTime + "\r\n" +
				"FPS=" + c.stream.currentFPS + "\r\n" + "liveDelay=" + c.stream.liveDelay
				sendStatusToJS(statesStr);
			} else {
				trace("stream stopped");
				sendStatusToJS("stream stopped");
				//event.target.stop();
			}
		}
		private function uploadresult(res:String):void {
			trace("*******" + res + "********");
			//var ResultStr:String = "ClientID:"+c.id+"="+res;
			//sendResultToJS(ResultStr);
			sendResultToJS(res);
		}
	
	}
}