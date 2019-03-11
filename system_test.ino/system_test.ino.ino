#include <Wire.h>
#include <Adafruit_AMG88xx.h> // IR Camera
#include <Adafruit_LSM9DS1.h> // Gryo/Accel 
#include <Adafruit_Sensor.h>


Adafruit_AMG88xx amg;
Adafruit_LSM9DS1 lsm = Adafruit_LSM9DS1();

int pin_led = 13;
int pin_prox_front = 12;
int pin_prox_back = 14;
int front_obst;
int back_obst;

// Add these in when we hook up the motors
int pin_lmotor_forwards;
int pin_lmotor_backwards;
int pin_lmotor_enable;
int pin_rmotor_forwards;
int pin_rmotor_backwards;
int pin_rmotor_enable;


void setup() {
    Serial.begin(115200);
    bool status;

    // IR Camera Init
    Wire.setSCL(16);
    Wire.setSDA(17);
    status = amg.begin();
    if (!status) {
        Serial.println("ERROR: IR Camera init failed");
        while (1);
    } else {
        Serial.println("Initialized IR camera");
    }

    // Accel Init

    status = lsm.begin();
    if (!status){
        Serial.println("ERROR: Accel sensor init failed!");
    } else {
        Serial.println("Initialized Accel sensor");
    }

    lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_2G);
    lsm.setupMag(lsm.LSM9DS1_MAGGAIN_4GAUSS);
    lsm.setupGyro(lsm.LSM9DS1_GYROSCALE_245DPS);

    pinMode(pin_prox_front, INPUT);
    pinMode(pin_prox_back, INPUT); 

    pinMode(pin_led, OUTPUT);
    digitalWrite(pin_led, HIGH);

    delay(100); // let sensors boot up
}

float heat[AMG88xx_PIXEL_ARRAY_SIZE];

void loop() { 
    amg.readPixels(heat);
    Serial.println("IR Camera Reading:");
    Serial.print("[");
    for(int i=0; i<AMG88xx_PIXEL_ARRAY_SIZE; i++){
        Serial.print(heat[i]);
        Serial.print(", ");
        if( (i+1)%8 == 0 ) {
            Serial.println();
        }
    }
    Serial.println("]");
    Serial.println();

    lsm.read();  /* ask it to read in the data */ 
    sensors_event_t a, m, g, temp;
    lsm.getEvent(&a, &m, &g, &temp); 
    Serial.println("IR Camera Reading:");
    Serial.print("Accel X: "); Serial.print(a.acceleration.x); Serial.print(" m/s^2");
    Serial.print("\tY: "); Serial.print(a.acceleration.y);     Serial.print(" m/s^2 ");
    Serial.print("\tZ: "); Serial.print(a.acceleration.z);     Serial.println(" m/s^2 ");

    Serial.print("Mag X: "); Serial.print(m.magnetic.x);   Serial.print(" gauss");
    Serial.print("\tY: "); Serial.print(m.magnetic.y);     Serial.print(" gauss");
    Serial.print("\tZ: "); Serial.print(m.magnetic.z);     Serial.println(" gauss");

    Serial.print("Gyro X: "); Serial.print(g.gyro.x);   Serial.print(" dps");
    Serial.print("\tY: "); Serial.print(g.gyro.y);      Serial.print(" dps");
    Serial.print("\tZ: "); Serial.print(g.gyro.z);      Serial.println(" dps");

    Serial.println();

    back_obst = digitalRead(pin_prox_back);
    front_obst = digitalRead(pin_prox_front);
    Serial.print("Obstacle front: "); Serial.println(front_obst);
    Serial.print("Obstacle back: "); Serial.println(back_obst);
}


