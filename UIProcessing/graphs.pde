import processing.net.*;
import controlP5.*;
import java.util.Arrays;

Client client;
ControlP5 cp5;


float[] iphoneAccX = new float[width]; // Create a buffer for the x-axis data
float[] iphoneAccY = new float[width]; // Create a buffer for the y-axis data
float[] iphoneAccZ = new float[width]; // Create a buffer for the z-axis data

float[] iphoneGyroX = new float[width]; // Create a buffer for the x-axis data
float[] iphoneGyroY = new float[width]; // Create a buffer for the y-axis data
float[] iphoneGyroZ = new float[width]; // Create a buffer for the z-axis data

float[] airpodsAccX = new float[width]; // Create a buffer for the x-axis data
float[] airpodsAccY = new float[width]; // Create a buffer for the y-axis data
float[] airpodsAccZ = new float[width]; // Create a buffer for the z-axis data

float[] airpodsGyroX = new float[width]; // Create a buffer for the x-axis data
float[] airpodsGyroY = new float[width]; // Create a buffer for the y-axis data
float[] airpodsGyroZ = new float[width]; // Create a buffer for the z-axis data

int index = 0;

void setup() {
    size(500, 500);
    cp5 = new ControlP5(this);

    cp5.addLabel("iPhone accelerometer")
    .setPosition(5, 10)
    .setColor(color(0));
    cp5.addLabel("iPhone gyroscpe")
    .setPosition(230, 10)
    .setColor(color(0));
    cp5.addLabel("AirPods accelerometer")
    .setPosition(5, 280)
    .setColor(color(0));
    cp5.addLabel("AirPods gyroscpe")
    .setPosition(230, 280)
    .setColor(color(0));
    
    client = new Client(this, "192.168.0.37", 92);  // Change the IP address and port to match your Python code
    client.write("ping");


}

void draw() {
  background(255);
  // wait for data to be available
  // Draw x and y axes
  stroke(0);
  line(0, 230/2, 230, 230/2); // x axis
  line(230/2, 0, 230/2, 230); // y axis
  
  stroke(0);
  line(270, 115, 500, 115); // x axis
  line(385, 0, 385, 230); // y axis
  
  stroke(0);
  line(270, 385, 500, 385); // x axis
  line(385, 270, 385, 500); // y axis
  
  stroke(0);
  line(0, 385, 230, 385); // x axis
  line(115, 270, 115, 500); // y axis
  
  client.write("ping");
  if (client.available() > 0) {
    // read the data as a String
    String data = client.readString();
    // print the data to the console
    
    println("reviceved fata " +(data));
    if (data != null) {
          // Parse the sensor data into x, y, and z coordinates
      String[] values = data.split(",");
      println(values);
      
      if(values[0].equals("iPhone")){
        float iphoneaccx = float(values[2]);
        float iphoneaccy = float(values[3]);
        float iphoneaccz = float(values[4]);
        
        float iphonegyrox = float(values[5]);
        float iphonegyroy = float(values[6]);
        float iphonegyroz = float(values[7]);
        
        
      // Add the x, y, and z values to their respective buffers and remove the oldest values
      iphoneAccX[index] = iphoneaccx;
      iphoneAccY[index] = iphoneaccy;
      iphoneAccZ[index] = iphoneaccz;
      
      iphoneGyroX[index] = iphonegyrox;
      iphoneGyroY[index] = iphonegyroy;
      iphoneGyroZ[index] = iphonegyroz;
      
      index = (index + 1) % iphoneAccX.length;
      
      plot(iphoneAccX,iphoneAccY,iphoneAccZ, 0, 230,0, 230);
      plot(iphoneGyroX,iphoneAccY,iphoneGyroZ, 0, 230,270, 500); 
      
      }
      if (values.length > 11){

      if(values[11].equals("AirPods")){
  
          float airpodsaccx = float(values[13]);
          float airpodsaccy = float(values[14]);
          float airpodsaccz = float(values[15]);
          
          float airpodsgyrox = float(values[16]);
          float airpodsgyroy = float(values[17]);
          float airpodsgyroz = float(values[18]);
            
          // Add the x, y, and z values to their respective buffers and remove the oldest values
          airpodsAccX[index] = airpodsaccx;
          airpodsAccY[index] = airpodsaccy;
          airpodsAccZ[index] = airpodsaccz;
          
          airpodsGyroX[index] = airpodsgyrox;
          airpodsGyroY[index] = airpodsgyroy;
          airpodsGyroZ[index] = airpodsgyroz;
          
          index = (index + 1) % airpodsAccX.length;
          s
          plot(airpodsAccX,airpodsAccY,airpodsAccZ, 500, 270,0, 230);
          plot(airpodsGyroX,airpodsGyroY,airpodsGyroZ, 500, 270,270, 500); 
        }
      }
   
    }
  }

 }
 
 void plot(float[] x,float[] y,float[] z, int heightNum1,int heightNum2, int widthNum1,int widthNum2){
    // Draw the x-axis data as a red line
      stroke(255, 0, 0);
      noFill();
      beginShape();
      for (int i = 0; i < x.length; i++) {
        float xX = map(i, 0, x.length - 1, widthNum1, widthNum2);
        float yX = map(x[i], -10, 10, heightNum1, heightNum2);
        vertex(xX, yX);
      }
      endShape();
  
      // Draw the y-axis data as a green line
      stroke(0, 255, 0);
      beginShape();
      for (int i = 0; i < y.length; i++) {
        float xY = map(i, 0, y.length - 1,widthNum1, widthNum2);
        float yY = map(y[i], -10, 10, heightNum1, heightNum2);
        vertex(xY, yY);
      }
      endShape();
  
      // Draw the z-axis data as a blue line
      stroke(0, 0, 255);
      beginShape();
      for (int i = 0; i < z.length; i++) {
        float xZ = map(i, 0, z.length - 1, widthNum1, widthNum2);
        float yZ = map(z[i], -10, 10, heightNum1, heightNum2);
        vertex(xZ, yZ);
      }
      endShape();
 }


      
     
