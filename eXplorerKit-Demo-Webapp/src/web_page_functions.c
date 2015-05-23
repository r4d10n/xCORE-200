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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "simplefs.h"
#include "web_server.h"

/* Web application state */
typedef struct app_state_t {
  int counter;                  // Page visit counter
  int led_state[4];             // LED states
  int button_state[2];          // Button states
  int accel_state[3];
} app_state_t;

static app_state_t app_state;

/* Web images used for LED state indication */
static char led_on_image[] = "green_led_on.png";
static char led_off_image[] = "green_led_off.png";

/* Function to initialize web application state */
void init_web_state() {
  int i=0;
  app_state.counter = 1;
  for(i = 0; i < 4; i++) {
      app_state.led_state[i] = 0;
  }
  app_state.button_state[0] = 0;
  app_state.button_state[1] = 0;

  for(i = 0; i < 3; i++) {
      app_state.accel_state[i] = 0;
  }

  web_server_set_app_state((int) &app_state);    // Set app state to be used by dynamic content
}

/* Function to increment the page visit counter
 * It will be called everytime a page is rendered */
void post_page_render_increment_counter(int app_state0, int connection_state)
{
  app_state_t * app_state = (app_state_t *) app_state0;
  if (web_server_end_of_page(connection_state) &&
      web_server_get_current_file(connection_state) ==
      simplefs_get_file("index.html"))
    {
      app_state->counter++;
    }
  return;
}

/* Function to get the current page visit counter value */
int get_counter_value(int app_state0, char buf[])
{
  app_state_t * app_state = (app_state_t *) app_state0;
  int len = sprintf(buf, "%u", app_state->counter);
  return len;
}

/* Function to get the parameter passed with POST request */
int get_input_param(int connection_state, char buf[]) {
  return web_server_copy_param("input",  connection_state, buf);
}

/* Function to get the LED ON/OFF image filename */
int get_led_image(char buf[], int app_state0, int led_id)
{
  app_state_t *app_state = (app_state_t *) app_state0;
  if(app_state->led_state[led_id]) {
    strcpy(buf, led_on_image);
  } else {
    strcpy(buf, led_off_image);
  }
  return strlen(buf);
}

/* Function to get the status of button; ("Pressed" or "Not pressed") */
int get_button_state_str(char buf[], int app_state0, int button_id)
{
  app_state_t *app_state = (app_state_t *) app_state0;
  if(app_state->button_state[button_id]) {
      strcpy(buf, "Pressed");
  } else {
      strcpy(buf, "Not pressed");
  }
  return strlen(buf);
}

/* Function to get the status of button as a value; ("1" or "0") */
int get_button_state_val(char buf[], int app_state0, int button_id)
{
  app_state_t *app_state = (app_state_t *) app_state0;
  if(app_state->button_state[button_id]) {
      strcpy(buf, "1");
  } else {
      strcpy(buf, "0");
  }
  return strlen(buf);
}

/* Function to get the CSS class name used to indicate button state as a image */
int get_button_state_img(char buf[], int app_state0, int button_id)
{
  app_state_t *app_state = (app_state_t *) app_state0;
  if(app_state->button_state[button_id]) {
      strcpy(buf, "down");
  } else {
      strcpy(buf, "up");
  }
  return strlen(buf);
}

/* Function to get the accelerometer value for the specified id (X,Y,Z) */
int get_accel_state_val(char buf[], int app_state0, int accel_id)
{
  app_state_t *app_state = (app_state_t *) app_state0;
  
  sprintf(buf, "%d", app_state->accel_state[accel_id]);
  
  return strlen(buf);
}


/* Function to read the button and accelerometer status and store them on app state
 * This will be called from the web page before reading the app state
 * values */
int update_button_status(int app_state0)
{
  app_state_t *app_state = (app_state_t *) app_state0;
  
  app_state->button_state[0] = !get_button_state(0);
  app_state->button_state[1] = !get_button_state(1);
  
  app_state->accel_state[0] = get_accel_reading(0);
  app_state->accel_state[1] = get_accel_reading(1);
  app_state->accel_state[2] = get_accel_reading(2);
  
  return 0;
}

/* Function to process the web page post request to toggle and reset LED states */
int process_web_page_data(char buf[], int app_state0, int connection_state)
{
  char *user_choice;
  app_state_t *app_state = (app_state_t *) app_state0;

  if (!web_server_is_post(connection_state))
    return 0;

  user_choice = web_server_get_param("l0", connection_state);
  if (user_choice && (*user_choice)) {
    // toggle LED 0
    app_state->led_state[0] ^= 1;
    set_led_state(0, app_state->led_state[0]);
    return 0;
  }

  user_choice = web_server_get_param("l1", connection_state);
  if (user_choice && (*user_choice)) {
    // toggle LED 1
    app_state->led_state[1] ^= 1;
    set_led_state(1, app_state->led_state[1]);
    return 0;
  }

  user_choice = web_server_get_param("l2", connection_state);
  if (user_choice && (*user_choice)) {
    // toggle LED 1
    app_state->led_state[2] ^= 1;
    set_led_state(2, app_state->led_state[2]);
    return 0;
  }

  user_choice = web_server_get_param("l3", connection_state);
  if (user_choice && (*user_choice)) {
    // toggle LED 1
    app_state->led_state[3] ^= 1;
    set_led_state(3, app_state->led_state[3]);
    return 0;
  }

  user_choice = web_server_get_param("l4", connection_state);
  if (user_choice && (*user_choice)) {
    // reset all LEDs
    init_gpio();	
    for(int i = 0; i < 4; i++) app_state->led_state[i] = 0;
    return 0;
  }
  return 0;
}
