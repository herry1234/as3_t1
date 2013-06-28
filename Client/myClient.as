/**
 * Client class
 * author: Herry Wang
 * version: 
 * modified: 11/06/2007
 * copyright: Cisco,.
 * Description: This class represent actualy client user. It establishes connection and play stream. 
 */	
package Client {
	import flash.events.ActivityEvent;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
    import flash.events.NetStatusEvent;
	import flash.events.AsyncErrorEvent;
    import flash.events.SecurityErrorEvent;
	import flash.net.NetStreamPlayTransitions;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;
	import flash.events.*;
	import Client.myEvent;
	import Client.mylogger;
	import flash.net.NetStreamPlayOptions;
	import flash.net.Responder;
	public class myClient implements IEventDispatcher{
		public var _dispatcher:EventDispatcher;
		public var ClientVideo:Video;
		//NetConnection, used to connect FMS
		private var _connection:NetConnection;
		//NetStream,
		private var _stream:NetStream;
		private var _streamName:String;

		private var _metaData:Object;
		
		private var _startTime:Number;

		private var _rebuffering:Boolean = false;
		private var _rebufferingCount:Number = 1;
		private static var _ID_SEED:Number = 0;
		//public static const STATUS:String = "finish";
		private var _streamStarted:Boolean = false;
		private var _connectOpened:Boolean = false;
		//id, indentify the client
		private var _id:String;
		//Video,
		private var _video:Video;
		//Custom Client class
		private var _client:Object;
		
		private var _log:mylogger;
		private static var _CONNECTION_RESPONSE_TIME:Number = 10; // in second
		private static var _STREAM_RESPONSE_TIME:Number = 10; // in second
	
		// These are used internally to track connection/stream response time
		private var _connectionStartTime:Number;
		private var _streamStartTime:Number;
		private var _myResponse:Responder;
		private var _dvrDuration:Number;
	
	// Default constructor
	public function myClient(){
		// Initialize instance variables
		_metaData = new Object();
		var current:Date = new Date();
		myClient._ID_SEED = current.getTime();
		_id = myClient._ID_SEED.toString();
		_client = new Object();
		_myResponse = new Responder(onDVRResult);
		_dvrDuration = 0;
		_dispatcher = new EventDispatcher(this);
		_connection = new NetConnection();
		_connection.addEventListener(NetStatusEvent.NET_STATUS, onNcStatus);
		_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
		_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityErrorHandler);
		_client.onMetaData = _onMetaData;
		_client.onPlayStatus = _onPlayStatus;
		_client.onDVRSubscribe = _onDVRSubscribe;
		//_connection.onDVRSubscribe = function(info:Object) {
			//trace("subscribe:" + info.description);
		//}
		_connection.client = this;
	}
	public function securityErrorHandler(evt:SecurityErrorEvent):void {
	  trace("security"+evt.type);
	}
	public function get connection():NetConnection {
		return _connection;
	}
	public function set connection(nc:NetConnection):void{
		_connection = nc;
	}
	public function get stream():NetStream {
		return _stream;
	}
	public function set stream(ns:NetStream) :void{
		_stream = ns;
	}
	public function get clientvideo():Video {
		return _video;
	}
	public function set clientvideo(vid:Video) :void{
		_video = vid;
	}	
	public function get streamName():String {
		return _streamName;
	}
	public function set streamName(sn:String):void {
		_streamName = sn;
	}	
	public function get metaData():Object {
		return _metaData;
	}
	public function set metaData(md:Object) :void{
		_metaData = md;
	}	
	public function get streamStarted():Boolean {
		return _streamStarted;
	}
	public function set streamStarted(s:Boolean) :void{
		_streamStarted = s;
	}
	public function get id():String {
		return _id;
	}
	public function set id(s:String) :void{
		_id = s;
	}	
	public function get dvrDuration():Number {
		return _dvrDuration;
	}
	public function get startTime():Number {
		return _startTime;
	}
	
	public function set startTime(s:Number) :void{
		_startTime = s;
	}

	/**
	 * Till now, I don't know the BW details. So igore this feature first.--Herry
	 * There are two bandwidth detections, script based bw detection and native bw detection.
	 * Native bandwidth detection is available only from Flash Media Server 2.5 release
	 * Script based bandwidth detection works regardless of server version,
	 * but it requires server side script, main.asc. 
	 * If it is script based bandwidth detection, 
	 * connection need to provide additional flag to enable that. 
	 */
	public function connect(u:String) :void{
		// Set connectionStartTime to check how long it takes to establish connection
		_connectionStartTime = (new Date()).getTime();
		mylogger.debug("** "+ this._id+" "+ this._connection.uri+" " + "Connection Start Time " + _connectionStartTime.toString(), mylogger.DEBUG);
		_connection.connect(u);
	}
	

	public function playStream(stream_name:String,start:Number,len:Number,reset:Number) :void{
		_stream.play(stream_name,start,len,reset);
	}
	public function playStream2(OldStreamName:String, StreamName:String, type:Number,duration:Number):void {
		var param:NetStreamPlayOptions = new NetStreamPlayOptions();
		param.len = duration;
		param.start = -2;
		param.oldStreamName = OldStreamName;
		param.streamName = StreamName;
		switch(type) {
			case 1:
			param.transition = NetStreamPlayTransitions.SWAP;
			break;
			case 2:
			param.transition = NetStreamPlayTransitions.SWITCH;
			break;
			default:
			trace("Wrong type");
		}
		_stream.play2(param);
	}
	
	public function onBWDone():void {
		//trace("DEBUG onbandwithdone");
		mylogger.debug("onbandwithdone", mylogger.DEBUG);
	}
	public function seek(pos:Number) :void{
		//seek pos, based on time, second
		if(_streamStarted)
			_stream.seek(pos);
	}
	public function resume() :void{
		//seek pos, based on time, second
		if(_streamStarted)
			_stream.resume();
	}
	
	public function asyncErrorHandler(event:AsyncErrorEvent):void {
		trace("ERROR"+event.error);
	}
	/**
	 * NetConnection status handler and callback function
	 */
	private function onNcStatus(info:NetStatusEvent) :void{
		mylogger.debug("** " + this._id + " " + this._connection.uri + " : " + info.info.code + " : " + info.info.description, mylogger.DEBUG);
		switch(info.info.code) {
			case "NetConnection.Connect.Success": 
				_connectOpened = true;
				var currentTime:Number= (new Date()).getTime();
				var responseTime:Number = ( currentTime - this._connectionStartTime) / 1000;
				if(responseTime > myClient._CONNECTION_RESPONSE_TIME) {
					// Connection takes long time need to check what happens. 
					var d:Object = new Object();
					d.name = "_" + this._id;
					d.info = _connection.uri+" - Duration to get connection "+ responseTime;
					d.description = "Connection delay happened";
					mylogger.debug("** response time: " + responseTime
					 + " threshold: " + myClient._CONNECTION_RESPONSE_TIME, mylogger.DEBUG);
				}
				this._startTime = currentTime;
				this._streamStartTime = currentTime;
				// Play a stream on Connection complete
				this._stream = new NetStream(this._connection);
				this._stream.addEventListener(NetStatusEvent.NET_STATUS, onNsStatus);
				this._stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				this._stream.client = _client;
				mylogger.debug("** " + this._id + "StreamName " + _streamName, mylogger.DEBUG);
				this._video.attachNetStream(_stream);
				SendingEvents("ConnectionSuccess", "ConnectionSuccess");
				//this.playStream(_connection);
				break;
			case "NetConnection.Connect.Rejected":
			if (info.info.ex.code == "302") {
				var redirectUrl:String = info.info.ex.redirect;
				SendingEvents("Connection302", redirectUrl);
				//trace("DEBUG Redirect 302:"+ redirectUrl + "***" );
				_connection.close();
				_connection.removeEventListener(NetStatusEvent.NET_STATUS,onNcStatus);
				_connection.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				
				_connection = new NetConnection();
				_connection.addEventListener(NetStatusEvent.NET_STATUS, onNcStatus);
				_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				_connection.client = this;
				connect(redirectUrl);
			} else {
				trace("DEBUG"+info.info.ex.code);
				_connection.close();
			}
				break;
			case "NetConnection.Connect.Closed":
				//successUsers.text = parseInt(successUsers.text) - 1;
				trace("DEBUG Close NC");
				if(!_connectOpened) {
					SendingEvents("ConnectionClosed", "ConnectionClosed");
				}
				break;
			case "NetConnection.Connect.Failed":
				//successUsers.text = parseInt(successUsers.text) - 1;
				mylogger.debug("Connect Failed", mylogger.ERROR);
				SendingEvents("ConnectionFailed", "ConnectionFailed");
				break;
			default:
				trace("DEBUG default,catch nothing");
		}
	}
	private function SendingEvents(eventCode:String, eventDetail:String) :void {
		var evtObj:myEvent = new myEvent();
		evtObj.ClientEvt = eventCode;
		evtObj.ClientEvtInfo = eventDetail;
		dispatchEvent(evtObj);
	}
	private function SendingEvents2(eventCode:String, eventDetail:String,eventMsg:String) :void {
		var evtObj:myEvent = new myEvent();
		evtObj.ClientEvt = eventCode;
		evtObj.ClientEvtInfo = eventDetail;
		evtObj.PutsMsg(eventMsg);
		dispatchEvent(evtObj);
	}
	/**
	 * Callback functions for script bandwidth detection
	 */
	
	/**
	 * NetStream status handlers & global setting
	 */
	private function onNsStatus(info:NetStatusEvent) :void {
		//trace("nsstatus:"+info.info.code);
		mylogger.debug("** "+this._id + " " + this._streamName + " NetStream.onStatus " + info.info.code, mylogger.DEBUG);
		var d:Object = new Object();
		switch(info.info.code) {
			case "NetStream.Play.Start":
			SendingEvents("StreamStarted", "StreamStarted");
			_streamStarted = true;
				
				if(this._streamStartTime != 0) {
					var responseTime:Number = ( (new Date()).getTime() - this._streamStartTime) / 1000;
					if(responseTime > myClient._STREAM_RESPONSE_TIME) {
						// Stream play takes long time need to check what happens. 
						// Broadcast delay event. 
						
						d.name = "_" + this._id;
						d.streamName = this._streamName;
						d.info = this._connection.uri+" - "+this._streamName+" - Duration from connect to play " +responseTime;
						d.description = "Stream delay happened";
						mylogger.debug("** stream response time: " + responseTime
						 + " threshold: " + myClient._STREAM_RESPONSE_TIME, mylogger.DEBUG);
					}
					this._streamStartTime = 0;
				}
				break;
			case "NetStream.Play.Stop":
				this._streamStarted = false;
				SendingEvents("StreamStopped", "Stopped: "+this._streamName);
				break;
			case "NetStream.Buffer.Full":
				mylogger.debug("bufferTime Full",mylogger.DEBUG);
				break;
			case "NetStream.Play.StreamNotFound":
				mylogger.debug("StreamNotFound", mylogger.DEBUG);
				SendingEvents("StreamNotFound", "StreamName :"+this._streamName);
				break;
			case "NetStream.Play.Transition":
				//trace(info.info.details);
				//trace(info.info.description);
				mylogger.debug("Transition to" + info.info.details, mylogger.DEBUG);
				SendingEvents("StreamTransition", info.info.details);
				break;
			case "NetStream.Buffer.Empty":
				if (this._rebuffering == false) {
					//this.stream.bufferTime = this.stream.bufferTime * 2;
					//this._rebuffering = true;
				} else {
					// Video starts stuttering.
					if(this._rebufferingCount == 3) {
						//var d:Object = new Object();
						d.name = "_" + this._id;
						d.streamName = this._streamName;
						d.info = this._connection.uri+" - "+this._streamName+" - Playtime="+this._stream.time+" - Play rebuffering";
						d.description = "Client video stuttering from buffer empty/full";
						mylogger.debug("** stream stuttering happened", mylogger.DEBUG);
					} else {
						//this.stream.bufferTime = this.stream.bufferTime * 2;
						this._rebufferingCount = this._rebufferingCount + 1;
					}

				}
				//break;
			case "NetSream.Play.InsufficientBW":
				//var d:Object = new Object();
				d.name = "_" + this._id;
				d.streamName = this._streamName;
				d.info = this._connection.uri+" - "+this._streamName+" - Playtime="+this._stream.time+" - InsufficientBW";
				d.description = "Client doesn't have enough data to play";
				mylogger.debug("** stream insufficient bw happened", mylogger.DEBUG);
				//break;
			default :
				SendingEvents("NetStreamEvt", info.info.code);
		}
	}
	private function onDVRResult(result:Object):void
	{
		switch(result.code) {
			case "NetStream.DVRStreamInfo.Success":
			var myresult_currLen:String = result.data.currLen;
			var myresult_maxLen:String = result.data.maxLen;
			var myresult_begOffset:String = result.data.begOffset;
			var myresult_endOffset:String = result.data.endOffset;
			var myresult_streamName:String = result.data.streamName;
			if (myresult_maxLen == "0") {
				//Not finished DVR
				//SendingEvents("DVRStreamInfo", "DEBUG 0");
				_dvrDuration = result.data.currLen;
			} else {
				// DVR finished, no seek required
				//SendingEvents("DVRStreamInfo", "DEBUG max not 0");
				_dvrDuration = 0;
			}
			//SendingEvents("DVRStreamInfo", myresult_currLen);
			//SendingEvents("DVRStreamInfo", myresult_streamName);
			//SendingEvents("DVRStreamInfo", myresult_maxLen );
			//SendingEvents("DVRStreamInfo", myresult_begOffset);
			//SendingEvents("DVRStreamInfo", myresult_endOffset);
			SendingEvents("DVRStreamInfo", "DVRStreamInfoSuccess"); 
			var DVRMsg : String = myresult_currLen+ ','+ myresult_maxLen + ',' + myresult_streamName;
			//var DVRMsg : String = myresult_streamName;
			//SendingEvents2("DVRStreamInfo", "DVRStreamInfoSuccess",DVRMsg); 

			break;
			case "NetStream.DVRStreamInfo.Failed":
			SendingEvents("DVRStreamInfo", "DVRStreamInfoFailed"); break;
			case "NetStream.DVRStreamInfo.Retry":
			SendingEvents("DVRStreamInfo", "DVRStreamInfoRetry"); 
			//TODO
			break;
			default:
			SendingEvents("DVRStreamInfo", "UnknownInfo"); break;
		}
	}
	public function getDVRMetadata(streamName:String):void {
		_connection.call("DVRGetStreamInfo", this._myResponse, streamName);
		
	}
	public function DVRSubscribe(streamName:String):void {
		_connection.call("DVRSubscribe", null, streamName);
	}
	private function _onPlayStatus(info:Object) :void {
		mylogger.debug("** "+this._id + " " + this._streamName + " NetStream.onPlayStatus " + info.code, mylogger.DEBUG );
		if (info.code == "NetStream.Play.Complete") {
			//It's not documented...
			//When playlist is played, playcomplete event can occur. But Stream status is not stopped.
			//So, we disable this status.
			//this._streamStarted = false;
			SendingEvents("NetStream", "PlayComplete");
		}
		if(info.code == "NetStream.Play.Switch") {
			
		}
		if (info.code == "NetStream.Play.TransitionComplete") {
			SendingEvents("StreamSwitchComplete", "StreamSwitchComplete");
		}
	}
	private function _onDVRSubscribe(info:Object) :void {
		SendingEvents("DVRSubscribe", "ERROR");
		if (info.code == "NetStream.Play.Start") {
			SendingEvents("DVRSubscribe", "DVRSubscribeSuccess");
		}else {
			SendingEvents("DVRSubscribe", "DVRSubscribeNOStart");
		}
	}
	private function _onMetaData(info:Object) :void {
		mylogger.debug("** " + this._id + " " + this._streamName + " onMeataData ", mylogger.DEBUG);
		SendingEvents("MetaData", "duration = " + info.duration);
		mylogger.debug("   vcodec/acodec/vrate/arate/duration = " + info.videocodecid + "/"+info.audiocodecid+"/"+info.videodatarate+"/"+info.audiodatarate+"/"+info.duration, mylogger.DEBUG);
		var key:String;
		for (key in info) {
			trace(key + ": " + info[key]);
		}
	}
	public function addEventListener(type:String,listener:Function,useCapture:Boolean=false,
	priority:int = 0, useWeakReference:Boolean=true):void {
		_dispatcher.addEventListener(type,listener,useCapture,priority,useWeakReference);
		
	}
	public function dispatchEvent(evt:Event):Boolean {
		return _dispatcher.dispatchEvent(evt);
	}
	public function hasEventListener(type:String):Boolean {
		return _dispatcher.hasEventListener(type);
	}
	public function	removeEventListener(type:String,listener:Function,useCapture:Boolean=false):void {
		return _dispatcher.removeEventListener(type,listener,useCapture);
	}
	public function willTrigger(type:String):Boolean {
		return _dispatcher.willTrigger(type);
	}

}
}