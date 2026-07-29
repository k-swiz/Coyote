######################################################################################
# This file is part of the Coyote <https://github.com/fpgasystems/Coyote>
#
# MIT Licence
# Copyright (c) 2025, Systems Group, ETH Zurich
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
######################################################################################

# Utility block for HBM AXI clock cross (CC) & data width conversion (DWC)
# The NoC inputs cannot be wider than 256 bits, so do a clock crossing and a data width conversion through a SmartConnect
proc cr_bd_lpddr_cc_dwc { parentCell } {
   upvar #0 cfg cnfg

   set design_name lpddr_cc_dwc

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

########################################################################################################
# Check IPs
########################################################################################################
   set bCheckIPs 1
   set bCheckIPsPassed 1

   if { $bCheckIPs == 1 } {
      set list_check_ips "\
         xilinx.com:ip:smartconnect:1.0\
      "

      set list_ips_missing ""
      common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

      foreach ip_vlnv $list_check_ips {
         set ip_obj [get_ipdefs -all $ip_vlnv]
         if { $ip_obj eq "" } {
            lappend list_ips_missing $ip_vlnv
         }
      }

      if { $list_ips_missing ne "" } {
         catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
         set bCheckIPsPassed 0
      }
   }

   if { $bCheckIPsPassed != 1 } {
      common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
      return 3
   }

   if { $parentCell eq "" } {
      set parentCell [get_bd_cells /]
   }

   # Get object for parentCell
   set parentObj [get_bd_cells $parentCell]
   if { $parentObj == "" } {
      catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
      return
   }

   # Make sure parentObj is hier blk
   set parentType [get_property TYPE $parentObj]
   if { $parentType ne "hier" } {
      catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
      return
   }

   # Save current instance; Restore later
   set oldCurInst [current_bd_instance .]

   # Set parent object as current
   current_bd_instance $parentObj

########################################################################################################
# Create interface ports
########################################################################################################

   set S_AXI [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI]
   set cmd "set_property -dict \[list \
      CONFIG.ADDR_WIDTH {64} \
      CONFIG.ARUSER_WIDTH {0} \
      CONFIG.AWUSER_WIDTH {0} \
      CONFIG.BUSER_WIDTH {0} \
      CONFIG.DATA_WIDTH {512} \
      CONFIG.HAS_BRESP {1} \
      CONFIG.HAS_BURST {1} \
      CONFIG.HAS_CACHE {1} \
      CONFIG.HAS_LOCK {1} \
      CONFIG.HAS_PROT {1} \
      CONFIG.HAS_QOS {0} \
      CONFIG.HAS_REGION {0} \
      CONFIG.HAS_RRESP {1} \
      CONFIG.HAS_WSTRB {1} \
      CONFIG.ID_WIDTH {6} \
      CONFIG.MAX_BURST_LENGTH {64} \
      CONFIG.NUM_READ_OUTSTANDING {8} \
      CONFIG.NUM_READ_THREADS {8} \
      CONFIG.NUM_WRITE_OUTSTANDING {8} \
      CONFIG.NUM_WRITE_THREADS {8} \
      CONFIG.PROTOCOL {AXI4} \
      CONFIG.READ_WRITE_MODE {READ_WRITE} \
      CONFIG.RUSER_BITS_PER_BYTE {0} \
      CONFIG.RUSER_WIDTH {0} \
      CONFIG.SUPPORTS_NARROW_BURST {0} \
      CONFIG.WUSER_BITS_PER_BYTE {0} \
      CONFIG.WUSER_WIDTH {0} \
   ] \$S_AXI"
   eval $cmd

   set M_AXI [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI]
   set cmd "set_property -dict \[list \
      CONFIG.ADDR_WIDTH {64} \
      CONFIG.DATA_WIDTH {256} \
      CONFIG.HAS_BRESP {1} \
      CONFIG.HAS_BURST {1} \
      CONFIG.HAS_CACHE {1} \
      CONFIG.HAS_LOCK {1} \
      CONFIG.HAS_PROT {1} \
      CONFIG.HAS_QOS {0} \
      CONFIG.HAS_REGION {0} \
      CONFIG.HAS_RRESP {1} \
      CONFIG.HAS_WSTRB {1} \
      CONFIG.NUM_READ_OUTSTANDING {8} \
      CONFIG.NUM_WRITE_OUTSTANDING {8} \
      CONFIG.PROTOCOL {AXI4} \
      CONFIG.READ_WRITE_MODE {READ_WRITE} \
   ] \$M_AXI"
   eval $cmd

########################################################################################################
# Create ports
########################################################################################################
   # Input clock and the associated reset; coming from the shell
   set cmd "set aclk \[ create_bd_port -dir I -type clk aclk ]
         set_property -dict \[ list \
            CONFIG.ASSOCIATED_BUSIF {S_AXI} \
            CONFIG.ASSOCIATED_RESET {aresetn} \
            CONFIG.FREQ_HZ {$cnfg(aclk_f)000000} \
         ] \$aclk"
   eval $cmd

   set aresetn [ create_bd_port -dir I -type rst aresetn ]
   set_property -dict [ list \
      CONFIG.POLARITY {ACTIVE_LOW} \
   ] $aresetn

   # HBM clock; to the NoC
   set cmd "set hclk \[ create_bd_port -dir I -type clk hclk ]
         set_property -dict \[ list \
            CONFIG.ASSOCIATED_BUSIF {M_AXI} \
            CONFIG.FREQ_HZ {$cnfg(hclk_f)000000} \
         ] \$hclk"
   eval $cmd

########################################################################################################
# Create components
########################################################################################################
   # AXI SmartConnect for clock crossing & data width conversion
   set inst_smartconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 inst_smartconnect]
   set_property -dict [list \
      CONFIG.NUM_CLKS {2} \
      CONFIG.NUM_SI {1} \
      CONFIG.NUM_MI {1} \
   ] $inst_smartconnect

########################################################################################################
# Create interface connections
########################################################################################################
   connect_bd_intf_net [get_bd_intf_ports S_AXI] [get_bd_intf_pins $inst_smartconnect/S00_AXI]
   connect_bd_intf_net [get_bd_intf_pins $inst_smartconnect/M00_AXI] [get_bd_intf_ports M_AXI]

########################################################################################################
# Create port connections
########################################################################################################
   connect_bd_net [get_bd_ports aclk] [get_bd_pins $inst_smartconnect/aclk]
   connect_bd_net [get_bd_ports hclk] [get_bd_pins $inst_smartconnect/aclk1]
   connect_bd_net [get_bd_ports aresetn] [get_bd_pins $inst_smartconnect/aresetn]

########################################################################################################
# Create address segments
########################################################################################################
   assign_bd_address -offset 0x0 -range 16E -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs M_AXI/Reg]

   # Restore current instance
   current_bd_instance $oldCurInst

   # Validate and save
   validate_bd_design
   save_bd_design
   close_bd_design $design_name
}

# Main LPDDR design through the Versal NoC
# The LPDDR memory controllers are embedded within the NoC itself. The VPK120 is outfitted with 3 triplets
# with each triplet containing 2 channels. The memory controllers are only capable of being interleaved in
# a x1, x2, or x4 configuration. To appease Vivado, Trip0 and 1 are configured on NoC 0, with a secondary
# NoC containing Trip 2. The NoC's are connected via an INI so access to memory is universal.

# TODO: Currently doesn't support any striping and only supports a single input bus. There are probably a
# lot of optimizations that can be done here..

proc cr_bd_design_lpddr { parentCell } {
   upvar #0 cfg cnfg

   set design_name design_lpddr

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

########################################################################################################
# Check IPs
########################################################################################################
   set bCheckIPs 1
   set bCheckIPsPassed 1

   if { $bCheckIPs == 1 } {
      set list_check_ips "\
         xilinx.com:ip:axi_noc:1.1\
      "

      set list_ips_missing ""
      common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

      foreach ip_vlnv $list_check_ips {
         set ip_obj [get_ipdefs -all $ip_vlnv]
         if { $ip_obj eq "" } {
            lappend list_ips_missing $ip_vlnv
         }
      }

      if { $list_ips_missing ne "" } {
         catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
         set bCheckIPsPassed 0
      }
   }

   if { $bCheckIPsPassed != 1 } {
      common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
      return 3
   }

   if { $parentCell eq "" } {
      set parentCell [get_bd_cells /]
   }

   # Get object for parentCell
   set parentObj [get_bd_cells $parentCell]
   if { $parentObj == "" } {
      catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
      return
   }

   # Make sure parentObj is hier blk
   set parentType [get_property TYPE $parentObj]
   if { $parentType ne "hier" } {
      catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
      return
   }

   # Save current instance; Restore later
   set oldCurInst [current_bd_instance .]

   # Set parent object as current
   current_bd_instance $parentObj

########################################################################################################
########################################################################################################
# HBM MAIN
########################################################################################################
########################################################################################################

########################################################################################################
# Create interface ports
########################################################################################################
  set ch0_lpddr0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr0 ]

  set ch1_lpddr0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr0 ]

  set ch0_lpddr1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr1 ]

  set ch1_lpddr1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr1 ]

  set ch0_lpddr2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr2 ]

  set ch1_lpddr2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr2 ]

  # AXI-MM ports
  set axi_lpddr_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi_lpddr_in_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {2} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $axi_lpddr_in_0

########################################################################################################
# Create ports
########################################################################################################
   # Clock associated with the AXI-MM interfaces
   set cmd "set hclk \[ create_bd_port -dir I -type clk hclk ]
         set_property -dict \[ list \
            CONFIG.ASSOCIATED_BUSIF {axi_lpddr_in_0} \
            CONFIG.FREQ_HZ {$cnfg(hclk_f)000000} \
         ] \$hclk"
   eval $cmd

  set lpddr0_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr0_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200321000} \
   ] $lpddr0_clk

  set lpddr1_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr1_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200321000} \
   ] $lpddr1_clk

  set lpddr2_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr2_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200321000} \
   ] $lpddr2_clk

########################################################################################################
# Create components
########################################################################################################

  # Create instance: lpddr_noc_0, and set properties
  set lpddr_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 lpddr_noc_0 ]
  set_property -dict [list \
    CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_trip1} \
    CONFIG.CH0_LPDDR4_1_BOARD_INTERFACE {ch0_lpddr4_trip2} \
    CONFIG.CH0_LPDDR4_2_BOARD_INTERFACE {Custom} \
    CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_trip1} \
    CONFIG.CH1_LPDDR4_1_BOARD_INTERFACE {ch1_lpddr4_trip2} \
    CONFIG.CH1_LPDDR4_2_BOARD_INTERFACE {Custom} \
    CONFIG.INLINE_HDL {false} \
    CONFIG.MC2_CONFIG_NUM {config26} \
    CONFIG.MC3_CONFIG_NUM {config26} \
    CONFIG.MC_ADDR_WIDTH {6} \
    CONFIG.MC_BOARD_INTRF_EN {true} \
    CONFIG.MC_BURST_LENGTH {16} \
    CONFIG.MC_CASLATENCY {36} \
    CONFIG.MC_CASWRITELATENCY {18} \
    CONFIG.MC_CH0_LP4_CHA_ENABLE {true} \
    CONFIG.MC_CH0_LP4_CHB_ENABLE {true} \
    CONFIG.MC_CH1_LP4_CHA_ENABLE {true} \
    CONFIG.MC_CH1_LP4_CHB_ENABLE {true} \
    CONFIG.MC_CHANNEL_INTERLEAVING {true} \
    CONFIG.MC_CHAN_REGION0 {DDR_LOW0} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_CH_INTERLEAVING_SIZE {64_Bytes} \
    CONFIG.MC_CKE_WIDTH {0} \
    CONFIG.MC_CK_WIDTH {0} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_ECC_SCRUB_SIZE {4096} \
    CONFIG.MC_EN_INTR_RESP {TRUE} \
    CONFIG.MC_F1_CASLATENCY {36} \
    CONFIG.MC_F1_CASWRITELATENCY {18} \
    CONFIG.MC_F1_LPDDR4_MR13 {0x00C0} \
    CONFIG.MC_F1_TCCD_L {0} \
    CONFIG.MC_F1_TCCD_L_MIN {0} \
    CONFIG.MC_F1_TFAW {30000} \
    CONFIG.MC_F1_TFAWMIN {30000} \
    CONFIG.MC_F1_TMOD {0} \
    CONFIG.MC_F1_TMOD_MIN {0} \
    CONFIG.MC_F1_TMRD {14000} \
    CONFIG.MC_F1_TMRDMIN {14000} \
    CONFIG.MC_F1_TMRW {10000} \
    CONFIG.MC_F1_TMRWMIN {10000} \
    CONFIG.MC_F1_TRAS {42000} \
    CONFIG.MC_F1_TRASMIN {42000} \
    CONFIG.MC_F1_TRCD {18000} \
    CONFIG.MC_F1_TRCDMIN {18000} \
    CONFIG.MC_F1_TRPAB {21000} \
    CONFIG.MC_F1_TRPABMIN {21000} \
    CONFIG.MC_F1_TRPPB {18000} \
    CONFIG.MC_F1_TRPPBMIN {18000} \
    CONFIG.MC_F1_TRRD {7500} \
    CONFIG.MC_F1_TRRDMIN {7500} \
    CONFIG.MC_F1_TRRD_L {0} \
    CONFIG.MC_F1_TRRD_L_MIN {0} \
    CONFIG.MC_F1_TRRD_S {0} \
    CONFIG.MC_F1_TRRD_S_MIN {0} \
    CONFIG.MC_F1_TWR {18000} \
    CONFIG.MC_F1_TWRMIN {18000} \
    CONFIG.MC_F1_TWTR {10000} \
    CONFIG.MC_F1_TWTRMIN {10000} \
    CONFIG.MC_F1_TWTR_L {0} \
    CONFIG.MC_F1_TWTR_L_MIN {0} \
    CONFIG.MC_F1_TWTR_S {0} \
    CONFIG.MC_F1_TWTR_S_MIN {0} \
    CONFIG.MC_F1_TZQLAT {30000} \
    CONFIG.MC_F1_TZQLATMIN {30000} \
    CONFIG.MC_IP_TIMEPERIOD1 {512} \
    CONFIG.MC_LP4_CA_A_WIDTH {6} \
    CONFIG.MC_LP4_CA_B_WIDTH {6} \
    CONFIG.MC_LP4_CKE_A_WIDTH {1} \
    CONFIG.MC_LP4_CKE_B_WIDTH {1} \
    CONFIG.MC_LP4_CKT_A_WIDTH {1} \
    CONFIG.MC_LP4_CKT_B_WIDTH {1} \
    CONFIG.MC_LP4_CS_A_WIDTH {1} \
    CONFIG.MC_LP4_CS_B_WIDTH {1} \
    CONFIG.MC_LP4_DMI_A_WIDTH {2} \
    CONFIG.MC_LP4_DMI_B_WIDTH {2} \
    CONFIG.MC_LP4_DQS_A_WIDTH {2} \
    CONFIG.MC_LP4_DQS_B_WIDTH {2} \
    CONFIG.MC_LP4_DQ_A_WIDTH {16} \
    CONFIG.MC_LP4_DQ_B_WIDTH {16} \
    CONFIG.MC_LP4_RESETN_WIDTH {1} \
    CONFIG.MC_ODTLon {8} \
    CONFIG.MC_ODT_WIDTH {0} \
    CONFIG.MC_PER_RD_INTVL {0} \
    CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} \
    CONFIG.MC_SYSTEM_CLOCK {Differential} \
    CONFIG.MC_TCCD {8} \
    CONFIG.MC_TCCD_L {0} \
    CONFIG.MC_TCCD_L_MIN {0} \
    CONFIG.MC_TCKE {15} \
    CONFIG.MC_TCKEMIN {15} \
    CONFIG.MC_TDQS2DQ_MAX {800} \
    CONFIG.MC_TDQS2DQ_MIN {200} \
    CONFIG.MC_TDQSCK_MAX {3500} \
    CONFIG.MC_TFAW {30000} \
    CONFIG.MC_TFAWMIN {30000} \
    CONFIG.MC_TMOD {0} \
    CONFIG.MC_TMOD_MIN {0} \
    CONFIG.MC_TMRD {14000} \
    CONFIG.MC_TMRDMIN {14000} \
    CONFIG.MC_TMRD_div4 {10} \
    CONFIG.MC_TMRD_nCK {28} \
    CONFIG.MC_TMRW {10000} \
    CONFIG.MC_TMRWMIN {10000} \
    CONFIG.MC_TMRW_div4 {10} \
    CONFIG.MC_TMRW_nCK {20} \
    CONFIG.MC_TODTon_MIN {3} \
    CONFIG.MC_TOSCO {40000} \
    CONFIG.MC_TOSCOMIN {40000} \
    CONFIG.MC_TOSCO_nCK {79} \
    CONFIG.MC_TPBR2PBR {90000} \
    CONFIG.MC_TPBR2PBRMIN {90000} \
    CONFIG.MC_TRAS {42000} \
    CONFIG.MC_TRASMIN {42000} \
    CONFIG.MC_TRAS_nCK {83} \
    CONFIG.MC_TRC {63000} \
    CONFIG.MC_TRCD {18000} \
    CONFIG.MC_TRCDMIN {18000} \
    CONFIG.MC_TRCD_nCK {36} \
    CONFIG.MC_TRCMIN {0} \
    CONFIG.MC_TREFI {3904000} \
    CONFIG.MC_TREFIPB {488000} \
    CONFIG.MC_TRFC {0} \
    CONFIG.MC_TRFCAB {280000} \
    CONFIG.MC_TRFCABMIN {280000} \
    CONFIG.MC_TRFCMIN {0} \
    CONFIG.MC_TRFCPB {140000} \
    CONFIG.MC_TRFCPBMIN {140000} \
    CONFIG.MC_TRP {0} \
    CONFIG.MC_TRPAB {21000} \
    CONFIG.MC_TRPABMIN {21000} \
    CONFIG.MC_TRPAB_nCK {42} \
    CONFIG.MC_TRPMIN {0} \
    CONFIG.MC_TRPPB {18000} \
    CONFIG.MC_TRPPBMIN {18000} \
    CONFIG.MC_TRPPB_nCK {36} \
    CONFIG.MC_TRPRE {1.8} \
    CONFIG.MC_TRRD {7500} \
    CONFIG.MC_TRRDMIN {7500} \
    CONFIG.MC_TRRD_L {0} \
    CONFIG.MC_TRRD_L_MIN {0} \
    CONFIG.MC_TRRD_S {0} \
    CONFIG.MC_TRRD_S_MIN {0} \
    CONFIG.MC_TRRD_nCK {15} \
    CONFIG.MC_TWPRE {1.8} \
    CONFIG.MC_TWPST {0.4} \
    CONFIG.MC_TWR {18000} \
    CONFIG.MC_TWRMIN {18000} \
    CONFIG.MC_TWR_nCK {36} \
    CONFIG.MC_TWTR {10000} \
    CONFIG.MC_TWTRMIN {10000} \
    CONFIG.MC_TWTR_L {0} \
    CONFIG.MC_TWTR_S {0} \
    CONFIG.MC_TWTR_S_MIN {0} \
    CONFIG.MC_TWTR_nCK {20} \
    CONFIG.MC_TXP {15} \
    CONFIG.MC_TXPMIN {15} \
    CONFIG.MC_TXPR {0} \
    CONFIG.MC_TZQCAL {1000000} \
    CONFIG.MC_TZQCAL_div4 {489} \
    CONFIG.MC_TZQCS_ITVL {0} \
    CONFIG.MC_TZQLAT {30000} \
    CONFIG.MC_TZQLATMIN {30000} \
    CONFIG.MC_TZQLAT_div4 {15} \
    CONFIG.MC_TZQLAT_nCK {59} \
    CONFIG.MC_TZQ_START_ITVL {1000000000} \
    CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-3BA-10CA} \
    CONFIG.MC_XPLL_CLKOUT1_PERIOD {1024} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MC {2} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {1} \
    CONFIG.NUM_SI {1} \
    CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_clk1} \
    CONFIG.sys_clk1_BOARD_INTERFACE {lpddr4_clk2} \
  ] $lpddr_noc_0

  # Create instance: lpddr_noc_1, and set properties
  set lpddr_noc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 lpddr_noc_1 ]
  set_property -dict [list \
    CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_trip3} \
    CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_trip3} \
    CONFIG.INLINE_HDL {false} \
    CONFIG.MC1_CONFIG_NUM {config26} \
    CONFIG.MC1_FLIPPED_PINOUT {true} \
    CONFIG.MC2_CONFIG_NUM {config26} \
    CONFIG.MC3_CONFIG_NUM {config26} \
    CONFIG.MC_ADDR_WIDTH {6} \
    CONFIG.MC_BOARD_INTRF_EN {true} \
    CONFIG.MC_BURST_LENGTH {16} \
    CONFIG.MC_CASLATENCY {36} \
    CONFIG.MC_CASWRITELATENCY {18} \
    CONFIG.MC_CH0_LP4_CHA_ENABLE {true} \
    CONFIG.MC_CH0_LP4_CHB_ENABLE {true} \
    CONFIG.MC_CH1_LP4_CHA_ENABLE {true} \
    CONFIG.MC_CH1_LP4_CHB_ENABLE {true} \
    CONFIG.MC_CHANNEL_INTERLEAVING {true} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
    CONFIG.MC_CHAN_REGION1 {NONE} \
    CONFIG.MC_CH_INTERLEAVING_SIZE {64_Bytes} \
    CONFIG.MC_CKE_WIDTH {0} \
    CONFIG.MC_CK_WIDTH {0} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_ECC_SCRUB_SIZE {4096} \
    CONFIG.MC_F1_CASLATENCY {36} \
    CONFIG.MC_F1_CASWRITELATENCY {18} \
    CONFIG.MC_F1_LPDDR4_MR13 {0x00C0} \
    CONFIG.MC_F1_TCCD_L {0} \
    CONFIG.MC_F1_TCCD_L_MIN {0} \
    CONFIG.MC_F1_TFAW {30000} \
    CONFIG.MC_F1_TFAWMIN {30000} \
    CONFIG.MC_F1_TMOD {0} \
    CONFIG.MC_F1_TMOD_MIN {0} \
    CONFIG.MC_F1_TMRD {14000} \
    CONFIG.MC_F1_TMRDMIN {14000} \
    CONFIG.MC_F1_TMRW {10000} \
    CONFIG.MC_F1_TMRWMIN {10000} \
    CONFIG.MC_F1_TRAS {42000} \
    CONFIG.MC_F1_TRASMIN {42000} \
    CONFIG.MC_F1_TRCD {18000} \
    CONFIG.MC_F1_TRCDMIN {18000} \
    CONFIG.MC_F1_TRPAB {21000} \
    CONFIG.MC_F1_TRPABMIN {21000} \
    CONFIG.MC_F1_TRPPB {18000} \
    CONFIG.MC_F1_TRPPBMIN {18000} \
    CONFIG.MC_F1_TRRD {7500} \
    CONFIG.MC_F1_TRRDMIN {7500} \
    CONFIG.MC_F1_TRRD_L {0} \
    CONFIG.MC_F1_TRRD_L_MIN {0} \
    CONFIG.MC_F1_TRRD_S {0} \
    CONFIG.MC_F1_TRRD_S_MIN {0} \
    CONFIG.MC_F1_TWR {18000} \
    CONFIG.MC_F1_TWRMIN {18000} \
    CONFIG.MC_F1_TWTR {10000} \
    CONFIG.MC_F1_TWTRMIN {10000} \
    CONFIG.MC_F1_TWTR_L {0} \
    CONFIG.MC_F1_TWTR_L_MIN {0} \
    CONFIG.MC_F1_TWTR_S {0} \
    CONFIG.MC_F1_TWTR_S_MIN {0} \
    CONFIG.MC_F1_TZQLAT {30000} \
    CONFIG.MC_F1_TZQLATMIN {30000} \
    CONFIG.MC_IP_TIMEPERIOD1 {512} \
    CONFIG.MC_LP4_CA_A_WIDTH {6} \
    CONFIG.MC_LP4_CA_B_WIDTH {6} \
    CONFIG.MC_LP4_CKE_A_WIDTH {1} \
    CONFIG.MC_LP4_CKE_B_WIDTH {1} \
    CONFIG.MC_LP4_CKT_A_WIDTH {1} \
    CONFIG.MC_LP4_CKT_B_WIDTH {1} \
    CONFIG.MC_LP4_CS_A_WIDTH {1} \
    CONFIG.MC_LP4_CS_B_WIDTH {1} \
    CONFIG.MC_LP4_DMI_A_WIDTH {2} \
    CONFIG.MC_LP4_DMI_B_WIDTH {2} \
    CONFIG.MC_LP4_DQS_A_WIDTH {2} \
    CONFIG.MC_LP4_DQS_B_WIDTH {2} \
    CONFIG.MC_LP4_DQ_A_WIDTH {16} \
    CONFIG.MC_LP4_DQ_B_WIDTH {16} \
    CONFIG.MC_LP4_RESETN_WIDTH {1} \
    CONFIG.MC_ODTLon {8} \
    CONFIG.MC_ODT_WIDTH {0} \
    CONFIG.MC_PER_RD_INTVL {0} \
    CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} \
    CONFIG.MC_TCCD {8} \
    CONFIG.MC_TCCD_L {0} \
    CONFIG.MC_TCCD_L_MIN {0} \
    CONFIG.MC_TCKE {15} \
    CONFIG.MC_TCKEMIN {15} \
    CONFIG.MC_TDQS2DQ_MAX {800} \
    CONFIG.MC_TDQS2DQ_MIN {200} \
    CONFIG.MC_TDQSCK_MAX {3500} \
    CONFIG.MC_TFAW {30000} \
    CONFIG.MC_TFAWMIN {30000} \
    CONFIG.MC_TMOD {0} \
    CONFIG.MC_TMOD_MIN {0} \
    CONFIG.MC_TMRD {14000} \
    CONFIG.MC_TMRDMIN {14000} \
    CONFIG.MC_TMRD_div4 {10} \
    CONFIG.MC_TMRD_nCK {28} \
    CONFIG.MC_TMRW {10000} \
    CONFIG.MC_TMRWMIN {10000} \
    CONFIG.MC_TMRW_div4 {10} \
    CONFIG.MC_TMRW_nCK {20} \
    CONFIG.MC_TODTon_MIN {3} \
    CONFIG.MC_TOSCO {40000} \
    CONFIG.MC_TOSCOMIN {40000} \
    CONFIG.MC_TOSCO_nCK {79} \
    CONFIG.MC_TPBR2PBR {90000} \
    CONFIG.MC_TPBR2PBRMIN {90000} \
    CONFIG.MC_TRAS {42000} \
    CONFIG.MC_TRASMIN {42000} \
    CONFIG.MC_TRAS_nCK {83} \
    CONFIG.MC_TRC {63000} \
    CONFIG.MC_TRCD {18000} \
    CONFIG.MC_TRCDMIN {18000} \
    CONFIG.MC_TRCD_nCK {36} \
    CONFIG.MC_TRCMIN {0} \
    CONFIG.MC_TREFI {3904000} \
    CONFIG.MC_TREFIPB {488000} \
    CONFIG.MC_TRFC {0} \
    CONFIG.MC_TRFCAB {280000} \
    CONFIG.MC_TRFCABMIN {280000} \
    CONFIG.MC_TRFCMIN {0} \
    CONFIG.MC_TRFCPB {140000} \
    CONFIG.MC_TRFCPBMIN {140000} \
    CONFIG.MC_TRP {0} \
    CONFIG.MC_TRPAB {21000} \
    CONFIG.MC_TRPABMIN {21000} \
    CONFIG.MC_TRPAB_nCK {42} \
    CONFIG.MC_TRPMIN {0} \
    CONFIG.MC_TRPPB {18000} \
    CONFIG.MC_TRPPBMIN {18000} \
    CONFIG.MC_TRPPB_nCK {36} \
    CONFIG.MC_TRPRE {1.8} \
    CONFIG.MC_TRRD {7500} \
    CONFIG.MC_TRRDMIN {7500} \
    CONFIG.MC_TRRD_L {0} \
    CONFIG.MC_TRRD_L_MIN {0} \
    CONFIG.MC_TRRD_S {0} \
    CONFIG.MC_TRRD_S_MIN {0} \
    CONFIG.MC_TRRD_nCK {15} \
    CONFIG.MC_TWPRE {1.8} \
    CONFIG.MC_TWPST {0.4} \
    CONFIG.MC_TWR {18000} \
    CONFIG.MC_TWRMIN {18000} \
    CONFIG.MC_TWR_nCK {36} \
    CONFIG.MC_TWTR {10000} \
    CONFIG.MC_TWTRMIN {10000} \
    CONFIG.MC_TWTR_L {0} \
    CONFIG.MC_TWTR_S {0} \
    CONFIG.MC_TWTR_S_MIN {0} \
    CONFIG.MC_TWTR_nCK {20} \
    CONFIG.MC_TXP {15} \
    CONFIG.MC_TXPMIN {15} \
    CONFIG.MC_TXPR {0} \
    CONFIG.MC_TZQCAL {1000000} \
    CONFIG.MC_TZQCAL_div4 {489} \
    CONFIG.MC_TZQCS_ITVL {0} \
    CONFIG.MC_TZQLAT {30000} \
    CONFIG.MC_TZQLATMIN {30000} \
    CONFIG.MC_TZQLAT_div4 {15} \
    CONFIG.MC_TZQLAT_nCK {59} \
    CONFIG.MC_TZQ_START_ITVL {1000000000} \
    CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-3BA-10CA} \
    CONFIG.MC_XPLL_CLKOUT1_PERIOD {1024} \
    CONFIG.NUM_CLKS {0} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NSI {1} \
    CONFIG.NUM_SI {0} \
    CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_clk3} \
  ] $lpddr_noc_1

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} initial_boot {true} } MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $lpddr_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $lpddr_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
 ] [get_bd_intf_pins $lpddr_noc_1/S00_INI]

########################################################################################################
# Create interface connections
########################################################################################################
  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins lpddr_noc_0/S00_AXI] [get_bd_intf_ports axi_lpddr_in_0]
  connect_bd_intf_net -intf_net lpddr0_clk_1 [get_bd_intf_pins lpddr_noc_0/sys_clk0] [get_bd_intf_ports lpddr0_clk]
  connect_bd_intf_net -intf_net lpddr1_clk_1 [get_bd_intf_pins lpddr_noc_0/sys_clk1] [get_bd_intf_ports lpddr1_clk]
  connect_bd_intf_net -intf_net lpddr2_clk_1 [get_bd_intf_pins lpddr_noc_1/sys_clk0] [get_bd_intf_ports lpddr2_clk]
  connect_bd_intf_net -intf_net lpddr_noc_0_CH0_LPDDR4_0 [get_bd_intf_pins lpddr_noc_0/CH0_LPDDR4_0] [get_bd_intf_ports ch0_lpddr0]
  connect_bd_intf_net -intf_net lpddr_noc_0_CH0_LPDDR4_1 [get_bd_intf_pins lpddr_noc_0/CH0_LPDDR4_1] [get_bd_intf_ports ch0_lpddr1]
  connect_bd_intf_net -intf_net lpddr_noc_0_CH1_LPDDR4_0 [get_bd_intf_pins lpddr_noc_0/CH1_LPDDR4_0] [get_bd_intf_ports ch1_lpddr0]
  connect_bd_intf_net -intf_net lpddr_noc_0_CH1_LPDDR4_1 [get_bd_intf_pins lpddr_noc_0/CH1_LPDDR4_1] [get_bd_intf_ports ch1_lpddr1]
  connect_bd_intf_net -intf_net lpddr_noc_0_M00_INI [get_bd_intf_pins lpddr_noc_0/M00_INI] [get_bd_intf_pins lpddr_noc_1/S00_INI]
  connect_bd_intf_net -intf_net lpddr_noc_1_CH0_LPDDR4_0 [get_bd_intf_pins lpddr_noc_1/CH0_LPDDR4_0] [get_bd_intf_ports ch0_lpddr2]
  connect_bd_intf_net -intf_net lpddr_noc_1_CH1_LPDDR4_0 [get_bd_intf_pins lpddr_noc_1/CH1_LPDDR4_0] [get_bd_intf_ports ch1_lpddr2]


########################################################################################################
# Create port connections
########################################################################################################
   connect_bd_net [get_bd_ports hclk] [get_bd_pins lpddr_noc_0/aclk0]

########################################################################################################
# Create address segments
########################################################################################################

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs lpddr_noc_0/S00_AXI/C3_DDR_LOW0x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs lpddr_noc_0/S00_AXI/C3_DDR_LOW1x2] -force
  assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs lpddr_noc_1/S00_INI/C0_DDR_CH1] -force

   # Restore current instance
   current_bd_instance $oldCurInst

   # Validate and save
   validate_bd_design
   save_bd_design
   close_bd_design $design_name

   return 0
}
