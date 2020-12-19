#include < amxmodx >

enum Color
{
	YELLOW = 1,
	GREEN,
	TEAM_COLOR,
	GREY,
	RED,
	BLUE,
}

new TeamInfo;
new SayText;
new MaxSlots;

new TeamName[ ][ ] =
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}


new bool: g_Restart = true;

public plugin_init ( )
{
	register_plugin ( "Auto Restart", "1.0", "Rap^^" );

	register_event ( "TextMsg", "game_comencing", "a", "2&#Game_C" );
	register_logevent ( "round_end", 2, "1=Round_End" );

	TeamInfo = get_user_msgid ( "TeamInfo" );
	SayText = get_user_msgid ( "SayText" );
	MaxSlots = get_maxplayers ( );
}

public game_comencing ( )
	g_Restart = true;

public round_end ( )
{
	if( g_Restart )
	{
		server_cmd ( "sv_restart 2" );
		ColorChat( 0, GREEN, "^x01[-----LIVE!-----]" );
		ColorChat( 0, GREEN, "^x01[-----LIVE!-----]" );
		ColorChat( 0, GREEN, "^x01[-----LIVE!-----]" );
		ColorChat( 0, GREEN, "^x01[-----LIVE!-----]" );
		ColorChat( 0, GREEN, "^x01[-----LIVE!-----]" );

	}

	g_Restart = false;
}

public ColorChat( id, Color:type, const msg[ ], { Float, Sql, Result, _ }:... )
{
	static message[ 256 ];

	switch( type )
	{
		case YELLOW: message[ 0 ] = 0x01;
		case GREEN: message[ 0 ] = 0x04;

		default: message[ 0 ] = 0x03;
	}

	vformat( message[ 1 ], 251, msg, 4 );

	message[ 192 ] = '^0';

	new team, ColorChange, index, MSG_Type;

	if( id )
	{
		MSG_Type = MSG_ONE;
		index = id;
	}
	else
	{
		index = FindPlayer ( );
		MSG_Type = MSG_ALL;
	}

	team = get_user_team( index );
	ColorChange = ColorSelection( index, MSG_Type, type );

	ShowColorMessage( index, MSG_Type, message);

	if( ColorChange )
		Team_Info( index, MSG_Type, TeamName[ team ] );
}

ShowColorMessage ( id, type, message[ ] )
{
	message_begin ( type, SayText, _, id );
	write_byte ( id )
	write_string ( message );
	message_end ();
}

Team_Info ( id, type, team[ ] )
{
	message_begin (type, TeamInfo, _, id );
	write_byte ( id );
	write_string ( team );
	message_end ();

	return 1;
}

ColorSelection ( index, type, Color:Type )
{
	switch( Type )
	{
		case RED:
			return Team_Info( index, type, TeamName[ 1 ] );
		case BLUE:
			return Team_Info( index, type, TeamName[ 2 ] );
		case GREY:
			return Team_Info(index, type, TeamName[ 0 ] );
	}

	return 0;
}

FindPlayer ( )
{
	for ( new i = 1; i <= MaxSlots; i++ )
		if ( is_user_connected( i ) )
			return i;

	return -1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
