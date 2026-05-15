# ===========================================================
# Created by Microsemi SmartDesign Fri May 15 15:06:22 2026
# 
# Warning: Do not modify this file, it may lead to unexpected 
#          simulation failures in your design.
#
# ===========================================================

if {$tcl_platform(os) == "Linux"} {
  exec "$env(ACTEL_SW_DIR)/bin64/bfmtovec"   -in SERDESIF_0_user.bfm   -out SERDESIF_0.vec
} else {
  exec "$env(ACTEL_SW_DIR)/bin64/bfmtovec.exe"   -in SERDESIF_0_user.bfm   -out SERDESIF_0.vec
}
