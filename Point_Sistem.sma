#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <ColorChat>

#pragma semicolon 1

#define ZERO 0
#define TOPNUM 15

static const PLUGIN[ ]  = "Top Points";
static const VERSION[ ] = "1.0";
static const AUTHOR[ ]  = "Rap^^";

new user_points[33];
new szName[33][32];

new cvar_frag;
new cvar_deces;
new cvar_sinucidere;
new cvar_runda;
new cvar_hs;

new iVault;
new Data[64];
new toppoints[33], topnames[33][33];
new bool: round_ended;

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /points", "cmdPoints");
	register_clcmd("say /point", "cmdPoints");
	register_clcmd("say /puncte", "cmdPoints");
	register_clcmd("say /top", "cmdTop");
	register_clcmd("say /toppoints", "cmdTop");
	register_concmd("add_points", "cmdAddPoints");
	register_concmd("remove_points", "cmdRemovePoints");
	register_concmd("reset_top", "cmdResetTop");
	register_clcmd("reset_top", "cmdResetTop");

	register_event("DeathMsg", "EventDeathMsg", "a");

	register_event("SendAudio", "EventTerroWin", "a", "2=%!MRAD_terwin");

	cvar_frag = register_cvar("points_frag", "4"); //primeste
	cvar_deces = register_cvar("points_deces", "4"); // pierde
	cvar_sinucidere = register_cvar("points_sinucidere", "5"); //pierde
	cvar_runda = register_cvar("points_runda", "3"); //primeste
	cvar_hs = register_cvar("points_hs", "5"); //primeste

	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_logevent("EventEndRound", 2, "0=World triggered", "1=Round_End");

	iVault = nvault_open("UsersPoints");

	if( iVault == INVALID_HANDLE )
	{
		set_fail_state("nValut returned invalid handle");
	}
	get_datadir(Data, 63);

	read_top( );

	round_ended = false;
}
public plugin_end( )
{
	nvault_close(iVault);
}
public client_putinserver(id)
{
	if( !is_user_bot(id) && !is_user_hltv(id) )
	{
		format(szName[id], 31, "%s", get_name(id));
		user_points[id] = 0;

		LoadPoints(id);
	}
}
public client_disconnect(id)
{
	if( !is_user_bot(id) && !is_user_hltv(id) )
	{
		SavePoints(id);
	}
}
public cmdPoints(id)
{
	ColorChat(id, RED, "^x04[Points]^x01 Ai^x03 %d^x01 puncte.", user_points[id]);
}
public cmdAddPoints(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;

	new target[32], szPoints[32];
    	read_argv(1, target, 31);
	read_argv(2, szPoints, 31);

	new player = cmd_target(id, target, 8);

	if( !player )
		return PLUGIN_HANDLED;

	new Points = str_to_num(szPoints);

	user_points[player] += Points;

	if( id == player )
	{
		ColorChat(player, RED, "^x04[Points]^x01 Ti-ai dat^x04 %d^x01 puncte.", Points);
	}
	else
	{
		ColorChat(player, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 ti-a dat^x04 %d^x01 puncte.", get_name(id), Points);
		ColorChat(id, RED, "^x04[Points]^x01 I-ai dat lui^x03 %s^x04 %d^x01 puncte.", get_name(player), Points);
	}
	UpdateTop(player, user_points[player], false);

	return PLUGIN_HANDLED;
}
public cmdRemovePoints(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;

	new target[32], szPoints[32];
    	read_argv(1, target, 31);
	read_argv(2, szPoints, 31);

	new player = cmd_target(id, target, 8);

	if( !player )
		return PLUGIN_HANDLED;

	new Points = str_to_num(szPoints);

	if( user_points[player] <= Points )
	{
		user_points[player] = 0;

		if( id == player )
		{
			ColorChat(player, RED, "^x04[Points]^x01 Te-ai lasat cu^x04 %d^x01 puncte.", user_points[id]);
		}
		else
		{
			ColorChat(player, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 te-a lasat cu^x04 %d^x01 puncte.", get_name(id), user_points[player]);
			ColorChat(id, RED, "^x04[Points]^x01 L-ai lasat pe^x03 %s^x01 cu^x04%d^x01 puncte.", get_name(player), user_points[player]);
		}
	}
	else
	{
		user_points[player] -= Points;

		if( id == player )
		{
			ColorChat(player, RED, "^x04[Points]^x01 Ti-ai luat^x04 %d^x01 puncte.", Points);
		}
		else
		{
			ColorChat(player, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 ti-a luat^x04 %d^x01 puncte.", get_name(id), Points);
			ColorChat(id, RED, "^x04[Points]^x01 I-ai luat lui^x03 %s^x04%d^x01 puncte.", get_name(player), Points);
		}
	}
	UpdateTop(player, user_points[player], true);

	return PLUGIN_HANDLED;
}
public cmdResetTop(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;

	new path[128], npath[127];
	formatex(path, 127, "%s/TopPoints.dat", Data);
	formatex(npath, 127, "addons/amxmodx/data/vault/UsersPoints.vault");

	if( file_exists(path) )
		delete_file(path);

	nvault_close(iVault);

	if( file_exists(npath) )
		delete_file(npath);

	nvault_open("UsersPoints");

	static info_none[33];
	info_none = "";

	for( new i = ZERO; i < TOPNUM; i++ )
	{
		formatex(topnames[i], 31, info_none);
		toppoints[i] = ZERO;
	}
	save_top( );

	new Players[32], iNum, player;
	get_players(Players, iNum, "ch");

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];

		user_points[player] = 0;
	}
	ColorChat(0, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 a resetat Points Top.", get_name(id));
	console_print(0, "[Points] Adminul %s a resetat Points Top.", get_name(id));

	return PLUGIN_CONTINUE;
}
public EventEndRound( )
{
	round_ended = true;
}
public EventNewRound( )
{
	round_ended = false;
}
public EventDeathMsg( )
{
	if( round_ended || get_playersnum( ) <= 4 )
		return PLUGIN_CONTINUE;

	new iKiller = read_data(1);
	new iVictim = read_data(2);

	if( iKiller == 0 || iKiller == iVictim )
	{
		if( user_points[iVictim] <= get_pcvar_num(cvar_sinucidere) )
		{
			user_points[iVictim] = 0;

			ColorChat(iVictim, RED, "^x04[Points]^x01 Ai ajuns la^x03 %d^x01 puncte.", user_points[iVictim]);
		}
		else
		{
			user_points[iVictim] -= get_pcvar_num(cvar_sinucidere);

			ColorChat(iVictim, RED, "^x04[Points]^x01 Ai pierdut^x03 %d^x01 puncte.", get_pcvar_num(cvar_sinucidere));
		}
		UpdateTop(iVictim, user_points[iVictim], true);
	}
	else
	{
		if( read_data(3) )
		{
			user_points[iKiller] += get_pcvar_num(cvar_hs);

			ColorChat(iKiller, RED, "^x04[Points]^x01 Ai primit^x03 %d^x01 puncte.", get_pcvar_num(cvar_hs));
		}
		else
		{
			user_points[iKiller] += get_pcvar_num(cvar_frag);

			ColorChat(iKiller, RED, "^x04[Points]^x01 Ai primit^x03 %d^x01 puncte.", get_pcvar_num(cvar_frag));
		}
		UpdateTop(iKiller, user_points[iKiller], false);

		if( user_points[iVictim] <= get_pcvar_num(cvar_deces) )
		{
			user_points[iVictim] = 0;

			ColorChat(iVictim, RED, "^x04[Points]^x01 Ai ajuns la^x03 %d^x01 puncte.", user_points[iVictim]);
		}
		else
		{
			user_points[iVictim] -= get_pcvar_num(cvar_deces);

			ColorChat(iVictim, RED, "^x04[Points]^x01 Ai pierdut^x03 %d^x01 puncte.", get_pcvar_num(cvar_deces));
		}
		UpdateTop(iVictim, user_points[iVictim], true);
	}
	return PLUGIN_CONTINUE;
}
public EventTerroWin( )
{
	if( get_playersnum( ) <= 4 )
		return PLUGIN_CONTINUE;

	new Players[32], iNum, player;
	get_players(Players, iNum, "aceh", "TERRORIST");

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];

		user_points[player] += get_pcvar_num(cvar_runda);

		ColorChat(player, RED, "^x04[Points]^x01 Ai primit^x03 %d^x01 puncte.", get_pcvar_num(cvar_runda));

		UpdateTop(player, user_points[player], false);
	}
	return PLUGIN_CONTINUE;
}
public cmdTop(id)
{
	show_top(id);
}
public LoadPoints(id)
{
	static szData[256], iTimestamp;
	if( nvault_lookup(iVault, szName[id], szData, sizeof(szData) - 1, iTimestamp) )
	{
		static szPoints[15];
		parse(szData, szPoints, sizeof(szPoints) - 1);

		user_points[id] = str_to_num(szPoints);

		return;
	}
	else
	{
		user_points[id] = 0;
	}
}
public SavePoints(id)
{
	static szKey[256], szData[256];

	format(szKey, 255, "%s", szName[id]);
	format(szData, sizeof(szData) -1, "^"%i^"", user_points[id]);

	nvault_set(iVault, szKey,  szData);
}
public read_top( )
{
	new Buffer[256], path[128];
	formatex(path, 127, "%s/TopPoints.dat", Data);

	new f = fopen(path, "rt");
	new i = ZERO;

	while( !feof(f) && i < TOPNUM + 1 )
	{
		fgets(f, Buffer, 255);
		new szPoints[25];
		parse(Buffer, topnames[i], 31, szPoints[i], 24);

		toppoints[i] = str_to_num(szPoints[i]);

		i++;
	}
	fclose(f);
}
public save_top( )
{
	new path[128];
	formatex(path, 127, "%s/TopPoints.dat", Data);
	if( file_exists(path) )
	{
		delete_file(path);
	}
	new Buffer[256];
	new f = fopen(path, "at");

	for( new i = ZERO; i < TOPNUM; i++ )
	{
		formatex(Buffer, 255, "^"%s^" ^"%d^"^n", topnames[i], toppoints[i]);
		fputs(f, Buffer);
	}
	fclose(f);
}
public UpdateTop( id, const iPoints, const bool:bUpdateTop )
{
        if( bUpdateTop )
        {
                for( new i = ZERO; i < TOPNUM; i++ )
                {
                        if( equal(topnames[i], szName[id]) )
                        {
                                for(new j = i; j < TOPNUM; j++)
                                {
                                        formatex(topnames[j], 32, topnames[j+1]);
                                        toppoints[j] = toppoints[j+1];
                                }

                                break;
                        }
                }
        }
        for( new i = ZERO; i < TOPNUM; i++ )
        {
                if( iPoints > toppoints[i] )
                {
                        new pos = i;
                        while( !equal(topnames[pos],  szName[id]) && pos < TOPNUM )
                        {
                                pos++;
                        }

                        for( new j = pos; j > i; j-- )
                        {
                                formatex(topnames[j], 31, topnames[j-1]);
                                toppoints[j] = toppoints[j-1];

                        }
                        formatex(topnames[i], 31,  szName[id]);

                        toppoints[i]= iPoints;

                        save_top( );
                        break;
                }
                else if( equal(topnames[i], szName[id]) )
                        break;
        }
}
public show_top(id)
{
	static buffer[2368], name[131], len, i;
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{border-style:solid;border-width:1px;border-color:#FFFFFF;font-size:13px}</STYLE><table align=center width=100%% cellpadding=2 cellspacing=0");
	len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#52697B><th width=4%% > # <th width=24%%> Nume Jucator <th width=24%%> Puncte");
	for( i = ZERO; i < TOPNUM; i++ )
	{
		if( toppoints[i] == 0 )
		{
			len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#232323><td> %d <td> %s <td> %s", (i+1), "-", "-");
		}
		else
		{
			name = topnames[i];
			while( containi(name, "<") != -1 )
				replace(name, 129, "<", "&lt;");

			while( containi(name, ">") != -1 )
				replace(name, 129, ">", "&gt;");

			new plname[32];
			get_user_name(id, plname ,32);

			if( equal(topnames[i], plname) )
			{
				len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d", (i+1), name, toppoints[i]);
			}
			else
			{
				len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#232323><td> %d <td> %s <td> %d", (i+1), name, toppoints[i]);
			}
		}
	}
	len += format(buffer[len], 2367-len, "</table>");
	//len += formatex(buffer[len], 2367-len, "<tr align=bottom font-size:11px><Center><br><br><br><br>Primii 15 jucatori cu cele mai multe puncte.</body>");
	static strin[20];
	format(strin,33, "Top Points");
	show_motd(id, buffer, strin);
}
stock get_name(id)
{
	new szName[32];
	get_user_name(id, szName, sizeof szName -1);

	return szName;
}
