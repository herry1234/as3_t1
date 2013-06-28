/**
* ...
* @author Default
* @version 0.1
*/
package Client {
	import flash.display.Sprite;
	public class mylogger {	
	public static var debugTrace:Object = new Object();
	
	// Define public log level static
	// Use this set to trace log in other class
	public static var DEBUG:String = "debug";
	public static var WARN:String = "warn";
	public static var ERROR:String = "error";
	public static var INFO:String = "info";
	public static var NONE:String = "none";
	
	public static var logLevel:String = DEBUG;

	public static function debug(p:String, l:String):void {
		switch(logLevel) {
			case DEBUG:
				dtrace(p, l);
				break;
			case WARN:
				if(l == WARN || l == ERROR || l == INFO)
					dtrace(p, l);
				break;
			case ERROR:
				if(l == ERROR || l == INFO)
					dtrace(p, l);
				break;
			case INFO:
				if(l == INFO)
					dtrace(p, l);
				break;
			case NONE:
				// no trace
				break;
		}
	}
	
	public static function dtrace(p:String, l:String) :void {
		trace("[" + l + "] " + p);
		if(debugTrace != null) 
			debugTrace.text += "[" + l + "] " + p + "\n";
	}	
	
}
}