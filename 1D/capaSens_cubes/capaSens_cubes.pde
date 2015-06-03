// sensCap_1D
//  Display an interactive feedback for a 1D capacitive sensor.
//
//  The cube display come from https://processing.org/examples/spacejunk.html
//
// by antoine.delhomme@espci.fr
//

import processing.serial.*;

// Init the serial port
Serial serial;
int serialPort = 0;   // << Set this to be the serial port of your Arduino

// Parameters
//  nb_calib:            number of samples to do the calibration
int nb_calib = 100;

// Variables
//  capTime_min:        smallest value of the sensor, set during the calibration
//  capTime_max:        biggest value of the sensor
//  capTime_delta:      capTime_max is not updated until capTime_delta is passed
//  capTime_buff:       the output dynamic range is constraint by capTime_buff
//  capTime_buff_range: fraction of the dynamicRange used as a capTime_buff
float capTime_min = 0;
float capTime_max = 10100;
float capTime_delta = 60;
float capTime_buff = 10;
float capTime_buff_range = 40;

float zoom = 0;
float zoom_toGo = 0;
float zoom_step = 1;
float zoom_speed = 0.1;
float zoom_buff = 0;
int zoom_range = 640;

// Used for oveall rotation
float angle;

// Cube count-lower/raise to test performance
int limit = 200;

// Array for all cubes
Cube[] cubes = new Cube[limit];

void setup() {
  // setup: Init the programm
  //
  
  // Init the windows
  size(640, 360, P3D);
  background(0); 
  noStroke();
  
  // Set the window resizable
  if (frame != null) {
    frame.setResizable(true);
  }

  // Instantiate cubes, passing in random vals for size and postion
  for (int i = 0; i < cubes.length; i++){
    cubes[i] = new Cube(int(random(-10, 10)), int(random(-10, 10)), 
                        int(random(-10, 10)), int(random(-140, 140)), 
                        int(random(-140, 140)), int(random(-140, 140)));
  }

  // Init the serial connexion
  println("Serial ports list");
  println(Serial.list());
  serial = new Serial(this, Serial.list()[serialPort], 115200);
  
  // Do the calibration
  calibration();
}

void draw() {
  // draw: main function, update the display
  //
  
  // Read the capacitive sensor value
  float zoom_new = sensor2Range(zoom_range);
  
  if (zoom_new >= 0) {
    zoom_toGo = zoom_new;
  }
  
  if (zoom < zoom_toGo - zoom_buff) {
    zoom = zoom + zoom_step + zoom_speed * (zoom_toGo - zoom);
  } else if (zoom > zoom_toGo + zoom_buff) {
    zoom = zoom - zoom_step + zoom_speed * (zoom_toGo - zoom);
  }
  
  background(0); 
  fill(200);

  // Set up some different colored lights
  pointLight(51, 102, 255, 65, 60, 100); 
  pointLight(200, 40, 60, -65, -60, -150);

  // Raise overall light in scene 
  ambientLight(70, 70, 10); 

  // Center geometry in display windwow.
  // you can changlee 3rd argument ('0')
  // to move block group closer(+) / further(-)
  translate(width/2, height/2, -200 + zoom * 0.65);

  // Rotate around y and x axes
  rotateY(radians(angle));
  rotateX(radians(angle));

  // Draw cubes
  for (int i = 0; i < cubes.length; i++){
    cubes[i].drawCube();
  }
  
  // Used in rotate function calls above
  angle += 0.2;
}

float readFromSerial() {
  //readFromSensor: read the value of the sensor from the serial port
  //
  
  String capTimes = serial.readStringUntil('\n');
  float capTime =  -1;
  
  if(capTimes != null) {
    String[] parts = split(capTimes, " ");
    capTime = float(parts[0]);
    
    // Update capTime_max and capTime_buff if necessary
    if (capTime > capTime_max + capTime_buff) {
      capTime_max = capTime;
      capTime_buff = ( capTime_buff_range * (capTime_max - capTime_min) ) / 100;
      
      println("capTime_max: " + capTime_max);
    }
  }
  
  return capTime;
}

float sensor2Range(int range) {
  //sensor2Range: scale the sensor value onto a given range
  //
  
  float colr = 0;
  
  // Read the value of the sensor
  float capTime = readFromSerial();

  if (capTime >= 0) {
    colr = range * sqrt( (capTime - capTime_min) / (capTime_max - capTime_min  - capTime_buff) );
    colr = ( colr > range ) ? range : colr;
    colr = ( colr < 0 ) ? 0 : colr;
  } else {
    colr = -1;
  }
  
  return colr;
  
}

void calibration() {
  //calibration: get the noise level of the sensor
  
  println("\nCalibration ...");
  println("Le capteur doit être libre.");
  
  // La calibration mesure le bruit de font et le fixe comme minimum de sensibilité.
  int calibID = 0;
  
  // Loop over samples to get the lowest value of the sensor due to noise
  while ( calibID < nb_calib ) {
    float capTime = readFromSerial();
    
    if(capTime > capTime_min) {
      capTime_min = capTime;
    }
    
    println("[" + calibID + "] capTime_min: " + capTime_min);
    
    calibID = calibID + 1;
    delay(10);
  }
  
  // Update the capTime buff
  capTime_buff = ( capTime_buff_range * (capTime_max - capTime_min) ) / 100;
  
  println("Calibration terminée.");
  println("Vous pouvez utiliser le capteur.");
}


class Cube {

  // Properties
  int w, h, d;
  int shiftX, shiftY, shiftZ;

  // Constructor
  Cube(int w, int h, int d, int shiftX, int shiftY, int shiftZ){
    this.w = w;
    this.h = h;
    this.d = d;
    this.shiftX = shiftX;
    this.shiftY = shiftY;
    this.shiftZ = shiftZ;
  }

  // Main cube drawing method, which looks 
  // more confusing than it really is. It's 
  // just a bunch of rectangles drawn for 
  // each cube face
  void drawCube(){
    beginShape(QUADS);
    // Front face
    vertex(-w/2 + shiftX, -h/2 + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, -h/2 + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, h + shiftY, -d/2 + shiftZ); 
    vertex(-w/2 + shiftX, h + shiftY, -d/2 + shiftZ); 

    // Back face
    vertex(-w/2 + shiftX, -h/2 + shiftY, d + shiftZ); 
    vertex(w + shiftX, -h/2 + shiftY, d + shiftZ); 
    vertex(w + shiftX, h + shiftY, d + shiftZ); 
    vertex(-w/2 + shiftX, h + shiftY, d + shiftZ);

    // Left face
    vertex(-w/2 + shiftX, -h/2 + shiftY, -d/2 + shiftZ); 
    vertex(-w/2 + shiftX, -h/2 + shiftY, d + shiftZ); 
    vertex(-w/2 + shiftX, h + shiftY, d + shiftZ); 
    vertex(-w/2 + shiftX, h + shiftY, -d/2 + shiftZ); 

    // Right face
    vertex(w + shiftX, -h/2 + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, -h/2 + shiftY, d + shiftZ); 
    vertex(w + shiftX, h + shiftY, d + shiftZ); 
    vertex(w + shiftX, h + shiftY, -d/2 + shiftZ); 

    // Top face
    vertex(-w/2 + shiftX, -h/2 + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, -h/2 + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, -h/2 + shiftY, d + shiftZ); 
    vertex(-w/2 + shiftX, -h/2 + shiftY, d + shiftZ); 

    // Bottom face
    vertex(-w/2 + shiftX, h + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, h + shiftY, -d/2 + shiftZ); 
    vertex(w + shiftX, h + shiftY, d + shiftZ); 
    vertex(-w/2 + shiftX, h + shiftY, d + shiftZ); 

    endShape(); 

    // Add some rotation to each box for pizazz.
    rotateY(radians(1));
    rotateX(radians(1));
    rotateZ(radians(1));
  }
}
