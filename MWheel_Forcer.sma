#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < nvault >

#pragma semicolon		1

#define MAX_PLAYERS		32
#define NVAULT_MAX_DAYS_SAVE	30
#define A_DAY_IN_SECONDS	86400	// 60 * 60 * 24

#define Set(%1,%2)		( %1 |= 1 << ( %2 & 31 ) )
#define Clear(%1,%2)		( %1 &= ~( 1 <<( %2 & 31 ) ) )
#define Get(%1,%2)		( %1 & 1 << ( %2 & 31 ) )


static const

	PLUGIN[ ] =		"MWheel_Forcer",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"ConnorMcLeod/Rap^^";
	//  Original idea: Exolent - Original plugin: Fatalis


enum MWheelSettings
{
	SETTING_NONE,
	SETTING_JUMPDUCK,
	SETTING_DUCKJUMP,
	SETTING_JUMPJUMP,
	SETTING_DUCKDUCK
};

new const g_szMWheelBinds[ MWheelSettings ][ ] =
{
	"",
	";bind mwheelup +jump;bind mwheeldown +duck",
	";bind mwheelup +duck;bind mwheeldown +jump",
	";bind mwheelup +jump;bind mwheeldown +jump",
	";bind mwheelup +duck;bind mwheeldown +duck"
};

new MWheelSettings: g_iSetting[ MAX_PLAYERS + 1 ];

new g_iNVault;

new g_iAccepted;
new g_iChooseMenuShown;
new g_iCommandRanOnce;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_clcmd( "say /mwheel", "cmdMWheel");
	
	RegisterHam( Ham_Player_Jump, "player", "FwdPlayerJump" );
	RegisterHam( Ham_Player_Duck, "player", "FwdPlayerDuck" );
	
	g_iNVault = nvault_open( "mwheel" );
	
	nvault_prune( g_iNVault, 0, get_systime( - ( A_DAY_IN_SECONDS * NVAULT_MAX_DAYS_SAVE ) ) );
}

public plugin_end( )
{
	nvault_close( g_iNVault );
}

public client_authorized( id )
{
	GetPlayerAuthid( id, true );

	if( ( g_iSetting[ id ] = MWheelSettings: nvault_get( g_iNVault, GetPlayerAuthid( id ) ) ) )
	{
		Set( g_iAccepted, id );
		Set( g_iChooseMenuShown, id );
	}
	
	else
	{
		g_iSetting[ id ] = SETTING_JUMPDUCK;
		
		Clear( g_iAccepted, id );
		Clear( g_iChooseMenuShown, id );
	}

	Clear( g_iCommandRanOnce, id );
}

public FwdPlayerJump( id )
{
	if( !( entity_get_int( id, EV_INT_oldbuttons ) & IN_JUMP )
	&& entity_get_int( id, EV_INT_flags ) & FL_ONGROUND )
	{
		if( Get( g_iAccepted, id ) )
		{
			client_cmd( id, g_szMWheelBinds[ g_iSetting[ id ] ] );
		}
		
		else
		{
			entity_set_int( id, EV_INT_oldbuttons, entity_get_int( id, EV_INT_oldbuttons ) | IN_JUMP );
			
			if( !Get( g_iChooseMenuShown, id ) )
			{
				Set( g_iChooseMenuShown, id );
				
				ShowChooseMenu( id );
			}
		}
	}
}

public FwdPlayerDuck( id )
{
	if( !( entity_get_int( id, EV_INT_oldbuttons ) & IN_DUCK )
	&& entity_get_int( id, EV_INT_flags ) & FL_ONGROUND )
	{
		if( Get( g_iAccepted, id ) )
		{
			client_cmd( id, g_szMWheelBinds[ g_iSetting[ id ] ] );
		}
		
		else
		{
			entity_set_int( id, EV_INT_oldbuttons, entity_get_int( id, EV_INT_oldbuttons ) | IN_DUCK );
			
			if( !Get( g_iChooseMenuShown, id ) )
			{
				Set( g_iChooseMenuShown, id );
				
				ShowChooseMenu( id );
			}
		}
	}
}

public cmdMWheel( id )
{
	if( !Get( g_iCommandRanOnce, id ) )
	{
		g_iSetting[ id ] = SETTING_NONE;
		
		Set( g_iCommandRanOnce, id );
		Clear( g_iAccepted, id );
		
		nvault_set( g_iNVault, GetPlayerAuthid( id ), "0" );
		
		ShowChooseMenu( id );
	}
	
	else
	{
		client_print( id, print_center, "Poti folosi aceasta comanda doar odata pe harta" );
	}
	
	return PLUGIN_HANDLED;
}

public ShowChooseMenu( id )
{
	new iMenu = menu_create( "\dMWheel \wMenu", "MenuHandler", 0 );
	
	static szMWheelUp[ 32 ];
	static szMWheelDown[ 32 ];
	
	formatex( szMWheelUp, charsmax( szMWheelUp ), "MWheelUp: \y%s",
	( g_iSetting[ id ] == SETTING_DUCKDUCK || g_iSetting[ id ] == SETTING_DUCKJUMP ) ? "DUCK" : "JUMP" );
	
	formatex( szMWheelDown, charsmax( szMWheelDown ), "MWheelDown: \y%s^n",
	( g_iSetting[ id ] == SETTING_DUCKDUCK || g_iSetting[ id ] == SETTING_JUMPDUCK ) ? "DUCK" : "JUMP" );
	
	menu_additem( iMenu, szMWheelUp );
	menu_additem( iMenu, szMWheelDown );
	menu_additem( iMenu, "\yGata" );
	
	menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );
	menu_display( id, iMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public MenuHandler( id, iMenu, iItem )
{
	switch( iItem )
	{
		case 0:
		{
			g_iSetting[ id ] = MWheelSettings: 5 - g_iSetting[ id ];
		}
		
		case 1:
		{
			g_iSetting[ id ] -= MWheelSettings: 2;
			
			if( g_iSetting[ id ] <= SETTING_NONE )
			{
				g_iSetting[ id ] += MWheelSettings: 4;
			}
		}
		
		case 2:
		{
			new szSetting[ 2 ];
			
			szSetting[ 0 ] = '0' + _: g_iSetting[ id ];

			nvault_set( g_iNVault, GetPlayerAuthid( id ), szSetting );

			Set( g_iAccepted, id );
			
			return PLUGIN_HANDLED;
		}
	}
	
	ShowChooseMenu( id );
	
	return PLUGIN_HANDLED;
}

GetPlayerAuthid( id, bool: bSet = false )
{
	static szAuthid[ MAX_PLAYERS ][ 32 ];
	
	if( bSet )
	{
		get_user_authid( id, szAuthid[ id - 1 ], charsmax( szAuthid[ ] ) );
	}
	
	return szAuthid[ id - 1 ];
}
