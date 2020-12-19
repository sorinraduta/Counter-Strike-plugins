#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < hamsandwich >
#include < ColorChat >

#pragma semicolon 1

#define MAX_FPS				105
#define TASK_LOAD			10123

#define Set(%1,%2)			( %1 |= 1 << ( %2 & 31 ) )
#define Clear(%1,%2)			( %1 &= ~( 1 <<( %2 & 31 ) ) )
#define Get(%1,%2)			( %1 & 1 << ( %2 & 31 ) )


static const

	PLUGIN[ ] =	"Anti_developer",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Askhanar", // Rap^ update

	TAG[ ] =	"[D/C]";


//new const g_szClassName[ ] = "Anti_developer_Entity";


new Float: g_flGameTime[ 33 ];

new g_iFrames[ 33 ];
new g_iFramesPerSecond[ 33 ];
new g_iCurrentFramesPerSecond[ 33 ];
new g_iNotAllowedFpsFrames[ 33 ];
new g_iWarnings[ 33 ];

new g_iConnected;
new g_iAlive;

new SyncHudMessage;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );

	register_clcmd( "say", "ClCmdSay" );

	register_concmd( "amx_fps", "CmdFPS" );

	RegisterHam( Ham_Spawn, "player",	"FwdPlayerSpawn", true );
	RegisterHam( Ham_Killed, "player",	"FwdPlayerKilled", true );

	register_forward( FM_PlayerPreThink,	"FwdPlayerPreThink", true );

	set_task( 240.0, "ShowCenterMessage", _, _, _, "b", 0 );

	SyncHudMessage = CreateHudSyncObj( );

	//CreateAntiDeveloperEntity( )
}

public client_putinserver( id )
{
	if( !is_user_bot( id ) )
	{
		Set( g_iConnected, id );
		g_iNotAllowedFpsFrames[ id ] = 0;
		g_iWarnings[ id ] = 0;

		if( !task_exists( id + TASK_LOAD ) )
		{
			set_task( 15.0, "FpsCheckerLoaded", id + TASK_LOAD );
		}
	}
}

public client_disconnect( id )
{
	if( !is_user_bot( id ) )
	{
		Clear( g_iConnected, id );
		Clear( g_iAlive, id );
		g_iNotAllowedFpsFrames[ id ] = 0;

		remove_task( id + TASK_LOAD );
	}
}

public ClCmdSay( id )
{
	static szArgs[ 192 ];
	static szCommand[ 192 ];

	read_args( szArgs, charsmax( szArgs ) );

	if( !szArgs[ 0 ] )
	{
		return PLUGIN_CONTINUE;
	}

	remove_quotes( szArgs[ 0 ] );

	if( equal( szArgs, "/fps", strlen( "/fps" ) ) )
	{
		replace( szArgs, charsmax( szArgs ), "/", "" );

		formatex( szCommand, charsmax( szCommand ), "amx_%s", szArgs );

		client_cmd( id, szCommand );

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public CmdFPS( id )
{
	new szTarget[ 32 ];

    	read_argv( 1, szTarget,  charsmax( szTarget ) );

	if( equali( szTarget, "" ) )
	{
		static szBuffer[ 2368 ];
		static iLen;

		iLen = format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen,"<STYLE>body{background-color:#000000; font-family:Tahoma; font-size:12px; color:#FFFFFF;}table{border-style:solid; border-width:1px; border-color:#FFFFFF; font-family:Tahoma; font-size:10px; color:#FFFFFF; }</STYLE><table align=center width=28%% cellpadding=1 cellspacing=0");
		iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#292929><th width=5%% > # <th width=15%%> Nume <th width=8%%>FPS");

		static iPlayers[ 32 ];
		static iNum;
		static player;

		get_players( iPlayers, iNum, "ch" );

		for( new i = 0; i < iNum; i++ )
		{
			player = iPlayers[ i ];

			new szName[ 32 ];

			get_user_name( player, szName, charsmax( szName ) );

			if( containi( szName, "<") != -1 )
			{
				replace( szName, charsmax( szName ), "<", "&lt;");
			}

			if( containi( szName, ">") != -1 )
			{
				replace( szName, charsmax( szName ), ">", "&gt;");
			}

			if( player == id )
			{
				iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d", ( i + 1 ), szName, g_iCurrentFramesPerSecond[ id ]);
			}

			else
			{
				iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#000000><td> %d <td> %s <td> %d", ( i + 1 ), szName, g_iCurrentFramesPerSecond[ id ]);
			}
		}

		iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "</table>" );

		static szTitle[ 20 ];

		format( szTitle, charsmax( szTitle ), "Tabel FPS" );

		show_motd( id, szBuffer, szTitle );
	}

    	new player = cmd_target( id, szTarget, 8 );

    	if( !player )
	{
		return PLUGIN_HANDLED;
	}


	new szName[ 32 ];

	get_user_name( player, szName, charsmax( szName ) );

	ColorChat( id, RED, "^x04%s^x03 %s^x01 are^x03 %d^x01 FPS.", TAG, szName, g_iCurrentFramesPerSecond[ id ] );

	return PLUGIN_HANDLED;
}

public FwdPlayerSpawn( id )
{
	if( is_user_alive( id ) )
	{
		Set( g_iAlive, id );
		g_iNotAllowedFpsFrames[ id ] = 0;
	}
}

public FwdPlayerKilled( id )
{
	Clear( g_iAlive, id );
}

public FwdPlayerPreThink( id )
{
	g_flGameTime[ id ] = get_gametime( );

	if( g_iFramesPerSecond[ id ] >= g_flGameTime[ id ] )
	{
		g_iFrames[ id ] += 1;
	}

	else
	{
		g_iFramesPerSecond[ id ] += 1;
		g_iCurrentFramesPerSecond[ id ] = g_iFrames[ id ];
		g_iFrames[ id ] = 0;
	}

	if( Get( g_iAlive, id ) )
	{
		if( g_iCurrentFramesPerSecond[ id ] > MAX_FPS )
		{
			if( ++g_iNotAllowedFpsFrames[ id ] >= g_iCurrentFramesPerSecond[ id ] )
			{
				static szSounds[ 3 ][ ] =
				{
					"illegal command _comma detected",
					"fvox/warning",
					"you use illegal _comma command"
				};

				if( ++g_iWarnings[ id ] >= 3 )
				{
					static szName[ 32 ];

					get_user_name( id, szName, charsmax( szName ) );

					server_cmd( "kick #%d ^"Folosesti developer^"", get_user_userid( id ) );

					client_cmd( 0, "spk ^"%s^"", szSounds[ random( 3 ) ] );

					ColorChat( 0, GREEN, "%s^x03 %s^x01 a primit kick deoarece foloseste developer.", TAG, szName );
				}

				else
				{
					client_cmd( id, "spk ^"%s^"", szSounds[ random( 3 ) ] );

					ColorChat( id, GREEN, "%s^x01 Developer detectat. Avertizmentul ^x04%d^x01/3.", TAG, g_iWarnings[ id ] );
				}

				g_iNotAllowedFpsFrames[ id ] = 0;

				SetUserLegalSettings( id );
			}
		}
	}
}

/*
public AntiDeveloperEntityThink( iEnt )
{
	entity_set_float( iEnt, EV_FL_nextthink, get_gametime(  ) + 0.3 );

	static iPlayers[ 32 ];
	static iPlayersNum;

	get_players( iPlayers, iPlayersNum, "ch" );
	if( !iPlayersNum )
		return;

	static id, i;
	for( i = 0; i < iPlayersNum; i++ )
	{
		id = iPlayers[ i ];

		if( IsUserAlive( id ) )
		{

			if( g_iCurrentFramesPerSecond[ id ] >= g_iMaxAllowedFramesPerSecond )
			{

				if( g_iNotAllowedFpsFrames[ id ] >= g_iCurrentFramesPerSecond[ id ] )
				{

					g_iNotAllowedFpsFrames[ id ] = 0;

					static szName[ 32 ];
					get_user_name( id, szName, sizeof ( szName ) -1 );

					ColorChat( 0, RED, "^x04%s^x03 %s^x01 a fost detectat jucand cu^x03 %i^x01 fps!",
						g_szTag, szName, g_iCurrentFramesPerSecond[ id ] );
					ColorChat( 0, RED, "^x04%s^x01 Setarile^x03 legale^x01 i-au fost aplicate!", g_szTag );
					SetUserLegalSettings( id );

					static szSounds[ 2 ][ ] =
					{
						"illegal command _comma detected",
						"fvox/warning"
					};

					client_cmd( 0, "spk ^"%s^"", szSounds[ random( 2 ) ] );

				}

			}

			else if( g_iNotAllowedFpsFrames[ id ] > 0 )
			{

				g_iNotAllowedFpsFrames[ id ] = 0;
				SetUserLegalSettings( id );
			}
		}
	}

}

public CreateAntiDeveloperEntity( )
{
	static iFailCount;

	iEnt = create_entity( "info_target" );

	if( !is_valid_ent( iEnt ) )
	{
		log_amx( "[ERROR] Failed to create announcement entity (%i/10)", ++iFailCount );

		if( iFailCount < 10 )
		{
			set_task( 1.0, "CreateAntiDeveloperEntity" );
		}

		else
		{
			log_amx( "[ERROR] Could not create anti developer entity!" );
		}

		return;
	}

	entity_set_string( iEnt, EV_SZ_classname, g_szClassName );
	entity_set_float( iEnt, EV_FL_nextthink, get_gametime( ) + 0.3 );

	register_think( g_szClassName, "AntiDeveloperEntityThink" );
}
*/
public FpsCheckerLoaded( id )
{
	id -= TASK_LOAD;

	if( Get( g_iConnected, id ) )
	{
		SetUserLegalSettings( id );

		//ColorChat( id, GREEN, "%s^x03 Anti developer^x01 incarcat cu succes.", TAG );
	}
}

public ShowCenterMessage( )
{
	set_hudmessage( random( 256 ), random( 256 ), random( 256 ), -1.0, 0.35, 0, 0.0, random_float( 10.0, 15.0 ) , 0.1, 0.2, -1 );
	ShowSyncHudMsg( 0, SyncHudMessage, "Anti developer^nScanning" );
	client_cmd( 0, "echo Anti developer - Scanning" );
}

stock SetUserLegalSettings( id )
{
	client_cmd( id, "developer 0" );
	client_cmd( id, "fps_max 101" );
	client_cmd( id, "fps_override 0.0" );
	client_cmd( id, "cl_sidespeed 400" );
	client_cmd( id, "cl_forwardspeed 400" );
	client_cmd( id, "cl_backspeed 400" );
	client_cmd( id, "cl_pitchspeed 225" );
	client_cmd( id, "cl_anglespeedkey 0.67" );
	client_cmd( id, "cl_movespeedkey 0.67" );
	client_cmd( id, "cl_pitchdown 89" );
	client_cmd( id, "cl_pitchup 89" );
	client_cmd( id, "cl_upspeed 320" );
	client_cmd( id, "cl_yawspeed 210" );
	client_cmd( id, "m_yaw 0.022" );
	client_cmd( id, "m_pitch 0.022" );
	client_cmd( id, "ex_interp 0.01" );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
