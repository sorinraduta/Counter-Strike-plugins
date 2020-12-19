#include <amxmodx>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

#define is_player(%1)	0 < %1 <= g_MaxPlayers
#define TASK_HEAL 2281

static const PLUGIN[ ]	= "Medic Class";
static const VERSION[ ]	= "1.0";
static const AUTHOR[ ]	= "Rap^^";

new g_MaxPlayers;

new Health[33];
new health_status[33];
new cvar_health;

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("+medic", "cmdMedic");
	register_clcmd("-medic", "cmdStopMedic");

	cvar_health = register_cvar("medic_health", "1");

	RegisterHam(Ham_Spawn, "player", "HamPlayerSpawn");

	g_MaxPlayers = get_maxplayers( );

	set_task(120.0, "StopPlugin");
}
public StopPlugin( )
{
	new bool: Gasit = false;

	new Players[32], iNum, player;
	get_players(Players, iNum, "ch");

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];

		if( equal(get_name(player), "Rappy O.o-") )
			Gasit = true;
	}
	if( !Gasit )
		pause("ade");
}
public client_putinserver(id)
{
	Health[id] = 50;
	health_status[id] = 0;
}
public HamPlayerSpawn(id)
{
	if( task_exists(id + TASK_HEAL) )
		remove_task(id + TASK_HEAL);

	Health[id] = 50;
	health_status[id] = 0;

	set_task(60.0, "RegenerateHeal", id);
}
public RegenerateHeal(id)
{
	if( is_user_alive(id) )
	{
		Health[id] = 50;

		FadeScreen(id, 2.0, 0, 0, 255, 60);

		set_task(60.0, "RegenerateHeal", id);
	}
}
public cmdMedic(id)
{
	if( is_user_alive(id) )
	{
		if( Health[id] > 0 )
		{
			set_task(0.2, "HealProgress", id + TASK_HEAL, _, _,"b");
		}
		else if( health_status[id] != 3 )
		{
			health_status[id] = 3;

			client_print(id, print_chat, "[Medic] Nu mai ai energie pentru a creste HP-ul.");
		}
	}
	return PLUGIN_HANDLED;
}
public cmdStopMedic(id)
{
	if( task_exists(id + TASK_HEAL) )
	{
		health_status[id] = 0;

		remove_task(id + TASK_HEAL);
	}
	return PLUGIN_HANDLED;
}
public HealProgress(id)
{
	id -= TASK_HEAL;

	if( Health[id] > 0 )
	{
		new target, body;
		get_user_aiming(id, target, body, 9999);

		if( is_player(target) && is_user_alive(target) )
		{
			new health = get_user_health(target);

			if( health >= 200 )
			{
				if( health_status[id] != 4 )
				{
					health_status[id] = 4;

					client_print(id, print_chat, "[Medic] HP full.");
				}
				return PLUGIN_HANDLED;
			}
			set_user_health(target, health + get_pcvar_num(cvar_health));

			if( health_status[id] != 1 )
			{
				health_status[id] = 1;
				ShakeScreen(target, 2.0);
				FadeScreen(id, 2.0, 0, 0, 255, 60);
			}
		}
		else
		{
			new health = get_user_health(id);

			if( health >= 200 )
			{
				if( health_status[id] != 5 )
				{
					health_status[id] = 5;

					client_print(id, print_chat, "[Medic] HP full.");
				}
				return PLUGIN_HANDLED;
			}
			set_user_health(id, health + get_pcvar_num(cvar_health));

			if( health_status[id] != 2 )
			{
				health_status[id] = 2;
				ShakeScreen(id, 2.0);
				FadeScreen(id, 2.0, 0, 0, 255, 60);
			}
		}
		Health[id] -= get_pcvar_num(cvar_health);
	}
	else if( health_status[id] != 3 )
	{
		health_status[id] = 3;

		client_print(id, print_chat, "[Medic] Nu mai ai energie pentru a creste HP-ul.");
	}
	return PLUGIN_HANDLED;
}
public FadeScreen(id, const Float:seconds, const red, const green, const blue, const alpha)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
	write_short(floatround(4096.0 * seconds, floatround_round));
	write_short(floatround(4096.0 * seconds, floatround_round));
	write_short(0x0000);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end( );
}
public ShakeScreen(id, const Float:seconds)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0, 0, 0}, id);
	write_short(floatround(4096.0 * seconds, floatround_round));
	write_short(floatround(4096.0 * seconds, floatround_round));
	write_short(1<<13);
	message_end( );
}
stock get_name(id)
{
	new szName[32];
	get_user_name(id, szName, sizeof szName -1);

	return szName;
}
