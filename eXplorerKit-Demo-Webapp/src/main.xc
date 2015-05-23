// Copyright (c) 2015, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <platform.h>
#include <web_server.h>
#include <stdio.h>
#include "otp_board_info.h"
#include "ethernet.h"
#include "xtcp.h"
#include "smi.h"
#include "i2c.h"
#include "debug_print.h"
#include <string.h>
#include <print.h>
#include <stdlib.h>

// These ports are for accessing the OTP memory
otp_ports_t otp_ports = on tile[0]: OTP_PORTS_INITIALIZER;

rgmii_ports_t rgmii_ports = on tile[1]: RGMII_PORTS_INITIALIZER;

port p_smi_mdio   = on tile[1]: XS1_PORT_1C;
port p_smi_mdc    = on tile[1]: XS1_PORT_1D;
port p_eth_reset  = on tile[1]: XS1_PORT_1N;

/* PORT_4F connected to the RGB LEDs + 1 Green LED and PORT_4E connected to 2 buttons */
on tile[0]: port p_led=XS1_PORT_4F; // TODO: correct colors
on tile[0]: port p_button=XS1_PORT_4E;

// I2C interface ports
on tile[0]: port p_scl = XS1_PORT_1E;
on tile[0]: port p_sda = XS1_PORT_1F;

struct accel_input_data {
    int x;
    int y;
    int z;
};

interface ai_input_if {
    struct accel_input_data get_input_data();
};

int g_reportBuffer[3] = { 0, 0, 0 };

xtcp_ipconfig_t ipconfig = {
        { 192, 168, 1, 55 }, // ip address (eg 192,168,0,2) ** All zeros for DHCP **
        { 255, 255, 255, 0 }, // netmask (eg 255,255,255,0) ** All zeros for DHCP **
        { 192, 168, 1, 1 } // gateway (eg 192,168,0,1)      ** All zeros for DHCP **
};

// An enum to manage the array of connections from the ethernet component
// to its clients.
enum eth_clients {
  ETH_TO_ICMP,
  NUM_ETH_CLIENTS
};

enum cfg_clients {
  CFG_TO_ICMP,
  CFG_TO_PHY_DRIVER,
  NUM_CFG_CLIENTS
};

[[combinable]]
void ar8035_phy_driver(client interface smi_if smi,
                client interface ethernet_cfg_if eth) {
  ethernet_link_state_t link_state = ETHERNET_LINK_DOWN;
  ethernet_speed_t link_speed = LINK_1000_MBPS_FULL_DUPLEX;
  const int phy_reset_delay_ms = 1;
  const int link_poll_period_ms = 1000;
  const int phy_address = 0x4;
  timer tmr;
  int t;
  tmr :> t;
  p_eth_reset <: 0;
  delay_milliseconds(phy_reset_delay_ms);
  p_eth_reset <: 1;

  while (smi_phy_is_powered_down(smi, phy_address));
  smi_configure(smi, phy_address, LINK_1000_MBPS_FULL_DUPLEX, SMI_ENABLE_AUTONEG);

  while (1) {
    select {
    case tmr when timerafter(t) :> t:
      ethernet_link_state_t new_state = smi_get_link_state(smi, phy_address);
      // Read AR8035 status register bits 15:14 to get the current link speed
      if (new_state == ETHERNET_LINK_UP) {
        link_speed = (ethernet_speed_t)(smi.read_reg(phy_address, 0x11) >> 14) & 3;
      }
      if (new_state != link_state) {
        link_state = new_state;
        eth.set_link_state(0, new_state, link_speed);
      }
      t += link_poll_period_ms * XS1_TIMER_KHZ;
      break;
    }
  }
}

/* Function to get 32-bit timer value as a string */
int get_timer_value(char buf[])
{
  /* Declare a timer resource */
  timer tmr;
  unsigned time;
  int len;
  /* Read the timer value in a variable */
  tmr :> time;
  /* Convert the timer value to string */
  sprintf(buf, "%u", time);
  return len;
}

/* Function to initialize the GPIO */
void init_gpio(void)
{
  /* Set all LEDs to OFF (Active high)*/
  p_led <: 0x00;
}

/* Function to set LED state - ON/OFF */
void set_led_state(int led_id, int val)
{
  int value;
  /* Read port value into a variable */
  p_led :> value;
  if (!val) {
      p_led <: (value | (1 << led_id));
  } else {
      p_led <: (value & ~(1 << led_id));
  }
}

/* Function to read current button state */
int get_button_state(int button_id)
{
  int value;
  p_button :> value;
  value &= (1 << button_id);
  return (value >> button_id);
}

int get_accel_reading(int accel_id)	// FIXME: Return entire reportBuffer in a single call
{     
     // Print reading on debug console
     printf("X = %d, Y = %d, Z=%d       \n", g_reportBuffer[0], g_reportBuffer[1], g_reportBuffer[2]);
    
     return g_reportBuffer[accel_id];
}

/* Function to handle the HTTP connections (TCP events)
 * from the TCP server task through 'c_xtcp' channels */
void http_handler(chanend c_xtcp) {

  xtcp_connection_t conn;  /* TCP connection information */

  /* Initialize webserver */
  web_server_init(c_xtcp, null, null);
  /* Initialize web application state */
  init_web_state();
  init_gpio();

  while (1) {
    select
      {
      case xtcp_event(c_xtcp,conn):
        /* Handles HTTP connections and other TCP events */
        web_server_handle_event(c_xtcp, null, null, conn);
        break;
      }
  }
}

/* Accelerometer code taken from AN00181  */

// FXOS8700EQ register address defines

#define FXOS8700EQ_I2C_ADDR 0x1E
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6

int read_acceleration(client interface i2c_master_if i2c, int reg) {
    i2c_regop_res_t result;
    int accel_val = 0;
    unsigned char data = 0;

    // Read MSB data
    data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, reg, result);
    if (result != I2C_REGOP_SUCCESS) {
      return 0;
    }

    accel_val = data << 2;

    // Read LSB data
    data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, reg+1, result);
    if (result != I2C_REGOP_SUCCESS) {
      return 0;
    }

    accel_val |= (data >> 6);

    if (accel_val & 0x200) {
      accel_val -= 1023;
    }

    return accel_val;
}

void get_accelerometer_data(client interface i2c_master_if i2c, int &x, int &y, int &z) {
   i2c_regop_res_t result;
   char status_data = 0;
   
   // Wait for valid accelerometer data
   do {
      status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
   } while (!status_data & 0x08);

   // Read x and y axis values
   x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);
   y = read_acceleration(i2c, FXOS8700EQ_OUT_Y_MSB);
   z = read_acceleration(i2c, FXOS8700EQ_OUT_Z_MSB);
}

void init_accelerometer(client interface i2c_master_if i2c) {
    i2c_regop_res_t result;

    int i = 0;

    // Configure FXOS8700EQ
    result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
    i = 1;

    if (result != I2C_REGOP_SUCCESS) {
      return;
    }

    // Enable FXOS8700EQ
    result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
    if (result != I2C_REGOP_SUCCESS) {
      return;
    }
}

void accel_input(server interface ai_input_if ai_if, client interface i2c_master_if i2c) {
    init_accelerometer(i2c);
    while (1) {
        select {
            case ai_if.get_input_data() -> struct accel_input_data data:
            get_accelerometer_data(i2c, data.x, data.y, data.z);
            break;
        }
    }
}

void accel_report(client interface ai_input_if ai_if)
{  
    struct accel_input_data ai_data;
     
    while (1)
    {
        ai_data = ai_if.get_input_data();

	unsafe {

 	 int * unsafe p_reportBuffer = g_reportBuffer;

	 p_reportBuffer[0] = ai_data.x;  // X axis
	 p_reportBuffer[1] = ai_data.y;  // Y axis
 	 p_reportBuffer[2] = ai_data.z;  // Z axis
		
	}
    }
}

#define ETHERNET_SMI_PHY_ADDRESS (0)

int main()
{
  chan c_xtcp[1];
  ethernet_cfg_if i_cfg[NUM_CFG_CLIENTS];
  ethernet_rx_if i_rx[NUM_ETH_CLIENTS];
  ethernet_tx_if i_tx[NUM_ETH_CLIENTS];
  streaming chan c_rgmii_cfg;
  smi_if i_smi;

  i2c_master_if i2c[1];
  interface ai_input_if ai_if[1];

  par {
    on tile[1]: rgmii_ethernet_mac(i_rx, NUM_ETH_CLIENTS,
                                   i_tx, NUM_ETH_CLIENTS,
                                   null, null,
                                   c_rgmii_cfg,
                                   rgmii_ports, 
                                   ETHERNET_DISABLE_SHAPER);
    on tile[1].core[0]: rgmii_ethernet_mac_config(i_cfg, NUM_CFG_CLIENTS, c_rgmii_cfg);
    on tile[1].core[0]: ar8035_phy_driver(i_smi, i_cfg[CFG_TO_PHY_DRIVER]);
  
    on tile[1]: smi(i_smi, p_smi_mdio, p_smi_mdc);

    on tile[0]: xtcp(c_xtcp, 1, null,
            i_cfg[CFG_TO_ICMP], i_rx[ETH_TO_ICMP], i_tx[ETH_TO_ICMP],
            null, ETHERNET_SMI_PHY_ADDRESS,
            null, otp_ports, ipconfig);

    /* This function runs in a separate core and handles the TCP events
     * i.e the HTTP connections from the above TCP server task
     * through the channel 'c_xtcp[0]'
     */
    on tile[0]: http_handler(c_xtcp[0]);
    
    on tile[0]: accel_input(ai_if[0], i2c[0]);
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);
    on tile[0]: accel_report(ai_if[0]);
  }
  return 0;
}
