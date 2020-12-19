#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <ColorChat>

new const g_Plugin[] = "HNS Deathmatch";
new const g_Version[] = "2.1";
new const g_Author[] = "Rap^^";

new g_MsgScreenFade;

new CsTeams:g_Team[33];
new bool:g_bSolid[33];
new bool:g_bRestoreSolid[33];

new const g_BuyCommands[][] =
{
	"usp", "glock", "deagle", "p228", "elites",
	"fn57", "m3", "xm1014", "mp5", "tmp", "p90",
	"mac10", "ump45", "ak47", "galil", "famas",
	"sg552", "m4a1", "aug", "scout", "awp", "g3sg1",
	"sg550", "m249", "vest", "vesthelm", "flash",
	"hegren", "sgren", "defuser", "nvgs", "shield",
	"primammo", "secammo", "km45", "9x19mm", "nighthawk",
	"228compact", "fiveseven", "12gauge", "autoshotgun",
	"mp", "c90", "cv47", "defender", "clarion", "krieg552",
	"bullpup", "magnum", "d3au1", "krieg550"
}

new const g_EntityClassNames[][] =
{
	"func_breakable",
	"func_door_rotating",
	"func_door",
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_bomb_target",
	"info_bomb_target",
	"armoury_entity"
}

new bool:g_Joined[33];

public plugin_init()
{
	register_plugin(g_Plugin, g_Version, g_Author);

	g_MsgScreenFade = get_user_msgid("ScreenFade");

	register_event("DeathMsg", "eventDeathMsg", "a");
	register_message(g_MsgScreenFade, "msgScreenFade");

	register_forward(FM_CmdStart, "fwdCmdStart");
	register_forward(FM_ClientKill, "fwdClientKill");
	register_forward(FM_AddToFullPack, "fwdAddToFullPackPost", 1);

	register_forward(FM_PlayerPreThink, "fwdPlayerPreThink", 0);
	register_forward(FM_PlayerPostThink, "fwdPlayerPostThink", 0);

	RegisterHam(Ham_Spawn, "player", "eventPlayerSpawn", 1);

	register_clcmd("buy", "HandleBlock");
	register_clcmd("buyammo1", "HandleBlock");
	register_clcmd("buyammo2", "HandleBlock");
	register_clcmd("buyequip", "HandleBlock");
	register_clcmd("cl_autobuy", "HandleBlock");
	register_clcmd("cl_rebuy", "HandleBlock");
	register_clcmd("cl_setautobuy", "HandleBlock");
	register_clcmd("cl_setrebuy", "HandleBlock");
	register_clcmd("chooseteam", "HandleBlock");
	register_clcmd("say /respawn", "RespawnPlayer");
}

public plugin_precache() register_forward(FM_Spawn, "fwdSpawn");

public eventDeathMsg()
{
	new killer = read_data(1)
	new victim = read_data(2)

	if(killer == 0 && get_user_team(victim) == 1)
	{
		new lucky = GetRandomCT();

		cs_set_user_team(lucky, 1)
		ColorChat(lucky, RED, "^x04[D/C]^x01 Un^x03 terorist^x01 a murit, iar tu ai fost mutat in locul lui.")

		cs_set_user_team(victim, 2);

		GiveItems(lucky)
	}
	else if(killer == victim)
	{
		set_task(1.0, "RespawnPlayer", victim)

		return PLUGIN_HANDLED;
	}
	else if(get_user_team(killer) == 2)
	{
		cs_set_user_team(killer, 1);
		cs_set_user_team(victim, 2);

		GiveItems(killer)
	}
	set_task(1.0, "RespawnPlayer", victim)

	return PLUGIN_CONTINUE;
}
public eventPlayerSpawn(id)
{
	if(is_user_alive(id)) GiveItems(id);
}
public RespawnPlayer(id)
{
	if(!is_user_alive(id) && 1 <= get_user_team(id) <= 2 )
	{
		ExecuteHam(Ham_CS_RoundRespawn, id);
	}
}
public fwdAddToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{
	if( player )
	{
		if( g_bSolid[host] && g_bSolid[ent] )
		{
			if( g_Team[host] == g_Team[ent] )
			{
				set_es(es, ES_Solid, SOLID_NOT);

				static Float:fOldAlpha;

				new Float:fAlpha = 127.0;
				if( fAlpha < 255.0 )
				{
					set_es(es, ES_RenderMode, kRenderTransAlpha);
					set_es(es, ES_RenderAmt, fAlpha);
				}
				else if( fOldAlpha < 255.0 )
				{
					set_es(es, ES_RenderMode, kRenderNormal);
					set_es(es, ES_RenderAmt, 16.0);
				}

				fOldAlpha = fAlpha;
			}
		}
	}

	return FMRES_IGNORED;
}
public fwdCmdStart(id, handle, seed)
{
	if(!is_user_alive(id) || get_user_team(id) != 2) return FMRES_IGNORED;

	static clip, ammo;

	if(get_user_weapon(id, clip, ammo) != CSW_KNIFE) return FMRES_IGNORED;

	static button;
	button = get_uc(handle, UC_Buttons);

	if(button & IN_ATTACK) button = (button & ~IN_ATTACK) | IN_ATTACK2;

	set_uc(handle, UC_Buttons, button);

	return FMRES_SUPERCEDE;
}
public client_putinserver(id)
{
	set_task(5.0, "taskRespawn", id);
}
public fwdPlayerPreThink(plr)
{
	static LastThink, i;

	new Players[32], iNum;
	get_players(Players, iNum, "ch");

	if( plr < LastThink ) // player think loop started again
	{
		for( i = 1; i <= iNum; i++ )
		{
			if( !is_user_connected(i) || !is_user_alive(i) )
			{
				g_bSolid[i] = false;
				continue;
			}

			g_Team[i] = cs_get_user_team(i);
			g_bSolid[i] = bool:(pev(i, pev_solid) == SOLID_SLIDEBOX);
		}
	}

	LastThink = plr;

	if( !g_bSolid[plr] )
	{
		return FMRES_IGNORED;
	}

	for( i = 1; i <= iNum; i++ )
	{
		if( !g_bSolid[i] || g_bRestoreSolid[i] || i == plr )
		{
			continue;
		}

		if( g_Team[plr] == g_Team[i] )
		{
			set_pev(i, pev_solid, SOLID_NOT);
			g_bRestoreSolid[i] = true;
		}
	}

	return FMRES_IGNORED;
}
public fwdPlayerPostThink(plr)
{
	static i;

	new Players[32], iNum;
	get_players(Players, iNum, "ch");

	for( i = 1; i <= iNum; i++ )
	{
		if( g_bRestoreSolid[i] )
		{
			set_pev(i, pev_solid, SOLID_SLIDEBOX);
			g_bRestoreSolid[i] = false;
		}
	}

	return FMRES_IGNORED;
}
public taskRespawn(id)
{
	if(!g_Joined[id])
	{
		if(0 < get_user_team(id) < 3 && !is_user_alive(id))
		{
			set_task(1.0, "RespawnPlayer", id)

			g_Joined[id] = true;
		}
	}
}
public fwdClientKill(id) return FMRES_SUPERCEDE;

public fwdSpawn(ent)
{
	if(!pev_valid(ent)) return FMRES_IGNORED;

	new class[32];
	pev(ent, pev_classname, class, 31);

	for(new i = 0; i < sizeof(g_EntityClassNames); i++)
	{
		if(equal(class, g_EntityClassNames[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent);

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}
public msgScreenFade(msgid, dest, id)
{
	if(is_user_alive(id) && get_user_team(id) == 1)
	{
		static data[4];
		data[0] = get_msg_arg_int(4);
		data[1] = get_msg_arg_int(5)
		data[2] = get_msg_arg_int(6);
		data[3] = get_msg_arg_int(7)

		if(data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] > 199) return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
public client_command(id)
{
	new sArg[13];

	if(read_argv(0, sArg, 12) > 11) return PLUGIN_CONTINUE;

	for(new i = 0; i < sizeof(g_BuyCommands); i++)
	{
		if(equali(g_BuyCommands[i], sArg, 0)) return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
public HandleBlock(id) return PLUGIN_HANDLED;

GiveItems(id)
{
	cs_reset_user_model(id)
	fm_strip_user_weapons(id)

	switch(get_user_team(id))
	{
		case 1:
		{
			fm_give_item(id, "weapon_flashbang")
			cs_set_user_bpammo(id, CSW_FLASHBANG, 2)

			fm_give_item(id, "weapon_smokegrenade")
		}
		case 2:
		{
			fm_give_item(id, "weapon_knife")
		}
	}
}
GetRandomCT( )
{
	static iPlayers[32], iCT_num;
	get_players(iPlayers, iCT_num, "ae", "CT");

	if(!iCT_num)
		return 0;

	return iCT_num > 1 ? iPlayers[random(iCT_num)] : iPlayers[iCT_num - 1];
}
stock fm_strip_user_weapons(index)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent))
		return 0

	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, index)
	engfunc(EngFunc_RemoveEntity, ent)

	return 1
}
stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)

	return 1
}
