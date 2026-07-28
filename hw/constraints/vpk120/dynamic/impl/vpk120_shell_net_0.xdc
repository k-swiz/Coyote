##
## QSFP 0 - J2
##

# Reference clock (156.25 MHz)
set_property    PACKAGE_PIN AF45    [get_ports 	gt0_refclk_p];

# Transceiver connections
set_property    PACKAGE_PIN BG52    [get_ports  {gt0_rxp_in[0]} ];
set_property    PACKAGE_PIN BE52    [get_ports  {gt0_rxp_in[1]} ];
set_property    PACKAGE_PIN BC52    [get_ports  {gt0_rxp_in[2]} ];
set_property    PACKAGE_PIN BA52    [get_ports  {gt0_rxp_in[3]} ];

set_property    PACKAGE_PIN BE47    [get_ports  {gt0_txp_out[0]} ];
set_property    PACKAGE_PIN BD49    [get_ports  {gt0_txp_out[1]} ];
set_property    PACKAGE_PIN BC47    [get_ports  {gt0_txp_out[2]} ];
set_property    PACKAGE_PIN BB49    [get_ports  {gt0_txp_out[3]} ];
