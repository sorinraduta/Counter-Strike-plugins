#include <amxmodx>

#define PLUGIN "MOTD Commands"
#define VERSION "1.0"
#define AUTHOR "Rap^^"


public plugin_init() {
   register_plugin(PLUGIN, VERSION, AUTHOR)
   register_clcmd ("say /comenzi" , "commands" , -1);
   register_clcmd ("say_team /comenzi" , "commands" , -1);
   register_clcmd ("say /info" , "commands" , -1);
   register_clcmd ("say_team /info" , "commands" , -1);
   register_clcmd ("say /commands" , "commands" , -1);
   register_clcmd ("say_team /commands" , "commands" , -1);
}

public commands(id)
{
   show_motd(id,"addons/amxmodx/configs/commands.html")
}
