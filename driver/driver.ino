// NOTE: This code is out of date

#include <Adafruit_LSM9DS1.h>
#include <Adafruit_Sensor.h>
#include <MotorInterface.h>

#define num_readings 10
#define threshold 20
#define accel_base 13
#define move_delay 600
#define turn_delay 100
#define stop_delay 300

enum states {
  SCAN,
  CHASE,
  AVOID,
  OBST
};

bool lastMoveForward = false;

enum states state;

Adafruit_LSM9DS1 lsm = Adafruit_LSM9DS1();
MotorInterface motor1 = MotorInterface(5, 4, 3);
MotorInterface motor2 = MotorInterface(12, 11, 13);

bool irArr[4] = {false};
bool pirArr[2] = {false};

int fl_pin = 10;
int fr_pin = 8;
int bl_pin = 6;
int br_pin = 9;
int f_pir_pin = 2;
int b_pir_pin = 7;

byte pins[6] = {
  fl_pin,
  fr_pin,
  bl_pin,
  br_pin,
  f_pir_pin,
  b_pir_pin
};

byte sensorByte = B00000000;

bool isEngaged = false;

void forward() {
  motor1.forward();
  motor2.forward();
  lastMoveForward = true;
  delay(move_delay);
}

void backward() {
  motor1.backward();
  motor2.backward();
  lastMoveForward = false;
  delay(move_delay);
}

void left() {
  motor1.forward();
  motor2.backward();
  delay(turn_delay);
}

void right() {
  motor1.backward();
  motor2.forward();
  delay(turn_delay);
}

void hardStop(){
  motor1.hardStop();
  motor2.hardStop();
  delay(stop_delay);
}


void randomTurn() {
  long rng = random(0, 1);
  if (rng == 0) {
    left();
  } else {
    right();
  }
  hardStop();
}

void setup() {
  Serial.begin(115200);

  while (!Serial) {
    delay(1); 
  }
  
  if (!lsm.begin())
  {
    Serial.println("E1");
    while (1);
  }

  lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_2G);
  lsm.setupMag(lsm.LSM9DS1_MAGGAIN_4GAUSS);
  lsm.setupGyro(lsm.LSM9DS1_GYROSCALE_245DPS);

  // Sensor pins
  pinMode(fl_pin, INPUT);
  pinMode(fr_pin, INPUT);
  pinMode(bl_pin, INPUT);
  pinMode(br_pin, INPUT);
  pinMode(f_pir_pin, INPUT);
  pinMode(b_pir_pin, INPUT);

  Serial.println("SETUP COMPLETE");
  Serial.println("===============");
}

void loop() {
  switch (state) {
    case SCAN:
      Serial.println("SCAN STATE");
      scan();
      if (bitRead(sensorByte, 4) == 0 || bitRead(sensorByte, 5) == 0) {
        if (bitRead(sensorByte, 0) == 1 ||
            bitRead(sensorByte, 1) == 1 ||
            bitRead(sensorByte, 2) == 1 ||
            bitRead(sensorByte, 3) == 1){
          state = OBST;
        }
      } else if (isEngaged == 0) {
        state = CHASE;
      } else if (isEngaged == 1) {
        state = AVOID;
      }
      randomTurn();
      break;
    case CHASE:
      Serial.println("CHASE STATE");
      if (bitRead(sensorByte, 4) == 1) {
        forward();  
      } else {
        backward();
      }
      state = SCAN;
      break;
    case AVOID:
      Serial.println("AVOID STATE");
      if (bitRead(sensorByte, 5) == 1) {
        forward();  
      } else {
        backward();
      }
      state = SCAN;
      break;
    case OBST:
      Serial.println("OBST STATE");
      if (lastMoveForward) {
        backward();
      } else {
        forward();
      }
      hardStop();
      randomTurn();
      state = SCAN;
      break;
  }
  Serial.println("============");
}

// Updates sensorByte
// Updates isEngaged
void scan() {
  hardStop();
  sensorByte = B00000000;
  for (int i = 0; i < 6; i++) {
    if (digitalRead(pins[i]) == 0) {
      sensorByte |= (1<<i);
    }
  }
  for (int i = 0; i<6; i++) {
    Serial.print(bitRead(sensorByte, i));
  }
  Serial.println();
  isEngaged = false;
  for (int i = 0; i < num_readings; i ++) {
    lsm.read();
    sensors_event_t a, m, g, temp;
    lsm.getEvent(&a, &m, &g, &temp); 
    if (abs(a.acceleration.x) + abs(a.acceleration.y) + abs(a.acceleration.z) > threshold) {
      isEngaged = true;
      break;
    }
  }
  Serial.print("isEngaged: "); Serial.println(isEngaged);
}

