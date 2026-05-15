set_component CorePCS_C0
set_false_path -through [get_nets {*/cpcs_rst_sync*/RESET_N*}]
set_false_path -through [get_nets {*/cpcs_rst_sync*/WA_RSTn*}]
set_false_path -through [get_nets {*/cpcs_rst_sync*/EPCS_RxVAL*}]
