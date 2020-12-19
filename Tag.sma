#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < engine >
#include < ColorChat >
#include < fun >

#pragma semicolon 1

#define TASK_UNTOUCHBLE 12335
#define TASK_GIVEITEMS 123445


static const

	PLUGIN[ ]	= "Tag",
	VERSION[ ]	= "1.0",
	AUTHOR[ ]	= "Rap^^",
	TAG[ ]		= "[D/C]";


new const g_szPlayer[ ] = "player";

new bool: g_bShouldJump[ 33 ];

new g_iDonkey;
new g_iLastDonkey;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_event( "HLTV",	"EventNewRound", "a", "1=0", "2=0" );
	
	register_forward( FM_CmdStart,		"FwdCmdStart" );
	register_forward( FM_PlayerPreThink,	"FwdPlayerPreThink", true );
	register_forward( FM_PlayerPostThink,	"FwdPlayerPostThink", true );
	
	//register_touch( g_szPlayer, g_szPlayer, "FwdPlayerTouch" );
	
	RegisterHam( Ham_Killed,	g_szPlayer,	"FwdPlayerKilled" );
	RegisterHam( Ham_Spawn,		g_szPlayer,	"FwdPlayerSpawn" );
	RegisterHam( Ham_TakeDamage,	g_szPlayer,	"FwdPlayerTakeDamage" );
}

public client_putinserver( id )
{
	set_task( 5.0, "Respawn", id );
}

public client_disconnect( id )
{
	if( g_iDonkey == id )
	{
		SetNewDonkey( 0 );
	}
}

public EventNewRound( )
{
	set_task( 3.0, "TaskSetNewDonkey" );
	
	return PLUGIN_CONTINUE;
}

public FwdCmdStart( id, ucHandle, iSeed )
{
	if( !is_user_alive( id ) )
	{
		return FMRES_IGNORED;
	}
	
	if( !nade_in_hand( id ) )
	{
		return FMRES_IGNORED;
	}
	
	static iButton;
	
	iButton = get_uc( ucHandle, UC_Buttons );
	
	if( iButton & IN_ATTACK )
	{
		iButton &= ~IN_ATTACK;
		
		set_uc( ucHandle, UC_Buttons, iButton );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdPlayerPreThink( id )
{
	if( !is_user_alive( id ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	static iFlags;
	static iNewButton;
	static iOldButton;
	
	iFlags = pev( id, pev_flags );
	iNewButton = pev( id, pev_button );
	iOldButton = pev( id, pev_oldbuttons );
	
	if( ( iNewButton & IN_JUMP ) && !( iFlags & FL_ONGROUND ) && !( iOldButton & IN_JUMP ) )
	{
		g_bShouldJump[ id ] = true;
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public FwdPlayerPostThink( id )
{
	if( !is_user_alive( id ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( g_bShouldJump[ id ] )
	{
		new Float: flVelocity[ 3 ];
		
		pev( id, pev_velocity, flVelocity );
		
		flVelocity[ 2 ] = random_float( 275.0,295.0 );
		
		set_pev( id, pev_velocity, flVelocity );
		
		g_bShouldJump[ id ] = false;
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}
/*
public FwdPlayerTouch( iToucher, iTouched )
{
	if( g_iDonkey && g_iDonkey == iToucher )
	{
		if( iTouched != g_iLastDonkey )
		{
			if( is_user_alive( iTouched ) )
			{
				SetNewDonkey( iTouched );
				
				g_iLastDonkey = iToucher;
				
				set_task( 1.0, "ResetLastDonkey" );
			}
		}
	}
}
*/
public FwdPlayerKilled( id )
{
	g_bShouldJump[ id ] = false;
}

public FwdPlayerSpawn( id )
{
	if( is_user_alive( id ) && is_user_connected( id ) )
	{
		strip_user_weapons( id );
		
		set_task( 2.0, "TaskGiveItems", id + TASK_GIVEITEMS );
	}
}

public FwdPlayerTakeDamage( id, iInflictor, iAttacker, Float: flDamage, iDamageBits )
{
	if( !iAttacker || id == iAttacker || !is_user_connected( iAttacker ) || !is_user_connected( id ) )
	{
		SetHamParamFloat( 4, 0.0 );
		
		return HAM_HANDLED;
	}
	
	if( g_iDonkey == iAttacker )
	{
		if( id != g_iLastDonkey )
		{
			if( is_user_alive( id ) )
			{
				SetNewDonkey( id );
				
				g_iLastDonkey = iAttacker;
				
				set_task( 1.0, "ResetLastDonkey" );
			}
		}
	}
	
	SetHamParamFloat( 4, 0.0 );
	
	return HAM_HANDLED;
}

public Respawn( id )
{
	if( !is_user_alive( id ) )
	{
		ExecuteHamB( Ham_CS_RoundRespawn, id );
	}
}

public ResetLastDonkey( )
{
	g_iLastDonkey = 0;
	
	remove_task( TASK_UNTOUCHBLE );
}

public TaskSetNewDonkey( )
{
	SetNewDonkey( 0 );
}

public TaskGiveItems( id )
{
	id -= TASK_GIVEITEMS;
	
	give_item( id, "weapon_knife" );
	give_item( id, "weapon_smokegrenade" );
	
}

bool: nade_in_hand( id )
{
	if( is_user_connected( id ) && is_user_alive( id ) )
	{
		new iClip;
		new iAmmo;
		new iWeapon = get_user_weapon( id, iClip, iAmmo );
		
		if( iWeapon == CSW_SMOKEGRENADE || iWeapon == CSW_HEGRENADE || iWeapon == CSW_FLASHBANG )
		{
			return true;
		}
	}
	
	return false;
}

SetNewDonkey( iDonkey )
{
	if( get_playersnum( ) < 2 )
	{
		ColorChat( 0, GREEN, "%s^x01 Sunt prea putini jucatori online pentru a porni modul.", TAG );
	
		
		return PLUGIN_HANDLED;
	}
	
	if( !iDonkey )
	{
		g_iDonkey = PickRandomDonkey( );
	}
	
	new szDonkeyName[ 32 ];
	
	ResetLastDonkey( );
	
	g_iDonkey = iDonkey;
	
	get_user_name( g_iDonkey, szDonkeyName, charsmax( szDonkeyName ) );
	
	set_user_rendering( g_iDonkey, kRenderFxGlowShell, 50, 100, 50, kRenderNormal, 15 ); 
	
	set_hudmessage( 84, 84, 84, -1.0, 0.16, 0, 6.0, 5.0 );
	show_hudmessage( 0, "%s ESTE NOUL MAGAR", szDonkeyName );
	
	return PLUGIN_HANDLED;
}

PickRandomDonkey( )
{
	new iPlayers[ 32 ];
	new iNum;
	
	get_players( iPlayers, iNum, "ach" );
	
	return iPlayers[ random( iNum + 1 ) ];
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
