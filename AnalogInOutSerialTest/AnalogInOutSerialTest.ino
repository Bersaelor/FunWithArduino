/*
  Analog input, analog output, serial output
 
 Reads an analog input pin, maps the result to a range from 0 to 255
 and uses the result to set the pulsewidth modulation (PWM) of an output pin.
 Also prints the results to the serial monitor.
 
 The circuit:
 * potentiometer connected to analog pin 0.
   Center pin of the potentiometer goes to the analog pin.
   side pins of the potentiometer go to +5V and ground
 * LED connected from digital pin 9 to ground
 
 created 29 Dec. 2008
 modified 9 Apr 2012
 by Tom Igoe
 
 This example code is in the public domain.
 
 */

// These constants won't change.  They're used to give names
// to the pins used:

#include <dht.h>
#include <Servo.h>

dht DHT;
Servo myservo;  // create servo object to control a servo

#define DHT11_PIN 5

const int analogPotiInPin = A0;  // Analog input pin that the potentiometer is attached to
const int analogLightInPin = A1;  // Analog input pin that the light sensor is attached to
const int analogOutPin = 9; // Analog output pin that the LED is attached to
const int servoPin = 3; // Analog output pin that the LED is attached to

int potiValue = 0;        // value read from the pot
int lightValue = 0;
int outputValue = 0;        // value output to the PWM (analog out)
int incomingByte = 0;
int ledState = 1;             // the current reading from the input pin
int servoPos = 90;    // variable to store the servo position
int servoState = 0;    // variable to store the servo position


unsigned long lastTempReadTime = 0;  // the last time the temp & hum was read
unsigned long humidTempDelay = 1000;    // the debounce time; temp and hum don't change that fast anyway

unsigned long lastServoChangeTime = 0;  // the last time the temp & hum was read
unsigned long servoChangeDelay = 1000;    // the debounce time; temp and hum don't change that fast anyway


void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600); 
  
  myservo.attach(servoPin);  // attaches the servo on pin 9 to the servo object
  pinMode(analogOutPin, OUTPUT);
}

void loop() {
  // read the analog in value:
  potiValue = analogRead(analogPotiInPin);
  // map it to the range of the analog out:
  outputValue = map(potiValue, 0, 1023, 0, 255);  
  // change the analog out value:
//  analogWrite(analogOutPin, outputValue);           
  outputValue = constrain(outputValue, 0, 255);
  // print the results to the serial monitor:
  Serial.print("poti = " );                       
  Serial.print(potiValue);      
  Serial.println(";");      


  if (Serial.available() > 0) {
    
    // read the incoming byte:
    incomingByte = Serial.read();
    if(incomingByte == 'H'){
      if (ledState) ledState = 0;
      else ledState = 1;
    }
    else if (incomingByte == 'S') {
      servoState = 1;
      servoPos = Serial.parseInt();
    }
    
    Serial.print("data received : " );
    Serial.println(incomingByte);      
  }
  
  if (ledState) {
    analogWrite(analogOutPin, 255);
  }
  else {
    analogWrite(analogOutPin, 0);
  }

  lightValue = analogRead(analogLightInPin);
  Serial.print("lightValue = " );                       
  Serial.print(lightValue);      
  Serial.println(";");

  outputValue = map(lightValue, 50, 500, 0, 255);
  outputValue = constrain(outputValue, 0, 255);
  Serial.print("light = " );                       
  Serial.print(outputValue);      
  Serial.println(";");
  
  if ((millis() - lastTempReadTime) > humidTempDelay) {
    int chk = DHT.read11(DHT11_PIN);
    switch (chk)
    {
      case DHTLIB_OK:  
                  Serial.print("OK,\t"); 
                  break;
      case DHTLIB_ERROR_CHECKSUM: 
                  Serial.print("Checksum error,\t"); 
                  break;
      case DHTLIB_ERROR_TIMEOUT: 
                  Serial.print("Time out error,\t"); 
                  break;
      case DHTLIB_ERROR_CONNECT:
          Serial.print("Connect error,\t");
          break;
      case DHTLIB_ERROR_ACK_L:
          Serial.print("Ack Low error,\t");
          break;
      case DHTLIB_ERROR_ACK_H:
          Serial.print("Ack High error,\t");
          break;
      default:
                  Serial.print("Unknown error,\t"); 
                  break;
    }
    
    Serial.print("humi = " );                       
    Serial.print(DHT.humidity, 1);      
    Serial.println(";");
  
    Serial.print("temp = " );                       
    Serial.print(DHT.temperature - 4.0, 1);      
    Serial.println(";");
    
    lastTempReadTime = millis();
  }
  
  //servo
  if ((millis() - lastServoChangeTime) > servoChangeDelay) {
    if (servoState) {
      myservo.write(servoPos);
      
      servoState = 0;
      lastServoChangeTime = millis();
    }
  }

  // wait 50 milliseconds before the next loop
  // for the analog-to-digital converter to settle
  // after the last reading:
  delay(50);                     
}
