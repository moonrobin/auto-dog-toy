#include "MotorInterface.h"
#include "Arduino.h"


MotorInterface::MotorInterface(int l_forward, int l_backward, int l_enable, int r_forward, int r_backward, int r_enable)
{
	_l_enable = l_enable;
	_l_forward = l_forward;
	_l_backward = l_backward;
	_r_enable = r_enable;
    _r_forward = r_forward;
    _r_backward = r_backward;
    _slope = (SPEED_MAX - SPEED_MIN)/TURN_MAX;

    pinMode(_l_enable, OUTPUT);
    pinMode(_l_forward, OUTPUT);
    pinMode(_l_backward, OUTPUT);
    pinMode(_r_enable, OUTPUT);
    pinMode(_r_forward, OUTPUT);
    pinMode(_r_backward, OUTPUT);
}

void MotorInterface::stop()
{
    digitalWrite(_l_enable, LOW);
    digitalWrite(_r_enable, LOW);
}

void MotorInterface::forward(float turn = 0)
{   
    digitalWrite(_l_forward, HIGH);
    digitalWrite(_l_backward, LOW);
    digitalWrite(_r_forward, HIGH);
    digitalWrite(_r_backward, LOW);

    float l_speed = min(SPEED_MAX, (_slope * turn) + SPEED_MAX);
    float r_speed = min(SPEED_MAX, (-1 * _slope * turn) + SPEED_MAX);
	Serial.print("Turning at angle "); Serial.println(turn);
    analogWrite(_l_enable, (int)(l_speed*TRIM_L));
    analogWrite(_r_enable, (int)(r_speed*TRIM_R));
}

void MotorInterface::backward()
{   
    digitalWrite(_l_forward, LOW);
    digitalWrite(_l_backward, HIGH);
    digitalWrite(_r_forward, LOW);
    digitalWrite(_r_backward, HIGH);

    analogWrite(_l_enable, (int)(SPEED_MAX*TRIM_L));
    analogWrite(_r_enable, (int)(SPEED_MAX*TRIM_R));
}

void MotorInterface::hardStop()
{
    digitalWrite(_l_forward, LOW);
    digitalWrite(_l_backward, LOW);
    digitalWrite(_r_forward, LOW);
    digitalWrite(_r_backward, LOW);
	stop();
}
