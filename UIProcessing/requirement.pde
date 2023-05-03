import controlP5.*;
import processing.core.*;
import java.io.*;

PFont font;
ControlP5 cp5;
Textfield trialField;
Textfield labelField;
Textfield partcipantField;
Button addButton, saveButton;
DropdownList labelList;
Table table;

void setup() {
  size(400, 400);
  ControlFont font = new ControlFont(createFont("Arial", 20), color(0));


  cp5 = new ControlP5(this);


  // Create "Trial" label and number input field
  cp5.addLabel("Enter number of partcipiants:")
    .setPosition(100, 20)
    .setFont(font)
    .setColor(color(0));
  partcipantField = cp5.addTextfield("partcipantField")
    .setPosition(105, 50)
    .setSize(200, 25)
    .setFont(font)
    .setInputFilter(ControlP5.INTEGER);
  cp5.addLabel("Enter number of trials:")
    .setPosition(100, 90)
    .setFont(font)
    .setColor(color(0));
  trialField = cp5.addTextfield("trialField")
    .setPosition(105, 120)
    .setSize(200, 25)
    .setFont(font)
    .setInputFilter(ControlP5.INTEGER);
  // Create "Gestures" label and text input field
  cp5.addLabel("Enter labels:")
    .setPosition(100, 160)
    .setFont(font)
    .setColor(color(0));
  labelField = cp5.addTextfield("labelField")
    .setPosition(105, 190)
    .setSize(200, 25)
    .setFont(font);
  
   

  // Create "Add" button
  addButton = cp5.addButton("addButton")
    .setPosition(330, 189)
    .setSize(50, 27)
    .setCaptionLabel("Add")
    .setFont(font);
  

  // Create "Save" button
  saveButton = cp5.addButton("saveButton")
    .setPosition(330, 350)
    .setSize(50, 27)
    .setCaptionLabel("Save")
    .setFont(font);


  // Create a dropdown list to show the gestures
  labelList = cp5.addDropdownList("Labels")
    .setPosition(105, 250)
    .setSize(200, 230)
    .setItemHeight(20)
    .setBarHeight(25)
    .setFont(font);
    //.setColorLabel(color(0));
   // .setColorBackground(color(200));

  // Set the color of the label of each item to black
  labelList.setColorValueLabel(color(0));

  // Create a table to store the data
  table = new Table();
  table.addColumn("Participants");
  table.addColumn("Trial");
  table.addColumn("Labels");
}

void draw() {
  background(255);
}

void addButton(int value) {
  // Add the new gesture to the table and the dropdown list
  TableRow row = table.addRow();
  row.setString("Participants", partcipantField.getText());
  row.setString("Trial", trialField.getText());
  row.setString("Labels", labelField.getText());
  labelList.addItem(labelField.getText(), table.getRowCount()-1);
  labelField.clear();
}

void saveButton(int value) {
  // Save the table to a CSV file
  String filename = "requirements.csv";
  saveTable(table, filename);
  println("Saved " + table.getRowCount() + " rows to " + filename);
}
