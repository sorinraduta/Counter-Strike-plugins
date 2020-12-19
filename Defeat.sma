#include < amxmodx >
#include < fakemeta >
#include < hamsandwich>
#include < fun >
#include < dhudmessage >

#pragma semicolon		1

#define NONE			-1
#define ZERO			0
#define MAX_PLUGINS		2


static const

	PLUGIN[ ] =		"Defeat",
	VERSION[ ] =		"0.0.1b",
	AUTHOR[ ] =		"Rap^^";


new const g_szPlugins[ MAX_PLUGINS ][ ] =
{
	"DM_Medic.amxx",
	"DM_Ravenger.amxx"
};

enum ( += 33 )
{
	TASK_SPEED = 1337,
	TASK_HUD
};

enum _: ClassesData
{
	ClassName[ 32 ] = 0,
	ClassHP,
	ClassAP,
	ClassSpeed,
	ClassGravity,
	ClassVisibility
};

enum _: UsersAttrib
{
	Class = 0
	//Credits..
	//Etc..
};

new Array: g_aClassesData;

new g_iUser[ 33 ][ UsersAttrib ];

new g_cbClasses;

new g_iForwardUpdateData;

new g_iClassesNum;

new g_MsgID_HideWeapon;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_clcmd( "chooseteam", "ClassMenu" );
	
	//register_event( "CurWeapon","EvCurWeapon","be","1=1" );
	
	RegisterHam( Ham_Spawn, "player", "FwdPlayerSpawn", 1 );
	RegisterHam( Ham_CS_Player_ResetMaxSpeed, "player", "FwdPlayerResetMaxSpeed", 1 );
	
	g_aClassesData = ArrayCreate( ClassesData );
	
	g_cbClasses = menu_makecallback("ClassCallback");
	
	g_iForwardUpdateData = CreateMultiForward( "FwdUpdateData", ET_IGNORE, FP_CELL, FP_ARRAY );
	
	g_MsgID_HideWeapon = get_user_msgid("HideWeapon");
}

public plugin_natives( )
{
	register_native( "register_class", "native_register_class" );
}

public client_putinserver( id )
{
	arrayset( g_iUser[ id ], NONE, UsersAttrib );
	
	set_task( 0.1, "ShowPlayerHUD", id + TASK_HUD, _, _, "b", _ );
}

public client_disconnect( id )
{
	remove_task( id + TASK_HUD );
}

public ClassMenu( id )
{
	new iMenu = menu_create("\dClasses Menu \yby Rap^^", "ClassHandler", ZERO);
	new szInfo[ 4 ];
	new eData[ ClassesData ];
	
	for( new i = 0; i < g_iClassesNum; i++ )
	{
		num_to_str( i + 1, szInfo, charsmax( szInfo ) );
		
		ArrayGetArray( g_aClassesData, i, eData );
		
		menu_additem( iMenu, eData[ ClassName ], szInfo, _, g_cbClasses );
	}
	
	menu_display( id, iMenu, ZERO );
	
	return PLUGIN_HANDLED;
}

public ClassCallback( id, iMenu, iItem )
{
	static _access, szInfo[ 8 ], iCallback;
	
	menu_item_getinfo( iMenu, iItem, _access, szInfo, charsmax( szInfo ), _, _, iCallback );
	
	new iKey = str_to_num( szInfo );
	
	if( iKey - 1 == g_iUser[ id ][ Class ] )
	{
		return ITEM_DISABLED;
	}
	
	return ITEM_ENABLED;
}

public ClassHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );
		
		return PLUGIN_HANDLED;
	}
	
	new szInfo[ 8 ], szName[ 64 ];
	new _access, iCallback;
	
	menu_item_getinfo( iMenu, iItem, _access, szInfo, charsmax( szInfo ), szName, charsmax( szName ), iCallback );
	
	new iKey = str_to_num( szInfo );
	
	g_iUser[ id ][ Class ] = iKey - 1;
	
	UpdateData( id );
	
	return PLUGIN_HANDLED;
}

public FwdPlayerSpawn( id )
{
	if( g_iUser[ id ][ Class ] != NONE )
	{
		new eClassData[ ClassesData ];
		
		ArrayGetArray( g_aClassesData, g_iUser[ id ][ Class ], eClassData );
		
		set_pev( id, pev_health, float( eClassData[ ClassHP ] ) );
		set_pev( id, pev_armorvalue, float( eClassData[ ClassAP ] ) );
		set_pev( id, pev_gravity, eClassData[ ClassGravity ] / 800.0 );
		set_user_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, eClassData[ ClassVisibility ] );
	}
	
	message_begin( MSG_ONE_UNRELIABLE, g_MsgID_HideWeapon, { 0,0,0 }, id );
	write_byte( ( 1 << 0 ) | ( 1 << 1 ) | ( 1 << 3 ) | ( 1 << 4 ) | ( 1 << 5 ) );
	message_end( );
}

public FwdPlayerResetMaxSpeed( id )
{
	if( g_iUser[ id ][ Class ] != NONE )
	{
		new eClassData[ ClassesData ];
		
		ArrayGetArray( g_aClassesData, g_iUser[ id ][ Class ], eClassData );
		
		set_pev( id, pev_maxspeed, float( eClassData[ ClassSpeed ] ) );
	}
}

UpdateData( id )
{
	new iReturn;
	
	new iArray = PrepareArray( g_iUser[ id ], UsersAttrib, 0 );
	
	if( !ExecuteForward( g_iForwardUpdateData, iReturn, id, iArray ) )
	{
		log_amx( "Error: Execute forward ( FwdUpdateData )" );
	}
}

public ShowPlayerHUD( id )
{
	id -= TASK_HUD;
	
	if( is_user_alive( id ) )
	{
		new iHP = get_user_health( id );
		new iArmor = get_user_armor( id );
		
		set_dhudmessage( 0, 100, 250, 0.02, 0.92, 0, 0.0, 0.2, 0.0, 0.0, false );
		show_dhudmessage( id, "Health: %d  Armor %d", iHP, iArmor );
	}
}

public native_register_class( iPlugin, iParams )
{
	if( is_valid_plugin( iPlugin ) )
	{
		new eData[ ClassesData ];
		new iData[ ClassesData - 1 ];
		
		get_string( 1, eData[ ClassName ], charsmax( eData[ ClassName ] ) );
		
		get_array( 2, iData, sizeof iData );
		
		eData[ ClassHP ] = iData[ 0 ];
		eData[ ClassAP ] = iData[ 1 ];
		eData[ ClassSpeed ] = iData[ 2 ];
		eData[ ClassGravity ] = iData[ 3 ];
		eData[ ClassVisibility ] = iData[ 4 ];
		
		ArrayPushArray( g_aClassesData, eData );
		
		return ++g_iClassesNum;
	}
	
	return NONE;
}

stock bool: is_valid_plugin( iPlugin )
{
	new szPlugin[ 64 ];
	new szPluginName[ 32 ];
	new szPluginVersion[ 32 ];
	new szPluginAuthor[ 32 ];
	
	get_plugin( iPlugin, szPlugin, charsmax( szPlugin),
	szPluginName, charsmax( szPluginName ),
	szPluginVersion, charsmax( szPluginVersion ),
	szPluginAuthor, charsmax( szPluginAuthor ) );
	
	for( new i = 0; i < MAX_PLUGINS; i++ )
	{
		if( equal( szPlugin, g_szPlugins[ i ] ) )
		{
			if( contain( szPluginName, "DM" ) != -1
			 && equal( szPluginVersion, VERSION )
			 && equal( szPluginAuthor, AUTHOR ) )
			{
				return true;
			}
		}
	}
	
	return false;
}
