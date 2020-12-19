#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <ColorChat>

#pragma semicolon 1

static const PLUGIN[ ]	= "Show Keys";
static const VERSION[ ]	= "1.0";
static const AUTHOR[ ]	= "Rap^^";

new g_Keys[33];
new sz_Keys[33][32];
new sz_SpeedFPS[33][32];

new Float:GameTime[33];

new FramesPer[33];
new CurFps[33];
new Fps[33];

new bool: g_ShowKeys[33];

new SyncHud;
new SyncHud2;

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /showkeys", "cmdShowKeys");
	register_clcmd("say /keys", "cmdShowKeys");
	register_forward(FM_PlayerPreThink, "FwdPlayerPreThink");

	SyncHud = CreateHudSyncObj( );
	SyncHud2 = CreateHudSyncObj( );
}
public client_connect(id)
{
	g_ShowKeys[id] = true;
}
public server_frame( )
{
	new Players[32], iNum, id;
	get_players(Players, iNum, "ach");

	for( new i = 0; i < iNum; i++ )
	{
		id = Players[i];

		if( get_user_button(id) & IN_FORWARD )
			g_Keys[id] |= IN_FORWARD;

		else if( !(get_user_button(id) & IN_FORWARD) )
			g_Keys[id] &= ~ IN_FORWARD;

		if( get_user_button(id) & IN_BACK )
			g_Keys[id] |= IN_BACK;

		else if( !(get_user_button(id) & IN_BACK) )
			g_Keys[id] &= ~ IN_BACK;

		if( get_user_button(id) & IN_MOVELEFT )
			g_Keys[id] |= IN_MOVELEFT;

		else if( !(get_user_button(id) & IN_MOVELEFT) )
			g_Keys[id] &= ~ IN_MOVELEFT;

		if( get_user_button(id) & IN_MOVERIGHT )
			g_Keys[id] |= IN_MOVERIGHT;

		else if( !(get_user_button(id) & IN_MOVERIGHT) )
			g_Keys[id] &= ~ IN_MOVERIGHT;

		if( get_user_button(id) & IN_DUCK )
			g_Keys[id] |= IN_DUCK;

		else if( !(get_user_button(id) & IN_DUCK) )
			g_Keys[id] &= ~ IN_DUCK;

		if( get_user_button(id) & IN_JUMP )
			g_Keys[id] |= IN_JUMP;

		else if( !(get_user_button(id) & IN_JUMP) )
			g_Keys[id] &= ~ IN_JUMP;
	}
}
public cmdShowKeys(id)
{
	if( g_ShowKeys[id] )
	{
		g_ShowKeys[id] = false;
	}
	else if( !g_ShowKeys[id] )
	{
		g_ShowKeys[id] = true;
	}
	ColorChat(id, RED, "^x04[D/C]^x01 ShowKeys^x03 %sactivat^x01.", g_ShowKeys[id] ? "" : "dez");
}
public FwdPlayerPreThink(id)
{
	if( is_user_connected(id) )
	{
		if( is_user_alive(id) )
		{
			GameTime[id] = get_gametime();

			if(FramesPer[id] >= GameTime[id]) Fps[id] += 1;

			else
			{
				FramesPer[id]	+= 1;
				CurFps[id]	= Fps[id];
				Fps[id]		= 0;
			}

			new sz_Speed[32];
			new Float: speed[3];

			pev(id, pev_velocity, speed);

			float_to_str(floatsqroot(floatadd(floatpower(speed[0], 2.0), floatpower(speed[1], 2.0))), sz_Speed, 5);

			formatex(sz_Keys[id], 31, "  %s      %s^n%s %s %s    %s",
			g_Keys[id] & IN_FORWARD ? "W" : "-",
			g_Keys[id] & IN_DUCK ? "Duck" : "----",
			g_Keys[id] & IN_MOVELEFT ? "A" : "-",
			g_Keys[id] & IN_BACK ? "S" : "-",
			g_Keys[id] & IN_MOVERIGHT ? "D" : "-",
			g_Keys[id] & IN_JUMP ? "Jump" : "----");

			formatex(sz_SpeedFPS[id], 31, "Speed: %s^n   FPS: %d", sz_Speed, CurFps[id]);

			if( g_ShowKeys[id] )
			{
				set_hudmessage(15, 15, 20, -1.0, 0.70, 0, 2.5, 0.0, 0.0, 0.1, -1);
				ShowSyncHudMsg(id, SyncHud, "%s", sz_Keys[id]);

				set_hudmessage(15, 15, 20, -1.0, 0.76, 0, 2.5, 0.0, 0.0, 0.1, -1);
				ShowSyncHudMsg(id, SyncHud2,"%s", sz_SpeedFPS[id]);
			}
		}
		else if( !is_user_alive(id) && g_ShowKeys[id])
		{
			new id2 = pev(id, pev_iuser2);
			if( !id2 )
				return PLUGIN_CONTINUE;

			set_hudmessage(15, 15, 20, -1.0, 0.70, 0, 2.5, 0.0, 0.0, 0.1, -1);
			ShowSyncHudMsg(id, SyncHud, "%s", sz_Keys[id2]);

			set_hudmessage(15, 15, 20, -1.0, 0.76, 0, 2.5, 0.0, 0.0, 0.1, -1);
			ShowSyncHudMsg(id, SyncHud2, "%s", sz_SpeedFPS[id2]);
		}
	}
	return PLUGIN_CONTINUE;
}
