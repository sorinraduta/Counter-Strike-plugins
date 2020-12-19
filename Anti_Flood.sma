#include < amxmodx >

#pragma semicolon 1


static const

	PLUGIN[ ]	= "Anti_Flood",
	AUTHOR[ ]	= "AMXX Dev Team"; // Rap^ update


new Float: g_flFlooding[ 33 ] = { 0.0, ... };

new g_iFloodNum[ 33 ] = { 0, ... };

new amx_flood_time;


public plugin_init( )
{
	register_plugin( PLUGIN, AMXX_VERSION_STR, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	register_clcmd( "say", "CheckFlood" );
	register_clcmd( "say_team", "CheckFlood" );

	amx_flood_time = register_cvar( "amx_flood_time", "0.75" );
}

public CheckFlood( id )
{
	new Float: flFloodTime = get_pcvar_float( amx_flood_time );

	if( flFloodTime )
	{
		new Float: flGameTime = get_gametime( );

		if( g_flFlooding[ id ] > flGameTime )
		{
			if( g_iFloodNum[ id ] >= 3 )
			{
				client_print( id, print_center, "Te rugam sa te opresti din a face flood" );
				client_print( id, print_notify, "[D/C] Te rugam sa te opresti din a face flood." );

				g_flFlooding[ id ] = flGameTime + flFloodTime + 2.0;

				return PLUGIN_HANDLED;
			}

			g_iFloodNum[ id ]++;
		}

		else if( g_iFloodNum[ id ] )
		{
			g_iFloodNum[ id ]--;
		}

		g_flFlooding[ id ] = flGameTime + flFloodTime;
	}

	return PLUGIN_CONTINUE;
}
