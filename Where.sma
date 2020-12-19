#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < ColorChat >

#define MAX_ZONES 36
#define PLAYER_WIDTH 16.0
#define PLAYER_HEIGHT 36.0

#pragma semicolon 1


static const

	PLUGIN[ ] =		"Where",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Rap^^",
	
	TAG[ ] =		"[D/C]";


new const Float: g_flMins[ MAX_ZONES ][ 3 ] =
{
	{ 512.6, -1152.8, 960.0 },
	{ -1661.7, -128.0, 640.6 },
	{ -256.0, 320.0, 573.8 },
	{ -1664.4, 257.9, 917.0 },
	{ -512.4, 56.8, -127.5 },
	{ -640.0, -528.7, 387.7 },
	{ -1279.8, -1023.2, -127.9 },
	{ -638.2, -1117.4, -126.9 },
	{ -274.9, -1149.9, -126.4 },
	{ -221.9, 335.5, -127.9 },
	{ -540.0, -387.4, 1405.0 },
	{ 513.6, 513.9, 844.1 },
	{ 1099.6, -126.9, 840.0 },
	{ 1857.1, -126.7, -382.9 },
	{ 513.8, -385.9, -126.9 },
	{ -255.1, 641.1, 1408.0 },
	{ -256.0, 1281.5, 768.0 },
	{ -2815.4, -1152.4, 896.0 },
	{ -2688.7, -3072.5, 1280.0 },
	{ -1791.0, -895.6, 1344.0 },
	{ -1790.5, -895.8, 1343.9 },
	{ -2176.3, -3327.4, 1024.0 },
	{ -640.5, -3071.2, 1024.0 },
	{ -1662.9, -863.4, 1152.0 },
	{ -766.5, -1534.8, 512.1 },
	{ -1311.8, -2080.5, 1025.0 },
	{ -767.7, -2142.9, 897.0 },
	{ 258.7, -2175.8, 753.1 },
	{ 257.0, -1805.5, 410.7 },
	{ 463.6, -1808.3, -127.9 },
	{ -1664.7, -2049.0, 832.0 },
	{ 896.4, 1664.7, 768.0 },
	{ -384.0, 1920.4, 1344.0 },
	{ -2687.7, 767.8, 1536.0 },
	{ 1664.6, -1279.5, 1216.0 },
	{ 766.4, -896.7, 1784.0 }
};

new const Float: g_flMax[ MAX_ZONES ][ 3 ] =
{
	{ 1534.6, -128.8, 1260.0 },
	{ -513.7, 253.9, 1292.6 },
	{ 511.9, 640.0, 1085.8 },
	{ -254.4, 1857.9, 1521.0 },
	{ -312.4, 256.8, 1072.4 },
	{ -384.0, -128.7, 1401.7 },
	{ -385.8, -527.2, 684.0 },
	{ 765.7, 332.5, 333.0 },
	{ 573.0, -1089.9, 327.5 },
	{ 478.0, 863.5, 62.0 },
	{ -500.0, -187.4, 1545.0 },
	{ 1407.6, 1279.9, 1604.1 },
	{ 1325.6, 511.0, 1120.0 },
	{ 2175.1, 511.2, 215.0 },
	{ 1853.8, 510.0, 571.0 },
	{ 510.8, 1279.1, 2488.0 },
	{ 511.9, 1919.5, 988.0 },
	{ -2047.4, -128.4, 1196.0 },
	{ -1792.7, -1152.5, 1580.0 },
	{ -1665.0, 1792.3, 1540.0 },
	{ -1024.5, -639.8, 1583.9 },
	{ -896.3, -3073.4, 1254.0 },
	{ 383.4, -2559.2, 1324.0 },
	{ -640.9, -129.4, 1412.0 },
	{ 255.4, -1026.8, 874.1 },
	{ -737.8, -992.5, 1305.0 },
	{ 288.2, -1504.9, 1157.0 },
	{ 638.7, -1759.8, 973.1},
	{ 1151.0, -1153.5, 1310.7 },
	{ 1663.6, -388.3, 472.0 },
	{ -1280.7, -897.0, 1002.0 },
	{ 1664.4, 2304.7, 1068.0 },
	{ 895.9, 2688.4, 1644.0 },
	{ -1921.7, 2303.8, 2036.0 },
	{ 2304.6, -127.5, 1416.0 },
	{ 1280.4, -382.7, 2444.0 }
};

new const g_szWhere[ MAX_ZONES ][ ] =
{
	"la^x04 Panouri",
	"la^x04 Garden",
	"la^x04 Pop Dog",
	"la^x04 White Roof",
	"pe^x04 Scara mare",
	"la^x04 Panou TS",
	"in^x04 TS Jos",
	"la^x04 Market",
	"la^x04 Market",	//parte mica
	"la^x04 WC",
	"pe^x04 Panou TS",
	"la^x04 Pod",
	"pe^x04 Pod",
	"in^x04 AntiCamera",
	"sub^x04 Pod",
	"in^x04 Tower",
	"in^x04 Jail",
	"in^x04 Jail LJR",
	"la^x04 LJR",
	"la^x04 LJR",		//mic
	"la^x04 LJR",		//mic mic
	"la^x04 LJR (Spate)",
	"la^x04 LJR (Boost)",
	"in^x04 TS Sus",
	"la^x04 Blue Roof",
	"la^x04 Red Roof",	//parte ts
	"la^x04 Red Roof",	//parte br
	"la^x04 Red Roof",	//parte cts
	"in^x04 CTS Sus",
	"in^x04 CTS Jos",
	"la^x04 RR (Spate)",
	"in^x04 Jail (Surf)",
	"la^x04 White Roof (Boost)",
	"la^x04 Gard (Boost)",
	"la^x04 Panouri (Boost)",
	"pe^x04 Tower CTS"
};


public plugin_init( )
{
	new szMap[ 32 ];
	new const szAwpRooftops[ 32 ] = "awp_rooftops";
	
	get_mapname( szMap, charsmax( szMap ) );
	
	if( !equali( szMap, szAwpRooftops ) || strlen( szMap ) != strlen( szAwpRooftops ) )
	{
		new szPlugin[ 33 ];
		
		formatex( szPlugin, charsmax( szPlugin ), "%s dezactivat", PLUGIN );
		
		register_plugin( szPlugin, VERSION, AUTHOR );
		
		pause( "ade" );
	}
	
	else
	{
		register_plugin( PLUGIN, VERSION, AUTHOR );
		register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
		
		register_clcmd( "say",			"HookSay" );
		register_clcmd( "say /whererandom",	"CmdWhereRandom" );
		
		new const szWhere[ ] = "CmdWhere";
		new const szName[ ] = "<name>";
		
		register_concmd( "amx_where",		szWhere, ADMIN_ALL, szName );
		register_concmd( "amx_where?",		szWhere, ADMIN_ALL, szName );
		register_concmd( "amx_unde",		szWhere, ADMIN_ALL, szName );
		register_concmd( "amx_unde?",		szWhere, ADMIN_ALL, szName );
	}
}

public CmdWhereRandom( id )
{
	new iPlayers[ 32 ], iNum;
	
	get_players( iPlayers, iNum, "aceh", "TERRORIST" );
	
	switch( iNum )
	{
		case 0:
		{
			ColorChat( id, RED, "^x04%s^x01 Nu este niciun^x03 TERO^x01 in viata.", TAG );
		}
		
		case 1:
		{
			WhereIs( id, iPlayers[ 0 ] );
		}
		
		default:
		{
			new iRandom = random( iNum );
			
			WhereIs( id, iPlayers[ iRandom ] );
		}
	}
}

public CmdWhere( id )
{
	new szArg[ 32 ];
	
	read_argv( 1, szArg, charsmax( szArg ) );
	
	new player;
	
	if( equali( szArg, "" ) )
	{
		new iPlayers[ 32 ], iNum;
		
		get_players( iPlayers, iNum, "aceh", "TERRORIST" );
		
		switch( iNum )
		{
			case 0:
			{
				ColorChat( id, RED, "^x04%s^x01 Nu este niciun^x03 TERO^x01 in viata.", TAG );
			}
			
			case 1:
			{
				player = iPlayers[ 0 ];
				
				WhereIs( id, player );
			}
			
			default:
			{
				ColorChat( id, RED, "^x04%s^x01 Sunt mai multi^x03 TERO^x01 in viata.", TAG );
			}
		}
		
		return PLUGIN_HANDLED;
	}
	
	player = cmd_target( id, szArg, 8 );
	
	if( !player )
	{
		return PLUGIN_HANDLED;
	}
	
	WhereIs( id, player );
	
	return PLUGIN_CONTINUE;
}

public HookSay( id )
{
	static szArgs[ 192 ];
	static szCommand[ 192 ];
	
	read_args( szArgs, charsmax( szArgs ) );
	
	if( !szArgs[ 0 ] )
	{
		return PLUGIN_CONTINUE;
	}
	
	remove_quotes( szArgs[ 0 ] );
	
	if( equal( szArgs, "/where", strlen( "/where" ) )
	 || equal( szArgs, "where?", strlen( "where?" ) )
	 || equal( szArgs, "where", strlen( "where" ) )
	 || equal( szArgs, "/unde", strlen( "/unde" ) )
	 || equal( szArgs, "unde?", strlen( "unde?" ) )
	 || equal( szArgs, "unde", strlen( "unde" ) ) )
	{
		replace( szArgs, charsmax( szArgs ), "/", "" );
		
		formatex( szCommand, charsmax( szCommand ), "amx_%s", szArgs );
		
		client_cmd( id, szCommand );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

WhereIs( id, iWanted )
{
	new szName[ 32 ];

	get_user_name( id, szName, charsmax( szName ) );
	
	if( !is_user_alive( id ) )
	{
		ColorChat( id, RED, "^x04%s^x03 %s^x01 nu este in viata.", TAG, szName );
		
		return PLUGIN_HANDLED;
	}
	
	if( get_user_team( id ) != 1 )
	{
		ColorChat( id, RED, "^x04%s^x03 %s^x01 nu este^x03 TERO^x01.", TAG, szName );
		
		return PLUGIN_HANDLED;
	}
	
	new szWantedName[ 32 ];

	get_user_name( iWanted, szWantedName, charsmax( szWantedName ) );
	
	for( new i = 0; i < MAX_ZONES; i++ )
	{
		if( user_touch_zone( iWanted, i ) )
		{
			ColorChat( id, RED, "^x04%s^x03 %s^x01 este %s^x01.", TAG, szWantedName, g_szWhere[ i ] );
			
			return PLUGIN_HANDLED;
		}
	}
	
	ColorChat( id, RED, "^x04%s^x03 %s^x01 este in^x04 aer^x01.", TAG, szWantedName );
	ColorChat( id, RED, "^x04%s^x01 Cauta-l iar peste cateva secunde.", TAG );
	
	return PLUGIN_HANDLED;
}

stock bool: user_touch_zone( id, iZone )
{
	new Float: flOrigin[ 3 ];
	
	pev( id, pev_origin, flOrigin );

	if( g_flMins[ iZone ][ 0 ] - PLAYER_WIDTH <= flOrigin[ 0 ]
	&& g_flMins[ iZone ][ 1 ] - PLAYER_WIDTH <= flOrigin[ 1 ]
	&& g_flMins[ iZone ][ 2 ] - PLAYER_HEIGHT <= flOrigin[ 2 ]
	&& g_flMax[ iZone ][ 0 ] + PLAYER_WIDTH >= flOrigin[ 0 ]
	&& g_flMax[ iZone ][ 1 ] + PLAYER_WIDTH >= flOrigin[ 1 ]
	&& g_flMax[ iZone ][ 2 ] + PLAYER_HEIGHT >= flOrigin[ 2 ] )
	{
		return true;
	}

	return false;
}
