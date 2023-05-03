import processing.net.*;
import controlP5.*;
import java.util.List;
import javax.swing.JOptionPane;
import java.util.Arrays; // Import the Arrays class



Client client;
int lastPrintTime = 0; // Variable to store the last time "hie" was printed
int printInterval = 1000;
int newIndex;
int startTime; 
boolean startButtonPressed = false;
Button startButton;
Textlabel predict;
String[] values;
String data;
String[] valueslist;
String x;
String datasplit;

float barHeight;
float maxValue;
float newsize;
float barWidth;
float y;
int lastTime;
/*
String[] xLabels = { 
"hand clockwise circle", "hand clockwise circle, head clockwise circle", "hand down" 
    ,"hand down, head down", "hand left", "hand left, head left",
 "hand right", "hand right, head right" ,"hand up" ,"hand up, head up",
 "head clockwise circle" ,"head down","head left", "head right", "head up",
 "standing still"
};


String[] xLabels = { 
"hand clockwise circle", "hand clockwise circle, head clockwise circle", "hand down" 
    ,"hand down, head down", "hand left", "hand left, head left",
 "hand right", "hand right, head right" ,"hand up" ,"hand up, head up",
 "head clockwise circle" ,"head down","head left", "head right", "head up"
};
*/


String[] xLabels = { 
"hand clockwise circle", "hand down" ,"hand left" ,"hand right" ,"hand up",
 "standing still"
};

/*
String[] xLabels = { 
"head clockwise circle", "head down" ,"head left" ,"head right" ,"head up",
 "standing still"
};

String[] xLabels = { 
"hand clockwise circle,clockwise circle", "hand down, head down" ,"hand left, head left" ,"hand right, head right" ,"hand up, head up",
 "standing still"
};
*/

String[] values2 = new String[xLabels.length];
float[] arr2 = new float[xLabels.length];


float[] arr = new float[xLabels.length + 3];
void setup() {
  size(500, 500);
  //startTime = millis(); 
  ControlP5 cp5 = new ControlP5(this);

 cp5.addLabel("Prediction:")
  .setPosition(50, 50)
  .setColorValue(color(0))
  .setFont(createFont("Arial", 16));
  /*
 startButton = cp5.addButton("startButton")
    .setPosition(50, 150)
    .setSize(70, 40)
    .setLabel("start")
    .setColorBackground(color(64));
    */
  
 predict = cp5.addLabel("N/A")
  .setPosition(150, 50)
  .setColorValue(color(0))
  .setFont(createFont("Arial", 16));
    
  client = new Client(this, "192.168.0.37", 373);  // Change the IP address and port to match your Python code
  client.write("ping");
  lastTime = millis(); 
  
  


  
}
void draw() {
  background(255);
  int currentTime = millis(); // Get the current time in milliseconds

  int elapsedTime = currentTime - lastTime;

  // wait for data to be available
  if (client.available() > 0) {
     data = client.readString();
     if (data != null) {
          // Parse the sensor data into x, y, and z coordinates
        //if (elapsedTime >= 200) {
        valueslist = data.split("/n"); 
        x=valueslist[0];
        println(valueslist[0].length());
       
        datasplit =valueslist[0].substring(1,  valueslist[0].length() - 2);
        print(datasplit);
        values = datasplit.split(" ");
        println(values);
       
        if(values.length==xLabels.length){
        
          for (int i = 0; i < (values.length); i++) {
            arr[i] = float(values[i]); // Convert strings to float and store in the data array
          }
          arr2=arr;
          maxValue = max(arr);
          for (int i = 0; i < arr.length; i++) {
    //println(o);
            if (arr[i] == maxValue){
              predict.setValue(xLabels[i]);
            }
          }
          //println(arr);
        //println(arr.length);
        /*
        newIndex = 0;
        
        // Copy the non-NaN values to the new array
        for (float value : arr) {
          if (!Float.isNaN(value)){
            try{
              //println(value);
              arr2[newIndex] = value;
              newIndex++;
            }
            catch (ArrayIndexOutOfBoundsException ex){
              println("error");
            }
          }
        }
        */
        //println(arr2.length);
       }
      // lastTime = currentTime; // Update the last collected time
      //}
     }
  }

  if(arr2 != null && arr2.length == xLabels.length){
    drawgraph(arr2);
    
  }
  
  

  if (startButtonPressed){
    if(millis() - startTime >= 2650) {
      client.write("stop");
      startButton.setColorBackground(color(64));
      startTime = 0;
      startButtonPressed = false;
    }
  }
  
}


void drawgraph(float[] arr2){
   boolean allZeros = true;
    for (float num : arr2) {
      if (num != 0.0f) {
        allZeros = false;
        break;
      }
    }
    if  (allZeros && xLabels.length != 15) {
      arr2[arr2.length - 1] = 1.0;  
   }
  
  if (allZeros && xLabels.length == 15) {

    fill(20); // Set the fill color
    for (int i = 0; i < arr2.length; i++) {
      y = i * barHeight + 150; // Calculate the y-coordinate of the bar
      rect(50, y, 0, barHeight); // Draw empty rectangles at 0 width
      fill(0); // Set text color
      text(xLabels[i], 50 + 5, y + barHeight / 2); // Draw the label as text next to the bar
      String n = "none";
      predict.setValue(n);

    }

  }  else{  
   
  
  barHeight = 250 / arr2.length; // Calculate the height of each bar
  maxValue = max(arr2) * 100; // Find the maximum value in the data array

  textAlign(LEFT, CENTER); // Set text alignment to left horizontally and center vertically
  textSize(12); // Set text size

  for (int i = 0; i < arr2.length; i++) {
    newsize = arr2[i] * 100;
    //println(o);
    if (newsize == maxValue){
      predict.setValue(xLabels[i]);
    }
    barWidth = map(newsize, 0, maxValue, 0, 250); // Map the data value to the width of the canvas
    y = i * barHeight + 150; // Calculate the y-coordinate of the bar

    // Draw a rectangle for each data value
    fill(20); // Set the fill color
    rect(50, y, barWidth, barHeight); // Draw the rectangle

    fill(0); // Set text color
    text(xLabels[i], 50 + barWidth + 5, y + barHeight / 2); // Draw the label as text next to the bar
 
 
    }  
  }
   
        
  
}


void startButton() {
    client.write("start");
    println("j");
    startButtonPressed = true;
    startButton.setColorBackground(color(200));
    startTime = millis();
 }
