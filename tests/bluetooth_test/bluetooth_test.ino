#include <SoftwareSerial.h>

const byte rxPin = 10;
const byte txPin = 11;

// set up a new serial object
SoftwareSerial mySerial (rxPin, txPin);

char junk;
String inputString="";
int pin_led = 13;

void setup()
{
    Serial.begin(9600);
    mySerial.begin(9600);            // set the baud rate to 9600, same as the Serial Monitor
}

void loop()
{
   // Serial.println("HELLO");   // Sends string to Serial Monitor
   // char x = mySerial.read();
   // mySerial.println("AT"); // Sends string to BLE
     waitForResponse();
}

void waitForResponse(){
    delay(500);
    while(mySerial.available()){
      Serial.write(mySerial.read()); //Reading from BLE, Writing to Serial Monitor
    }
    Serial.write("\n");
}
