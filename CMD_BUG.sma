#include < amxmodx >
#include < ColorChat>

#pragma semicolon 1

static const

	PLUGIN[ ] =		"CMD BUG FIX",
	VERSION[ ] =		"0.0.1",
	AUTHOR[ ] =		"Rap^^";


new const g_szNonAccepted[ 2 ][ ] =
{
	"say %s",
	"say s0"
};

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	for( new i = 0; i < 2; i++ )
	{
		register_clcmd( g_szNonAccepted[ i ], "HandleCommand" );
	}
}

public HandleCommand( id )
{
	ColorChat( id, GREEN, "[Anti CMD BUG by %s]^x01 Nu este permisa aceasta comanda.", AUTHOR ); 
	
	return PLUGIN_HANDLED;
}