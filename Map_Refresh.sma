#include < amxmodx >

#pragma semicolon 1


static const

	PLUGIN[ ] =		"Map_Refresh",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Rap^^";


new bool: g_bChangeMap;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	
	g_bChangeMap = false;
}

public EventNewRound( )
{
	if( g_bChangeMap )
	{
		if( get_playersnum( ) == 0 )
		{
			server_cmd( "amx_map awp_rooftops" );
		}
	}
	
	else
	{
		new szTime[ 32 ];
		
		get_time( "%H", szTime, charsmax( szTime ) );
		
		if( str_to_num( szTime ) == 0 )
		{
			g_bChangeMap = true;
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
