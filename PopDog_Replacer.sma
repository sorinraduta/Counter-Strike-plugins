#include < amxmodx >
#include < fakemeta >

#pragma semicolon 1


static const

	PLUGIN[ ] =	"PopDog_Replacer",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^";


new const g_szSprite[ ] =	"sprites/popdog.spr";
new const g_szBlank[ ] =		"";
new const NULL =			0;

new g_iAxe;
new g_iPopDog;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	register_clcmd( "say /popdog", "ClCmdPopDog" );
}

public plugin_precache( )
{
	precache_model( g_szSprite );
}

public ClCmdPopDog( id )
{
	MainMenu( id, NULL );
}

public MainMenu( id, iPage )
{
	static const szAxes[ ][ ] = { "X", "Y", "Z" };

	new szAxesMSG[ 51 ];

	new iMenu = menu_create( "PopDog Replacer Menu", "MainHandler", NULL );

	formatex( szAxesMSG, charsmax( szAxesMSG ), "Current Axe:\r %s", szAxes[ g_iAxe ] );

	menu_additem( iMenu, szAxesMSG, g_szBlank, NULL );
	menu_additem( iMenu, "Create sprite here^n", g_szBlank, NULL );

	menu_additem( iMenu, "Show origins & scale^n", g_szBlank, NULL );

	menu_additem( iMenu, "+ ON CURRENT AXE", g_szBlank, NULL );
	menu_additem( iMenu, "- ON CURRENT AXE^n", g_szBlank, NULL );

	menu_additem( iMenu, "++ ON CURRENT AXE", g_szBlank, NULL );
	menu_additem( iMenu, "-- ON CURRENT AXE^n", g_szBlank, NULL );

	menu_additem( iMenu, "+++ ON CURRENT AXE", g_szBlank, NULL );
	menu_additem( iMenu, "--- ON CURRENT AXE^n", g_szBlank, NULL );

	menu_additem( iMenu, "INCREASE SCALE 0.005", g_szBlank, NULL );
	menu_additem( iMenu, "DECREASE SCALE 0.005", g_szBlank, NULL );

	menu_additem( iMenu, "INCREASE SCALE 0.01", g_szBlank, NULL );
	menu_additem( iMenu, "DECREASE SCALE 0.01", g_szBlank, NULL );

	menu_setprop( iMenu, MPROP_EXITNAME, "Exit^n^n\rwww.disconnect.ro" );

	menu_display( id, iMenu, iPage );

	return PLUGIN_HANDLED;
}

public MainHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		return PLUGIN_HANDLED;
	}

	new iPage = floatround( float( iItem ) / 6.0001, floatround_floor );

	switch( iItem )
	{
		case 0:
		{
			if( g_iAxe == 2 )
			{
				g_iAxe = NULL;
			}

			else
			{
				g_iAxe++;
			}
		}

		case 1:
		{
			CreateSprite( id );
		}

		case 2:
		{
			new flScale;

			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_scale, flScale );
			pev( g_iPopDog, pev_origin, flOrigin );

			client_print( 0, print_chat, "{ %f, %f, %f }", flOrigin[ NULL ], flOrigin[ 1 ], flOrigin[ 2 ] );
			client_print( 0, print_chat, "%d", flScale );
		}

		case 3:
		{
			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_origin, flOrigin );

			flOrigin[ g_iAxe ] += 0.1;

			set_pev( g_iPopDog, pev_origin, flOrigin );
		}

		case 4:
		{
			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_origin, flOrigin );

			flOrigin[ g_iAxe ] -= 0.1;

			set_pev( g_iPopDog, pev_origin, flOrigin );
		}

		case 5:
		{
			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_origin, flOrigin );

			flOrigin[ g_iAxe ] += 1.0;

			set_pev( g_iPopDog, pev_origin, flOrigin );
		}

		case 6:
		{
			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_origin, flOrigin );

			flOrigin[ g_iAxe ] -= 1.0;

			set_pev( g_iPopDog, pev_origin, flOrigin );
		}

		case 7:
		{
			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_origin, flOrigin );

			flOrigin[ g_iAxe ] += 5.0;

			set_pev( g_iPopDog, pev_origin, flOrigin );
		}

		case 8:
		{
			new Float: flOrigin[ 3 ];

			pev( g_iPopDog, pev_origin, flOrigin );

			flOrigin[ g_iAxe ] -= 5.0;

			set_pev( g_iPopDog, pev_origin, flOrigin );
		}

		case 9:
		{
			new Float: flScale;

			pev( g_iPopDog, pev_scale, flScale );
			set_pev( g_iPopDog, pev_scale, flScale + 0.005 );
		}

		case 10:
		{
			new Float: flScale;

			pev( g_iPopDog, pev_scale, flScale );
			set_pev( g_iPopDog, pev_scale, flScale - 0.005 );
		}

		case 11:
		{
			new Float: flScale;

			pev( g_iPopDog, pev_scale, flScale );
			set_pev( g_iPopDog, pev_scale, flScale + 0.01 );
		}

		case 12:
		{
			new Float: flScale;

			pev( g_iPopDog, pev_scale, flScale );
			set_pev( g_iPopDog, pev_scale, flScale - 0.01 );
		}
	}

	MainMenu( id, iPage );

	return PLUGIN_HANDLED;
}

public CreateSprite( id )
{
	if( pev_valid( g_iPopDog ) )
	{
		engfunc( EngFunc_RemoveEntity, g_iPopDog );
	}

	new Float: flOrigin[ 3 ];

	pev( id, pev_origin, flOrigin );

	g_iPopDog = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) );

	set_pev( g_iPopDog, pev_classname, "PopDog_Disconnect" );
	set_pev( g_iPopDog, pev_origin, flOrigin );
	set_pev( g_iPopDog, pev_angles, { 0.0, 90.0, 0.0 } );
	engfunc( EngFunc_SetModel, g_iPopDog, g_szSprite );
	set_pev( g_iPopDog, pev_scale, 1.0 );
}
