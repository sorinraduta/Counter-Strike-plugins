#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < engine >

#pragma semicolon 1


static const

	PLUGIN[ ] =	"Restrictions",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^",
	
	TAG[ ] =	"[D/C]";


new const NULL =		0;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	new const szClCmdHandled[ ] = "ClCmdHandled";
	
	register_clcmd( "radio1",	szClCmdHandled );
	register_clcmd( "radio2",	szClCmdHandled );
	register_clcmd( "radio3",	szClCmdHandled );
	register_clcmd( "chooseteam",	szClCmdHandled );
	
	register_impulse( 201,		szClCmdHandled );
	
	register_forward( FM_Voice_SetClientListening, "FwdVoiceClientListening" ); 
}

public client_command( id )
{
	if( !is_user_connected( id ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( cs_get_user_team( id ) == CS_TEAM_UNASSIGNED )
	{
		return PLUGIN_CONTINUE;
	}
	
	static const szJoinCommand[ 10 ] = "jointeam";
	
	static szCommand[ 10 ];
	
	read_argv( NULL, szCommand, charsmax( szCommand ) );
	
	if( equal( szCommand, szJoinCommand ) )
	{
		console_print( id, "%s Comanda jointeam este blocata.", TAG );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public ClCmdHandled( id )
{
	client_print( id, print_center, "Aceasta comanda este blocata" );
	
	return PLUGIN_HANDLED_MAIN;
}

public FwdVoiceClientListening( iReceiver, iSender, bool: bListen )
{
	bListen = false;
	
	return FMRES_SUPERCEDE;
	
	/*if( !is_user_connected( iReceiver ) || !is_user_connected( iSender ) || iReceiver == iSender )
	{
		return FMRES_IGNORED;
	}
	
	bListen = false;
	
	engfunc( EngFunc_SetClientListening, iReceiver, iSender, bListen );
    
	return FMRES_SUPERCEDE;*/
}  
