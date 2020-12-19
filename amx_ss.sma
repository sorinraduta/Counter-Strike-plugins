#include <amxmodx>
#include <amxmisc>

new gmsgFade
public plugin_init()
{
	register_plugin("Amx_SS", "1.0", "Rap^^")
	register_concmd("amx_ss", "ScreenShot", ADMIN_KICK, "amx_ss <player>")

	gmsgFade = get_user_msgid("ScreenFade")
}

new name_player[32],param,pozes,poze

public ScreenShot(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
	return PLUGIN_HANDLED

	new arg[32], ip_player[32]
	read_argv(1, arg, 31)

	new player = cmd_target(id, arg, 4)

	if (!player)
	return PLUGIN_HANDLED

	get_user_name(player, name_player, 31);
	get_user_ip(player, ip_player, 31, 1);

	client_print(id, print_chat, "Nick: ^"%s^" - IP: %s", name_player,ip_player);

	client_print(id, print_console, "Nick: ^"%s^" - IP: %s", name_player,ip_player);
	client_print(id, print_console, "Nick: ^"%s^" - IP: %s", name_player,ip_player);
	client_print(id, print_console, "Nick: ^"%s^" - IP: %s", name_player,ip_player);

	pozes=5
	poze=1

	client_print(id, print_chat, "^"%s^" ti-a facut 5 Screenshot-uri, una dintre ele ar trebui sa fie VERDE !", name_player);

	new hostname[64], name_admin[32], timer[32];

  	get_cvar_string("hostname",hostname,63);
	get_user_name(id, name_admin, 31);
   	get_time("%m/%d/%Y - %H:%M:%S", timer,31);

	client_print(player, print_center, "Screenshot #%d", poze+1);

	client_print(player, print_chat, "--------------------------------------------");
	client_print(player, print_chat, "Adminul: ^"%s^" ti-a facut poze !", name_admin);
	client_print(player, print_chat, "Numele tau: ^"%s^" - IP-ul tau: %s", name_player, ip_player);
	client_print(player, print_chat, "Data si Timpul: %s - Server: ^"%s^"", timer, hostname);
	client_print(player, print_chat, "--------------------------------------------");

	client_cmd(player,"snapshot");

	poze++
	param=player
	set_task(1.0,"GreenShot",3322,_,_,"b");
	return PLUGIN_HANDLED
}

public GreenShot(id, level, cid)
{
	if(poze < pozes) {

	if(poze==3) {

			message_begin(MSG_ONE, gmsgFade, {0,0,0},param)
     			write_short(14<<7)
     			write_short(58<<6)
     			write_short(1<<0)
     			write_byte(5)
     			write_byte(255)
    			write_byte(0)
    			write_byte(255)
			message_end()
	}

	new hostname[64], name_player[32], ip_player[32], timer[32];
	new frags = get_user_frags (param)
	new deaths = get_user_deaths (param)

	get_cvar_string("hostname",hostname,63);
	get_user_name(param,name_player,31);
	get_user_ip(param, ip_player, 31, 1);
	get_time("%m/%d/%Y - %H:%M:%S", timer,31);

	client_print(param, print_center, "Screenshot #%d", poze+1);

	client_print(param, print_chat, "--------------------------------------------");
	client_print(param, print_chat, "Fragurile tale: %d - Decesurile tale: %d",frags, deaths);
	client_print(param, print_chat, "Numele tau: ^"%s^" - IP-ul tau: %s", name_player, ip_player);
	client_print(param, print_chat, "Data si Timpul: %s - Server: ^"%s^"", timer, hostname);
	client_print(param, print_chat, "--------------------------------------------");

	client_cmd(param,"snapshot");
	poze++

	} else {

		client_cmd(param,"snapshot");
		client_cmd(param,"kill;wait;jointeam 6");

		get_user_name(param, name_player, 31);

		client_print(0, print_chat, "Adminul ^"%s^" a facut poze unu jucator !", name_player);

		client_print(param, print_chat, "%s, ti-a facut 5 poze. Scrieti ID-ul de Messenger, ori admini te vor considera codat !", name_player);
		client_print(param, print_chat, "ID-ul de Messenger trebuie sa-l scri folosind comanda say_team@ !");

		remove_task(3322);

	}

	return PLUGIN_HANDLED;
}
