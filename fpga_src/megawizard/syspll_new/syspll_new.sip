set_global_assignment -entity "syspll_new" -library "lib_syspll_new" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "syspll_new" -library "lib_syspll_new" -name IP_TOOL_VERSION "13.1"
set_global_assignment -entity "syspll_new" -library "lib_syspll_new" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_syspll_new" -name SPD_FILE [file join $::quartus(sip_path) "syspll_new.spd"]

set_global_assignment -library "lib_syspll_new" -name MISC_FILE [file join $::quartus(sip_path) "syspll_new_sim/syspll_new.vo"]
