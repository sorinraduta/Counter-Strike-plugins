#include < amxmodx >
#include < ColorChat >

#pragma semicolon 1

#define SetVoted(%1)		(g_iVoted |= 1 << (%1 & 31))
#define SubVoted(%1)		(g_iVoted &= ~(1 <<(%1 & 31)))
#define HasVoted(%1)		(g_iVoted & 1 << (%1 & 31))


static const
	
	PLUGIN[ ] =		"Mod_Changer",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Rap^^",
	TAG[ ] =		"[D/C]";


enum Mod: eMods
{
	HNSDC = 0,
	HNSDM
};


new const TASK_VOTE =		10023;

new Float: VOTE_TIME =		15.0;
new Float: TASK_TIME =		1800.0;

new Mod: g_iModType;

new g_iModVotes[ eMods ];

new g_iModMenu;
new g_iVoted;
new g_iVotesCount;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	new const szStartVote[ ] = "ClCmdStartVote";
	
	register_clcmd( "say /votemod",	szStartVote );
	register_clcmd( "say /mod",	szStartVote );
	
	register_logevent( "LogEventRoundEnd", 2, "1=Round_End" );
	
	set_task( 60.0, "PrepareVote", TASK_VOTE );
	
	SetMod( HNSDM, false, false );
}

public plugin_cfg( )
{
	g_iModMenu = menu_create( "\yCe mod doresti sa joci in urmatoarele\r 30\y de minute ?", "ModHandler", 0 );
	
	menu_additem( g_iModMenu, "Hide-N-Seek\y Clasic", "", 0 );
	menu_additem( g_iModMenu, "Hide-N-Seek\y DeathMatch", "", 0 );
	
	menu_setprop( g_iModMenu, MPROP_EXIT, MEXIT_NEVER );
	
	SetMod( HNSDM, false, false );
}

public client_putinserver( id )
{
	SubVoted( id );
}

public client_disconnect( id )
{
	if( HasVoted( id ) )
	{
		g_iVotesCount--;
		
		SubVoted( id );
	}
}

public ClCmdStartVote( id )
{
	if( get_user_flags( id ) & ADMIN_RCON )
	{
		new szName[ 32 ];
		
		get_user_name( id, szName, charsmax( szName ) );
		
		PrepareVote( );
		
		ColorChat( 0, RED, "^x04[D/C]^x03 %s^x01 a pornit votul de alegere a modului.", szName );
	}
	
	else
	{
		SetVoted( id );
		
		client_print( id, print_center, "Ai votat pentru schimbarea modului" );
		
		if( ++g_iVotesCount == get_playersnum( ) - 1 )
		{
			switch( g_iModType )
			{
				case HNSDC:
				{
					SetMod( HNSDM, true, true );
				}
				
				case HNSDM:
				{
					SetMod( HNSDC, true, true );
				}
			}
			
			g_iVoted = 0;
			g_iVotesCount = 0;
			
			change_task( TASK_VOTE, TASK_TIME );
		}
	}
}

public LogEventRoundEnd( )
{
	if( get_playersnum( ) == 0 )
	{
		SetMod( HNSDC, true, false );
	}
}

public ModHandler( id, iMenu, iKey )
{
	new szName[ 32 ];
	
	get_user_name( id, szName, charsmax( szName ) );
	
	switch( iKey )
	{
		case 0:
		{
			g_iModVotes[ HNSDC ]++;
			
			ColorChat( 0, RED, "^x04%s^x03 %s^x01 a ales^x03 Hide'N'Seek Clasic", TAG, szName );
		}
		
		case 1:
		{
			g_iModVotes[ HNSDM ]++;
			
			ColorChat( 0, RED, "^x04%s^x03 %s^x01 a ales^x03 Hide'N'Seek DeathMatch", TAG, szName );
		}
	}
	
	return PLUGIN_HANDLED;
}

public PrepareVote( )
{
	new iPlayers[ 32 ];
	
	new iNum;
	
	get_players( iPlayers, iNum, "ch" );
	
	if( !iNum )
	{
		set_task( TASK_TIME, "PrepareVote", TASK_VOTE );
		
		return PLUGIN_HANDLED;
	}
	
	new player;
	
	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[ i ];
		
		menu_display( player, g_iModMenu, 0 );
		
		set_task( VOTE_TIME, "RemoveMenu", player );
	}
	
	g_iModVotes[ HNSDC ] = 0;
	g_iModVotes[ HNSDM ] = 0;
	
	remove_task( TASK_VOTE );
	
	set_task( VOTE_TIME, "EndVote" );
	
	return PLUGIN_HANDLED;
}

public EndVote( )
{
	ColorChat( 0, GREEN, "%s^x01 Votul a luat sfarsit. Rezultat:", TAG );
	ColorChat( 0, RED, "^x04%s^x03 %d^x01 - HNS Clasic |^x03 %d^x01 - HNS DeathMatch", TAG, g_iModVotes[ HNSDC ], g_iModVotes[ HNSDM ] );
	
	if( g_iModVotes[ HNSDC ] > g_iModVotes[ HNSDM ] )
	{
		SetMod( HNSDC, true, false );
	}
	
	else if( g_iModVotes[ HNSDC ] < g_iModVotes[ HNSDM ] )
	{
		SetMod( HNSDM, true, false );
	}
	
	ShowMessage( g_iModType );
	
	g_iVoted = 0;
	g_iVotesCount = 0;
	
	set_task( TASK_TIME, "PrepareVote", TASK_VOTE );
}

public RemoveMenu( id )
{
	show_menu( id, 0, "^n", 1 );
}

stock SetMod( Mod: iMod, bool: bRestart, bool: bMessage )
{
	switch( iMod )
	{
		case HNSDC:
		{
			g_iModType = HNSDC;
			
			server_cmd( "amx_pausecfg pause ^"HNSDM.amxx^"" );
			server_cmd( "amx_pausecfg enable ^"HNSDC.amxx^"" );
		}
		
		case HNSDM:
		{
			g_iModType = HNSDM;
			
			server_cmd( "amx_pausecfg pause ^"HNSDC.amxx^"" );
			server_cmd( "amx_pausecfg enable ^"HNSDM.amxx^"" );
		}
	}
	
	if( bRestart )
	{
		server_cmd( "sv_restart 1" );
	}
	
	if( bMessage )
	{
		ShowMessage( iMod );
	}
}

stock ShowMessage( Mod: iGameType )
{
	switch( iGameType )
	{
		case HNSDC:
		{
			ColorChat( 0, RED, "^x04%s^x01 Modul^x03 Hide'N'Seek Clasic^x01 va rula in urmatoarele^x04 30^x01 de minute.", TAG );
		}
		
		case HNSDM:
		{
			ColorChat( 0, RED, "^x04%s^x01 Modul^x03 Hide'N'Seek DeathMatch^x01 va rula in urmatoarele^x04 30^x01 de minute.", TAG );
		}
	}
}
