package sched {
	import flash.events.Event;
	
	public class addCourseEvent extends Event{
		static public var COURSE_ADDED:String = "courseAdded";
		public var courseID:String;
			
		public function addCourseEvent(id:String, type:String, bubbles:Boolean = false, cancelable:Boolean = false){
			super(type, bubbles,cancelable);
			courseID = id;
		}
	}
}