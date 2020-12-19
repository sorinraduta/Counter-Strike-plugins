#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < engine >
#include < ColorChat >
//#include < afk_checker >

//#pragma semicolon 1

#define MAX_ZONES		36

#define Set(%1,%2)		( %1 |= 1 << ( %2 & 31 ) )
#define Sub(%1,%2)		( %1 &= ~( 1 <<( %2 & 31 ) ) )
#define Get(%1,%2)		( %1 & 1 << ( %2 & 31 ) )


static const
	
	PLUGIN[ ] =		"Ownage",
	VERSION[ ] =		"2.1",
	AUTHOR[ ] =		"Rap^^ & Askhanar",
	
	TAG[ ] =		"[D/C]";


enum Ownage
{
	CLASIC,
	UNDER
};

enum
{
	NULL = 0,
	VERIFY,
	TOUCHED
};

new const Float: g_flMins[ MAX_ZONES ][ 3 ] =
{
	{ 1795.4, 85.5, 226.0 },		//pod
	{ -61.9, -575.7, 25.0 },		//market
	{ -445.2, 386.7, 1025.0 },	//cutie scara mare
	{ -381.6, 451.2, 1025.0 },	//cutie scara panou red dog
	{ 193.8, -155.8, 0.8 },		//cutie market 1
	{ 131.1, -90.5, 1.7 }, 		//cutie market 2
	{ -124.5, -170.8, 2.0 },		//cutie market 3
	{ 1155.0, -126.5, 1.0 },		//cutie pod
	{ 546.9, -381.9, 64.0 },		//wb market spre mkt
	{ 578.5, -188.9, 64.0 },		//wb market spre scara stiu eu uscara :))
	{ 546.9, -1086.8, 64.0 },	//wb cts spre market
	{ 578.0, -1117.0, 64.0 },	//wb cts spre pod de la cts rr
	{ 1283.9, -189.6, 67.0 },	//wb pod spre scara
	{ 1473.3, -381.8, 67.00 },  	//wb pod culoar
	{ -1276.5, -251.1, 1217.0 },	//cutie ts langa scara verdeata
	{ -1212.5, -509.2, 1217.0 },	//cutie ts spre rr cutia de jos
	{ -1213.5, -444.1, 1281.0 },	//cutie ts spre rr cutia de sus
	{ 1073.0, -201.8, 1120.0 },	//panou pod
	{ 1049.5, -213.0, 1087.0 },	//margine panou pod
	{ 661.4, -1485.9, 1184.0 },	//panou cts scara pod zona spre stg
	{ 715.2, -1443.8, 1153.0 },	//picior panou cts 1
	{ 793.2, -1363.3, 1152.0 },	//picior panou cts 2
	{ -798.2, -701.4, 512.7 },	//cutie sus scara ts de jos
	{ -1405.5, 258.7, 1152.5 },	//scara verdeata wr colt
	{ -85.8,-1086.5, -23.5 }, 	//prelata zona in dreata
	{ 77.9, -1087.8, -27.2 },	//prelata zona in stanga
	{ -84.5, -910.5, 2.0 },		//prelata zona in fata
	{ 1280.3, -1017.2, 1088.3 },	//panou wb ct spawn
	{ -477.7, -1112.5, 641.5 },	//cutie de langa umbrele
	{ 773.8, 771.9,930.0 },		//pod cabana zona 1
	{ 772.5, 812.4, 952.0 }, 	//pod cabana zona 2
	{ -2170.5, -1530.6, 1344.8 },	//lj zona 1
	{ -2043.8, -2748.2, 1345.0 },	//lj zona 2
	{ -2555.5, -2747.4, 1345.8 },	//lj zona 3
	{ 1282.0, -275.2, 1088.0 },	//panou pod spre stanga
	{ 178.2, -652.0, -61.9 }		//cutie mareket spre prelata
};

new const Float: g_flMaxs[ MAX_ZONES ][ 3 ] =
{
	{ 1853.4, 255.5, 228.0 }, 	//pod
	{ 190.0, -129.5, 27.0 },		//market
	{ -323.2, 444.7, 1027.0 },	//cutie scara mare
	{ -323.6, 509.2, 1027.0 },	//cutie scara panou red dog
	{ 251.8, -99.9, 2.9 },		//cutie market 1
	{ 187.1, -36.5, 3.7 },		//cutie market 2
	{ -68.5, -116.8, 4.0 },		//cutie market 3
	{ 1213.0, -66.5, 3.0 },		//cutie pod
	{ 572.9, -197.9, 80.0 },		//wb market spre mkt
	{ 766.5, -162.9, 76.0 },		//wb market spre scara stiu eu uscara :))
	{ 572.9, -896.8, 76.0 },		//wb cts spre market
	{ 766.0, -1091.0, 78.0 },	//wb cts spre pod de la cts rr
	{ 1469.9, -163.6, 85.0 },	//wb pod spre scara
	{ 1501.3, -193.8, 83.0 },	//wb pod culoar
	{ -1220.5, -197.1, 1219.0 },	//cutie ts langa scara verdeata
	{ -1156.5, -453.2, 1219.0 },	//cutie ts spre rr cutia de jos
	{ -1155.5, -388.1, 1283.0 },	//cutie ts spre rr cutia de sus
	{ 1147.0, -197.8, 1132.0 },	//panou pod
	{ 1109.5, -211.0, 1099.0 },	//margine panou pod
	{ 663.4, -1473.9, 1196.0 },	//panou cts scara pod spre stg
	{ 719.2, -1439.8, 1157.0 },	//picior panou cts 1
	{ 797.2, -1359.3, 1156.0 },	//picior panou cts 2
	{ -738.2, -641.4, 514.7 },	//cutie sus scara ts de jos
	{ -1365.5, 274.7, 1180.5 },	//scara verdeata wr colt
	{ -77.8, -898.5, 18.3 },		//prelata in dreapta
	{ 83.9, -899.7, 16.7 },		//prelata in stanga
	{ 83.3, -898.5, 24.0 },		//prelata fata
	{ 1284.3, -1015.2, 1092.3 },	//panou wb ct spawn
	{ -455.7, -1090.5, 643.5 },	//cutie de langa umbrele
	{ 1145.8, 1017.9, 964.0 },	//pod cabana zona 1
	{ 1146.5, 978.4, 1026.0 }, 	//pod cabana zona 2
	{ -1988.5, -1284.6, 1348.8 },	//lj zona 1
	{ -1923.8, -2628.2, 1347.0 },	//lj zona 2
	{ -2435.5, -2627.4, 1347.8 },	//lj zona 3
	{ 1284.0, -273.2, 1092.0 },	//panou pod spre stanga
	{ 186.2, -598.0, -23.9 }
};

new const g_szAreas[ MAX_ZONES ][ ] =
{
	"Anticamera",
	"Market",
	"Cutii, pop dog",
	"Cutii, pop dog",
	"Market",
	"Market",
	"Market",
	"Sub pod, la cutie",
	"WallBug",
	"WallBug",
	"WallBug",
	"WallBug",
	"WallBug",
	"WallBug",
	"Cutie, TS",
	"Cutie, TS",
	"Cutia mare, TS",
	"Panou, pod",
	"Panou, pod",
	"Panou, CTS",
	"Panou, CTS",
	"Panou, CTS",
	"Cutie, sub TS-RR",
	"TS - White Roof",
	"Prelata",
	"Prelata",
	"Prelata",
	"Panou, CTS",
	"Cutie, umbrele",
	"Cabana",
	"Cabana",
	"LJR",
	"LJR",
	"LJR",
	"Panou, pod",
	"Cutie, market"
};

new const Float: g_flLimits[ 3 ] = { 16.0, 16.0, 36.0 }

new const Float: g_flNormalMins[ 3 ] = { -10.0, -10.0, -61.0 };
new const Float: g_flNormalMaxs[ 3 ] = { 10.0, 10.0, -36.0 };

new const Float: g_flDuckMins[ 3 ] = { -10.0, -10.0, -43.0 };
new const Float: g_flDuckMaxs[ 3 ] = { 10.0, 10.0, -18.0 };

new const g_szPlayer[ ] = "player";
new const g_szInfoTarget[ ] = "info_target";
new const g_szOwnageCube[ ] = "Ownage_Cube";
new const g_szOwnageCheck[ ] = "Ownage_Check";

new const PLAYER_HALF_WIDTH = 16;
new const PLAYER_HALF_HEIGHT = 36;

new Float: g_flMinSpeed[ 33 ];//
new Float: g_flMaxSpeed[ 33 ];//
new Float: g_flMaxVelo[ 33 ]; //
new Float: g_flCooldown[ 33 ];////
new g_flTime[ 33 ];//

new g_iFrames[ 33 ];//
new g_iOwnageEnt[ 33 ];
new g_iTouchEnt[ 33 ];
new g_iOwned[ 33 ];
static const szSprite[ ]		= "sprites/dot.spr";
new g_iAlive;
new g_iInDuck;
new iSprite;

public plugin_precache( )
{
	iSprite = precache_model(szSprite);
}
public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_forward( FM_PlayerPreThink,		"FwdPlayerPreThink", true );
	register_forward( FM_PlayerPostThink,		"FwdPlayerPostThink", true );
	register_forward( FM_Touch,			"FwdTouch" );
	
	RegisterHam( Ham_Killed,	g_szPlayer,	"FwdPlayerKilled" );
	RegisterHam( Ham_Player_Duck,	g_szPlayer,	"FwdPlayerDuck" );
	RegisterHam( Ham_Spawn,		g_szPlayer,	"FwdPlayerSpawn" );
	register_concmd( "draw", "cmddraw" )
	CreateEntities( );
}
public cmddraw(id)
{
	client_print(0, print_chat, "asda");
	new szArg[ 32 ];
	
	read_argv( 1, szArg, charsmax( szArg ) );
	
	new i = str_to_num( szArg );
	
	new color[3]
	color[0] = 0
	color[1] = 128
	color[2] = 255
	
	DrawLine(g_flMaxs[ i ][0], g_flMaxs[ i ][1], g_flMaxs[ i ][2], g_flMins[ i ][0], g_flMaxs[ i ][1], g_flMaxs[ i ][2], color);
	DrawLine(g_flMaxs[ i ][0], g_flMaxs[ i ][1], g_flMaxs[ i ][2], g_flMaxs[ i ][0], g_flMins[ i ][1], g_flMaxs[ i ][2], color);
	DrawLine(g_flMaxs[ i ][0], g_flMaxs[ i ][1], g_flMaxs[ i ][2], g_flMaxs[ i ][0], g_flMaxs[ i ][1], g_flMins[ i ][2], color);
	//  -> alle Linien beginnen bei g_flMins
	DrawLine(g_flMins[ i ][0], g_flMins[ i ][1], g_flMins[ i ][2], g_flMaxs[ i ][0], g_flMins[ i ][1], g_flMins[ i ][2], color);
	DrawLine(g_flMins[ i ][0], g_flMins[ i ][1], g_flMins[ i ][2], g_flMins[ i ][0], g_flMaxs[ i ][1], g_flMins[ i ][2], color);
	DrawLine(g_flMins[ i ][0], g_flMins[ i ][1], g_flMins[ i ][2], g_flMins[ i ][0], g_flMins[ i ][1], g_flMaxs[ i ][2], color);
	//  -> die restlichen 6 Lininen
	DrawLine(g_flMins[ i ][0], g_flMaxs[ i ][1], g_flMaxs[ i ][2], g_flMins[ i ][0], g_flMaxs[ i ][1], g_flMins[ i ][2], color);
	DrawLine(g_flMins[ i ][0], g_flMaxs[ i ][1], g_flMins[ i ][2], g_flMaxs[ i ][0], g_flMaxs[ i ][1], g_flMins[ i ][2], color);
	DrawLine(g_flMaxs[ i ][0], g_flMaxs[ i ][1], g_flMins[ i ][2], g_flMaxs[ i ][0], g_flMins[ i ][1], g_flMins[ i ][2], color);
	DrawLine(g_flMaxs[ i ][0], g_flMins[ i ][1], g_flMins[ i ][2], g_flMaxs[ i ][0], g_flMins[ i ][1], g_flMaxs[ i ][2], color);
	DrawLine(g_flMaxs[ i ][0], g_flMins[ i ][1], g_flMaxs[ i ][2], g_flMins[ i ][0], g_flMins[ i ][1], g_flMaxs[ i ][2], color);
	DrawLine(g_flMins[ i ][0], g_flMins[ i ][1], g_flMaxs[ i ][2], g_flMins[ i ][0], g_flMaxs[ i ][1], g_flMaxs[ i ][2], color);
}

public client_putinserver( id )
{
	Sub( g_iAlive, id );
	Sub( g_iInDuck, id );
	
	g_iTouchEnt[ id ] = NULL;
	g_iOwned[ id ] = NULL;
	
	g_flMaxSpeed[ id ] = 0.0;
	g_flMinSpeed[ id ] = 0.0;
	g_flMaxVelo[ id ] = 0.0;
}

public client_disconnect( id )
{
	Sub( g_iAlive, id );
	
	set_pev( id, pev_origin, Float: { 0.0, 0.0, -55000.0 } );
}

public FwdPlayerPreThink( id )
{	
	if( Get( g_iAlive, id ) )
	{
		if( Get( g_iInDuck, id ) )
		{
			if( pev( id, pev_flags ) & ~FL_DUCKING )
			{
				new iEntity;
			
				iEntity = g_iOwnageEnt[ id ];
				
				set_pev( iEntity, pev_mins, g_flNormalMins );
				set_pev( iEntity, pev_maxs, g_flNormalMaxs );
				
				Sub( g_iInDuck, id );
			}
		}
		
		if( g_iTouchEnt[ id ] == TOUCHED )
		{
			g_iTouchEnt[ id ] = VERIFY;
		}
	}
}

public FwdPlayerPostThink( id )
{
	if( g_iTouchEnt[ id ] == VERIFY )
	{
		g_iTouchEnt[ id ] = NULL;
		
		//if( get_gametime( ) - g_flCooldown[ id ] > 1.0 )
		//{
		
		g_flCooldown[ id ] = get_gametime( );
		
		new szName[ 32 ];
		new szOwnedName[ 32 ];
		new id2;
		
		get_user_name( id, szName, charsmax( szName ) );
		get_user_name( g_iOwned[ id ], szOwnedName, charsmax( szOwnedName ) );
		
		id2 = g_iOwned[ id ];
		g_iOwned[ id ] = NULL;
		
		if( !touch_ground( id, id2 ) )//&& NothingBetween( id2, id ) )
		{
			Owned( id, id2, UNDER );
			ColorChat( NULL, GREEN, "%s^x03 %f | %d", TAG, get_systime( ) - g_flTime[ id ], g_iFrames[ id ] );
		//ColorChat( NULL, GREEN, "%s OWNER^x03 MIN: %f | MAX: %f", TAG, g_flMinSpeed[ id ], g_flMaxSpeed[ id ] );
		//ColorChat( NULL, GREEN, "%s OWNED^x03 MIN: %f | MAX: %f", TAG, g_flMinSpeed[ id2 ], g_flMaxSpeed[ id2 ] );
		}
		g_iFrames[ id ] = NULL;
		
		g_flMaxSpeed[ id ] = 0.0;
		g_flMaxVelo[ id ] = 0.0;
		g_flMaxSpeed[ id2 ] = 0.0;
		g_flMaxVelo[ id2 ] = 0.0;
		g_flMinSpeed[ id ] = 9999.9;
		g_flMinSpeed[ id2 ] = 9999.9;
		//}
	}
}

public FwdTouch( iTouched, iToucher )
{
	static szTouched[ 32 ];
	static szToucher[ 32 ];
	
	pev( iTouched, pev_classname, szTouched, charsmax( szTouched ) );
	pev( iToucher, pev_classname, szToucher, charsmax( szToucher ) );
	
	if( equal( szToucher, g_szPlayer ) && Get( g_iAlive, iToucher ) )
	{
		static iOwner;
		static iOwned;
		
		if( equal( szTouched, g_szPlayer ) && Get( g_iAlive, iTouched ) )
		{
			iOwner = iToucher;
			
			if( cs_get_user_team( iOwner ) == CS_TEAM_T )
			{
				iOwned = iTouched;
				
				if( pev( iOwner, pev_groundentity ) == iOwned )
				{
					if( !g_iOwned[ iOwner ] )
					{
						g_iOwned[ iOwner ] = iOwned;
						
						StartChecking( iOwner );
					}
				}
				
				else if( pev( iOwned, pev_groundentity ) == iOwner )
				{
					client_print( NULL, print_chat, "ERROR: 1" );
				}
			}
			
			return PLUGIN_CONTINUE;
		}
		
		else if( equal( szTouched, g_szOwnageCube ) )
		{
			iTouched = pev( iTouched, pev_owner );
			
			if( iTouched == iToucher || !Get( g_iAlive, iTouched ) )
			{
				return PLUGIN_CONTINUE;
			}
			
			if( GetOwnerOwned( iToucher, iTouched, iOwner, iOwned ) )
			{
				if( pev( iOwned, pev_movetype ) == MOVETYPE_FLY || pev( iOwner, pev_movetype ) == MOVETYPE_FLY )
				{
					return PLUGIN_CONTINUE;
				}
				
				static iOwnerFlags;
				
				iOwnerFlags = pev( iOwner, pev_flags );
				
				if( ( iOwnerFlags & FL_DUCKING ) && ( iOwnerFlags & FL_ONGROUND ) )
				{
					if( !touch_ground( iOwner, iOwned ) )//&& NothingBetween( iOwned, iOwner ) )
					{
						g_iTouchEnt[ iOwner ] = TOUCHED;
						g_iOwned[ iOwner ] = iOwned;
						g_flTime[ iOwner ] = get_systime( );
						g_iFrames[ iOwner ]++;
					}
				}
			}
		}
	}
	
	else if( equal( szToucher, g_szOwnageCube )
	&& equal( szTouched, g_szPlayer ) )
	{
		client_print( NULL, print_chat, "ERROR: 2" );
	}
	
	return PLUGIN_CONTINUE;
}

public FwdOwnageCheckThink( iEntity )
{
	if( !pev_valid( iEntity ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new szClassName[ 32 ];
	
	pev( iEntity, pev_classname, szClassName, charsmax( szClassName ) );
	
	if( !equal( g_szOwnageCheck, szClassName ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new id = pev( iEntity, pev_iuser1 );
	
	for( new i = NULL; i < MAX_ZONES; i++ )
	{
		if( user_touch_zone( id, i ) )
		{
			Owned( id, g_iOwned[ id ], CLASIC, g_szAreas[ i ] );
			
			StopChecking( iEntity );
			
			return PLUGIN_HANDLED;
		}
	}
	
	set_pev( iEntity, pev_nextthink, get_gametime( ) + 0.1 );
	
	return PLUGIN_HANDLED;
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
	
	g_iOwned[ id ] = NULL;
	g_iTouchEnt[ id ] = NULL;
}

public FwdPlayerDuck( id )
{
	if( !Get( g_iInDuck, id ) )
	{
		if( pev( id, pev_flags ) & FL_DUCKING )
		{
			new iEntity;
			
			iEntity = g_iOwnageEnt[ id ];
			
			set_pev( iEntity, pev_mins, g_flDuckMins );
			set_pev( iEntity, pev_maxs, g_flDuckMaxs );
			
			Set( g_iInDuck, id );
		}
	}
}

public FwdPlayerSpawn( id )
{
	Set( g_iAlive, id );
}

stock GetOwnerOwned( id1, id2, &iOwner, &iOwned )
{
	if( cs_get_user_team( id1 ) ==  cs_get_user_team( id2 ) )
	{
		return NULL;
	}
	
	if( cs_get_user_team( id1 ) == CS_TEAM_T )
	{
		iOwner = id1;
		iOwned = id2;
	}
	
	else
	{
		iOwner = id2;
		iOwned = id1;
	}
	
	return 1;
}

stock Owned( iOwner, iOwned, Ownage: iType, szArea[ ] = "" )
{
	new szOwner[ 32 ];
	new szOwned[ 32 ];
	
	get_user_name( iOwner, szOwner, charsmax( szOwner ) );
	get_user_name( iOwned, szOwned, charsmax( szOwned ) );
	
	switch( iType )
	{
		case CLASIC:
		{
			ColorChat( NULL, GREEN, "%s^x03 %s^x01 owned^x03 %s^x01 (^x04%s^x01).", TAG, szOwner, szOwned, szArea );
		}
		
		case UNDER:
		{
			ColorChat( NULL, GREEN, "%s^x03 %s^x01 owned^x03 %s^x01 (^x04Underneath^x01).", TAG, szOwner, szOwned );
		}
	}
	
	client_cmd( NULL, "spk vox/doop" );
}

public CreateEntities( )
{
	new iEntity;
	
	new iMaxPlayers = get_maxplayers( );
	
	new iInfoTarget = engfunc( EngFunc_AllocString, g_szInfoTarget );
	
	for( new id = 1; id <= iMaxPlayers; id++ )
	{
		iEntity = engfunc( EngFunc_CreateNamedEntity, iInfoTarget );
		
		if( pev_valid( iEntity ) )
		{
			set_pev( iEntity, pev_classname, g_szOwnageCube );
			set_pev( iEntity, pev_mins, g_flNormalMins );
			set_pev( iEntity, pev_maxs, g_flNormalMaxs );
			set_pev( iEntity, pev_movetype, MOVETYPE_FOLLOW );
			set_pev( iEntity, pev_aiment, id );
			set_pev( iEntity, pev_solid, SOLID_TRIGGER );
			set_pev( iEntity, pev_owner, id );
			//set_pev( id, pev_origin, Float: { 0.0, 0.0, -55000.0 } );
			
			g_iOwnageEnt[ id ] = iEntity;
		}
	}
}

public StartChecking( id )
{
	new iInfoTarget = engfunc( EngFunc_AllocString, g_szInfoTarget );
	new iEntity = engfunc( EngFunc_CreateNamedEntity, iInfoTarget );
	
	if( pev_valid( iEntity ) )
	{
		set_pev( iEntity, pev_classname, g_szOwnageCheck );
		set_pev( iEntity, pev_iuser1, id );
		
		register_forward( FM_Think, "FwdOwnageCheckThink" );
		
		set_pev( iEntity, pev_nextthink, get_gametime( ) + 0.1 );
		
		set_task( 2.0, "StopChecking", iEntity );
	}
}

public StopChecking( iEntity )
{
	if( pev_valid( iEntity ) )
	{
		new id = pev( iEntity, pev_iuser1 );
		
		g_iOwned[ id ] = NULL;
		
		engfunc( EngFunc_RemoveEntity, iEntity );
	}
}

stock bool: NothingBetween( iEntity1, iEntity2 )
{
	new Float: iEntity1Mins[ 3 ];
	new Float: iEntity1Maxs[ 3 ];
	new Float: iEntity1Origin[ 3 ];
	new Float: iEntity2Mins[ 3 ];
	new Float: iEntity2Maxs[ 3 ];
	new Float: iEntity2Origin[ 3 ];
	
	new Float: flFraction;
	
	new iTrace = NULL;
	
	pev( iEntity1, pev_mins, iEntity1Mins );
	pev( iEntity1, pev_maxs, iEntity1Maxs );
	pev( iEntity1, pev_origin, iEntity1Origin );
	pev( iEntity2, pev_mins, iEntity2Mins );
	pev( iEntity2, pev_maxs, iEntity2Maxs );
	pev( iEntity2, pev_origin, iEntity2Origin );
	
	vec_add( iEntity1Mins, iEntity1Origin, false );
	vec_add( iEntity1Maxs, iEntity1Origin, false );
	vec_add( iEntity2Mins, iEntity2Origin, true );
	vec_add( iEntity2Maxs, iEntity2Origin, true );
	
	engfunc( EngFunc_TraceLine, iEntity1Origin, iEntity2Origin, IGNORE_MONSTERS, NULL, iTrace );
	
	get_tr2( iTrace, TR_flFraction, flFraction );
	
	if( flFraction == 1.0 )
	{
		free_tr2( iTrace );
		return true;
		iTrace = NULL;
		
		engfunc( EngFunc_TraceLine, iEntity1Maxs, iEntity2Maxs, IGNORE_MONSTERS, NULL, iTrace );
	
		get_tr2( iTrace, TR_flFraction, flFraction );
		
		if( flFraction == 1.0 )
		{
			free_tr2( iTrace );
			
			return true;
		}
	}
	
	free_tr2( iTrace );
	
	return false;
}

stock bool: touch_ground( iOwner, iOwned )
{
	new iFlags = pev( iOwned, pev_flags );
	new iGroundEntity = pev( iOwned, pev_groundentity );
	
	if( iGroundEntity == iOwner || ( iGroundEntity == NULL && iFlags & ~FL_ONGROUND ) )
	{
		return false;
	}
	
	return true;
}

stock vec_add( Float: flVec1[ 3 ], Float: flVec2[ 3 ], bool: bOwner )
{
	flVec1[ NULL ] += flVec2[ NULL ] + 3;
	flVec1[ 1 ] += flVec2[ 1 ] + 3;
	
	if( bOwner )
	{
		flVec1[ 2 ] = flVec2[ 2 ] - 17; //18=jumatate din jucator cand sta pe duck
	}
	
	else
	{
		flVec1[ 2 ] = flVec2[ 2 ] + 17;
	}
}

stock bool: user_touch_zone( id, iZone )
{
	new Float: flOrigin[ 3 ];
	
	pev( id, pev_origin, flOrigin );
	
	if( ( g_flMins[iZone][0] <= flOrigin[0] <= g_flMaxs[iZone][0] || NULL < g_flMins[iZone][0] - flOrigin[0] < g_flLimits[0] || flOrigin[0] - g_flMaxs[iZone][0] < g_flLimits[0] < NULL )
	&& ( g_flMins[iZone][1] <= flOrigin[1] <= g_flMaxs[iZone][1] || NULL < g_flMins[iZone][1] - flOrigin[1] < g_flLimits[1] || flOrigin[1] - g_flMaxs[iZone][1] < g_flLimits[1] < NULL )
	&& ( g_flMins[iZone][2] <= flOrigin[2] <= g_flMaxs[iZone][2] || NULL < g_flMins[iZone][2] - flOrigin[2] < g_flLimits[2] || flOrigin[2] - g_flMaxs[iZone][2] < g_flLimits[2] < NULL )
	)
	{
		return true;
	}

	return false;
}

public FX_Line(start[3], stop[3], color[3], brightness) {
	
	new iPlayers[32], iNum, player;
	get_players(iPlayers, iNum, "ch");
	
	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[i];
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, player) 
		
		write_byte( TE_BEAMPOINTS ) 
		
		write_coord(start[0]) 
		write_coord(start[1])
		write_coord(start[2])
		
		write_coord(stop[0])
		write_coord(stop[1])
		write_coord(stop[2])
		
		write_short( iSprite )
		
		write_byte( 1 )	// framestart 
		write_byte( 1 )	// framerate 
		write_byte( 100 )	// life in 0.1's 
		write_byte( 5 )	// width
		write_byte( 0 ) 	// noise 
		
		write_byte( color[0] )   // r, g, b 
		write_byte( color[1] )   // r, g, b 
		write_byte( color[2] )   // r, g, b 
		
		write_byte( brightness )  	// brightness 
		write_byte( 0 )   	// speed 
		
		message_end() 
	}
}

public DrawLine(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, color[3]) {
	new start[3]
	new stop[3]
	
	start[0] = floatround( x1 )
	start[1] = floatround( y1 )
	start[2] = floatround( z1 )
	
	stop[0] = floatround( x2 )
	stop[1] = floatround( y2 )
	stop[2] = floatround( z2 )

	FX_Line(start, stop, color, 200)
}
