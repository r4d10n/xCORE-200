// Copyright (c) 2015, XMOS Ltd, All rights reserved
/**
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the
 *
 **/

#ifndef WEB_PAGE_FUNCTIONS_H_
#define WEB_PAGE_FUNCTIONS_H_

/** Initialize the web application state
 */
void init_web_state();


/** Increments page visit counter after a page is completed served.
 *  This functions gets called once the page is completed rendered.
 *
 *  \param    app_state0        Reference to web application state.
 *  \param    connection_state  The connection state of the page being served
 *
 *  \returns  none
 **/
void post_page_render_increment_counter(int app_state0, int connection_state);


/** Gets page visit counter value
 *
 *  \param    app_state0        Reference to web application state.
 *  \param    buf               The buffer to copy the page visit counter value into
 *
 *  \returns  the length of the copied counter value.
 **/
int get_counter_value(int app_state0, char buf[]);


/** Gets the parameter passed with GET / POST request
 *
 *  \param    connection_state  The connection state of the page being served
 *  \param    buf               The buffer to copy the parameter into
 *
 *  \returns  the length of the copied parameter value. 0 is returned if no parameter is received.
 **/
int get_input_param(int connection_state, char buf[]);


/** Gets the current value of an 32-bit timer
 *
 *  This functions is defined in .xc file as the XC features
 *  are used to obtain timer value.
 *  \param    buf               The buffer to copy the parameter into
 *
 *  \returns  the length of the copied timer value.
 **/
int get_timer_value(char buf[]);


/** Gets web image file name for LED status indication
 *
 *  \param    buf               The buffer to copy the image file name.
 *  \param    app_state0        Reference to web application state.
 *  \param    led_id            LED identification number (0,1,2,3)
 *
 *  \returns  the length of the copied file name.
 **/
int get_led_image(char buf[], int app_state0, int led_id);


/** Reads buttons status and updates the application state values
 *
 *  \param    app_state0        Reference to web application state.
 *
 *  \returns  0 indicating no output string.
 **/
int update_button_status(int app_state0);


/** Gets button state as string "Pressed" or "Not pressed"
 *
 *  \param    buf               The buffer to copy the string.
 *  \param    app_state0        Reference to web application state.
 *  \param    led_id            LED identification number (0,1,2,3)
 *
 *  \returns  the length of the copied string.
 **/
int get_button_state_str(char buf[], int app_state0, int button_id);


/** Gets button state image by means of a CSS class name ('up' or 'down')
 * These CSS class names are defined in gpio.html file.
 *
 *  \param    buf               The buffer to copy the page visit counter value into
 *  \param    app_state0        Reference to web application state.
 *  \param    led_id            Button number (0,1)
 *
 *  \returns  the length of the copied class name.
 **/
int get_button_state_img(char buf[], int app_state0, int button_id);

int get_button_state_val(char buf[], int app_state0, int button_id);
int get_accel_state_val(char buf[], int app_state0, int button_id);

/** Processes the POST requests to toggle LEDs
 *
 *  \param    buf               Not used
 *  \param    app_state0        Reference to web application state.
 *  \param    connection_state  The connection state of the page being served
 *
 *  \returns  0
 **/
int process_web_page_data(char buf[], int app_state0, int connection_state);


/** Initializes the GPIOs connected to LEDs and buttons
 **/
void init_gpio(void);


/** Switches the LED ON or OFF
 *
 *  \param    led_i             LED identification number (0,1,2,3)
 *  \param    val               Value to be set ( 1 - OFF; 0 - ON)
 **/
void set_led_state(int led_id, int val);

/** Gets button state by reading the I/O port connected to buttons.
 *
 *  \param    button_id         Button identification number (0,1)
 *
 *  \returns  button state (0 - Pressed; 1 - Not pressed)
 **/
int get_button_state(int button_id);

/** Gets accelerometer reading for id (X:0, Y:1, Z:2).
 *
 *  \param    accel_id         Accelerometer Axis Id (X:0,Y:1,Z:2)
 *
 *  \returns  accelerometer reading for specified axis
 **/
int get_accel_reading(int accel_id);

#endif /* WEB_PAGE_FUNCTIONS_H_ */
