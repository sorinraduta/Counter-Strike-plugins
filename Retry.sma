#include < amxmodx >
#include < csteams >

#pragma semicolon 1


static const

	PLUGIN[ ]	= "Retry",
	VERSION[ ]	= "1.0",
	AUTHOR[ ]	= "Rap^^";


new CsTeams: g_iTeam[ 33 ];

new g_iTeamsNum[ 4 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_event( "TeamInfo", "EventTeamInfo", "a" );
}

public EventTeamInfo( )
{
	new iPlayers[ 32 ];
	
	new iNum;
	new player;
	
	get_players( iPlayers, iNum, "ch" );
	arrayset( g_iTeamsNum, 0, sizeof g_iTeamsNum );
	
	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[ i ];
		
		g_iTeam[ player ] = cs_get_user_team( player );
		g_iTeamsNum[ _:cs_get_user_team( player ) ]++;
	}
}

public client_disconnect( id )
{
	client_print( 0, print_chat, "%d disconnect", print_chat );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
