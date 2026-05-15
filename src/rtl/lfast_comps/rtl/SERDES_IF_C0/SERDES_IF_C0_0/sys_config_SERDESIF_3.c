/*=============================================================*/
/* Created by Microsemi SmartDesign Wed May  6 16:40:11 2026   */
/*                                                             */
/* Warning: Do not modify this file, it may lead to unexpected */
/*          functional failures in your design.                */
/*                                                             */
/*=============================================================*/

/*-------------------------------------------------------------*/
/* SERDESIF_3 Initialization                                   */
/*-------------------------------------------------------------*/

#include <stdint.h>
#include "../../CMSIS/sys_init_cfg_types.h"

const cfg_addr_value_pair_t g_m2s_serdes_3_config[] =
{
    { (uint32_t*)( 0x40034000 + 0x2028 ), 0x20F } /* SYSTEM_CONFIG_PHY_MODE_1 */ ,
    { (uint32_t*)( 0x40034000 + 0x1598 ), 0x30 } /* LANE1_PHY_RESET_OVERRIDE */ ,
    { (uint32_t*)( 0x40034000 + 0x1400 ), 0x80 } /* LANE1_CR0 */ ,
    { (uint32_t*)( 0x40034000 + 0x1404 ), 0x20 } /* LANE1_ERRCNT_DEC */ ,
    { (uint32_t*)( 0x40034000 + 0x1408 ), 0xF8 } /* LANE1_RXIDLE_MAX_ERRCNT_THR */ ,
    { (uint32_t*)( 0x40034000 + 0x140c ), 0x80 } /* LANE1_IMPED_RATIO */ ,
    { (uint32_t*)( 0x40034000 + 0x1414 ), 0x29 } /* LANE1_PLL_M_N */ ,
    { (uint32_t*)( 0x40034000 + 0x1418 ), 0x20 } /* LANE1_CNT250NS_MAX */ ,
    { (uint32_t*)( 0x40034000 + 0x1424 ), 0x80 } /* LANE1_TX_AMP_RATIO */ ,
    { (uint32_t*)( 0x40034000 + 0x1428 ), 0x15 } /* LANE1_TX_PST_RATIO */ ,
    { (uint32_t*)( 0x40034000 + 0x1430 ), 0x10 } /* LANE1_ENDCALIB_MAX */ ,
    { (uint32_t*)( 0x40034000 + 0x1434 ), 0x38 } /* LANE1_CALIB_STABILITY_COUNT */ ,
    { (uint32_t*)( 0x40034000 + 0x143c ), 0x70 } /* LANE1_RX_OFFSET_COUNT */ ,
    { (uint32_t*)( 0x40034000 + 0x15d4 ), 0x2 } /* LANE1_GEN1_TX_PLL_CCP */ ,
    { (uint32_t*)( 0x40034000 + 0x15d8 ), 0x22 } /* LANE1_GEN1_RX_PLL_CCP */ ,
    { (uint32_t*)( 0x40034000 + 0x1598 ), 0x0 } /* LANE1_PHY_RESET_OVERRIDE */ ,
    { (uint32_t*)( 0x40034000 + 0x1600 ), 0x1 } /* LANE1_UPDATE_SETTINGS */ ,
    { (uint32_t*)( 0x40034000 + 0x2028 ), 0xF0F } /* SYSTEM_CONFIG_PHY_MODE_1 */ 
};

