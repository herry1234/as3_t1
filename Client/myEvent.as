/**
* ...
* @author Default
* @version 0.1
*/

package Client {
	import flash.events.Event;
	public class myEvent extends Event{
		public static const CLIENTEVENT:String = "FMSC";
		private var _clientevent:String;
		private var _entInfo:String;
		private var _msg:String;
		public function myEvent() {
			super(CLIENTEVENT);
		}
		public function set ClientEvt(evt:String):void {
			_clientevent = evt;
		}
		public function get ClientEvt():String {
			return _clientevent;
		}
		public function set ClientEvtInfo(evtInfo:String):void {
			_entInfo = evtInfo;
		}
		public function get ClientEvtInfo():String {
			return _entInfo;
		}
		public function PutsMsg(msg:String) :void {
			_msg = msg;
		}
		public function GetsMsg() :String {
			return _msg;
		}
	}
	
}
