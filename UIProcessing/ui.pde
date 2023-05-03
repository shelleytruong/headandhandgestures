import processing.net.*;
import controlP5.*;
import java.util.List;
import javax.swing.JOptionPane;


Client client;
Table table;
Table dataTable;
int participants;
int trials;
String[] labels;
List<String> devicesAvaliable = new ArrayList<>();
DropdownList participantsList;
DropdownList trialsList;
DropdownList labelList;
DropdownList deviceList;
RadioButton radio;
String selectedParticipant;
String selectedTrial;
String selectedLabel;
String selectedDevice;
String trialsText;
String buttonText;

int startTime; 
boolean startButtonPressed = false;

Button startButton;
Button redo;

void setup() {
  size(500, 500);
  //startTime = millis(); 
  ControlP5 cp5 = new ControlP5(this);


  table = loadTable("Users/shelleytruong/Documents/Processing/requirement/requirements.csv", "header");
  // Get data from CSV 
  TableRow row = table.getRow(0);

  String participantsString = row.getString("Participants");
  participants = Integer.parseInt(participantsString);
  String trialsString = row.getString("Trial");
  trials = Integer.parseInt(trialsString);

  labels = new String[table.getRowCount()];
  for (int i = 0; i < table.getRowCount(); i++) {
    TableRow r = table.getRow(i);
    labels[i] = r.getString("Labels");
  }
 
  cp5.addLabel("Participant ID:")
    .setPosition(40, 30)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16));
  
  participantsList = cp5.addDropdownList(" ")
    .setPosition(160, 30)
    .setSize(60, 230)
    .setItemHeight(30)
    .setBarHeight(30)
    .setColorBackground(color(64));
  for (int i = 1; i < participants+1; i++) {
    participantsList.addItem(String.valueOf(i), i);
   }
  participantsList.close();
  

  cp5.addLabel("Trial ID:")
    .setPosition(40, 95)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16));

  trialsList = cp5.addDropdownList("Trials")
    .setPosition(160, 93)
    .setSize(60, 270)
    .setItemHeight(30)
    .setBarHeight(30)
    .setColorBackground(color(64));
  for (int i = 1; i < trials+1; i++) {
    trialsList.addItem(String.valueOf(i), i);
   }
  trialsList.close();

  cp5.addLabel("Labels:")
    .setPosition(40, 155)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16));
  
  // Create a dropdown list to show the gestures
  labelList = cp5.addDropdownList("Label list")
    .setPosition(160, 153)
    .setSize(200, 230)
    .setItemHeight(30)
    .setBarHeight(30)
    .setColorBackground(color(64));

  for (int i = 0; i < table.getRowCount(); i++) {
    TableRow r = table.getRow(i);
    labelList.addItem(labels[i], table.getRowCount()-1);
   }
  labelList.close();

   
  
  cp5.addLabel("Devices:")
    .setPosition(40, 230)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16));
    
    
  radio = cp5.addRadioButton("radio")
     .setPosition(160, 230)
     .setSize(20, 20)
     .setItemsPerRow(3)
     .setColorActive(color(200))
     .setColorLabel(color(0))
     .setColorBackground(color(64))
     .setSpacingColumn(50)
     .addItem("iPhone",1)
     .addItem("AirPods",2)
     .addItem("Both",3);
     
  
   cp5.addLabel("Devices avaliable:")
    .setPosition(40, 290)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16));

  startButton = cp5.addButton("startButton")
    .setPosition(160, 400)
    .setSize(70, 40)
    .setLabel("start")
    .setColorBackground(color(64));

  redo = cp5.addButton("redo")
    .setPosition(280, 400)
    .setSize(70, 40)
    .setColorBackground(color(64));
    
  //check if a file already exists
  String filePath = "Users/shelleytruong/PycharmProjects/pythonProject/airpofdsmotion.csv";
  File file = new File(filePath);
  if (file.exists()){
    print("yesssir");
    dataTable = loadTable(filePath, "header");
    TableRow r = dataTable.getRow(dataTable.getRowCount()-1);
    String prevParticipant = r.getString("ParticipantID");
    String prevTrial = r.getString("TrialID");
    String prevLabel = r.getString("Label");
 //   String prevDevice = r.getString("Device");
 
    participantsList.setValue(Integer.parseInt(prevParticipant)-1);
    participantsList.setCaptionLabel(participantsList.getItem((Integer.parseInt(prevParticipant))-1).get("name").toString());
    
    trialsList.setValue(Integer.parseInt(prevTrial)-1);
    trialsList.setCaptionLabel(trialsList.getItem((Integer.parseInt(prevTrial))-1).get("name").toString());
    
    int indexLabel = -1;
    for (int i = 0; i < labels.length; i++) {
      if (labels[i].equals(prevLabel)) { // check if the current element matches the target
        indexLabel = i; // if found, assign the current index to the index variable
        break; // exit the loop
      }
    }
    
    trialsText = (Integer.parseInt(prevTrial) + " out of " + trials);
    text(trialsText, 250, 110);
    
    labelList.setCaptionLabel(labelList.getItem(indexLabel).get("name").toString());
 // deviceList.setCaptionLabel(deviceList.getItem(1).get("name").toString()); 
    
  }else {
    println("File does not exist!");
    trialsText = ("0 out of " + trials);
    text(trialsText, 250, 110);
  }
//  devicesAvaliable.add("AirPods");
 // devicesAvaliable.add("iPhone");  
  
  client = new Client(this, "192.168.0.37", 139);  // Change the IP address and port to match your Python code
  client.write("ping");
  startTime = 0;
}

void draw() {
  background(255);
  // wait for data to be available
  if (client.available() > 0) {
    // read the data as a String
    String data = client.readString();
    String[] arr = data.split(",");
    // print the data to the console
    println("Received data: " + arr);
    devicesAvaliable.clear();
     if (arr[0].equals("iPhone")) {
        devicesAvaliable.add(arr[0]);  
      }
      if(arr.length > 11){
        if (arr[11].equals("AirPods")){
           devicesAvaliable.add(arr[11]);
        }
    }
  }
 
  
  if (devicesAvaliable.size() == 2){
    text("iPhone connected", 250, 300);
    text("Airpods connected", 250, 330);
  } 
  if (devicesAvaliable.size() == 1){
    text(devicesAvaliable.get(0) + " connected",250, 305);
    
    
  }if (devicesAvaliable.size() == 0){
      text("None", 250, 305);
  }
  if (selectedDevice == "null"){
     fill(255, 0, 0);
     text("Device selected is not connected", 160, 275); // display the text at the center of the screen

  }
  
  if (startButtonPressed){
    if(millis() - startTime >= 3000) {
      client.write("stop");
      startButton.setColorBackground(color(64));
      redo.setColorBackground(color(64));
      startTime = 0;
      startButtonPressed = false;
    }
  }
  
  
 
  
  if (labelList.isOpen() ) {
    labelList.bringToFront();
  }
  else if (participantsList.isOpen() ) {
    participantsList.bringToFront();
    trialsList.setLock(true);
    labelList.setLock(true);
  } else {
    trialsList.setLock(false);
    labelList.setLock(false);
  }
  if (trialsList.isOpen() ) {
    trialsList.bringToFront();
    labelList.setLock(true);
  } else {
    labelList.setLock(false);
  }
 
  
  // Get the selected partcipant from the dropdown list
  int participantValue = (int) participantsList.getValue();
  selectedParticipant = participantsList.getItem(participantValue).get("name").toString();
  
  // Get the selected trial from the dropdown list
  int trialValue = (int) trialsList.getValue();
  selectedTrial = trialsList.getItem(trialValue).get("name").toString();
  
  // Get the selected label from the dropdown list
  int labelValue = (int) labelList.getValue();
  selectedLabel = labelList.getItem(labelValue).get("name").toString();
  
  // Get the selected device from the dropdown list
 // int deviceValue = (int) deviceList.getValue();
 // selectedDevice = deviceList.getItem(deviceValue).get("name").toString();
  
  // Display the selected item in a label
  fill(0);
  trialsText = (selectedTrial + " out of " + trials);
  text(trialsText, 250, 110);
  
}

void startButton() {
   if(selectedDevice == null || selectedDevice.equals("null") ){
        JOptionPane.showMessageDialog(null, "Error", "Error", JOptionPane.ERROR_MESSAGE);

    }else{
      client.write("start "+ selectedParticipant + " " + selectedTrial + " " + selectedLabel + " " + selectedDevice);
      startButtonPressed = true;
      startButton.setColorBackground(color(200));
      redo.setColorBackground(color(64));
      startTime = millis();
    }
  
  /*
  if ((startButton.getLabel()).equals("start")){
    if(selectedDevice == null || selectedDevice.equals("null") ){
        JOptionPane.showMessageDialog(null, "Error", "Error", JOptionPane.ERROR_MESSAGE);

    }else{
      client.write("start "+ selectedParticipant + " " + selectedTrial + " " + selectedLabel + " " + selectedDevice);
  
      startButton.setColorBackground(color(200));
      redo.setColorBackground(color(64));
      startButton.setLabel("stop");
    }
  }else if ((startButton.getLabel()).equals("stop")){
    client.write("stop");
    startButton.setLabel("start");
    startButton.setColorBackground(color(64));
  }
  */
  

}
//void stop() {
//  stop.setColorBackground(color(200));
//  redo.setColorBackground(color(64));
///  startButton.setColorBackground(color(64));
//  client.write("stop");
//}
void redo() {
  //redo.setColorBackground(color(200));
  startButton.setColorBackground(color(64));
  startButton.setLabel("start");

 // stop.setColorBackground(color(64));


  //client.write("redo");
}

void controlEvent(ControlEvent event) {
  if (event.isFrom(radio)) {
    int selected = (int) event.getValue();
    selectedDevice = radio.getItem(selected-1).getCaptionLabel().getText();
    print(selectedDevice);

    if (devicesAvaliable.size() <=1 && !devicesAvaliable.contains(radio.getItem(selected-1).getCaptionLabel().getText())){
      selectedDevice = "null";
     // if (millis() - startTime < 2000) { // display the text for 2 seconds
     // textSize(32); // set the text size
    //  }
      
    }
  }
}
