package sched {
	import flash.geom.*;
	import flash.display.*;
	import flash.events.*;
	import fl.controls.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.printing.*;
	
	public class courseSchedule extends Sprite {
		// xml data
		var scheduleXML:XML;
		var descriptionsXML:XML;
	
		// constants
		var weekdays=new Array();
		var timeslot=new Array();
		var colors=new Array();
		
		// time slots
		var slots=new Array();
		var conflictList=new Array();
		
		// list of added classes
		var classList=new Array();

		// selection stuff
		var mySelection;
		var descrField;
		var selBox;
		var submitBtn;
		var statusField;
		
		var printPage:Sprite;
		
		public function courseSchedule(sch:XML, descr:XML){
			scheduleXML=sch;
			descriptionsXML=descr;

			printPage=new Sprite();
			
			setupConstants();
			setupLabels();
			
			// create the time slots
			for(var x=0;x<5;++x){	
				slots[x]=new Array();
				for(var y=0;y<23;++y){
					var tmp=new timeslotLight();
					tmp.t.background=true;
					tmp.t.border=true;
					tmp.t.selectable=false;
					tmp.width=90;
					tmp.height=18;
					tmp.x=(x+1)*(tmp.width-1);
					tmp.y=(y+1)*(tmp.height-1);
					slots[x][y]=tmp;
					printPage.addChild(tmp);
					tmp.addEventListener(MouseEvent.CLICK, slotClickHandler);
				}
			}
			
			addChild(printPage);

			setupSelection();


			// setup status box
			statusField=new TextField();
			statusField.border=true;
			statusField.selectable=false;
			statusField.wordWrap=true;
			statusField.width=selBox.width;
			statusField.height=50;
			statusField.x=descrField.x;
			statusField.y=descrField.y + descrField.height + 10;
			addChild(statusField);

			// setup print button
			var printBtn = new Button();
			printBtn.x=statusField.x + statusField.width + 5;
			printBtn.y=statusField.y;
			printBtn.width=85;
			printBtn.label="Print";
			printBtn.addEventListener(MouseEvent.CLICK, printHandler);
			addChild(printBtn);

			
			var myTimer:Timer = new Timer(500);
			myTimer.addEventListener(TimerEvent.TIMER, timerLoop);
			myTimer.start();

		}
				
		public function printHandler(evt:Event){
			var pj=new PrintJob();
			var success = pj.start();
			
			if(success){
				try {
					pj.addPage(printPage);
				} catch (e:Error){
					trace(e.message);
				}
				pj.send();
			}
		}
				
		public function timerLoop(event:TimerEvent):void {
			for(var x=0;x<5;++x){
				for(var y=0;y<23;++y){
					var found=false;
					if(conflictList[x] && conflictList[x][y] && conflictList[x][y].length>0){
						for(var i=0;i<conflictList[x][y].length*2;++i){
							var j=i%conflictList[x][y].length;
							if(conflictList[x][y][j].id==slots[x][y].t.text){
								found=true;
							} else if(found){
								slots[x][y].t.text=conflictList[x][y][j].id;
								slots[x][y].t.backgroundColor=conflictList[x][y][j].bg;
								break;								
							}
						}
					}					
				}
			}	
		}

		// when clicking on an added class, set selection to that class
		public function slotClickHandler(evt:Event){
			for(var i=0;i<selBox.length;++i){
				if(selBox.getItemAt(i).data == evt.target.text){
					selBox.selectedIndex=i;
					selBox.dispatchEvent(new Event(Event.CHANGE));
				}
			}
		}
		
		// dispatch event for clicking on the submit button
		public function submitHandler(evt:Event){
			if(classList.indexOf(selBox.selectedItem.data.toString())==-1){
				addClass(selBox.selectedItem.data.toString());
			} else {
				remClass(selBox.selectedItem.data.toString());
			}

			selBox.dispatchEvent(new Event(Event.CHANGE));
		}
		
		// when a course is selected, fill out description etc
		public function newSelectionHandler(evt:Event){
			var course:XML=new XML(descriptionsXML.course.(@id==selBox.selectedItem.data));
			selBox.prompt = "";

			updateSubmitBtn();

			descrField.text=course.description;
			
			if(scheduleXML.course.(@id==course.@id).remarks != "None")
				descrField.appendText("\nRemarks: "+scheduleXML.course.(@id==course.@id).remarks);
			
			if(course.prerequisite && course.prerequisite.length()){
				descrField.appendText("\nPrerequisites: ");
	
				for(var i=0;i<course.prerequisite.length()-1;++i){	
					descrField.appendText(course.prerequisite[i].@id+", ");
				}
				descrField.appendText(course.prerequisite[i].@id);
			}

		  var conflicts=new Array();
			for(var x=0;x<5;++x){
				for(var y=0;y<23;++y){
					if(conflictList[x] && conflictList[x][y] && conflictList[x][y].length>0){
						for(i=0;i<conflictList[x][y].length;++i){
							if(conflictList[x][y][i].id == course.@id){
								for(var j=0;j<conflictList[x][y].length;++j){
									if(conflictList[x][y][j].id != course.@id && conflicts.indexOf(conflictList[x][y][j].id)==-1){
										conflicts.push(conflictList[x][y][j].id);
									}
								}
							}
						}
					}
				}
			}
			if(conflicts.length)
				descrField.appendText("\n\nConflicts with: "+conflicts);
		}
	

		// change submit button text if course is added or not
		public function updateSubmitBtn(){
			if(classList.indexOf(selBox.selectedItem.data.toString())==-1){
				submitBtn.label="Add";
			} else {
				submitBtn.label="Remove";
			}			
		}
	
		public function doUpdate(){
			// clear all slots
			conflictList=new Array();
			for(var x=0;x<5;++x){
				conflictList[x]=new Array();
				for(var y=0;y<23;++y){
					conflictList[x][y]=new Array();
					slots[x][y].t.text="";
					slots[x][y].t.backgroundColor=0xFFFFFF;
					slots[x][y].t.background=true;
				}
			}

			updateSubmitBtn();
			
			// build conflict list and fill in slots
			for(var j=0;j<classList.length;++j){
				var id=classList[j];
				for each (var meeting:XML in scheduleXML.course.(@id==id).meeting){
					for(var i=findStartSlot(meeting.time.@start);i<=findEndSlot(meeting.time.@end);++i){
						if(slots[weekdayToIndex(meeting.@day)][i].t.text != ""){
							conflictList[weekdayToIndex(meeting.@day)][i].push({id: id, bg: colors[j%colors.length]});
							conflictList[weekdayToIndex(meeting.@day)][i].push({id:slots[weekdayToIndex(meeting.@day)][i].t.text,
																																	bg:slots[weekdayToIndex(meeting.@day)][i].t.backgroundColor});														 							
						}

						slots[weekdayToIndex(meeting.@day)][i].t.text=id;
						slots[weekdayToIndex(meeting.@day)][i].t.backgroundColor=colors[j%colors.length];
					}
				}
			}
			
			var prereqs=new Array();
			for each (id in classList){
				var course=descriptionsXML.course.(@id==id);
				if(course.prerequisite && course.prerequisite.length()){
					for(i=0;i<course.prerequisite.length();++i){
						if(prereqs.indexOf(course.prerequisite[i].@id.toString())==-1)
							prereqs.push(course.prerequisite[i].@id.toString());
					}
				}
			}
			
			statusField.text="Total prerequisites: ";
			if(prereqs.length){
				statusField.appendText(prereqs.join(", "));
			} else {
				statusField.appendText("None");
			}
			
			statusField.appendText("\nConflicts: ");
			var conflicts = new Array();
			
			for(x=0;x<5;++x){
				for(y=0;y<23;++y){
					if(conflictList[x] && conflictList[x][y] && conflictList[x][y].length>0){
						for(i=0;i<conflictList[x][y].length;++i){
							if(conflicts.indexOf(conflictList[x][y][i].id.toString())==-1){
								conflicts.push(conflictList[x][y][i].id.toString());
							}
						}
					}
				}
			}
			
			if(conflicts.length){
				statusField.appendText(conflicts.join(", "));
			} else {
				statusField.appendText("None");
			}
			
		}

		public function addClass(id:String){
			classList.push(id);
			doUpdate();
		}
		
		public function remClass(id:String){
			classList.splice(classList.indexOf(id), 1);
			doUpdate();
		}
				
		// time/slot handling functions
		private function findStartSlot(start:String){
			for(var i=0;i<timeslot.length;++i){
				if(timeslot[i].start == start){
					return i;
				}
			}
			return -1;
		}
		private function findEndSlot(end:String){
			for(var i=0;i<timeslot.length;++i){
				if(timeslot[i].end == end){
					return i;
				}
			}
			return -1;
		}
		private function weekdayToIndex(day:String){
			for(var i=0;i<weekdays.length;++i){
				if(weekdays[i]==day){
					return i;
				}
			}
			return -1;
		}
		
		private function setupSelection(){
			// setup selection box
			selBox=new ComboBox()
			selBox.x=0;
			selBox.y=height+10;
//			selBox.prompt = "Select a Course";
			selBox.width=445;
			
			selBox.addEventListener(Event.CHANGE, newSelectionHandler);
			
			for each (var id:XML in scheduleXML.course.@id){
				selBox.addItem({ label: id+" - "+descriptionsXML.course.(@id==id).name, data:id });
			}
			addChild(selBox);
			selBox.prompt = "Select a Course";			
			
			// setup description box
			descrField=new TextField();
			descrField.border=true;
			descrField.selectable=false;
			descrField.wordWrap=true;
			descrField.width=selBox.width + 90;
			descrField.height=180;
			descrField.x=selBox.x;
			descrField.y=selBox.y + selBox.height + 5;
			addChild(descrField);
			
			// setup submit button
			submitBtn = new Button();
			submitBtn.x=selBox.x + selBox.width + 5;
			submitBtn.y=selBox.y;
			submitBtn.width=85;
			submitBtn.addEventListener(MouseEvent.CLICK, submitHandler);
			addChild(submitBtn);
			submitBtn.label="Add";
		}
		
		private function setupConstants(){
			colors.push(0xFFFFD5);
			colors.push(0xC4C4FF);
			colors.push(0xABFEFD);
			colors.push(0xE1E1E1);
			colors.push(0xB5FEB4);
			colors.push(0xCEA7E9);
			colors.push(0xFEBCBC);
						
			weekdays[0]="Monday";
			weekdays[1]="Tuesday";
			weekdays[2]="Wednesday";
			weekdays[3]="Thursday";
			weekdays[4]="Friday";
	
			timeslot[0]={ start : "08:00", end : "08:30" }
			timeslot[1]={ start : "08:30", end : "09:00" }
			timeslot[2]={	start : "09:00", end : "09:30" }
			timeslot[3]={	start : "09:30", end : "10:00" }
			timeslot[4]={ start : "10:00", end : "10:30" }
			timeslot[5]={	start : "10:30", end : "11:00" }
			timeslot[6]={	start : "11:00", end : "11:30" }
			timeslot[7]={	start : "11:30", end : "12:00" }
			timeslot[8]={	start : "12:00", end : "12:30" }
			timeslot[9]={	start : "12:30", end : "13:00" }
			timeslot[10]={start : "13:00", end : "13:30" }
			timeslot[11]={start : "13:30", end : "14:00" }
			timeslot[12]={start : "14:00", end : "14:30" }
			timeslot[13]={start : "14:30", end : "15:00" }
			timeslot[14]={start : "15:00", end : "15:30" }
			timeslot[15]={start : "15:30", end : "16:00" }
			timeslot[16]={start : "16:00", end : "16:30" }
			timeslot[17]={start : "16:30", end : "17:00" }
			timeslot[18]={start : "17:00", end : "17:30" }
			timeslot[19]={start : "17:30", end : "18:00" }
			timeslot[20]={start : "18:00", end : "18:30" }
			timeslot[21]={start : "18:30", end : "19:00" }
			timeslot[22]={start : "19:00", end : "19:30" }			
		}
		
		private function setupLabels(){
			var i:Number;
			var tmp;
	
			tmp=new timeslotLight();
			tmp.width=90;
			tmp.height=18;
			tmp.x=0;
			tmp.y=0;
			tmp.t.text="Time Table";
			printPage.addChild(tmp);
	
			for(i=0;i<5;++i){
				tmp=new timeslotDark();
				tmp.width=90;
				tmp.height=18;
				tmp.x=((i+1)*(tmp.width-1));
				tmp.y=0;
				tmp.t.text=weekdays[i];
				printPage.addChild(tmp);
			}

			for(i=0;i<timeslot.length;++i){
				tmp=new timeslotDark();
				tmp.width=90;
				tmp.height=18;
				tmp.x=0;
				tmp.y=((i+1)*(tmp.height-1));
				tmp.t.text=timeslot[i].start+" - "+timeslot[i].end;
				printPage.addChild(tmp);
			}
		}
	}
}