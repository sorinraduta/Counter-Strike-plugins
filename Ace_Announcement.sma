/*
**
**
**					ACE ANNOUNCEMENT
**						v1.2
**					     by RapZzw3rR
**
**
**
**
**
**
**	   CVars:
**
**	      aa_tag: Choose the prefix of chat messages
**
**		default: [ACE ANNOUNCEMENT]
**
**
**	      aa_show: Choose what you want to appear when is done
**
**		default: 3
**
**		0 - None
**		1 - Ace
**		2 - Semi-ace
**		3 - Ace + Semi-ace
**
**
**	      aa_showtype: Choose the type of announce
**
**		default: 1
**
**		1 - Chat
**		2 - HUD
**		3 - DHUD
**
**
**
**	   Forwards:
**
**	      FwdPlayerDidAce: Called when a player did ace (killed 5 enemies)
**
**		First param: Index of player who did ace
**
**
**	      FwdPlayerDidSemiAce: Called when a player did semi-ace (killed 4 enemies)
**
**		First param: Index of player who did semi-ace
**
**
**
**
**	   OFFICIAL FORUM: https://forums.alliedmods.net/showthread.php?t=229593
**
**
**
*/

#include < amxmodx >
#include < cstrike >
#include < dhudmessage >
#include < ColorChat >

#pragma semicolon	1

#define NULL		0

enum
{
	SEMI_ACE = 4,
	ACE
};


static const

	PLUGIN[ ] =	"Ace_announcement",
	VERSION[ ] =	"1.2",
	AUTHOR[ ] =	"Rap^^";


new g_iFrags[ 33 ];

new iFwdAce;
new iFwdSemiAce;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	register_cvar( "aa_tag",	"[ACE ANNOUNCEMENT]" );
	register_cvar( "aa_show",	"3" );
	register_cvar( "aa_showtype",	"1" );

	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	register_event( "DeathMsg", "EventDeathMsg", "a" );

	register_logevent( "LogEventRoundEnd", 2, "1=Round_End" );

	iFwdAce  = CreateMultiForward( "FwdPlayerDidAce", ET_STOP, FP_CELL );
	iFwdSemiAce  = CreateMultiForward( "FwdPlayerDidSemiAce", ET_STOP, FP_CELL );
}

public plugin_end( )
{
	DestroyForward( iFwdAce );
	DestroyForward( iFwdSemiAce );
}

public client_connect( id )
{
	g_iFrags[ id ] = NULL;
}

public EventNewRound( )
{
	arrayset( g_iFrags, NULL, sizeof g_iFrags );
}

public EventDeathMsg( )
{
	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );

	CheckAce( iVictim );

	if( !iKiller || iKiller == iVictim || cs_get_user_team( iKiller ) == cs_get_user_team( iVictim ) )
	{
		return PLUGIN_CONTINUE;
	}

	g_iFrags[ iKiller ]++;

	return PLUGIN_CONTINUE;
}

public LogEventRoundEnd( )
{
	new iPlayers[ 32 ];

	new iNum;
	new player;

	get_players( iPlayers, iNum, "ch" );

	for( new i = NULL; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		switch( g_iFrags[ player ] )
		{
			case ACE:
			{
				UserDidAce( player );

				return PLUGIN_CONTINUE;
			}

			case SEMI_ACE:
			{
				UserDidSemiAce( player );
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public CheckAce( id )
{
	switch( g_iFrags[ player ] )
	{
		case ACE:
		{
			UserDidAce( player );
		}

		case SEMI_ACE:
		{
			UserDidSemiAce( player );
		}
	}

	g_iFrags[ id ] = NULL;
}

public UserDidAce( id )
{
	new iReturn = PLUGIN_CONTINUE;

	ExecuteForward( iFwdAce, iReturn, id );

	if( iReturn == PLUGIN_HANDLED || iReturn == PLUGIN_HANDLED_MAIN )
	{
		return PLUGIN_HANDLED;
	}

	ColorChat( NULL, GREEN, "%s^x03 %s^x01 made an ^x03ACE^x01.", get_tag( ), get_name( id ) );

	client_cmd( NULL, "spk vox/buzwarn" );

	return PLUGIN_HANDLED;
}

public UserDidSemiAce( id )
{
	new iReturn = PLUGIN_CONTINUE;

	ExecuteForward( iFwdSemiAce, iReturn, id );

	if( iReturn == PLUGIN_HANDLED || iReturn == PLUGIN_HANDLED_MAIN )
	{
		return PLUGIN_HANDLED;
	}

	ColorChat( NULL, GREEN, "%s^x03 %s^x01 made a ^x03SEMI-ACE^x01.", get_tag( ), get_name( id ) );

	client_cmd( NULL, "spk vox/buzwarn" );

	return PLUGIN_HANDLED;
}

public get_tag( )
{
	new szTag[ 32 ];

	get_pcvar_string( aa_tag, szTag, charsmax( szTag ) );

	return szTag;
}

public get_name( id )
{
	new szName[ 32 ];

	get_user_name( id, szName, charsmax( szName ) );

	return szName;
}
