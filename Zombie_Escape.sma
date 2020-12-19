#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < dhudmessage >
#include < round_terminator >
#include < ColorChat >

#pragma semicolon	1

#define NULL 		0
#define MAX_SOUNDCOUNT	10

#define TASK_INFO	101010
#define TASK_ROUNDTIME	202020

#define DMG_GRENADE	( 1 << 24 )

#define Add(%1,%2)	( %1 |= 1 << (   %2 & 31 ) )
#define Sub(%1,%2)	( %1 &= ~( 1 <<( %2 & 31 ) ) )
#define Get(%1,%2)	( %1 & 1 << ( %2 & 31 ) )


static const

	PLUGIN[ ] =	"Zombie_Escape",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^",

	TAG[ ] =	"[D/C]",
	SERVER[ ] =	"ZE.DISCONNECT.RO",
	WEBSITE[ ] =	"WWW.DISCONNECT.RO";


new g_szPrimaryWeapons[ ][ ][ ] =
{
	{ "M4A1",	"weapon_m4a1" },
	{ "AK47",	"weapon_ak47" },
	{ "AUG",	"weapon_aug" },
	{ "SG552",	"weapon_sg552" },
	{ "Galil",	"weapon_galil" },
	{ "Famas",	"weapon_famas" },
	{ "MP5 Navy",	"weapon_mp5navy" },
	{ "Awp",	"weapon_awp" },
	{ "Scout",	"weapon_scout" },
	{ "XM1014",	"weapon_xm1014" },
	{ "M3",		"weapon_m3" },
	{ "TMP",	"weapon_tmp" },
	{ "Mac10",	"weapon_mac10" },
	{ "Ump45",	"weapon_ump45" },
	{ "P90",	"weapon_p90" },
	//{ "M249",	"weapon_m249" },
	{ "SG550",	"weapon_sg550" },
	{ "G3SG1",	"weapon_g3sg1" }
};

new g_szSecondaryWeapons[ ][ ][ ] =
{
	{ "USP",	"weapon_usp" },
	{ "Deagle",	"weapon_deagle" },
	{ "Elite",	"weapon_elite" }
};

new g_szGrenades[ ][ ] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

new g_szObjectiveClassNames[ ][ ] =
{
	"func_bomb_target",
	"info_bomb_target",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"item_longjump"
};

new const g_szNightVisionSound[ 2 ][ ] =
{
	"items/nvg_off.wav",
	"items/nvg_on.wav"
};

enum
{
	OFF = NULL,
	ON,
	HUMANS_FREEZE,
	ZOMBIES_FREEZE
};

enum
{
	BUYNAME = NULL,
	NAME
};

enum Zombie
{
	NOT_ZOMBIE,
	MAIN_ZOMBIE,
	SECOND_ZOMBIE
};

new const g_szBlank[ ]		= "";
new const g_szConfigFile[ ]	= "zombie_escape.ini";

new Ham: Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

new CsTeams: ZE_TEAM_ZOMBIE = CS_TEAM_T;
new CsTeams: ZE_TEAM_HUMAN = CS_TEAM_CT;
/*
new Array: g_aHumanModels;
new Array: g_aMainZombieModels;
new Array: g_aSecondZombieModels;
new Array: g_aClawsMainModels;
new Array: g_aClawsSecondModels;
new Array: g_aReadySounds;
new Array: g_aAmbienceSounds;
new Array: g_aZombieAppearSounds;
new Array: g_aInfectSounds;
new Array: g_aPainSounds;
new Array: g_aSuccessSounds;
new Array: g_aFailSounds;
new Array: g_aHitSounds;
new Array: g_aMissSounds;
new Array: g_aWallSounds;
*/
new Float: g_flHumanHealth;
new Float: g_flHumanArmor;
new Float: g_flHumanGravity;
new Float: g_flHumanSpeed;
new Float: g_flZombieHealth;
new Float: g_flZombieArmor;
new Float: g_flZombieGravity;
new Float: g_flZombieSpeed;
new Float: g_flZombieKnockback;

new Zombie: g_iZombieType[ 33 ];

new g_szCountdown[ 64 ];

new g_iNightVision[ 33 ];

new g_szFogDensity[ 32 ];
new g_szFogColor[ 32 ];

new g_szLight[ 2 ];

new g_iStage;
new g_iMinPlayers;
new g_iBPAmmo;
new g_iZombieFreeze;
new g_iHumanFreeze;
new g_iRoundTime;
new g_iFogEnable;

// Vars used like booleans
new g_iAlive;
new g_iConnected;
new g_iPrimaryChoosed;
new g_iSecondaryChoosed;

new g_iMsgHideWeapon;
new g_iMsgScreenFade;

new g_iMaxPlayers;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	new const szClCmdHandled[ ] = "ClCmdHandled";
	new const szClCmdWeapons[ ] = "ClCmdWeapons";

	register_clcmd( "jointeam",	szClCmdHandled );
	register_clcmd( "joinclass",	szClCmdHandled );
	register_clcmd( "nightvision",	"ClCmdNightVision" );
	register_clcmd( "say /guns",	szClCmdWeapons );
	register_clcmd( "say /weapons",	szClCmdWeapons );

	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );

	//register_forward( FM_EmitSound, "FwdEmitSound" );

	new const szPlayer[ ] = "player";

	RegisterHam( Ham_Spawn, szPlayer, "FwdPlayerSpawn", false );
	RegisterHam( Ham_Killed, szPlayer, "FwdPlayerKilled", false );
	RegisterHam( Ham_TakeDamage, szPlayer, "FwdTakeDamage" );
	RegisterHam( Ham_Player_ResetMaxSpeed, szPlayer, "FwdPlayerResetMaxSpeed", false );
	RegisterHam( Ham_Touch, "weaponbox", "FwdTouchWeapon", false );
	RegisterHam( Ham_Touch, "armoury_entity", "FwdTouchWeapon", false );
	RegisterHam( Ham_Touch, "weapon_shield", "FwdTouchWeapon", false);

	g_iMsgHideWeapon = get_user_msgid( "HideWeapon" );
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );

	g_iMaxPlayers = get_maxplayers( );

	register_message( get_user_msgid( "ShowMenu" ),	"MessageShowMenu" );
	register_message( get_user_msgid( "VGUIMenu" ),	"MessageVGUIMenu" );
	register_message( get_user_msgid( "TextMsg" ),	"MessageTextMsg" );
}

public plugin_precache( )
{
	new szSoundCount[ 64 ];

	/*g_aHumanModels		= ArrayCreate( 64, 1 );
	g_aMainZombieModels	= ArrayCreate( 64, 1 );
	g_aSecondZombieModels	= ArrayCreate( 64, 1 );
	g_aClawsMainModels	= ArrayCreate( 64, 1 );
	g_aClawsSecondModels	= ArrayCreate( 64, 1 );
	g_aReadySounds		= ArrayCreate( 64, 1 );
	g_aAmbienceSounds	= ArrayCreate( 64, 1 );
	g_aZombieAppearSounds	= ArrayCreate( 64, 1 );
	g_aInfectSounds		= ArrayCreate( 64, 1 );
	g_aPainSounds		= ArrayCreate( 64, 1 );
	g_aSuccessSounds	= ArrayCreate( 64, 1 );
	g_aFailSounds		= ArrayCreate( 64, 1 );
	g_aHitSounds		= ArrayCreate( 64, 1 );
	g_aMissSounds		= ArrayCreate( 64, 1 );
	g_aWallSounds		= ArrayCreate( 64, 1 );
	*/
	LoadConfigFile( );
	/*
	PrecacheModelsFromArray( g_aHumanModels );
	PrecacheModelsFromArray( g_aMainZombieModels );
	PrecacheModelsFromArray( g_aSecondZombieModels );
	PrecacheModelsFromArray( g_aClawsMainModels );
	PrecacheModelsFromArray( g_aClawsSecondModels );

	PrecacheSoundsFromArray( g_aReadySounds );
	PrecacheSoundsFromArray( g_aAmbienceSounds );
	PrecacheSoundsFromArray( g_aZombieAppearSounds );
	PrecacheSoundsFromArray( g_aInfectSounds );
	PrecacheSoundsFromArray( g_aPainSounds );
	PrecacheSoundsFromArray( g_aSuccessSounds );
	PrecacheSoundsFromArray( g_aFailSounds );
	PrecacheSoundsFromArray( g_aHitSounds );
	PrecacheSoundsFromArray( g_aMissSounds );
	PrecacheSoundsFromArray( g_aWallSounds );

	for( new i = 1; i <= MAX_SOUNDCOUNT; i++ )
	{
		format( szSoundCount, charsmax( szSoundCount ), szSoundCount, i );

		engfunc( EngFunc_PrecacheSound, szSoundCount );
	}*/

	if( g_iFogEnable )
	{
		new iFog = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "env_fog" ) );

		if( pev_valid( iFog ) )
		{
			SetKeyValue( iFog, "density", g_szFogDensity );
			SetKeyValue( iFog, "rendercolor", g_szFogColor );

			/*
			DispatchKeyValue( iEntity, "density", g_szFogDensity );
			DispatchKeyValue( iEntity, "rendercolor", g_szFogColor );
			DispatchSpawn( iEntity );
			*/
		}
	}

	register_forward( FM_Spawn, "FwdSpawn" );

	set_cvar_float( "mp_freezetime", float( NULL ) );
	set_cvar_float( "mp_roundtime", float( g_iRoundTime ) );
}

public client_putinserver( id )
{
	g_iNightVision[ id ] = OFF;

	Add( g_iConnected, id );

	set_task( 0.1, "ShowPlayerInfo", id + TASK_INFO, _, _, "b", _ );
}

public client_disconnect( id )
{
	Sub( g_iAlive, id );
	Sub( g_iConnected, id );

	CheckWinConditions( );

	remove_task( id + TASK_INFO );
}

public client_command( id )
{
	if( cs_get_user_team( id ) == CS_TEAM_UNASSIGNED )
	{
		return PLUGIN_CONTINUE;
	}

	static szCommand[ 10 ];
	static const szJoinCommand[ 10 ] = "jointeam";

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
	client_print( id, print_center, "This command is blocked." );

	return PLUGIN_HANDLED_MAIN;
}

public ClCmdNightVision( id )
{
	if( !Get( g_iAlive, id ) || !g_iZombieType[ id ] )
	{
		return PLUGIN_HANDLED;
	}

	if( g_iNightVision[ id ] )
	{
		SwitchNightVision( id, OFF );
	}

	else
	{
		SwitchNightVision( id, ON );
	}

	return PLUGIN_CONTINUE;
}

public ClCmdWeapons( id )
{
	if( cs_get_user_team( id ) != ZE_TEAM_ZOMBIE )
	{
		ColorChat( id, BLUE, "^x04%s^x01 Just^x03 humans^x01 can use this command.", TAG );

		return PLUGIN_HANDLED;
	}

	PrimaryWeapMenu( id );

	return PLUGIN_HANDLED;
}

public EventNewRound( )
{
	for( new id = NULL; id < g_iMaxPlayers; id++ )
	{
		if( !Get( g_iConnected, id ) )
		{
			continue;
		}

		cs_set_user_team( id, ZE_TEAM_HUMAN );
	}

	if( AlivePlayers( ZE_TEAM_HUMAN ) < g_iMinPlayers )
	{
		g_iStage = OFF;

		ColorChat( NULL, GREEN, "%s^x01 Not enough players to start the game.", TAG );

		return PLUGIN_HANDLED;
	}

	new szReadySound[ 128 ];

	g_iStage = HUMANS_FREEZE;

	CountDown( g_iHumanFreeze );

	//GetStringFormArray( g_aReadySounds, szReadySound, charsmax( szReadySound ), -1 );

	//PlaySound( NULL, szReadySound );

	set_task( float( g_iRoundTime + g_iHumanFreeze + g_iZombieFreeze ), "ZombieWin", TASK_ROUNDTIME );

	ColorChat( NULL, GREEN, "%s^x01 The game has started. Good luck." );

	return PLUGIN_CONTINUE;
}
/*
public FwdEmitSound( id, iChannel, const szSample[ ], Float: iVolume, Float: iAttn, iFlags, iPitch )
{
	if( equal( szSample, "hostage", strlen( "hostage" ) ) )
	{
		return FMRES_SUPERCEDE;
	}

	if( !Get( g_iConnected, id ) || !g_iZombieType[ id ] )
	{
		return FMRES_IGNORED;
	}

	new szSound[ 128 ];

	if( szSample[ 7 ] == 'b' && szSample[ 8 ] == 'h' && szSample[ 9 ] == 'i' && szSample[ 10 ] == 't'
	|| szSample[ 7 ] == 'h' && szSample[ 8 ] == 'e' && szSample[ 9 ] == 'a' && szSample[ 10 ] == 'd' )
	{
		GetStringFormArray( g_aPainSounds, szSound, charsmax( szSound ), -1 );

		emit_sound( id, iChannel, szSound, iVolume, iAttn, iFlags, iPitch );

		return FMRES_SUPERCEDE;
	}

	new iAttackType;

	if( equal( szSample, "weapons/knife_hitwall1.wav" ) )
	{
		iAttackType = 1;
	}

	else if( equal( szSample, "weapons/knife_hit1.wav" )
	|| equal( szSample, "weapons/knife_hit3.wav" )
	|| equal( szSample, "weapons/knife_hit2.wav" )
	|| equal( szSample, "weapons/knife_hit4.wav" )
	|| equal( szSample, "weapons/knife_stab.wav" ) )
	{
		iAttackType = 2;
	}

	else if( equal(szSample, "weapons/knife_slash1.wav" )
	|| equal( szSample, "weapons/knife_slash2.wav" ) )
	{
		iAttackType = 3;
	}

	if( iAttackType )
	{
		switch( iAttackType )
		{
			case 1:
			{
				GetStringFormArray( g_aWallSounds, szSound, charsmax( szSound ), -1 );
			}

			case 2:
			{
				GetStringFormArray( g_aHitSounds, szSound, charsmax( szSound ), -1 );
			}

			case 3:
			{
				GetStringFormArray( g_aMissSounds, szSound, charsmax( szSound ), -1 );
			}
		}

		emit_sound( id, iChannel, szSound, iVolume, iAttn, iFlags, iPitch );

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}*/

public FwdPlayerSpawn( id )
{
	if( !Get( g_iConnected, id ) )
	{
		return PLUGIN_CONTINUE;
	}

	Add( g_iAlive, id );
	Sub( g_iPrimaryChoosed, id );
	Sub( g_iSecondaryChoosed, id );

	switch( g_iStage )
	{
		case ON:
		{
			SetUserZombie( id, SECOND_ZOMBIE );
		}

		default:
		{
			SetUserHuman( id );
		}
	}

	PrimaryWeapMenu( id );

	message_begin( MSG_ONE_UNRELIABLE, g_iMsgHideWeapon, { NULL, NULL, NULL }, id );
	write_byte( ( 1 << 0 ) | ( 1 << 1 ) | ( 1 << 3 ) | ( 1 << 4 ) | ( 1 << 5 ) );
	message_end( );

	return PLUGIN_CONTINUE;
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );

	CheckWinConditions( );
}

public FwdTakeDamage( iVictim, iInflictor, iAttacker, Float: flDamage, iDamageBits )
{
	if( !iAttacker || iVictim == iAttacker || !Get( g_iConnected, iAttacker ) || !Get( g_iConnected, iAttacker )
	|| cs_get_user_team( iVictim ) == cs_get_user_team( iAttacker ) || iDamageBits & DMG_GRENADE )
	{
		return HAM_IGNORED;
	}

	if( g_iZombieType[ iAttacker ] )
	{
		AddFrags( iAttacker, 1 );
		AddDeaths( iVictim, 1 );

		SetUserZombie( iVictim, MAIN_ZOMBIE );
	}

	else if( g_iZombieType[ iAttacker ] && !g_iZombieType[ iVictim ] )
	{
		new Float: flOrigin[ 3 ];

		pev( iAttacker, pev_origin, flOrigin );

		set_pdata_float( iVictim, 108, 1.0, 50 );  //  m_flPainShock

		Knockback( iVictim, flOrigin );
	}

	return HAM_HANDLED;
}

public FwdPlayerResetMaxSpeed( id )
{
	/*if( g_iZombieType[ id ] )
	{
		return HAM_IGNORED;
	}*/

	return HAM_SUPERCEDE;
}

public FwdTouchWeapon( iWeapon, id )
{
	if( !Get( g_iConnected, id ) )
	{
		return HAM_IGNORED;
	}

	if( g_iZombieType[ id ] )
	{
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public FwdPreThink( id )
{
	if( !Get( g_iAlive, id ) )
	{
		return PLUGIN_CONTINUE;
	}

	new CsTeams: iTeam = cs_get_user_team( id );

	if( iTeam == ZE_TEAM_HUMAN )
	{
		if( g_iStage == HUMANS_FREEZE )
		{
			ResetSpeed( id );
		}
	}

	else if( iTeam == ZE_TEAM_ZOMBIE )
	{
		if( g_iStage == ZOMBIES_FREEZE )
		{
			ResetSpeed( id );
		}
	}

	return PLUGIN_CONTINUE;
}

public FwdSpawn( iEntity )
{
	if( !pev_valid( iEntity ) )
	{
		return FMRES_IGNORED;
	}

	new szClassName[ 32 ];

	new iObjectiveCNNum = sizeof g_szObjectiveClassNames;

	pev( iEntity, pev_classname, szClassName, charsmax( szClassName ) );

	for( new i = NULL; i < iObjectiveCNNum; i++ )
	{
		if( equal( szClassName, g_szObjectiveClassNames[ i ] ) )
		{
			engfunc( EngFunc_RemoveEntity, iEntity );

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public MessageShowMenu( iMsgid, iDest, id )
{
	if( !ShouldAutojoin( id ) )
	{
		return PLUGIN_CONTINUE;
	}

	new const szTeamSelect[ ] = "#Team_Select";

	new szMenuTextCode[ sizeof szTeamSelect ];

	get_msg_arg_string( 4, szMenuTextCode, charsmax( szMenuTextCode ) );

	if( !equal( szMenuTextCode, szTeamSelect ) )
	{
		return PLUGIN_CONTINUE;
	}

	new iParam[ 2 ];

	iParam[ NULL ] = iMsgid;

	set_task( 0.1, "ForceTeamJoin", id, iParam, sizeof iParam );

	return PLUGIN_HANDLED;
}

public MessageVGUIMenu( iMsgid, iDest, id )
{
	if( !ShouldAutojoin( id ) || get_msg_arg_int( 1 ) != 2 )
	{
		return PLUGIN_CONTINUE;
	}

	new iParam[ 2 ];

	iParam[ NULL ] = iMsgid;

	set_task( 0.1, "ForceTeamJoin", id, iParam, sizeof iParam );

	return PLUGIN_HANDLED;
}

public MessageTextMsg( iMsgid, iDest, id )
{
	new szMessage[ 32 ];

	get_msg_arg_string( 2, szMessage, charsmax( szMessage ) );

	if( equal( szMessage, "#Terrorists_Win" )
	|| equal( szMessage, "#CTs_Win" ) )
	{
		set_msg_arg_string( 2, g_szBlank );
	}
}

public PrimaryWeapMenu( id )
{
	if( Get( g_iPrimaryChoosed, id ) )
	{
		SecondaryWeapMenu( id );

		return PLUGIN_HANDLED;
	}

	new szTitle[ 96 ];

	new szExit[ 64 ];

	formatex( szTitle, charsmax( szTitle ), "Primary weapons^n\y%s", SERVER );
	formatex( szExit, charsmax( szExit ), "Exit^n^n^n\r%s", WEBSITE );

	new iMenu = menu_create( szTitle, "PrimaryWeapHandler", NULL );
	new iPrimaryNum = sizeof g_szPrimaryWeapons;

	for( new i = NULL; i < iPrimaryNum; i++ )
	{
		menu_additem( iMenu, g_szPrimaryWeapons[ BUYNAME ][ i ], g_szBlank, NULL );
	}

	menu_setprop( iMenu, MPROP_EXITNAME, szExit );

	menu_display( id, iMenu, NULL );

	return PLUGIN_HANDLED;
}

public SecondaryWeapMenu( id )
{
	if( Get( g_iSecondaryChoosed, id ) )
	{
		ColorChat( id, GREEN, "%s^x01 You already choosed your weapons.", TAG );

		return PLUGIN_HANDLED;
	}

	new szTitle[ 96 ];

	new szExit[ 64 ];

	formatex( szTitle, charsmax( szTitle ), "Secondary weapons^n\y%s", SERVER );
	formatex( szExit, charsmax( szExit ), "Exit^n^n^n\r%s", WEBSITE );

	new iMenu = menu_create( szTitle, "SecondaryWeapHandler", NULL );
	new iSecondaryNum = sizeof g_szSecondaryWeapons;

	for( new i = NULL; i < iSecondaryNum; i++ )
	{
		menu_additem( iMenu, g_szSecondaryWeapons[ BUYNAME ][ i ], g_szBlank, NULL );
	}

	menu_setprop( iMenu, MPROP_EXITNAME, szExit );

	menu_display( id, iMenu, NULL );

	return PLUGIN_HANDLED;
}

public PrimaryWeapHandler( id, iMenu, iItem )
{
	menu_destroy( iMenu );

	if( iItem == MENU_EXIT )
	{
		return PLUGIN_HANDLED;
	}

	if( cs_get_user_team( id ) != ZE_TEAM_ZOMBIE )
	{
		ColorChat( id, BLUE, "^x04%s^x01 Just^x03 humans^x01 can use this option.", TAG );

		return PLUGIN_HANDLED;
	}

	Add( g_iPrimaryChoosed, id );

	give_item( id, g_szPrimaryWeapons[ NAME ][ iItem ] );

	cs_set_user_bpammo( id, get_weaponid( g_szPrimaryWeapons[ NAME ][ iItem ] ), g_iBPAmmo );

	SecondaryWeapMenu( id );

	return PLUGIN_HANDLED;
}

public SecondaryWeapHandler( id, iMenu, iItem )
{
	menu_destroy( iMenu );

	if( iItem == MENU_EXIT )
	{
		return PLUGIN_HANDLED;
	}

	if( cs_get_user_team( id ) != ZE_TEAM_ZOMBIE )
	{
		ColorChat( id, BLUE, "^x04%s^x01 Just^x03 humans^x01 can use this option.", TAG );

		return PLUGIN_HANDLED;
	}

	new iGrenadesNum = sizeof g_szGrenades;

	for( new i = NULL; i < iGrenadesNum; i++ )
	{
		give_item( id, g_szGrenades[ i ] );
	}

	Add( g_iSecondaryChoosed, id );

	give_item( id, g_szSecondaryWeapons[ NAME ][ iItem ] );

	cs_set_user_bpammo( id, get_weaponid( g_szSecondaryWeapons[ NAME ][ iItem ] ), g_iBPAmmo );

	return PLUGIN_HANDLED;
}

public ForceTeamJoin( iMenuMsgid[ ], id )
{
	new const szJoinTeam[ ] = "jointeam";

	new iMsgid;
	new iMsgBlock;

	iMsgid = iMenuMsgid[ NULL ];
	iMsgBlock = get_msg_block( iMsgid );

	set_msg_block( iMsgid, BLOCK_SET );
	engclient_cmd( id, szJoinTeam, "2" );
	set_msg_block( iMsgid, iMsgBlock );
}

public ShowPlayerInfo( id )
{
	id -= TASK_INFO;

	if( Get( g_iAlive, id ) )
	{
		new iHP = get_user_health( id );
		new iArmor = get_user_armor( id );

		set_dhudmessage( NULL, 100, 250, 0.02, 0.92, 0, 0.0, 0.2, 0.0, 0.0, false );
		show_dhudmessage( id, "Health: %d  Armor: %d", iHP, iArmor );
	}
}

public ZombieWin( )
{
	TerminateRound( RoundEndType_Objective, TeamWinning_Terrorist );

	ColorChat( NULL, GREEN, "%s^x01 ZOMBIES WIN", TAG );
}

stock SetUserHuman( id )
{
	new szBodyModel[ 128 ];

	g_iZombieType[ id ] = NOT_ZOMBIE;

	//GetStringFormArray( g_aHumanModels, szBodyModel, charsmax( szBodyModel ), -1 );

	cs_set_user_team( id, ZE_TEAM_HUMAN );
	//cs_set_user_model( id, szBodyModel );

	set_pev( id, pev_maxspeed, g_flHumanSpeed );
	set_pev( id, pev_health, g_flHumanHealth );
	set_pev( id, pev_armorvalue, g_flHumanArmor );
	set_pev( id, pev_gravity, g_flHumanGravity );
}

stock SetUserZombie( id, Zombie: iType )
{
	new szBodyModel[ 128 ];
	new szClawsModel[ 128 ];
	/*
	switch( iType )
	{
		case MAIN_ZOMBIE:
		{
			new iItem = GetStringFormArray( g_aMainZombieModels, szBodyModel, charsmax( szBodyModel ), -1 );
			GetStringFormArray( g_aClawsMainModels, szClawsModel, charsmax( szClawsModel ), iItem );

			cs_set_user_model( id, szBodyModel );

			set_pev( id, pev_viewmodel2, szClawsModel );
			set_pev( id, pev_weaponmodel2, g_szBlank );
		}

		case SECOND_ZOMBIE:
		{
			new szInfectSound[ 128 ];

			new iItem = GetStringFormArray( g_aMainZombieModels, szBodyModel, charsmax( szBodyModel ), -1 );
			GetStringFormArray( g_aClawsSecondModels, szClawsModel, charsmax( szClawsModel ), iItem );
			GetStringFormArray( g_aInfectSounds, szInfectSound, charsmax( szInfectSound ), -1 );

			cs_set_user_model( id, szBodyModel );

			set_pev( id, pev_viewmodel2, szClawsModel );
			set_pev( id, pev_weaponmodel2, g_szBlank );

			emit_sound( id, CHAN_BODY, szInfectSound, 1.0, ATTN_NORM, NULL, PITCH_NORM );
		}
	}
	*/
	g_iZombieType[ id ] = iType;

	cs_set_user_team( id, ZE_TEAM_ZOMBIE );
	cs_set_user_zoom( id, CS_RESET_ZOOM, 1 );

	set_pev( id, pev_maxspeed, g_flZombieSpeed );
	set_pev( id, pev_health, iType == MAIN_ZOMBIE ? g_flZombieHealth:g_flZombieHealth / 2 );
	set_pev( id, pev_armorvalue, g_flZombieArmor );
	set_pev( id, pev_gravity, g_flZombieGravity );

	strip_user_weapons( id );
	give_item( id, "weapon_knife" );

	SwitchNightVision( id, ON );
	CheckWinConditions( );
}

stock CountDown( iTimeLeft )
{
	switch( g_iStage )
	{
		case HUMANS_FREEZE:
		{
			if( iTimeLeft <= NULL )
			{
				new iRandom;
				new iZombieRequire = RequireZombies( );

				for( new i = NULL; i < iZombieRequire; i++ )
				{
					iRandom = RandomAlivePlayer( ZE_TEAM_HUMAN );

					SetUserZombie( iRandom, MAIN_ZOMBIE );
				}

				g_iStage = ZOMBIES_FREEZE;

				CountDown( g_iZombieFreeze );

				ColorChat( NULL, GREEN, "%s^x01 The humans are now free to run.", TAG );
			}

			else
			{
				CountDownContinue( iTimeLeft );
			}
		}

		case ZOMBIES_FREEZE:
		{
			if( iTimeLeft <= NULL )
			{
				g_iStage = ON;

				ColorChat( NULL, GREEN, "%s^x01 The zombies are now free to run. Be careful.", TAG );
			}

			else
			{
				CountDownContinue( iTimeLeft );
			}
		}
	}
}

stock CountDownContinue( iTimeLeft )
{
	new szSound[ 64 ];

	format( szSound, charsmax( szSound ), g_szCountdown, iTimeLeft );

	PlaySound( NULL, szSound );

	CountDown( --iTimeLeft );
}

stock CheckWinConditions( )
{
	if( AlivePlayers( ZE_TEAM_HUMAN ) == NULL )
	{
		EndRound( ZE_TEAM_ZOMBIE );
	}

	else if( AlivePlayers( ZE_TEAM_ZOMBIE ) == NULL )
	{
		EndRound( ZE_TEAM_HUMAN );
	}
}

stock EndRound( CsTeams: iTeam )
{
	TerminateRound( RoundEndType_Objective, _: iTeam );

	ColorChat( NULL, GREEN, "%s^x03 %s^x01 castiga runda.", TAG, iTeam == ZE_TEAM_HUMAN ? "Oamenii":"Zombii" );
}

stock SwitchNightVision( id, iMode )
{
	new iAlpha;

	if( iMode )
	{
		iAlpha = 70;

		set_player_light( id, "z" );
	}

	else
	{
		iAlpha = NULL;

		set_player_light( id, g_szLight );
	}

	message_begin( MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, id );
	write_short( NULL );
	write_short( NULL );
	write_short( 0x0004 );
	write_byte( 253 );
	write_byte( 110 );
	write_byte( 110 );
	write_byte( iAlpha );
	message_end( );

	g_iNightVision[ id ] = iMode;

	PlaySound( id, g_szNightVisionSound[ iMode ] );
}

stock set_player_light( id, const szLightStyle[ ] )
{
	message_begin( MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id );
	write_byte( NULL );
	write_string( szLightStyle );
	message_end( );
}

stock PlaySound( id, szSound[ ] )
{
	if( contain( szSound, ".mp3") != NULL )
	{
		client_cmd( id, "mp3 play ^"sound/%s^"", szSound );
	}

	else
	{
		client_cmd( id, "spk ^"%s^"", szSound );
	}
}

stock ResetSpeed( id )
{
	set_pev( id, pev_maxspeed, -1.0 );
	set_pev( id, pev_velocity, Float: { 0.0, 0.0, 0.0 } );
}

stock RequireZombies( )
{
	switch( AlivePlayers( ZE_TEAM_HUMAN ) )
	{
		case 2..5:
		{
			return 1;
		}

		case 6..15:
		{
			return 2;
		}

		case 16..25:
		{
			return 3;
		}

		case 26..32:
		{
			return 4;
		}
	}

	return NULL;
}

stock AlivePlayers( CsTeams: iTeam )
{
	new iNum = NULL;

	for( new id = NULL; id < g_iMaxPlayers; id++ )
	{
		if( !Get( g_iConnected, id ) )
		{
			continue;
		}

		if( Get( g_iAlive, id ) && cs_get_user_team( id ) == iTeam )
		{
			iNum++;
		}
	}

	return iNum;
}

stock RandomAlivePlayer( CsTeams: iTeam )
{
	new iPlayers[ 32 ];
	new iNum = NULL;

	for( new id = NULL; id < g_iMaxPlayers; id++ )
	{
		if( !Get( g_iConnected, id ) || Get( g_iAlive, id ) )
		{
			continue;
		}

		if( cs_get_user_team( id ) == iTeam )
		{
			iPlayers[ iNum++ ] = id;
		}
	}

	return PLUGIN_HANDLED;
}

stock Knockback( id, Float: flAOrigin[ 3 ] )
{
	new Float: flVelocity[ 3 ];
	new Float: flOrigin[ 3 ];

	new Float: flDistance;
	new Float: flTime;

	pev( id, pev_origin, flOrigin );

	flDistance = get_distance_f( flOrigin, flAOrigin );
	flTime = flDistance / g_flZombieKnockback;

	flVelocity[ NULL ] = ( ( flOrigin[ NULL ] - flAOrigin[ NULL ] ) / flTime ) * 1.5;
	flVelocity[ 1 ] = ( ( flOrigin[ 1 ] - flAOrigin[ 1 ] ) / flTime ) * 1.5;
	flVelocity[ 2 ] = ( flOrigin[ 2 ] - flAOrigin[ 2 ] ) / flTime;

	set_pev( id, pev_velocity, flVelocity );
}

stock AddFrags( id, iFrags )
{
	new iCurrentFrags = get_user_frags( id );

	set_user_frags( id, iCurrentFrags + iFrags );
}

stock AddDeaths( id, iDeaths )
{
	new iCurrentDeaths = get_user_deaths( id );

	cs_set_user_deaths( id, iCurrentDeaths + iDeaths );
}

stock LoadConfigFile( )
{
	new szPath[ 64 ];

	get_configsdir( szPath, charsmax( szPath ) );

	format( szPath, charsmax( szPath ), "%s/%s", szPath, g_szConfigFile );

	if( !file_exists( szPath ) )
	{
		new const szError[ ] = "Can't load zombie escape main config file";

		set_fail_state( szError );

		return PLUGIN_CONTINUE;
	}

	new szData[ 1024 ];

	new szValue[ 960 ];

	new szKey[ 64 ];

	new iFile = fopen( szPath, "rt" );

	while( iFile && !feof( iFile ) )
	{
		fgets( iFile, szData, charsmax( szData ) );

		replace( szData, charsmax( szData ), "^n", g_szBlank );

		if( !szData[ NULL ] || ( szData[ NULL ] == '/' && szData[ 1 ] == '/' ) || szData[ NULL ] == ';' )
		{
			continue;
		}

		strtok( szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=' );

		trim( szKey );
		trim( szValue );

		switch( szKey[ NULL ] )
		{
			case 'G': //  GAMEPLAY
			{
				switch( szKey[ 9 ] )
				{
					case 'M': //  GAMEPLAY_MIN_PLAYERS
					{
						if( equal( szKey, "GAMEPLAY_MIN_PLAYERS" ) )
						{
							g_iMinPlayers = str_to_num( szValue );
						}
					}

					case 'B': //  GAMEPLAY_BPAMMO
					{
						if( equal( szKey, "GAMEPLAY_BPAMMO" ) )
						{
							g_iBPAmmo = str_to_num( szValue );
						}
					}

					case 'L': //  GAMEPLAY_LIGHT
					{
						if( equal( szKey, "GAMEPLAY_LIGHT" ) )
						{
							copy( g_szLight, charsmax( g_szLight ), szValue );
						}
					}

					case 'Z': //  GAMEPLAY_ZOMBIE_FREEZE
					{
						if( equal( szKey, "GAMEPLAY_ZOMBIE_FREEZE" ) )
						{
							g_iZombieFreeze = str_to_num( szValue );
						}
					}

					case 'H': //  GAMEPLAY_HUMAN_FREEZE
					{
						if( equal( szKey, "GAMEPLAY_HUMAN_FREEZE" ) )
						{
							g_iHumanFreeze = str_to_num( szValue );
						}
					}

					case 'R': //  GAMEPLAY_ROUND_TIME
					{
						if( equal( szKey, "GAMEPLAY_ROUND_TIME" ) )
						{
							g_iRoundTime = str_to_num( szValue );
						}
					}
				}
			}

			case 'H': //  HUMANS
			{
				switch( szKey[ 9 ] )
				{
					case 'H': //  HUMAN_HEALTH
					{
						if( equal( szKey, "HUMAN_HEALTH" ) )
						{
							g_flHumanHealth = str_to_float( szValue );
						}
					}

					case 'A': //  HUMAN_ARMOR
					{
						if( equal( szKey, "HUMAN_ARMOR" ) )
						{
							g_flHumanArmor = str_to_float( szValue );
						}
					}

					case 'G': //  HUMAN_GRAVITY
					{
						if( equal( szKey, "HUMAN_GRAVITY" ) )
						{
							g_flHumanGravity = str_to_float( szValue ) / 800;
						}
					}

					case 'S': //  HUMAN_SPEED
					{
						if( equal( szKey, "HUMAN_SPEED" ) )
						{
							g_flHumanSpeed = str_to_float( szValue );
						}
					}
				}
			}

			case 'Z': //  ZOMBIES
			{
				switch( szKey[ 9 ] )
				{
					case 'H': //  ZOMBIE_HEALTH
					{
						if( equal( szKey, "ZOMBIE_HEALTH" ) )
						{
							g_flZombieHealth = str_to_float( szValue );
						}
					}

					case 'A': //  ZOMBIE_ARMOR
					{
						if( equal( szKey, " ZOMBIE_ARMOR" ) )
						{
							g_flZombieArmor = str_to_float( szValue );
						}
					}

					case 'G': //  ZOMBIE_GRAVITY
					{
						if( equal( szKey, "ZOMBIE_GRAVITY" ) )
						{
							g_flZombieGravity = str_to_float( szValue ) / 800;
						}
					}

					case 'S': //  ZOMBIE_SPEED
					{
						if( equal( szKey, "ZOMBIE_SPEED" ) )
						{
							g_flZombieSpeed = str_to_float( szValue );
						}
					}

					case 'K': //  ZOMBIE_KNOCKBACK
					{
						if( equal( szKey, "ZOMBIE_KNOCKBACK" ) )
						{
							g_flZombieKnockback = str_to_float( szValue );
						}
					}
				}
			}
			/*
			case 'M': // MODELS
			{
				switch( szKey[ 9 ] )
				{
					case 'H': //  MODEL_HUMAN
					{
						if( equal( szKey, "MODEL_HUMAN" ) )
						{
							PushDataToArray( g_aHumanModels, szValue, charsmax( szValue ) );
						}
					}

					case 'M': //  MODEL_MAIN_ZOMBIE
					{
						if( equal( szKey, "MODEL_MAIN_ZOMBIE" ) )
						{
							PushDataToArray( g_aMainZombieModels, szValue, charsmax( szValue ) );
						}
					}

					case 'S': //  MODEL_SECOND_ZOMBIE
					{
						if( equal( szKey, "MODEL_SECOND_ZOMBIE" ) )
						{
							PushDataToArray( g_aSecondZombieModels, szValue, charsmax( szValue ) );
						}
					}

					case 'C': //  MODEL_C
					{
						if( equal( szKey, "MODEL_CLAWS_MAIN_ZOMBIE" ) )
						{
							PushDataToArray( g_aClawsMainModels, szValue, charsmax( szValue ) );
						}

						else if( equal( szKey, "MODEL_CLAWS_SECOND_ZOMBIE" ) )
						{
							PushDataToArray( g_aClawsSecondModels, szValue, charsmax( szValue ) );
						}
					}
				}
			}

			case 'S': //  SOUNDS
			{
				switch( szKey[ 9 ] )
				{
					case 'R': //  SOUND_READY
					{
						if( equal( szKey, "SOUND_READY" ) )
						{
							PushDataToArray( g_aReadySounds, szValue, charsmax( szValue ) );
						}
					}

					case 'A': //  SOUND_AMBIENCE
					{
						if( equal( szKey, "SOUND_AMBIENCE" ) )
						{
							PushDataToArray( g_aAmbienceSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'Z': //  SOUND_ZOMBIE_APPEAR
					{
						if( equal( szKey, "SOUND_ZOMBIE_APPEAR" ) )
						{
							PushDataToArray( g_aZombieAppearSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'I': //  SOUND_INFECT
					{
						if( equal( szKey, "SOUND_INFECT" ) )
						{
							PushDataToArray( g_aInfectSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'P': //  SOUND_PAIN
					{
						if( equal( szKey, "SOUND_PAIN" ) )
						{
							PushDataToArray( g_aPainSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'C': //  SOUND_COUNTDOWN
					{
						if( equal( szKey, "SOUND_COUNTDOWN" ) )
						{
							copy( g_szCountdown, charsmax( g_szCountdown ), szValue );
						}
					}

					case 'S': //  SOUND_SUCCESS
					{
						if( equal( szKey, "SOUND_SUCCESS" ) )
						{
							PushDataToArray( g_aSuccessSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'F': //  SOUND_FAIL
					{
						if( equal( szKey, "SOUND_FAIL" ) )
						{
							PushDataToArray( g_aFailSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'H': //  SOUND_HIT
					{
						if( equal( szKey, "SOUND_HIT" ) )
						{
							PushDataToArray( g_aHitSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'M': //  SOUND_MISS
					{
						if( equal( szKey, "SOUND_MISS" ) )
						{
							PushDataToArray( g_aMissSounds, szValue, charsmax( szValue ) );
						}
					}

					case 'W': //  SOUND_WALL
					{
						if( equal( szKey, "SOUND_WALL" ) )
						{
							PushDataToArray( g_aWallSounds, szValue, charsmax( szValue ) );
						}
					}
				}
			}
			*/
			case 'F': //  FOG
			{
				switch( szKey[ 9 ] )
				{
					case 'E': //  FOG_ENABLE
					{
						if( equal( szKey, "FOG_ENABLE" ) )
						{
							g_iFogEnable = str_to_num( szValue );
						}
					}

					case 'D': //  FOG_DENSITY
					{
						if( equal( szKey, "FOG_DENSITY" ) )
						{
							copy( g_szFogDensity, charsmax( g_szFogDensity ), szValue );
						}
					}

					case 'C': //  FOG_COLOR
					{
						if( equal( szKey, "FOG_COLOR" ) )
						{
							copy( g_szFogColor, charsmax( g_szFogColor ), szValue );
						}
					}
				}
			}
		}
	}

	if( iFile )
	{
		fclose( iFile );
	}

	return PLUGIN_CONTINUE;
}

stock PushDataToArray( Array: aArrayName, szString[ ], iLen )
{
	new szData[ 64 ];

	while( szString[ NULL ] != NULL && strtok( szString, szData, charsmax( szData ), szString, iLen, ',' ) )
	{
		trim( szData );
		trim( szString );

		ArrayPushString( aArrayName, szData );
	}
}

stock PrecacheModelsFromArray( Array: aArrayName )
{
	new szTemp[ 256 ];

	new szBuffer[ 128 ];

	new iArraySize = ArraySize( aArrayName );

	for( new i = NULL; i < iArraySize; i++ )
	{
		ArrayGetString( aArrayName, i, szTemp, charsmax( szTemp ) );

		formatex( szBuffer, charsmax( szBuffer ), "models/player/ZombieEscape/%s/%s.mdl", szTemp, szTemp );

		engfunc( EngFunc_PrecacheModel, szBuffer );
		//precache_model( szBuffer );
	}
}

stock PrecacheSoundsFromArray( Array: aArrayName )
{
	new szTemp[ 256 ];

	new szBuffer[ 128 ];

	new iArraySize = ArraySize( aArrayName );

	for( new i = NULL; i < iArraySize; i++)
	{
		ArrayGetString( aArrayName, i, szTemp, charsmax( szTemp ) );

		if( contain( szTemp, ".mp3" ) != NULL )
		{
			format( szBuffer, charsmax( szBuffer ), "sound/ZombieEscape/%s", szTemp );

			engfunc( EngFunc_PrecacheSound, szBuffer );
			//precache_generic( szBuffer );
		}

		else
		{
			engfunc( EngFunc_PrecacheSound, szTemp );
			//precache_sound( szTemp );
		}
	}
}

stock GetStringFormArray( Array: aArrayName, szString[ ], iLen, iItem )
{
	if( iItem == -1)
	{
		new iArraySize = ArraySize( aArrayName );

		iItem = random( iArraySize );
	}

	ArrayGetString( aArrayName, iItem, szString, iLen );

	return iItem;
}

stock SetKeyValue( iEntity, szKey[ ], szValue[ ] )
{
	new szClassname[ 32 ];

	pev( iEntity, pev_classname, szClassname, charsmax( szClassname ) );

	set_kvd( NULL, KV_ClassName, szClassname );
	set_kvd( NULL, KV_KeyName, szKey );
	set_kvd( NULL, KV_Value, szValue );
	set_kvd( NULL, KV_fHandled, NULL );

	dllfunc( DLLFunc_KeyValue, iEntity, NULL );
}

stock bool: ShouldAutojoin( id )
{
	return ( cs_get_user_team( id ) == CS_TEAM_UNASSIGNED && !task_exists( id ) );
}
// playsound facut pt fiecare  id in parte
//top 3
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
