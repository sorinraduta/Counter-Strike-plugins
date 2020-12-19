#include < amxmodx >
#include < fakemeta >
#include < utilities >

#pragma semicolon 1


static const

	PLUGIN[ ]	= "Bhop_Race",
	VERSION[ ]	= "1.0",
	AUTHOR[ ]	= "Rap^^";


new const g_szWallClassName[ ] =	"ArenaWalls";
new const g_szWallSprite[ ] =	"sprites/popdog.spr";


public plugin_precache( )
{
	precache_model( g_szWallSprite );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_clcmd( "say /createarena", "ClCmdCreateArena" );
}

public ClCmdCreateArena( id )
{
	new Float: flOrigin[ 3 ];
	
	pev( id, pev_origin, flOrigin );
	
	flOrigin[ 1 ] += 300.0;
	
	CreateWall( flOrigin, { 0.0, 90.0, 0.0 }, 1.0, g_szWallSprite );
	
	pev( id, pev_origin, flOrigin );
	
	flOrigin[ 1 ] -= 300.0;
	
	CreateWall( flOrigin, { 0.0, -90.0, 0.0 }, 1.0, g_szWallSprite );
	
	pev( id, pev_origin, flOrigin );
	
	flOrigin[ 2 ] += 200.0;
	
	CreateWall( flOrigin, { -90.0, 0.0, 0.0 }, 1.0, g_szWallSprite );
	
	pev( id, pev_origin, flOrigin );
	
	flOrigin[ 2 ] -= 200.0;
	
	CreateWall( flOrigin, { 90.0, 0.0, 0.0 }, 1.0, g_szWallSprite );
	
	pev( id, pev_origin, flOrigin );
	
	flOrigin[ 0 ] += 200.0;
	
	CreateWall( flOrigin, { 0.0, 0.0, 0.0 }, 1.0, g_szWallSprite );
	
	pev( id, pev_origin, flOrigin );
	
	flOrigin[ 0 ] -= 200.0;
	
	CreateWall( flOrigin, { 180.0, 0.0, 0.0 }, 1.0, g_szWallSprite );
}

public CreateWall( Float: flOrigin[ 3 ], Float: flAngle[ 3 ], Float: flScale, const szSprite[ ] )
{
	new iEntity = CreateEntity( );
	
	set_pev( iEntity, pev_classname, g_szWallClassName ); 
	set_pev( iEntity, pev_origin, flOrigin );
	set_pev( iEntity, pev_angles, flAngle );
	set_pev( iEntity, pev_scale, flScale );
	
	engfunc( EngFunc_SetModel, iEntity, szSprite );
}