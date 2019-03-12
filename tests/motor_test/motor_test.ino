#include <MotorInterface.h>

// Left, Right
// Forwards, backwards, enable
MotorInterface motor = MotorInterface(18, 19, 20, 23, 22, 21);

void setup() {

}

void loop() {
  for (int i = -10; i<= 10; i++) {
    motor.forward(i);
    delay(1000);
  }
  for (int i = 10; i>= -10; i--) {
    motor.forward(i);
    delay(1000);
  }
}

