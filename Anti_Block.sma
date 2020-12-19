#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < ColorChat >
#include < csteams >
#include < utilities >
#include < bits >

#pragma semicolon 1

#define TASK_MENU	10723
#define IsPlayer(%1)	(NULL < %1 <= g_iMaxPlayers)


static const
	
	PLUGIN[ ] =	"Anti_Block",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^";


new g_iMenuTime[ 33 ];
new g_iBlocker[ 33 ];

new g_iAlive;
new g_iMaxPlayers;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_forward( FM_Touch, "FwdTouch" );
	
	RegisterHam( Ham_Spawn, szPlayer, "FwdPlayerSpawn", NULL );
	RegisterHam( Ham_Killed, szPlayer, "FwdPlayerKilled", NULL );
	
	g_iMaxPlayers = get_maxplayers( );
}

public client_putinserver( id )
{
	Sub( g_iAlive, id );
}

public client_disconnect( id )
{
	Sub( g_iAlive, id );
}

public FwdTouch( iTouched, iToucher ) //trece pe ham
{	
	if( IsPlayer( iTouched ) && Get( g_iAlive, iTouched ) )
	{
		if( IsPlayer( iToucher ) && Get( g_iAlive, iToucher ) )
		{
			if( cs_get_user_team( iTouched ) != cs_get_user_team( iToucher ) )
			{
				if( pev( iTouched, pev_movetype ) == MOVETYPE_FLY && pev( iToucher, pev_movetype ) != MOVETYPE_FLY
				&& ( pev( iToucher, pev_flags ) & ~FL_ONGROUND ) /*&& are x velo[2] */ )
				{
					PossibleBlock( iTouched, iToucher ) // blocker blocked
					
					return PLUGIN_CONTINUE;
				}
				
				if( cs_get_user_team( iToucher ) == CS_TEAM_T )
				{
					iBlocked = iToucher;
					iBlocker = iTouched;
				}
				
				else
				{
					iBlocked = iTouched;
					iBlocker = iToucher;
				}
				
				if( !g_iBlocker[ iBlocked ] )
				{
					if( pev( iBlocked, pev_flags ) & ~FL_ONGROUND /*&& x velo pe 0 1*/ )
					{
						PossibleBlock( iBlocker, iBlocked );
					}
				}
			}
		}
	}
}

public FwdPlayerSpawn( id )
{
	Set( g_iAlive, id );
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
}



public BlockMenu( id )
{
	g_iMenuTime[ id ] = 11;
	
	TaskBlockMenu( id + TASK_MENU );
}

public TaskBlockMenu( id )
{
	id -= TASK_MENU;
	
	if( --g_iMenuTime[ id ] )
	{
		new szMenu[ 128 ];
		new szBlockerName[ 32 ];
		
		get_user_name( g_iBlocker[ id ], szBlockerName, charsmax( szBlockerName ) );
		
		formatex( szMenu, charsmax( szMenu ), "Doresti ca\r %s\w sa primesca\d slay\w pentru ca ti-a facut block ?^n^n\wMai ai\d %d\w secunde la dispozitie",
		szBlockerName, g_iMenuTime[ id ], g_iMenuTime[ id ] == 1 ? "":"i");
		
		new iMenu = menu_create( szMenu, "BlockHandler", NULL );
		
		menu_additem( iMenu, "Da", "", NULL );
		menu_additem( iMenu, "Nu", "", NULL );
		
		menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );
		menu_display( id, iMenu );
		
		set_task( 1.0, "TaskBlockMenu", id + TASK_MENU );
	}
	
	else
	{
		RemoveMenu( id );
	}
	
	return PLUGIN_HANDLED;
}

public BlockHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );
		
		return PLUGIN_HANDLED;
	}
	
	if( task_exists( id + TASK_MENU ) )
	{
		remove_task( id + TASK_MENU );
	}
	
	new _access, szData[ 64 ], szName[ 64 ], iCallback;
	
	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );
	
	switch( iItem )
	{
		case 0:
		{
			
		}
		
		case 1:
		{
			
		}
	}
	
	return PLUGIN_HANDLED;
}

public RemoveMenu( id )
{
	show_menu( id, NULL, "^n", 1 );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
