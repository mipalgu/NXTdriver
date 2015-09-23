/**                                                                     
 *  \file test.cpp 
 *                                                                       
 *  Test program Created by Vlad Estivill-Castro in 2014 (based on Esteve-Fernandez version).
 *  This is a program that test the r2d2mipal connection to the NXT from Ubuntu or MacOS
 *  via USB connection. It is part of the r2d2mipal package.
 *  The NXT is supposed to be built as a differential robot, 
 *  with the right wheel to Motor_B, left wheel to port of Motor_C, and Motor_A free
 *  Touch bumpers are right on port 1, left on port 2
 *  Sonar sensor on port 3 and light sensor on port 4
*/
#include <iostream>
#include <unistd.h>

#include "r2d2_base.h"
#include "bluetooth.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wold-style-cast"
#include "usb.h"
#pragma clang diagnostic pop

static __attribute__((__noreturn__)) void usage(const char *cmd)
{ std::cerr << "Usage (no parameters usb, -b bluetooth-connection): " << cmd << " [-b] " << std::endl;
	exit(EXIT_FAILURE); }


int main(int argc, char * argv[] )
{
    std::cout << "R2D2-NXT test program: (c) Vlad Estivill-Castro" << std::endl;

    int ch;
    bool bluethoothConenction = false;
    while ((ch = getopt(argc, argv, "b:")) != -1) { 
	    switch(ch) {
	    case 'b': bluethoothConenction = true;// bluethooth connection
		    std::cout << optarg << std::endl;
		    break;
	    case '?':
	    default: usage(argv[0]); }
    }

    r2d2::Brick* brick;
    if (bluethoothConenction)
    { r2d2::BTBrickManager btm;
       brick = btm.list()->at(0);
    }
    else
    { r2d2::USBBrickManager usbm;
      brick = usbm.list()->at(0);
    }

    int turnCount = 0;

    //initialize the NXT and continue if it succeeds
    r2d2::NXT* nxt = brick->configure(r2d2::SensorType::TOUCH_SENSOR, r2d2::SensorType::TOUCH_SENSOR,
                                      r2d2::SensorType::SONAR_SENSOR, r2d2::SensorType::ACTIVE_LIGHT_SENSOR,
				      r2d2::MotorType::STANDARD_MOTOR,
                                      r2d2::MotorType::STANDARD_MOTOR, r2d2::MotorType::STANDARD_MOTOR);


    if (nxt != nullptr) { 

        std::cout << brick->getName() << std::endl;
        r2d2::Sensor* sensor = nxt->sensorPort(r2d2::SensorPort::IN_2); // obtain a sensor from port 2
        r2d2::Sensor* sonar_sensor = nxt->sensorPort(r2d2::SensorPort::IN_3); // obtain a sensor from port 3
        r2d2::Motor* motor = nxt->motorPort(r2d2::MotorPort::OUT_A);
	brick->playTone(400, 10000);
        int oldCount = motor->getRotationCount();
        while (1) { //main loop
            if (true==sensor->getValue()) { //if the touch sensor is pressed down...
		   motor->setForward(50);    //turn the motor in port 1 on 50% power (Motor_A is free, robot does not move)
	           int value_sonar= sonar_sensor->getValue();
                   std::cout << "There is something at " << value_sonar << " cm " << std::endl;
		   brick->stopSound();
		    
            } else {
                motor->stop(false);    //if the touch sensor is not pressed down turn the motor off
            }
            int newCount = motor->getRotationCount();
            if (newCount > oldCount) {
                turnCount += newCount - oldCount;
                oldCount = newCount;
                std::cout << "Number of turns so far is..." << turnCount << std::endl;
            }
        }
    }
    return 0;
}
