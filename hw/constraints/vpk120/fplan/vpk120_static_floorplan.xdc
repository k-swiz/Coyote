create_pblock pblock_inst_shell
add_cells_to_pblock [get_pblocks pblock_inst_shell] [get_cells -quiet [list inst_shell]]
#resize_pblock [get_pblocks pblock_inst_shell] -add {SLICE_X84Y188:SLICE_X379Y331}
#resize_pblock [get_pblocks pblock_inst_shell] -add {BUFG_FABRIC_X0Y95:BUFG_FABRIC_X4Y48}
#resize_pblock [get_pblocks pblock_inst_shell] -add {BUFG_GT_X1Y48:BUFG_GT_X1Y95}
#resize_pblock [get_pblocks pblock_inst_shell] -add {BUFG_GT_SYNC_X1Y82:BUFG_GT_SYNC_X1Y163}
#resize_pblock [get_pblocks pblock_inst_shell] -add {DCMAC_X0Y0:DCMAC_X0Y0}
#resize_pblock [get_pblocks pblock_inst_shell] -add {DPLL_X14Y5:DPLL_X14Y7}
#resize_pblock [get_pblocks pblock_inst_shell] -add {BUFG_PS_X0Y24:BUFG_PS_X0Y35}
#resize_pblock [get_pblocks pblock_inst_shell] -add {DSP58_CPLX_X0Y94:DSP58_CPLX_X11Y165}
#resize_pblock [get_pblocks pblock_inst_shell] -add {DSP_X0Y94:DSP_X23Y165}
#resize_pblock [get_pblocks pblock_inst_shell] -add {GTM_QUAD_X0Y2:GTM_QUAD_X0Y4}
#resize_pblock [get_pblocks pblock_inst_shell] -add {GTM_REFCLK_X0Y4:GTM_REFCLK_X0Y9}
#resize_pblock [get_pblocks pblock_inst_shell] -add {IRI_QUAD_X26Y780:IRI_QUAD_X230Y1355}
#resize_pblock [get_pblocks pblock_inst_shell] -add {MISR_X0Y2:MISR_X3Y3}
#resize_pblock [get_pblocks pblock_inst_shell] -add {MRMAC_X0Y1:MRMAC_X0Y1}
#resize_pblock [get_pblocks pblock_inst_shell] -add {NOC_NMU512_X0Y4:NOC_NMU512_X3Y6}
#resize_pblock [get_pblocks pblock_inst_shell] -add {NOC_NSU512_X0Y4:NOC_NSU512_X3Y6}
#resize_pblock [get_pblocks pblock_inst_shell] -add {RAMB18_X2Y96:RAMB18_X16Y167}
#resize_pblock [get_pblocks pblock_inst_shell] -add {RAMB36_X2Y48:RAMB36_X16Y83}
#resize_pblock [get_pblocks pblock_inst_shell] -add {URAM288_X2Y48:URAM288_X8Y83}
# resize_pblock [get_pblocks pblock_inst_shell] -add {URAM_CAS_DLY_X3Y2:URAM_CAS_DLY_X4Y3 URAM_CAS_DLY_X3Y0:URAM_CAS_DLY_X3Y1}
#resize_pblock [get_pblocks pblock_inst_shell] -add {CLOCKREGION_X2Y4:CLOCKREGION_X9Y4 CLOCKREGION_X2Y3:CLOCKREGION_X9Y3}


resize_pblock [get_pblocks pblock_inst_shell] -add {SLICE_X204Y0:SLICE_X379Y331 BLI_X3232Y0:BLI_X6783Y0 BUFGCE_X8Y0:BUFGCE_X12Y23 BUFGCE_DIV_X8Y0:BUFGCE_DIV_X12Y3 BUFGCTRL_X8Y0:BUFGCTRL_X12Y7 BUFG_FABRIC_X3Y0:BUFG_FABRIC_X4Y95 BUFG_GT_X1Y0:BUFG_GT_X1Y95 BUFG_GT_SYNC_X1Y0:BUFG_GT_SYNC_X1Y163 DCMAC_X0Y0:DCMAC_X0Y0 DDRMC_X3Y0:DDRMC_X3Y0 DDRMC_RIU_X3Y0:DDRMC_RIU_X3Y0 DPLL_X8Y0:DPLL_X14Y7 DSP58_CPLX_X6Y0:DSP58_CPLX_X11Y165 DSP_X12Y0:DSP_X23Y165 GTM_QUAD_X0Y0:GTM_QUAD_X0Y4 GTM_REFCLK_X0Y0:GTM_REFCLK_X0Y9 GTYP_QUAD_X1Y0:GTYP_QUAD_X1Y1 GTYP_REFCLK_X1Y0:GTYP_REFCLK_X1Y3 HSC_X0Y0:HSC_X0Y0 IOB_X67Y0:IOB_X116Y2 IRI_QUAD_X111Y0:IRI_QUAD_X230Y1355 MISR_X2Y0:MISR_X3Y3 MMCM_X7Y0:MMCM_X12Y0 MRMAC_X0Y0:MRMAC_X0Y1 NOC_NMU512_X2Y0:NOC_NMU512_X3Y6 NOC_NSU512_X2Y0:NOC_NSU512_X3Y6 RAMB18_X16Y0:RAMB18_X8Y167 RAMB36_X16Y0:RAMB36_X8Y83 URAM288_X8Y0:URAM288_X5Y83} -replace


set_property SNAPPING_MODE ON [get_pblocks pblock_inst_shell]
set_property IS_SOFT FALSE [get_pblocks pblock_inst_shell]
