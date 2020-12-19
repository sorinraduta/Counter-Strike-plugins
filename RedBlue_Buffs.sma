#include <amxmodx>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>

#pragma semicolon 1

#define NO_TIME 0
#define TASK_BUFF 1234
#define BUFF_TIME 240
#define message_begin_fl(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_fl(%1) engfunc(EngFunc_WriteCoord, %1)

static const PLUGIN[ ]	= "RedBlue Buffs";
static const VERSION[ ]	= "1.0";
static const AUTHOR[ ]	= "Rap^^";

new const g_RedBlueBuff[ ]	= "RedBlue_Buff";
new const SPRITE_EXPLO[ ]	= "sprites/shockwave.spr";
new const SPRITE_RSPHERE[ ]	= "sprites/flares/rflare.spr";
new const SPRITE_BSPHERE[ ]	= "sprites/flares/bflare.spr";

new const Float: g_flBuffMins[3] = { -12.0, -12.0, 0.0 };
new const Float: g_flBuffMaxs[3] = { 12.0, 12.0, 12.0 };

enum _:Buffs
{
	RED_BUFF,
	BLUE_BUFF
};
new bool: is_user_buffed[33][Buffs];
//new bool: EntTouched[Buffs];

new Buff_Timer[33][Buffs];
new g_iBuffEnt[Buffs];
new ExplodeSpr;
new g_HudSync;

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for( new i = RED_BUFF; i <= BLUE_BUFF; i++ )
	{
		g_iBuffEnt[i] = create_entity("info_target");

		if( pev_valid(g_iBuffEnt[i]) )
		{
			entity_set_string(g_iBuffEnt[i], EV_SZ_classname, g_RedBlueBuff);
			set_pev(g_iBuffEnt[i], pev_movetype, MOVETYPE_NONE);
			set_pev(g_iBuffEnt[i], pev_solid, SOLID_NOT);

			entity_set_float(g_iBuffEnt[i], EV_FL_framerate,1.0);
			entity_set_int(g_iBuffEnt[i], EV_INT_rendermode, 5);
			entity_set_float(g_iBuffEnt[i], EV_FL_renderamt, 255.0);
			entity_set_float(g_iBuffEnt[i], EV_FL_scale, 1.5);

			entity_set_int(g_iBuffEnt[i], EV_INT_iuser1, i);

			fm_entity_set_size(g_iBuffEnt[i], g_flBuffMins, g_flBuffMaxs);

			engfunc(EngFunc_SetOrigin, g_iBuffEnt[i], Float: { 9999.0, 9999.0, 9999.0 });
		}
	}
	RegisterHam(Ham_Think,		"info_target",		"HamThink");
	RegisterHam(Ham_TakeDamage,	"player",		"HamTakeDamage");

	register_event("DeathMsg",	"EventDeathMsg",	"a");
	register_clcmd("say /buffs",	"cmdBuffs");

	g_HudSync = CreateHudSyncObj( );

	set_task(5.0, "SpawnBuffs");
}
public plugin_precache( )
{
	ExplodeSpr = precache_model(SPRITE_EXPLO);

	precache_model(SPRITE_RSPHERE);
	precache_model(SPRITE_BSPHERE);
}
public client_putinserver(id)
{
	is_user_buffed[id][RED_BUFF] = false;
	is_user_buffed[id][BLUE_BUFF] = false;

	Buff_Timer[id][RED_BUFF] = NO_TIME;
	Buff_Timer[id][BLUE_BUFF] = NO_TIME;
}
public cmdBuffs(id)
{
	new bool: isRed = true;
	new bool: isBlue = true;

	static Float: flBuffOrigin[3];
	pev(g_iBuffEnt[RED_BUFF], pev_origin, flBuffOrigin);

	if( flBuffOrigin[0] == 9999.0 )
		isRed = false;

	pev(g_iBuffEnt[BLUE_BUFF], pev_origin, flBuffOrigin);

	if( flBuffOrigin[0] == 9999.0 )
		isBlue = false;

	set_hudmessage(150, 0, 255, -1.0, 0.31, 0, 0.0, 0.5, 0.0, 0.5, 1);
	ShowSyncHudMsg(id, g_HudSync, "Red Buff - %s^nBlue Buff - %s", isRed ? "Nu e luat":"E luat", isBlue ? "Nu e luat":"E luat");
}
public BuffTime(id)
{
	id -= TASK_BUFF;

	if( Buff_Timer[id][RED_BUFF] == NO_TIME
	&& Buff_Timer[id][BLUE_BUFF] == NO_TIME )
	{
		if( task_exists(id) )
			remove_task(id);

		return PLUGIN_HANDLED;
	}
	if( is_user_buffed[id][RED_BUFF] )
	{
		Buff_Timer[id][RED_BUFF]--;

		if( Buff_Timer[id][RED_BUFF] == NO_TIME )
			RemoveBuff(id, RED_BUFF);
	}
	if( is_user_buffed[id][BLUE_BUFF] )
	{
		Buff_Timer[id][BLUE_BUFF]--;

		if( Buff_Timer[id][BLUE_BUFF] == NO_TIME )
			RemoveBuff(id, BLUE_BUFF);
	}
	set_task(1.0, "BuffTime", id + TASK_BUFF);

	return PLUGIN_HANDLED;
}
public EventDeathMsg( )
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);

	if( iKiller == 0 || iKiller == iVictim )
		return PLUGIN_CONTINUE;

	if( is_user_buffed[iVictim][RED_BUFF] )
	{
		Buff(iKiller, RED_BUFF, Buff_Timer[iVictim][RED_BUFF]);
		RemoveBuff(iVictim, RED_BUFF);
	}
	if( is_user_buffed[iVictim][BLUE_BUFF] )
	{
		Buff(iKiller, BLUE_BUFF, Buff_Timer[iVictim][BLUE_BUFF]);
		RemoveBuff(iVictim, BLUE_BUFF);
	}
	return PLUGIN_CONTINUE;
}
public HamThink(iEnt)
{
	if( !is_valid_ent(iEnt) )
		return HAM_IGNORED;

	if( !isBuff(iEnt) )
		return HAM_IGNORED;

	new id = -1, Float: flOrigin[3];
	pev(iEnt, pev_origin, flOrigin);

	RadiusEffect(iEnt, flOrigin);

	while( (id = engfunc(EngFunc_FindEntityInSphere, id, flOrigin, 70.0)) )
	{
		if( is_user_alive(id) )//!EntTouched[iEnt] )
		{
			new COLOR = entity_get_int(iEnt, EV_INT_iuser1);

			Buff(id, COLOR, BUFF_TIME);

			//EntTouched[iEnt] = true;

			engfunc(EngFunc_SetOrigin, iEnt, Float: { 9999.0, 9999.0, 9999.0 });
		}
	}
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime( ) + 1.0);

	return HAM_IGNORED;
}
public HamTakeDamage(id, inflictor, iAttacker, Float:damage, damagebits)
{
	if( !iAttacker || id == iAttacker || !is_user_connected(iAttacker) || !is_user_connected(id)
	|| get_user_team(id) == get_user_team(iAttacker) )
		return HAM_IGNORED;

	if( is_user_buffed[iAttacker][RED_BUFF] )
		damage *= 2;

	if( is_user_buffed[id][BLUE_BUFF] )
		damage /= 2;

	SetHamParamFloat(4, damage);

	return HAM_HANDLED;
}
public SpawnBuffs(id)
{
	static Float: flRandomOrigin[3];

	for( new i = RED_BUFF; i <= BLUE_BUFF; i++ )
	{
		engfunc(EngFunc_SetOrigin, g_iBuffEnt[i], Float: { 9999.0, 9999.0, 9999.0 });

		static Float: flBuffOrigin[3];
		pev(g_iBuffEnt[i], pev_origin, flBuffOrigin);

		while( flBuffOrigin[0] == 9999.0 )
		{
			flRandomOrigin[0] = random_float( -4800.0, 4800.0 );
			flRandomOrigin[1] = random_float( -4800.0, 4800.0 );
			flRandomOrigin[2] = random_float( -4800.0, 4800.0 );

			if( InMap(flRandomOrigin) )
			{
				engfunc(EngFunc_SetOrigin, g_iBuffEnt[i], flRandomOrigin);

				rirre_drop_to_floor(g_iBuffEnt[i]);

				pev(g_iBuffEnt[i], pev_origin, flBuffOrigin);

				flBuffOrigin[2] += 40.0;

				engfunc(EngFunc_SetOrigin, g_iBuffEnt[i], flBuffOrigin);

				entity_set_float(g_iBuffEnt[i], EV_FL_framerate,1.0);
				entity_set_int(g_iBuffEnt[i], EV_INT_rendermode, 5);
				entity_set_float(g_iBuffEnt[i], EV_FL_renderamt, 255.0);
				entity_set_float(g_iBuffEnt[i], EV_FL_scale, 1.1);

				if( i == RED_BUFF )
					entity_set_model(g_iBuffEnt[i], SPRITE_RSPHERE);

				else if( i == BLUE_BUFF )
					entity_set_model(g_iBuffEnt[i], SPRITE_BSPHERE);

				fm_entity_set_size(g_iBuffEnt[i], g_flBuffMins, g_flBuffMaxs);

				//EntTouched[i] = false;

				entity_set_float(g_iBuffEnt[i], EV_FL_nextthink, get_gametime( ) + 1.0);
			}
		}
	}
	set_task(5.0 * 60, "SpawnBuffs");

	return PLUGIN_HANDLED;
}
public RadiusEffect(iEnt, Float: flOrigin[3])
{
	new COLOR, RGB_Red = 0, RGB_Blue = 0;
	COLOR = entity_get_int(iEnt, EV_INT_iuser1);

	if( COLOR == RED_BUFF )
		RGB_Red = 255;

	else if( COLOR == BLUE_BUFF )
		RGB_Blue = 255;

	// smallest ring
	message_begin_fl(MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(flOrigin[0]); // x
	write_coord_fl(flOrigin[1]); // y
	write_coord_fl(flOrigin[2] - 30.0); // z
	write_coord_fl(flOrigin[0]); // x axis
	write_coord_fl(flOrigin[1]); // y axis
	write_coord_fl(flOrigin[2] + 50.0); // z axis
	write_short(ExplodeSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(15); // width
	write_byte(0); // noise
	write_byte(RGB_Red); // red
	write_byte(0); // green
	write_byte(RGB_Blue); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// medium ring
	message_begin_fl(MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(flOrigin[0]); // x
	write_coord_fl(flOrigin[1]); // y
	write_coord_fl(flOrigin[2] - 30.0); // z
	write_coord_fl(flOrigin[0]); // x axis
	write_coord_fl(flOrigin[1]); // y axis
	write_coord_fl(flOrigin[2] + 70.0); // z axis
	write_short(ExplodeSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(15); // width
	write_byte(0); // noise
	write_byte(RGB_Red); // red
	write_byte(0); // green
	write_byte(RGB_Blue); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end( );

	// largest ring
	message_begin_fl(MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(flOrigin[0]); // x
	write_coord_fl(flOrigin[1]); // y
	write_coord_fl(flOrigin[2] - 30.0); // z
	write_coord_fl(flOrigin[0]); // x axis
	write_coord_fl(flOrigin[1]); // y axis
	write_coord_fl(flOrigin[2] + 90.0); // z axis
	write_short(ExplodeSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(15); // width
	write_byte(0); // noise
	write_byte(RGB_Red); // red
	write_byte(0); // green
	write_byte(RGB_Blue); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end( );
}
public Buff(id, COLOR, Time)
{
	new RGBR = 0, RGBB = 0;

	switch( COLOR )
	{
		case RED_BUFF:
		{
			if( Time < Buff_Timer[id][RED_BUFF] )
				return PLUGIN_HANDLED;

			if( is_user_buffed[id][BLUE_BUFF] )
			{
				RGBR = 150;
				RGBB = 255;
			}
			else
				RGBR = 255;

			Buff_Timer[id][RED_BUFF] = Time;
			is_user_buffed[id][RED_BUFF] = true;
		}
		case BLUE_BUFF:
		{
			if( Time < Buff_Timer[id][BLUE_BUFF] )
				return PLUGIN_HANDLED;

			if( is_user_buffed[id][RED_BUFF] )
			{
				RGBR = 150;
				RGBB = 255;
			}
			else
				RGBB = 255;

			Buff_Timer[id][BLUE_BUFF] = Time;
			is_user_buffed[id][BLUE_BUFF] = true;
		}
	}
	fm_set_user_rendering(id, kRenderFxGlowShell, RGBR, 0, RGBB, kRenderNormal, 10);

	BuffTime(id + TASK_BUFF);

	return PLUGIN_HANDLED;
}
public RemoveBuff(id, COLOR)
{
	is_user_buffed[id][COLOR] = false;
	Buff_Timer[id][COLOR] = NO_TIME;

	fm_set_user_rendering(id);

	if( is_user_buffed[id][RED_BUFF] )
		fm_set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 10);

	else if( is_user_buffed[id][BLUE_BUFF] )
		fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 10);

	return PLUGIN_HANDLED;
}
stock InMap(Float: flOrigin[3])
{
	engfunc(EngFunc_TraceHull, flOrigin, flOrigin, IGNORE_MONSTERS, HULL_LARGE, 0, 0);

	return (!get_tr2(0, TR_StartSolid) && fm_point_contents(flOrigin) == CONTENTS_EMPTY);
}
stock rirre_drop_to_floor(iEnt)
{
	static Float: flStart[3], Float: flEnd[3];
	pev(iEnt, pev_origin, flStart);
	flEnd = flStart;
	flEnd[2] -= 3000.0;

	new iTr = create_tr2( );
	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, iEnt, iTr);
	get_tr2(iTr, TR_vecEndPos, flEnd);
	free_tr2(iTr);

	return engfunc(EngFunc_SetOrigin, iEnt, flEnd);
}
bool: isBuff(iEnt)
{
	if( is_valid_ent(iEnt) )
	{
		new iEntCN[32];
		entity_get_string(iEnt, EV_SZ_classname, iEntCN, 32);

		if( equal(iEntCN, g_RedBlueBuff) )
		{
			return true;
		}
	}
	return false;
}
stock get_name(id)
{
	new szName[32];
	get_user_name(id, szName, sizeof szName -1);

	return szName;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
