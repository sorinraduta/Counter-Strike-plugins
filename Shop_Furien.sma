#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <engine>
#include <ColorChat>

#define PLUGIN "Furin Shop"
#define VERSION "1.0"
#define AUTHOR "Rap"

#define DMG_GRENADE (1<<24)

#define PISTOL_WEAPONS_BIT	(1<<CSW_GLOCK18|1<<CSW_USP|1<<CSW_DEAGLE|1<<CSW_P228|1<<CSW_FIVESEVEN|1<<CSW_ELITE)
#define SHOTGUN_WEAPONS_BIT	(1<<CSW_M3|1<<CSW_XM1014)
#define SUBMACHINE_WEAPONS_BIT	(1<<CSW_TMP|1<<CSW_MAC10|1<<CSW_MP5NAVY|1<<CSW_UMP45|1<<CSW_P90)
#define RIFLE_WEAPONS_BIT	(1<<CSW_FAMAS|1<<CSW_GALIL|1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_M4A1|1<<CSW_SG550|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_AWP|1<<CSW_G3SG1)
#define MACHINE_WEAPONS_BIT	(1<<CSW_M249)

#define PRIMARY_WEAPONS_BIT	(SHOTGUN_WEAPONS_BIT|SUBMACHINE_WEAPONS_BIT|RIFLE_WEAPONS_BIT|MACHINE_WEAPONS_BIT)
#define SECONDARY_WEAPONS_BIT	(PISTOL_WEAPONS_BIT)

#define IsPrimaryWeapon(%1)	((1<<%1) & PRIMARY_WEAPONS_BIT)
#define IsSecondaryWeapon(%1)	((1<<%1) & SECONDARY_WEAPONS_BIT)

#define TASK_START 111111

#define HOSTNAME	"furien.disconnect.ro"
#define IP		"xx.xx.xx.xx"

#pragma semicolon 1

new const g_szLaserSprite[ ] = "sprites/zbeam4.spr";
new const g_szParaModel[ ] = "models/parachute.mdl";

new g_iLaserSprite;
new g_iParachute[33];
new user_knife[33];
new user_wpn[33];
new FurienClass[33];
new AntiFurienClass[33];
new GrenTime[33];

new bool: HasLaser[33];
new bool: HasParachute[33];
new bool: choosed[33];
new bool: RoundStarted = false;

new Float: g_flFrame[33];
new Float: g_Gravity[33];
new Float: g_flFallSpeed = -100.0;

new NextFurienClass[33];
new NextAntiFurienClass[33];

new superknife[55];
new ultraknife[55];
new megaknife[55];

new m4a1wpn[55];
new ak47wpn[55];
new mp5wpn[55];
new shotgunwpn[55];


public plugin_init( )
{
	new szHostName[101], szIP[51];

	get_cvar_string("hostname", szHostName, sizeof(szHostName) - 1);
	get_user_ip(0, szIP, sizeof(szIP) - 1, 1);

	if( containi(szHostName, HOSTNAME) != -1 && equal(IP, szIP) )
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);

		register_clcmd("say /class", "cmdClass");

		RegisterHam(Ham_TakeDamage,	"player",	"HamTakeDamage");
		RegisterHam(Ham_Spawn,		"player",	"HamPlayerSpawn",	1);

		register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
		register_event("CurWeapon", "EventCurWeapon", "be", "1=1");
		register_event("DeathMsg", "EventDeathMsg", "a");

		register_clcmd("say /shop", "cmdShop");
	}
	else
		pause("ade");
}
public plugin_precache( )
{
	g_iLaserSprite = precache_model(g_szLaserSprite);
	precache_model(g_szParaModel);

	formatex(superknife, sizeof(superknife) - 1, "models/super_knife.mdl");
	precache_model(superknife);

	formatex(ultraknife, sizeof(ultraknife) - 1, "models/ultra_knife.mdl");
	precache_model(ultraknife);

	formatex(megaknife, sizeof(megaknife) - 1, "models/mega_knife.mdl");
	precache_model(megaknife);

	formatex(m4a1wpn, sizeof(m4a1wpn) - 1, "models/golden_m4a1.mdl");
	precache_model(m4a1wpn);

	formatex(ak47wpn, sizeof(ak47wpn) - 1, "models/golden_ak47.mdl");
	precache_model(ak47wpn);

	formatex(mp5wpn, sizeof(mp5wpn) - 1, "models/golden_mp5.mdl");
	precache_model(mp5wpn);

	formatex(shotgunwpn, sizeof(shotgunwpn) - 1, "models/golden_shotgun.mdl");
	precache_model(shotgunwpn);

	precache_model(g_szParaModel);
}
public client_connect(id)
{
	FurienClass[id] = 1;
	AntiFurienClass[id] = 1;

	NextFurienClass[id] = 1;
	NextAntiFurienClass[id] = 1;
	choosed[id] = false;
	HasParachute[id] = false;
	HasLaser[id] = false;
	user_knife[id] = 0;
	user_wpn[id] = 0;
}
public EventCurWeapon(id)
{
	new Weapon = read_data(2);

	if( Weapon == CSW_KNIFE )
		switch(user_knife[id])
		{
			case 1: entity_set_string(id, EV_SZ_viewmodel, superknife);
			case 2: entity_set_string(id, EV_SZ_viewmodel, ultraknife);
			case 3: entity_set_string(id, EV_SZ_viewmodel, megaknife);
		}

	else
		switch(user_wpn[id])
		{
			case 1: if( Weapon == CSW_AK47 )	entity_set_string(id, EV_SZ_viewmodel, ak47wpn);
			case 2: if( Weapon == CSW_M4A1 )	entity_set_string(id, EV_SZ_viewmodel, m4a1wpn);
			case 3: if( Weapon == CSW_MP5NAVY) entity_set_string(id, EV_SZ_viewmodel, mp5wpn);
			case 4: if( Weapon == CSW_XM1014 ) entity_set_string(id, EV_SZ_viewmodel, shotgunwpn);
		}
	switch( get_user_team(id) )
	{
		case 1:
		{
				switch( FurienClass[id] )
				{
					case 1: set_user_maxspeed(id, 720.0);
					case 3: set_user_maxspeed(id, 850.0);
					case 4: set_user_maxspeed(id, 610.0);
					case 5: set_user_maxspeed(id, 720.0);
				}
		}
		case 2:
		{
				switch( AntiFurienClass[id] )
				{
					case 1: set_user_maxspeed(id, 270.0);
					case 3: set_user_maxspeed(id, 350.0);
					case 4: set_user_maxspeed(id, 220.0);
					case 5: set_user_maxspeed(id, 270.0);
				}
		}
	}
	return PLUGIN_HANDLED;
}
public EventDeathMsg( )
{
	new iVictim = read_data(2);

	user_knife[iVictim] = 0;
	user_wpn[iVictim] = 0;
	set_user_hitzones(0, 0, 255);
	HasParachute[iVictim] = false;
	HasLaser[iVictim] = false;
}
public EventNewRound( )
{
	if( task_exists(TASK_START) )
		remove_task(TASK_START);

	RoundStarted = false;

	set_task(get_cvar_float("mp_freezetime"), "taskStartR", TASK_START);
}
public client_PreThink(id)
{
	if( !is_user_alive(id) )
		return PLUGIN_CONTINUE;

	if( HasParachute[id] )
	{
		static const info_target[] = "info_target";
		static iEnt, Float:flFrame;
		iEnt = g_iParachute[id];
		flFrame = g_flFrame[id];

		if( iEnt > 0 && entity_get_int(id, EV_INT_flags) & FL_ONGROUND )
		{
			if( get_user_gravity(id) == 0.1 )
			{
				set_user_gravity(id, g_Gravity[id]);
			}

			if( entity_get_int(iEnt, EV_INT_sequence) != 2 )
			{
				entity_set_int(iEnt, EV_INT_sequence, 2);
				entity_set_int(iEnt, EV_INT_gaitsequence, 1);

				entity_set_float(iEnt, EV_FL_frame, 0.0);
				g_flFrame[id] = 0.0;

				entity_set_float(iEnt, EV_FL_animtime, 0.0);
				entity_set_float(iEnt, EV_FL_framerate, 0.0);
				return PLUGIN_HANDLED;
			}

			flFrame += 2.0;
			entity_set_float(iEnt, EV_FL_frame, flFrame);

			if ( flFrame > 254.0 )
			{
				entity_set_int(iEnt, EV_INT_flags, FL_KILLME);
				iEnt = 0;
			}
		}
		else if( entity_get_int(id, EV_INT_button) & IN_USE )
		{
			new Float:velocity[3];
			entity_get_vector(id, EV_VEC_velocity, velocity);

			if ( velocity[2] < 0.0 )
			{
				if ( iEnt <= 0 )
				{
					iEnt = create_entity(info_target);
					if( iEnt > 0 )
					{
						entity_set_edict(iEnt, EV_ENT_aiment, id);
						entity_set_edict(iEnt, EV_ENT_owner, id);
						entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FOLLOW);
						entity_set_model(iEnt, g_szParaModel);
						entity_set_int(iEnt, EV_INT_sequence, 0);
						entity_set_int(iEnt, EV_INT_gaitsequence, 1);

						flFrame = 0.0;
						entity_set_float(iEnt, EV_FL_frame, 0.0);
					}
				}

				if ( iEnt > 0 )
				{
					entity_set_int(id, EV_INT_sequence, 3);
					entity_set_int(id, EV_INT_gaitsequence, 1);
					entity_set_float(id, EV_FL_frame, 1.0);
					entity_set_float(id, EV_FL_animtime, 100.0);
					entity_set_float(id, EV_FL_framerate, 1.0);
					set_user_gravity(id, 0.1);

					velocity[2] += 40;
					velocity[2] = (velocity[2] < g_flFallSpeed) ? velocity[2] : g_flFallSpeed;
					entity_set_vector(id, EV_VEC_velocity, velocity);

					if ( entity_get_int(iEnt, EV_INT_sequence) == 0 )
					{
						flFrame += 1.0;
						entity_set_float(iEnt, EV_FL_frame, flFrame);

						if ( flFrame > 100.0 )
						{
							entity_set_float(iEnt, EV_FL_animtime, 120.0);
							entity_set_float(iEnt, EV_FL_framerate, 0.4);
							entity_set_int(iEnt, EV_INT_sequence, 1);
							entity_set_int(iEnt, EV_INT_gaitsequence, 1);
							flFrame = 0.0;
							entity_set_float(iEnt, EV_FL_frame, 0.0);
						}
					}
				}
			}
			else if ( iEnt > 0 )
			{
				entity_set_int(iEnt, EV_INT_flags, FL_KILLME);
				set_user_gravity(id, g_Gravity[id]);
				iEnt = 0;
			}
		}

		else if( iEnt > 0 && get_user_oldbutton(id) & IN_USE )
		{
			entity_set_int(iEnt, EV_INT_flags, FL_KILLME);
			set_user_gravity(id, g_Gravity[id]);
			iEnt = 0;
		}
		g_iParachute[id] = iEnt;
		g_flFrame[id] = flFrame;
	}
	if( cs_get_user_team(id) == CS_TEAM_CT )
	{
		if( HasLaser[id] )
		{
			new iWeapon = get_user_weapon(id);

			if( IsPrimaryWeapon(iWeapon) || IsSecondaryWeapon(iWeapon) )
			{
				static iTarget, iBody, iRed, iGreen, iBlue = 0;

				get_user_aiming(id, iTarget, iBody);

				if( is_user_alive(iTarget) && cs_get_user_team(iTarget) == CS_TEAM_T )
				{
					iRed = 255;
					iGreen = 0;
				}
				else
				{
					iRed = 0;
					iGreen = 255;
				}
				static iOrigin[3];
				get_user_origin(id, iOrigin, 3);

				message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_BEAMENTPOINT);
				write_short(id | 0x1000);
				write_coord(iOrigin[0]);
				write_coord(iOrigin[1]);
				write_coord(iOrigin[2]);
				write_short(g_iLaserSprite);
				write_byte(1);
				write_byte(10);
				write_byte(1);
				write_byte(5);
				write_byte(0);
				write_byte(iRed);
				write_byte(iGreen);
				write_byte(iBlue);
				write_byte(150);
				write_byte(25);
				message_end( );
			}
		}
	}
	return PLUGIN_CONTINUE;
}
public HamTakeDamage( id, iInflictor, iAttacker, Float: flDamage, iDamageBits )
{
	if( !iAttacker || id == iAttacker || !is_user_connected( iAttacker ) || !is_user_connected( id )
	|| get_user_team( id ) == get_user_team( iAttacker ) || iDamageBits & DMG_GRENADE )
	{
		return HAM_IGNORED;
	}

	switch( get_user_team(iAttacker) )
	{
		case 1:
		{
			switch( FurienClass[iAttacker] )
			{
				case 2:
				{
					if( user_knife[iAttacker] > 0 )
						SetHamParamFloat(4, damage * float(user_knife[iAttacker] + 2));

					else
						SetHamParamFloat(4, damage * 2.0);
				}
				case 4:
				{
					if( user_knife[iAttacker] >= 2 )
						SetHamParamFloat(4, damage * float(user_knife[iAttacker] + 2));

					else
						SetHamParamFloat(4, damage * 3.0);
				}
				case 5:
				{
					if( user_knife[iAttacker] == 3 )
						SetHamParamFloat(4, damage * 5.0);

					else
						SetHamParamFloat(4, damage * 4.0);
				}
				default:
			{
				if( user_knife[iAttacker] > 0 )
					SetHamParamFloat(4, damage * float(user_knife[iAttacker] + 2));
				}
			}
		}
		case 2:
		{
			switch( AntiFurienClass[iAttacker] )
			{
				case 2:
				{
					if( user_wpn[iAttacker]  > 0 )
						SetHamParamFloat(4, damage * 3.0);

					else
						SetHamParamFloat(4, damage * 2.0);
				}
				case 4: SetHamParamFloat(4, damage * 3.0);
					case 5: SetHamParamFloat(4, damage * 4.0);
					default:
			{
				if( user_wpn[iAttacker]  > 0 )
					SetHamParamFloat(4, damage * 3.0);
				}
			}
		}
	}
	return HAM_HANDLED;
}
public HamPlayerSpawn(id)
{
	if( !RoundStarted )
		set_task(get_cvar_float("mp_freezetime") + 0.2, "PlayerSpawn", id);

	else
		set_task(0.2, "PlayerSpawn", id);

	return HAM_IGNORED;
}
public PlayerSpawn(id)
{
	if( !is_user_alive(id) )
		return PLUGIN_HANDLED;

	if( task_exists(id) )
		remove_task(id);

	GrenTime[id] = 60;
	g_Gravity[id] = get_cvar_float("furien_speed")/800;


	if( get_user_team(id) == 1 )
	{
		FurienClass[id] = NextFurienClass[id];

		HasParachute[id] = false;
		HasLaser[id] = false;

		if( is_user_vip(id) )
		{
			if( user_knife[id] == 0 )
				user_knife[id] = 3;

			entity_set_string(id, EV_SZ_viewmodel, megaknife);

			new health = get_user_health(id);
			new armor = get_user_armor(id);

			set_user_health(id, health + 100);
			cs_set_user_armor(id, armor + 100, CS_ARMOR_VESTHELM);

			set_task(10.0, "taskGrenade", id, _, _, "b");
			set_task(1.0, "taskRegen", id, _, _, "b");
		}
		SetFurinAttrib(id);
		user_wpn[id] = 0;
	}
	else if( get_user_team(id) == 2 )
	{
		AntiFurienClass[id] = NextAntiFurienClass[id];

		SetAntiFurinAttrib(id);
		user_knife[id] = 0;

		choosed[id] = true;

		if( is_user_vip(id) )
		{
			HasParachute[id] = true;
			HasLaser[id] = true;
			choosed[id] = false;
			set_task(10.0, "taskGrenade", id, _, _, "b");
			set_task(1.0, "taskRegen", id, _, _, "b");
		}
	}
	return PLUGIN_CONTINUE;
}
public cmdShop(id)
{
	new menu = menu_create("\rShop Menu", "ShopHandler");

	if( cs_get_user_team(id) == CS_TEAM_T )
	{
		menu_additem(menu, "Furien special weapons", "1");
		menu_additem(menu, "Furien HP", "2");
		menu_additem(menu, "Furien Armor", "3");
		menu_additem(menu, "Furien Items", "4");
	}
	else if( cs_get_user_team(id) == CS_TEAM_CT )
	{
		menu_additem(menu, "AntiFurien special weapons", "1");
		menu_additem(menu, "AntiFurien HP", "2");
		menu_additem(menu, "AntiFurien Armor", "3");
		menu_additem(menu, "AntiFurien Items", "4");
	}
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}
public ShopHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	switch( Key )
	{
		case 1: WeaponMenu(id);
			case 2: HPMenu(id);
			case 3: ArmorMenu(id);
			case 4: ItemsMenu(id);
		}
	return PLUGIN_HANDLED;
}
public WeaponMenu(id)
{
	new menu;

	if( cs_get_user_team(id) == CS_TEAM_T )
	{
		menu = menu_create("\rWeapon Menu", "WeapTHandler");

		menu_additem(menu, "Super Knife [\r9000\w$]", "1");
		menu_additem(menu, "Ultra Knife [\r13000\w$]", "2");
		menu_additem(menu, "MEGA Knife [\r16000\w$]", "3");
	}
	else if( cs_get_user_team(id) == CS_TEAM_CT )
	{
		menu = menu_create("\rWeapon Menu", "WeapCTHandler");

		menu_additem(menu, "Golden AK47 [\r16000\w$]", "1");
		menu_additem(menu, "Golden M4A1 [\r16000\w$]", "2");
		menu_additem(menu, "Golden MP5NAVY [\r12000\w$]", "3");
		menu_additem(menu, "Golden ShotGun [\r14000\w$]", "4");
	}
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}
public WeapTHandler(id, menu, item)
{
	if( item == MENU_EXIT || get_user_team(id) != 1 )
	{
		cmdShop(id);

		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	new money = cs_get_user_money(id);

	switch( Key )
	{
		case 1:
		{
			if( cs_get_user_money(id) < 9000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 9000, 1);
			user_knife[id] = 1;

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if( cs_get_user_money(id) < 13000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 13000, 1);
			user_knife[id] = 2;

			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( cs_get_user_money(id) < 16000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 16000, 1);
			user_knife[id] = 3;

			return PLUGIN_HANDLED;
		}
	}
	WeaponMenu(id);

	return PLUGIN_HANDLED;
}
public WeapCTHandler(id, menu, item)
{
	if( item == MENU_EXIT || get_user_team(id) != 2 )
	{
		cmdShop(id);

		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	new money = cs_get_user_money(id);

	switch( Key )
	{
		case 1:
		{
			if( cs_get_user_money(id) < 16000 && choosed[id] )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			if( choosed[id] )
				cs_set_user_money(id, money - 16000, 1);

			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 300);
			user_wpn[id] = 1;
			choosed[id] = true;

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if( cs_get_user_money(id) < 16000 && choosed[id] )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			if( choosed[id] )
				cs_set_user_money(id, money - 16000, 1);

			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 300);
			user_wpn[id] = 2;
			choosed[id] = true;

			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( cs_get_user_money(id) < 12000 && choosed[id] )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			if( choosed[id] )
				cs_set_user_money(id, money - 12000, 1);

			give_item(id, "weapon_mp5navy");
			cs_set_user_bpammo(id, CSW_MP5NAVY, 300);
			user_wpn[id] = 3;
			choosed[id] = true;

			return PLUGIN_HANDLED;
		}
		case 4:
		{
			if( cs_get_user_money(id) < 14000 && choosed[id] )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			if( choosed[id] )
				cs_set_user_money(id, money - 14000, 1);

			cs_set_user_money(id, money - 14000, 1);
			give_item(id, "weapon_xm1014");
			cs_set_user_bpammo(id, CSW_XM1014, 300);
			user_wpn[id] = 4;
			choosed[id] = true;

			return PLUGIN_HANDLED;
		}
	}
	WeaponMenu(id);

	return PLUGIN_HANDLED;
}
public HPMenu(id)
{
	new menu;

	if( cs_get_user_team(id) == CS_TEAM_T )
		menu = menu_create("\rFurien HP", "HpHandler");

	else if( cs_get_user_team(id) == CS_TEAM_CT )
		menu = menu_create("\rAntiFurien HP", "HpHandler");


	menu_additem(menu, "\r25 \wHP [\r2.500\w$]", "1");
	menu_additem(menu, "\r50 \wHP [\r5.000\w$]", "2");
	menu_additem(menu, "\r75 \wHP [\r7.500\w$]", "3");
	menu_additem(menu, "\r100 \wHP [\r10.000\w$]", "4");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}
public HpHandler(id, menu, item)
{
	if( item == MENU_EXIT || !is_user_alive(id) )
	{
		cmdShop(id);

		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	new money = cs_get_user_money(id);
	new health = get_user_health(id);

	switch( Key )
	{
		case 1:
		{
			if( cs_get_user_money(id) < 2500 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 2500, 1);

			set_user_health(id, health + 25);

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if( cs_get_user_money(id) < 5000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 5000, 1);

			set_user_health(id, health + 50);

			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( cs_get_user_money(id) < 7500 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 7500, 1);

			set_user_health(id, health + 75);

			return PLUGIN_HANDLED;
		}
		case 4:
		{
			if( cs_get_user_money(id) < 10000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 10000, 1);

			set_user_health(id, health + 100);

			return PLUGIN_HANDLED;
		}
	}
	HPMenu(id);

	return PLUGIN_HANDLED;
}
public ArmorMenu(id)
{
	new menu;

	if( cs_get_user_team(id) == CS_TEAM_T )
		menu = menu_create("\rFurien Armor", "ArmorHandler");

	else if( cs_get_user_team(id) == CS_TEAM_CT )
		menu = menu_create("\rAntiFurien Armor", "ArmorHandler");


	menu_additem(menu, "\r25 \wAP [\r500\w$]", "1");
	menu_additem(menu, "\r50 \wAP [\r1.000\w$]", "2");
	menu_additem(menu, "\r75 \wAP [\r2.500\w$]", "3");
	menu_additem(menu, "\r100 \wAP [\r3.000\w$]", "4");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}
public ArmorHandler(id, menu, item)
{
	if( item == MENU_EXIT || !is_user_alive(id) )
	{
		cmdShop(id);

		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	new money = cs_get_user_money(id);
	new armor = get_user_armor(id);

	switch( Key )
	{
		case 1:
		{
			if( cs_get_user_money(id) < 500 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 500, 1);

			cs_set_user_armor(id, clamp(armor + 25, 1, 250), CS_ARMOR_VESTHELM);

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if( cs_get_user_money(id) < 1000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 1000, 1);

			cs_set_user_armor(id, clamp(armor + 50, 1, 250), CS_ARMOR_VESTHELM);

			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( cs_get_user_money(id) < 2500 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 2500, 1);

			cs_set_user_armor(id, clamp(armor + 75, 1, 250), CS_ARMOR_VESTHELM);

			return PLUGIN_HANDLED;
		}
		case 4:
		{
			if( cs_get_user_money(id) < 3000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 3000, 1);

			cs_set_user_armor(id, clamp(armor + 100, 1, 250), CS_ARMOR_VESTHELM);

			return PLUGIN_HANDLED;
		}

	}
	ArmorMenu(id);

	return PLUGIN_HANDLED;
}
public ItemsMenu(id)
{
	new menu;

	if( cs_get_user_team(id) == CS_TEAM_T )
	{
		menu = menu_create("\rItems Menu", "ItemsTHandler");

		menu_additem(menu, "HE Grenade [\r2.200\w$]", "1");
		menu_additem(menu, "FlashBang [\r1.600\w$]", "2");
		menu_additem(menu, "SmokeGrenade [\r1.200\w$]", "3");
		menu_additem(menu, "Titanium Helm [\r12.000\w$]", "4");
	}
	else if( cs_get_user_team(id) == CS_TEAM_CT )
	{
		menu = menu_create("\rItems Menu", "ItemsCTHandler");

		menu_additem(menu, "Defuse Kit [\r500\w$]", "1");
		menu_additem(menu, "Parasuta [\r1.000\w$]", "2");
		menu_additem(menu, "Xray Scanner [\r14.000\w$]", "3");
		menu_additem(menu, "Respawn [\r16.000\w$]", "4");
		menu_additem(menu, "HE Grenade [\r2.200\w$]", "5");
		menu_additem(menu, "FlashBang [\r1.600\w$]", "6");
		menu_additem(menu, "SmokeGrenade [\r1.200\w$]", "7");
		menu_additem(menu, "Titanium Helm [\r6.000\w$]", "8");
	}
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}
public ItemsTHandler(id, menu, item)
{
	if( item == MENU_EXIT  || get_user_team(id) != 1 )
	{
		cmdShop(id);

		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	new money = cs_get_user_money(id);

	switch( Key )
	{
		case 1:
		{
			if( cs_get_user_money(id) < 2200 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 2200, 1);
			give_item(id, "weapon_hegrenade");

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if( cs_get_user_money(id) < 1600 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 1600, 1);
			give_item(id, "weapon_flashbang");

			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( cs_get_user_money(id) < 1200 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 1200, 1);
			give_item(id, "weapon_smokegrenade");

			return PLUGIN_HANDLED;
		}
		case 4:
		{
			if( cs_get_user_money(id) < 12000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 12000, 1);
			set_user_hitzones(0, 0, 253);

			return PLUGIN_HANDLED;
		}
	}
	ItemsMenu(id);

	return PLUGIN_HANDLED;
}
public ItemsCTHandler(id, menu, item)
{
	if( item == MENU_EXIT  || get_user_team(id) != 2 )
	{
		cmdShop(id);

		return PLUGIN_HANDLED;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);

	new money = cs_get_user_money(id);

	switch( Key )
	{
		case 1:
		{
			if( cs_get_user_money(id) < 500 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 500, 1);

			cs_set_user_defuse(id, 1, 255, 0, 100);

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if( cs_get_user_money(id) < 1000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 1000, 1);

			HasParachute[id] = true;

			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( cs_get_user_money(id) < 14000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 14000, 1);

			HasLaser[id] = true;

			return PLUGIN_HANDLED;
		}
		case 4:
		{
			if( cs_get_user_money(id) < 16000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 16000, 1);

			if( !is_user_alive(id) )
				ExecuteHamB(Ham_CS_RoundRespawn, id);

			return PLUGIN_HANDLED;
		}
		case 5:
		{
			if( cs_get_user_money(id) < 2200 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 2200, 1);
			give_item(id, "weapon_hegrenade");

			return PLUGIN_HANDLED;
		}
		case 6:
		{
			if( cs_get_user_money(id) < 1600 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 1600, 1);
			give_item(id, "weapon_flashbang");

			return PLUGIN_HANDLED;
		}
		case 7:
		{
			if( cs_get_user_money(id) < 1200 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 1200, 1);
			give_item(id, "weapon_smokegrenade");

			return PLUGIN_HANDLED;
		}
		case 8:
		{
			if( cs_get_user_money(id) < 6000 )
			{
				client_print(id, print_center, "You don't have enough money");

				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, money - 6000, 1);
			set_user_hitzones(0, 0, 253);

			return PLUGIN_HANDLED;
		}
	}
	ItemsMenu(id);

	return PLUGIN_HANDLED;
}
public SetFurinAttrib(id)
{

	switch( FurienClass[id] )
	{
		case 1:
		{
			set_user_health(id, 100);
			set_user_maxspeed(id, 720.0);

			if( !is_user_vip(id) )
				set_task(1.0, "taskRegHP", id, _, _, "b");
		}
		case 2:
		{
			set_user_health(id, 170);
			set_user_gravity(id, 0.4875);	//390

			g_Gravity[id] = 0.4875;
		}
		case 3:
		{
			set_user_health(id, 120);
			set_user_maxspeed(id, 850.0);
			set_user_gravity(id, 0.4);	//320

			g_Gravity[id] = 0.4;
		}
		case 4:
		{
			set_user_health(id, 220);
			set_user_maxspeed(id, 610.0);
			set_user_gravity(id, 0.6625);	//530

			g_Gravity[id] = 0.6625;
		}
		case 5:
		{
			set_user_health(id, 140);
			set_user_maxspeed(id, 720.0);
			set_user_gravity(id, 0.525);	//420

			g_Gravity[id] = 0.525;
		}
	}
}
public SetAntiFurinAttrib(id)
{
	switch( AntiFurienClass[id] )
	{
		case 1:
		{
			set_user_health(id, 100);
			set_user_maxspeed(id, 270.0);

			if( !is_user_vip(id) )
				set_task(1.0, "taskRegHP", id, _, _, "b");
		}
		case 2:
		{
			set_user_health(id, 170);
			set_user_gravity(id, 0.975);	//780

			g_Gravity[id] = 0.975;
		}
		case 3:
		{
			set_user_health(id, 90);
			set_user_maxspeed(id, 360.0);
			set_user_gravity(id, 0.8125);	//650

			g_Gravity[id] = 0.8125;
		}
		case 4:
		{
			set_user_health(id, 200);
			set_user_maxspeed(id, 350.0);
			set_user_gravity(id, 1.05);	//840

			g_Gravity[id] = 1.05;
		}
		case 5:
		{
			set_user_health(id, 160);
			set_user_maxspeed(id, 270.0);
			set_user_gravity(id, 1.025);	//820

			g_Gravity[id] = 1.025;
		}
	}
}
public taskRegHP(id)
{
	if( is_user_alive(id) )
	{
		new health = get_user_health(id);

		set_user_health(id, clamp(health + 1, 1, 100));
	}
	else
		remove_task(id);

}
public taskRegen(id)
{
	if( is_user_alive(id) )
	{
		new health = get_user_health(id);

		set_user_health(id, clamp(health + 1, 1, 250));
	}
	else
		remove_task(id);
}
public cmdClass(id)
{
	if( cs_get_user_team(id) == CS_TEAM_T )
		ShowMenuF(id);

	if( cs_get_user_team(id) == CS_TEAM_CT )
		ShowMenuAF(id);
}
public ShowMenuF(id)
{
	new menu = menu_create( "\rClase Furieni^n\yfurien.disconnect.ro", "MenuHandlerF" );

	menu_additem(menu, "\yRegenerator \w(\rHP Regen\w, \rSpeed+\w, \rDMG x1\w, \rGravity=\w)", "1", 0);
	menu_additem(menu, "\yAssasin \w(\rHP++\w, \rSpeed=\w, \rDMG x2\w, \rGravity+\w)",          "2", 0);
	menu_additem(menu, "\ySpeedy \w(\rHP-\w, \rSpeed+++\w, \rDMG x1\w, \rGravity+++\w)",        "3", 0);
	menu_additem(menu, "\yGodFather \w(\rHP+++\w, \rSpeed--\w, \rDMG x3\w, \rGravity--\w)",     "4", 0);
	menu_additem(menu, "\yQuad \w(\rHP+\w, \rSpeed+\w, \rDMG x4\w, \rGravity-\w)",               "5", 0);


	menu_setprop(menu, MPROP_EXITNAME, "\wExit^n^n^n^n\ywww.disconnect.ro");

	menu_display(id, menu, 0);

}
public MenuHandlerF(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new iaccess, callback;

	menu_item_getinfo(menu, item, iaccess, data, 5, iName, 63, callback);

	new key = str_to_num(data);

	switch(key)
	{
		case 1:
		{
			NextFurienClass[id] = 1;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Regenerator^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 100^x03 HP,^x04 720^x03 Speed,^x04 x1^x03 DMG,^x04 400^x03 Gravity.");
		}
		case 2:
		{
			NextFurienClass[id] = 2;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Assasin^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 170^x03 HP,^x04 700^x03 Speed,^x04 x2^x03 DMG,^x04 390^x03 Gravity.");
		}
		case 3:
		{
			NextFurienClass[id] = 3;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Speedy^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 120^x03 HP,^x04 850^x03 Speed,^x04 x1^x03 DMG,^x04 320^x03 Gravity.");
		}
		case 4:
		{
			NextFurienClass[id] = 4;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 GodFather^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 220^x03 HP,^x04 610^x03 Speed,^x04 x3^x03 DMG,^x04 530^x03 Gravity.");
		}
		case 5:
		{
			NextFurienClass[id] = 5;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Quad^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 140^x03 HP,^x04 720^x03 Speed,^x04 x4^x03 DMG,^x04 420^x03 Gravity.");
		}
	}
	return PLUGIN_HANDLED;
}
public ShowMenuAF(id)
{
	new menu = menu_create( "\rClase Anti-Furieni^n\yfurien.disconnect.ro", "MenuHandlerAF" );

	menu_additem(menu, "\yCivilian \w(\rHP Regen\w, \rSpeed+\w, \rDMG x1\w, \rGravity=\w)", "1", 0 );
	menu_additem(menu, "\yExterminator \w(\rHP++\w, \rSpeed=\w, \rDMG x2\w, \rGravity+\w)", "2", 0 );
	menu_additem(menu, "\yApocalypse \w(\rHP-\w, \rSpeed+++\w, \rDMG x1\w, \rGravity+++\w)", "3", 0 );
	menu_additem(menu, "\yDestroyer \w(\rHP+++\w, \rSpeed--\w, \rDMG x3\w, \rGravity--\w)", "4", 0 );
	menu_additem(menu, "\yMutant \w(\rHP+\w, \rSpeed+\w, \rDMG x4\w, \rGravity-\w)", "5", 0 );


	menu_setprop(menu, MPROP_EXITNAME, "\wExit^n                 \ywww.disconnect.ro");

	menu_display(id, menu, 0);

}
public MenuHandlerAF(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new iaccess, callback;

	menu_item_getinfo(menu, item, iaccess, data, 5, iName, 63, callback);

	new key = str_to_num(data);

	switch(key)
	{
		case 1:
		{
			NextAntiFurienClass[id] = 1;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Civilian^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 100^x03 HP,^x04 260^x03 Speed,^x04 x1^x03 DMG,^x04 800^x03 Gravity.");
		}
		case 2:
		{
			NextAntiFurienClass[id] = 2;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Exterminator^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 170^x03 HP,^x04 240^x03 Speed,^x04 x2^x03 DMG,^x04 780^x03 Gravity.");
		}
		case 3:
		{
			NextAntiFurienClass[id] = 3;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Apocalypse^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 90^x03 HP,^x04 420^x03 Speed,^x04 x1^x03 DMG,^x04 650^x03 Gravity.");
		}
		case 4:
		{
			NextAntiFurienClass[id] = 4;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Destroyer^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 200^x03 HP,^x04 220^x03 Speed,^x04 x3^x03 DMG,^x04 840^x03 Gravity.");
		}
		case 5:
		{
			NextAntiFurienClass[id] = 5;

			ColorChat(id, GREEN, "[D/C]:^x03 You chose^x04 Mutant^x03 class. Next round, you will have:");
			ColorChat(id, GREEN, "[D/C]: 160^x03 HP,^x04 260^x03 Speed,^x04 x4^x03 DMG,^x04 820^x03 Gravity.");
		}
	}
	return PLUGIN_HANDLED;
}
public taskStartR( )
{
	RoundStarted = true;
}
public taskGrenade(id, bool: bRestart)
{
	if( bRestart )
	{
		GrenTime[id] = 60;

		taskGrenade(id, false);
	}

	if( is_user_alive(id) )
	{
		if( GrenTime[id] - 10 <= 0 )
		{
			give_item(id, "weapon_hegrenade");
			give_item(id, "weapon_smokegrenade");
			give_item(id, "weapon_flashbang");

			GrenTime[id] = 60;
		}
		else
		{
			GrenTime[id] -= 10;

			ColorChat(id, GREEN, "^x04[VIP]^x01 Mai sunt^x03 %d^x01 secunde pana vei primi grenadele.", GrenTime[id]);

			set_task( 10.0, "taskGrenade", id );
		}

	}
	else
	{
		remove_task(id);
	}
}
stock is_user_vip(id)
{
	if( get_user_flags(id) & read_flags("s") )
		return true;

	return false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
