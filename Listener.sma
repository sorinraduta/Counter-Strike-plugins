#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < engine >
#include < ColorChat >

#pragma semicolon 1


static const

	PLUGIN[ ] =		"PLUGIN",
	VERSION[ ] =		"0.0.1",
	AUTHOR[ ] =		"Rap^^",
	TAG[ ] =		"[Listener]";


new g_iEmitter[ 33 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_concmd( "amx_listen", "cmdListen" );
	register_concmd( "say /stop", "cmdStopListen" );
	
	register_forward( FM_Voice_SetClientListening, "FwdVoiceSetClientListening" );
}

public client_connect( id )
{
	g_iEmitter[ id ] = 0;
}

public cmdListen( id )
{
	if( get_user_flags( id ) & read_flags( "abcdefghijklmnopqrstu" ) )
	{
		client_print( id, print_console, "%s Nu ai acces la aceasta comanda, dar te las sa o folosesti", TAG );
		ColorChat( id, GREEN, "%s^x1 Nu ai acces la aceasta comanda, dar te las sa o folosesti", TAG );
	}
	
	new szArg[ 32 ];
	
	read_argv( 1, szArg, sizeof szArg - 1 );
	
	new player = cmd_target( id, szArg, 3 );
	
	if( !player )
	{
		client_print( id, print_console, "%s This player does not exist.", TAG );
		
		return PLUGIN_HANDLED;
	}
	
	g_iEmitter[ id ] = player;
	
	set_speak( player, SPEAK_ALL );
	
	client_cmd( player, "+voicerecord" );
	
	return PLUGIN_HANDLED;
}

public cmdStopListen( id )
{
	new player = g_iEmitter[ id ];
	
	if( player )
	{
		g_iEmitter[ id ] = 0;
		
		set_speak( player, SPEAK_NORMAL );
		
		client_cmd( player, "-voicerecord" );
	}
	
	return PLUGIN_HANDLED;
}

public FwdVoiceSetClientListening( iReceiver, iSender, bool: bListen )
{
	if( !is_user_connected( iSender ) || !is_user_connected( iReceiver ) )
	{
		return FMRES_IGNORED;
	}
	
	if( g_iEmitter[ iReceiver ] != iSender )
	{
		bListen = false;
	
		return FMRES_SUPERCEDE;
	}
	
	bListen = true;
	
	return FMRES_SUPERCEDE;
}
