## Environment setup
1. Install the Arduino IDE and Teensydruino: https://www.pjrc.com/teensy/teensyduino.html
2. pull this repository, root file is refered to as /auto-dog-toy for the remainder of the docs
3. In the Arduino IDE, go to File -> Preferences -> Sketchbook tab -> Sketchbook Location and set it to /auto-dog-toy
4. You should now be able to open up .ino files, and #include library_name, and upload sketches to the board

Note that you can always compile code without the board connected to catch compile time bugs.


## Directory structure
/auto-dog-toy
    /libraries
        - contains library files, both custom and downloaded
        - each library file has the directory structure:
            /LibraryName
                library_header.h
                library_source.cpp
    driver.ino
        - Main driver program, what we flash in the end
        - first iteration -> simple loop:
            - read sensors
            - update state
                - dog location
                - dog engagement
                - current velocity
            - actuator update
            - (periodic) - SD logging
            - (periodic/override) - Bluetooth reporting

    system_test.ino
        - System test script, to make sure everything is functional
        - loads libraries
        - sensor test
            - accel reader
                - does this have temp
            - pir sensors
            - thermal camera
        - actuator test
            - SD card read/write
            - motor forward/reverse
            - bluetooth module

