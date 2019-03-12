#ifndef MotorInterface_h
#define MotorInterface_h

#include "Arduino.h"

#define SPEED_MAX 250
#define SPEED_MIN 70
#define TURN_MAX 10
#define TRIM_L 1.0
#define TRIM_R 1.0 

class MotorInterface
{
    public:
        MotorInterface(int l_forward, int l_backward, int l_enable, int r_forward, int r_backward, int r_enable);
		void forward(float turn = 0); 
		void backward();
		void stop();
		void hardStop();

    private:
        int _l_forward;
        int _l_backward;
		int _l_enable;
        int _r_forward;
        int _r_backward;
        int _r_enable;
        float _slope;
};

#endif
