package sched {
	import flash.geom.*;
	import flash.display.*;
	import flash.events.*;
	import fl.controls.*;
	import flash.text.*;
	
	public class courseSelection extends Sprite {
		var descriptionsXML:XML;
		var scheduleXML:XML;
		var descrField;
		var selBox;
		
		public function courseSelection(sch:XML, descr:XML){
			scheduleXML=sch;
			descriptionsXML=descr;
			
			// setup selection box
			selBox=new ComboBox()
			selBox.x=0;
			selBox.y=0;
			selBox.prompt = "Select a Course";
			selBox.width=520;
			
			selBox.addEventListener(Event.CHANGE, newSelectionHandler);
			
			for each (var id:XML in scheduleXML.course.@id){
				selBox.addItem({ label: id+" - "+descriptionsXML.course.(@id==id).name, data:id });
			}
			addChild(selBox);
			
			
			// setup description box
			descrField=new TextField();
			descrField.border=true;
			descrField.selectable=false;
			descrField.wordWrap=true;
			descrField.width=selBox.width + 104;
			descrField.height=150;
			descrField.x=selBox.x;
			descrField.y=selBox.y + selBox.height + 5;
			addChild(descrField);
			
			// setup submit button
			var submitBtn = new Button();
			submitBtn.x=selBox.x + selBox.width + 5;
			submitBtn.y=selBox.y;
			submitBtn.width=99;
			submitBtn.label="Add Course";
			submitBtn.addEventListener(MouseEvent.CLICK, submitHandler);
			addChild(submitBtn);
			
		}
		
		public function submitHandler(evt:Event){
			dispatchEvent(new addCourseEvent(selBox.selectedItem.data, addCourseEvent.COURSE_ADDED));
		}
		
		public function newSelectionHandler(evt:Event){
			var course:XML=new XML(descriptionsXML.course.(@id==selBox.selectedItem.data));
			
			descrField.text=course.description;

			if(course.prerequisite && course.prerequisite.length()){
				descrField.appendText("\nPrerequisites: ");

				for(var i=0;i<course.prerequisite.length()-1;++i){	
					descrField.appendText(course.prerequisite[i].@id+", ");
				}
				descrField.appendText(course.prerequisite[i].@id);
			}
		}
	}
}