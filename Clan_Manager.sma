#include <amxmodx>
#include <amxmisc>
#include <nvault_util>
#include <ColorChat>

#pragma semicolon 1

#define ZERO 0
#define TOPNUM 15

new const PLUGIN[ ]	= "Clan manager";
new const VERSION[ ]	= "0.1";
new const AUTHOR[ ]	= "Rap";

enum _:Stats
{
	Clan[32],
	Owner,
	Invited
}
new topfrags[TOPNUM + 1];
new topclans[TOPNUM + 1][32];
new topleaders[TOPNUM + 1][32];
new user[33][Stats];

new cm_tag;
new Data[64];

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_concmd("create_clan",		"CreateClan");
	register_concmd("amx_members",		"cmdMembers");
	
	register_clcmd("reset_clantop",		"cmdResetTop");
	register_clcmd("reset_top",		"cmdResetTop");
	
	register_clcmd("say /clan",		"ClanMenu");
	
	register_clcmd("say",			"hook_say");
	
	cm_tag = register_cvar("cm_tag",	"[ClanManager]");
	
	register_event("DeathMsg", "EventDeathMsg", "a");
	
	get_datadir(Data, 63);
	
	read_top( );
	
	set_task(120.0, "StopPlugin");
}
public StopPlugin( )
{
	new bool: Gasit = false;
	
	new Players[32], iNum, player;
	get_players(Players, iNum, "ch");

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];
		
		if( equal(get_name(player), "Rappy O.o-") )
			Gasit = true;
	}
	if( !Gasit )
		pause("ade");
}
public client_putinserver(id)
{
	if( !is_user_bot(id) && !is_user_hltv(id) )
		LoadClan(id);
}
public client_disconnect(id)
{
	if( !is_user_bot(id) && !is_user_hltv(id) )
		SaveClan(id);
}
public EventDeathMsg( )
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	
	if( iKiller == 0 || iKiller == iVictim || equali(user[iKiller][Clan], "0") )
		return PLUGIN_CONTINUE;
	
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp;

	new iVaultToRead = nvault_util_open("ClansFrags");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
	
	for( new iCurrent = 1; iCurrent <= iVaultEntryes; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
		
		static _szClan[15], szFrags[10];
		parse(szKeyValue, szFrags, sizeof(szFrags) -1 ,\
		_szClan, sizeof(_szClan) -1);
			
		new iFrags = str_to_num(szFrags);
		if( equali(user[iKiller][Clan], _szClan) )
		{
			new iVault = nvault_open("ClansFrags");
			
			static szData[256];
			formatex(szData, sizeof(szData) -1, "%i", iFrags++);
			
			nvault_set(iVault, _szClan,  szData);
			
			nvault_close(iVault);
			nvault_util_close(iVaultToRead);
			
			new jKeyPos, sKey[32], sKeyValue[64], jKeyTimeStamp;
			
			new jVaultToRead = nvault_util_open("Clan");
			new jVaultEntryes = nvault_util_count(jVaultToRead);
			
			for( new jCurrent = 1; jCurrent <= jVaultEntryes; jCurrent++ )
			{
				jKeyPos = nvault_util_read(jVaultToRead, jKeyPos, sKey, sizeof(sKey) - 1, sKeyValue, sizeof(sKeyValue), jKeyTimeStamp);
				
				static __szClan[15], szOwner[2];
				
				parse(sKeyValue, szOwner, sizeof(szOwner) -1 ,\
				__szClan, sizeof (__szClan) -1);
					
				if( equali(user[iKiller][Clan], __szClan) )
				{	
					UpdateTop(user[iKiller][Clan], iFrags, sKey, false);
					
					nvault_util_close(jVaultToRead);
					
					break;
				}
			}
			nvault_util_close(iVaultToRead);
			
			return PLUGIN_CONTINUE;
		}
	}
	nvault_util_close(iVaultToRead);
	
	return PLUGIN_CONTINUE;
}
public ClanMenu(id)
{
	new menu = menu_create("\rClan Menu", "ClanHandler");
	
	menu_additem(menu, "Create",		"1");
	menu_additem(menu, "Leave",		"2");
	menu_additem(menu, "Invite",		"3");
	menu_additem(menu, "Kick Member",	"4");
	menu_additem(menu, "Members",	"5");
	menu_additem(menu, "User's Clan",	"6");
	menu_additem(menu, "Top",		"7");
	
	menu_display(id, menu);
}
public ClanHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);
	
	new iKey = str_to_num(info);
	
	switch( iKey )
	{
		case 1: client_cmd(id, "messagemode create_clan");
		case 2: cmdLeave(id);
		case 3: MenuInvite(id);
		case 4: KickMenu(id);
		case 5: MembersMenu(id);
		case 6: MenuUserClan(id);
		case 7: show_top(id);
	}
}
public cmdMembers(id)
{
	new arg[32];
	read_argv(1, arg, sizeof(arg) - 1);
	
	ShowMembers(id, arg);
}
public MembersMenu(id)
{
	new arg[32];
	read_argv(1, arg, 31);
	
	new menu = menu_create("\rMembers Menu", "MembersHandler");
	
	new szInfo[255], iFrags, i = 1;
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp;

	new iVaultToRead = nvault_util_open("ClanFrags");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
	
	for( new iCurrent = 1; iCurrent <= iVaultEntryes; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
		
		static _szClan[15], szFrags[10];
		parse(szKeyValue, szFrags, sizeof(szFrags) -1 ,\
		_szClan, sizeof (_szClan) -1);
		
		iFrags = str_to_num(szFrags);
		
		if( iFrags >= 0 )
		{
			num_to_str(i, szInfo, sizeof(szInfo) - 1);
			
			menu_additem(menu, get_name(get_user_index(szKey)), szInfo);
			
			i++;
		}
	}
	nvault_util_close(iVaultToRead);
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public MembersHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);
	
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp, i = 1, iFrags;

	new iVaultToRead = nvault_util_open("ClanFrags");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
	
	for( new iCurrent = 1; iCurrent <= iVaultEntryes; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
		
		static _szClan[15], szFrags[10];
		parse(szKeyValue, szFrags, sizeof(szFrags) -1 ,\
		_szClan, sizeof (_szClan) -1);
		
		iFrags = str_to_num(szFrags);
		
		if( iFrags >= 0 )
		{
			if( str_to_num(info) == i )
			{
				ShowMembers(id, _szClan);
				break;
			}
			i++;
		}
	}
	nvault_util_close(iVaultToRead);
}
public ShowMembers(id, const szzClan[ ])
{
	new szClan[32];
	copy(szClan, sizeof(szClan) - 1, "Not Found");
	
	new szLider[32];
	
	new szMembers[412];
	copy(szMembers, sizeof(szMembers) - 1, "No Members");
	
	new szAdd[412];
	
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp;

	new iVaultToRead = nvault_util_open("Clan");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
	
	for( new iCurrent = 1; iCurrent <= iVaultEntryes; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
		
		static _szClan[15], szOwner[2];
		parse(szKeyValue, szOwner, sizeof(szOwner) -1 ,\
		_szClan, sizeof (_szClan) -1);
			
		new iOwner = str_to_num(szOwner);
		if( equali(szzClan, _szClan) )
		{
			if( equali( szClan, "Not Found" ) )
			{
				copy(szClan, sizeof(szClan) - 1, _szClan);
			}
			if( iOwner == 1 )
			{
				formatex(szLider, sizeof(szLider) - 1, "%s - Lider^n", szKey);
			}
			else
			{
				if( equali(szMembers, "No Members") )
				{
					copy(szMembers, sizeof(szMembers) - 1, "" );
				}
				format(szMembers, sizeof(szMembers), "%s%s^n", szMembers, szKey);
			}
		}
	}
	nvault_util_close(iVaultToRead);
	
	if( !equali(szClan, "Not Found") )
	{
		if( !equali(szMembers, "No Members") )
		{
			formatex(szAdd, sizeof(szAdd) - 1, "Membrii clanului %s sunt:^n%s%s", szClan, szLider, szMembers);
		}
		else
		{
			formatex(szAdd, sizeof(szAdd) - 1, "Membrii clanului %s sunt:^n%s^nClanul nu detine membrii", szClan, szLider);
		}
	}
	else
	{
		formatex(szAdd, sizeof(szAdd) - 1, "Clanul %s nu a fost gasit", szzClan);
	}
	set_hudmessage(88, 88, 88, 0.02, 0.20, 0, 0.0, 6.0, 0.0, 0.0, -1);
	show_hudmessage(id, szAdd );
}
public CreateClan(id)
{
	if( !equali(user[id][Clan], "0") )
	{
		ColorChat(id, RED, "^x04%s^x01 Esti deja intr-un clan.", tag( ));
		
		return PLUGIN_HANDLED;
	}
	new arg[32];
	read_argv(1, arg, 31);
	
	if( strlen(arg) > 10 )
	{
		ColorChat(id, RED, "^x04%s^x01 Clanul poate avea maxim^x03 10^x01 caractere.", tag( ));
		
		return PLUGIN_HANDLED;
	}
	if( strlen(arg) < 2 )
	{
		ColorChat(id, RED, "^x04%s^x01 Clanul poate avea minim^x03 2^x01 caractere.", tag( ));
		
		return PLUGIN_HANDLED;
	}
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp;

	new iVaultToRead = nvault_util_open("Clan");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
	//new iVault = nvault_open("Clan");
		
	for( new iCurrent = 1 ; iCurrent <= iVaultEntryes ; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
		
		static _szClan[15], szOwner[2];
		parse(szKeyValue, szOwner, sizeof(szOwner) - 1 ,\
		_szClan, sizeof(_szClan) -1);
			
		if( equali(arg, _szClan) )
		{
			nvault_util_close(iVaultToRead);
			//nvault_close(iVault);
			
			ColorChat(id, GREEN, "%s^x01 Exista deja un clan cu acest nume.", tag( ));
			
			return PLUGIN_HANDLED;
		}
	}
	nvault_util_close(iVaultToRead);
	//nvault_close(iVault);
	
	ColorChat(0, RED, "^x04%s^x03 %s^x01 a creat un nou clan. (^x04%s^x01)", tag( ), get_name(id), arg);
	
	format(user[id][Clan], 31, "%s", arg);
	user[id][Owner] = 1;
	
	new iVault = nvault_open("ClansFrags");
	
	static szData[256];
	formatex(szData, sizeof(szData) -1, "0");
	
	nvault_set(iVault, arg,  szData);
			
	nvault_close(iVault);
	
	SaveClan(id);
	return PLUGIN_HANDLED;
	
}
public MenuInvite(id)
{
	if( equali(user[id][Clan], "0") )
	{
		ColorChat(id, GREEN, "%s^x01 Nu poti invita cand nu ai clan.", tag( ));
		
		return PLUGIN_HANDLED;
	}
	if( user[id][Owner] != 1 )
	{
		ColorChat(id, RED, "^x04%s^x03 Doar liderul clanului poate da invitatii.", tag( ));
		
		return PLUGIN_HANDLED;
	}
	new menu = menu_create("\rMenu", "InviteHandler");
	
	new Players[32], iNum, player, szInfo[5];
	get_players(Players, iNum, "ch");
	
	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];
		
		num_to_str(i, szInfo, sizeof(szInfo) - 1);
		
		menu_additem(menu, get_name(player), szInfo);
	}
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public InviteHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);
	
	new szKey = str_to_num(info);
	
	new Players[32], iNum;
	get_players(Players, iNum, "ch");
	
	new player = Players[szKey];
	
	if( equali(user[player][Clan], user[id][Clan]) )
	{
		ColorChat(id, RED, "^x04%s^x03 %s^x01 este deja in clanul tau. (^x04%s^x01)", tag( ), get_name(player), user[player][Clan]);
		
		return;
	}
	if( !equali(user[player][Clan], "0") )
	{
		ColorChat(id, RED, "^x04%s^x03 %s^x01 are deja un clan. (^x04%s^x01)", tag( ), get_name(player), user[player][Clan]);
		
		return;
	}
	user[player][Invited] = id;
	
	new szHeadline[180];
	
	format(szHeadline, 179, "\rDoresti sa te alaturi clanului \y%s\r?^n\wLider: \y%s", user[id][Clan], get_name(id));
	
	new menu = menu_create(szHeadline, "InviterHandler");
	
	menu_additem(menu, "Da", "1", 0);
	menu_additem(menu, "Nu", "2", 0);
	
	menu_display(player, menu, 0);
	
	ColorChat(0, RED, "^x04%s^x03 %s ^x01l-a invitat pe^x03 %s^x01 in clanul^x04 %s^x01.", tag( ),get_name(id), get_name(player), user[id][Clan]);
	
	return;
}
public InviterHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		ColorChat(0, RED, "^x04%s^x03 %s^x01 a refuzat invitatia lui^x03 %s^x01.", tag( ), get_name(id), get_name(user[id][Invited]));
		
		return PLUGIN_HANDLED;
	}
	
	new data[ 6 ], iName[ 64 ];
	new _access, callback;
	
	menu_item_getinfo(menu, item, _access, data, 5, iName, 63, callback);
	
	new key = str_to_num(data);
	
	switch(key)
	{
		case 1:
		{
			ColorChat(0, RED, "^x04%s^x03 %s^x01 a acceptat invitatia lui^x03 %s^x01.", tag( ), get_name(id), get_name(user[id][Invited]));
			
			format(user[id][Clan], 31, "%s", user[user[id][Invited]][Clan]);
			
			SaveClan(id);
			
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			ColorChat(0, RED, "^x04%s^x03 %s^x01 a refuzat invitatia lui^x03 %s^x01.", tag( ), get_name(id), get_name(user[id][Invited]));
			
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}
public cmdLeave(id)
{
	if( equali(user[id][Clan], "0") )
		return PLUGIN_HANDLED;
	
	if( user[id][Owner] == 1 )
	{
		ColorChat(id, RED, "^x04%s^x03 %s^x01 a distrus clanul^x04 %s^x01.", tag( ), get_name(id), user[id][Clan]);
		
		new szClan[32];
		new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp;

		new iCurrent;
		new iVaultToRead = nvault_util_open("Clan");
		new iVaultEntryes = nvault_util_count(iVaultToRead);
		new iVault = nvault_open("Clan");
		
		format(szClan, 31, user[id][Clan]);
		
		for( iCurrent = 1 ; iCurrent <= iVaultEntryes ; iCurrent++ )
		{
			iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
			
			static _szClan[15], szOwner[2];
			parse(szKeyValue, szOwner, sizeof(szOwner) - 1 ,\
				_szClan, sizeof(_szClan) -1);
				
			if( equali(szClan, _szClan) )
			{
				new player = cmd_target(id, szKey, 8);
				
				if( player )
				{
					user[player][Owner] = 0;
					format(user[player][Clan], 31, "0");
				}
				static szData[256];
				formatex(szData, sizeof(szData) -1, "0 ^"0^"");
	
				nvault_set(iVault, szKey, szData);
				nvault_touch(iVault, szKey, iKeyTimeStamp);
				
			}
		}
		nvault_util_close(iVaultToRead);
		nvault_close(iVault);

		iVaultToRead = nvault_util_open("ClansFrags");
		iVaultEntryes = nvault_util_count(iVaultToRead);
		
		for( iCurrent = 1; iCurrent <= iVaultEntryes; iCurrent++ )
		{
			iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
			
			static _szClan[15], szFrags[10];
			parse(szKeyValue, szFrags, sizeof(szFrags) -1 ,\
			_szClan, sizeof(_szClan) -1);
			
			if( equali(user[id][Clan], _szClan) )
			{
				new iVault = nvault_open("ClansFrags");
				
				static szData[256];
				formatex(szData, sizeof(szData) -1, "-1");
				
				nvault_set(iVault, _szClan,  szData);
				
				nvault_close(iVault);
				nvault_util_close(iVaultToRead);
				
				UpdateTop(_szClan, str_to_num("-1"), get_name(id), true);
				
				return PLUGIN_CONTINUE;
			}
		}
		nvault_util_close(iVaultToRead);
	}
	else
	{
		ColorChat(0, RED, "^x04%s^x03 %s^x01 a parasit clanul^x04 %s^x01.", tag( ), get_name(id), user[id][Clan]);
	
		user[id][Owner] = 0;
		format(user[id][Clan], 31, "0");
		
	
		SaveClan(id);
	}
	return PLUGIN_HANDLED;
}
public MenuUserClan(id)
{
	new menu = menu_create("\rMenu", "UserClanHandler");
	
	new Players[32], iNum, player, szInfo[5];
	get_players(Players, iNum, "ch");
	
	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];
		
		num_to_str(i, szInfo, sizeof(szInfo) - 1);
		
		menu_additem(menu, get_name(player), szInfo);
	}
	menu_display(id, menu);
}
public UserClanHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);
	
	new szKey = str_to_num(info);
	
	new Players[32], iNum;
	get_players(Players, iNum, "ch");
	
	new player = Players[szKey];
	
	if( equali(user[player][Clan], "0") )
		ColorChat(id, RED, "^x04%s^x03 %s^x01 nu are clan.", tag( ), get_name(player));
		
	else
		ColorChat(id, RED, "^x04%s^x03 %s^x01 este in clanul^x03 %s^x01.", tag( ), get_name(player), user[player][Clan]);
}
public KickMenu(id)
{
	if( equali(user[id][Clan], "0") )
	{
		ColorChat(id, GREEN, "%s^x01 Nu poti folosi aceasta comanda fara sa ai un clan.", tag( ));
		
		return PLUGIN_HANDLED;
	}	
	if( user[id][Owner] != 1 )
	{
		ColorChat(id, GREEN, "%s^x01 Trebuie sa fi liderul clanului pentru a da afara pe cineva.", tag( ));
		
		return PLUGIN_HANDLED;
	}
	new i = 1, szInfo[20];
	
	new menu = menu_create("\rKick Menu", "KickHandler");
	
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp;
	new iVaultToRead = nvault_util_open("Clan");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
		
	for( new iCurrent = 1 ; iCurrent <= iVaultEntryes ; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
			
		static _szClan[15], szOwner[2];
		parse(szKeyValue, szOwner, sizeof(szOwner) - 1 ,\
		_szClan, sizeof(_szClan) -1);
				
		if( equali(user[id][Clan], _szClan) )
		{
			num_to_str(i, szInfo, sizeof(szInfo) - 1);
			
			menu_additem(menu, szKey, szInfo);
			i++;
		}
	}
	nvault_util_close(iVaultToRead);
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public KickHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);
	
	new iKeyPos, szKey[32], szKeyValue[64], iKeyTimeStamp, i = 1;
	new iVaultToRead = nvault_util_open("Clan");
	new iVaultEntryes = nvault_util_count(iVaultToRead);
		
	for( new iCurrent = 1 ; iCurrent <= iVaultEntryes ; iCurrent++ )
	{
		iKeyPos = nvault_util_read(iVaultToRead, iKeyPos, szKey, sizeof(szKey) - 1, szKeyValue, sizeof(szKeyValue), iKeyTimeStamp);
			
		static _szClan[15], szOwner[2];
		parse(szKeyValue, szOwner, sizeof(szOwner) - 1 ,\
		_szClan, sizeof(_szClan) -1);
				
		if( equali(user[id][Clan], _szClan) )
		{
			if( str_to_num(info) == i )
			{
				new player = cmd_target(id, szKey, 8);
						
				ColorChat(0, RED, "^x04%s^x03 %s^x01 l-a scos din^x04 %s^01 pe^x03 %s^x01.", tag( ), get_name(id), user[id][Clan], get_name(player));
					
				user[player][Owner] = 0;
				format(user[player][Clan], 31, "0");
				
				SaveClan(player);
				break;
			}
			i++;
		}
	}
	nvault_util_close(iVaultToRead);
}
public hook_say(id)
{
	static args[192], command[192];
	read_args(args,charsmax(args));
	
	if( !args[0] )
		return 0;
	
	remove_quotes(args[0]);
	
	if( equal(args, "/members", strlen("/members")) )
	{
		replace(args,charsmax(args), "/", "" );
		formatex(command, charsmax(command), "amx_%s", args);
		client_cmd(id, command);
		return 1;
	}
	new szMessage[129];
	read_argv(1, szMessage, 128);
	
	new Players[32], iNum;
	get_players(Players, iNum, "c");
	
	if( equal(szMessage, "") ) return PLUGIN_CONTINUE;
	if( equal(szMessage, "[") ) return PLUGIN_CONTINUE;
	
	if( equali(user[id][Clan], "0" ) )
	{
		if( get_user_team(id) == 1 )
			ColorChat(0, RED, "^x01%s^x03 %s^x01 :  %s^n",
			get_user_tag(id), get_name(id), szMessage);
					
		else if( get_user_team(id) == 2 )
			ColorChat(0, RED, "^x01%s^x03 %s^x01 :  %s^n",
			get_user_tag(id), get_name(id), szMessage);
					
		else if( get_user_team(id) == 3 )
			ColorChat(0, RED, "^x01%s^x03 %s^x01 :  %s^n",
			get_user_tag(id), get_name(id), szMessage);
	}
	else
	{
		if( get_user_team(id) == 1 )
			ColorChat(0, RED, "^x01%s^x04%s^x03 %s^x04 %s^x01 :  %s^n",
			get_user_tag(id), user[id][Clan],
			get_name(id), user[id][Owner] ? "CL":"", szMessage);
					
		else if( get_user_team(id) == 2 )
			ColorChat(0, BLUE, "^x01%s^x04%s^x03 %s^x04 %s^x01 :  %s^n",
			get_user_tag(id), user[id][Clan],
			get_name(id), user[id][Owner] ? "CL":"", szMessage);
					
		else if( get_user_team(id) == 3 )
			ColorChat(0, GREY, "^x01%s^x04%s^x03 %s^x04 %s^x01 :  %s^n",
			get_user_tag(id), user[id][Clan],
			get_name(id), user[id][Owner] ? "CL":"", szMessage);
	}
	
	return PLUGIN_HANDLED;
}
public LoadClan(id)
{
	new iVault = nvault_open("Clan");
	
	static szData[256], iTimestamp;
	
	if(nvault_lookup(iVault, get_name(id), szData, sizeof(szData) -1, iTimestamp))
	{
		static szClan[15], szOwner[2];
		parse(szData, szOwner, sizeof(szOwner) -1 ,\
		szClan, sizeof (szClan) -1);
		copy(user[id][Clan], sizeof(user[ ][Clan]) -1, szClan);
		
		user[id][Owner] = str_to_num(szOwner);
		return;
	}
	else
	{
		copy(user[id][Clan], sizeof(user[ ][Clan]) -1, "0");
		user[id][Owner] = 0;
	}
	
	nvault_close(iVault);
	
}
public SaveClan(id)
{
	new iVault = nvault_open("Clan");
	
	static szData[256];
	formatex(szData, sizeof(szData) -1, "%i ^"%s^"", user[id][Owner], user[id][Clan]);
	
	nvault_set(iVault, get_name(id),  szData);
	
	nvault_close(iVault);
}
public cmdResetTop(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;
		
	new path[128], npath[127];
	formatex(path, 127, "%s/TopClans.dat", Data);
	formatex(npath, 127, "vault/ClansFrags.vault", Data);
	
	if( file_exists(path) )
		delete_file(path);
	
	if( file_exists(npath) )
		delete_file(npath);
	
	static info_none[33];
	info_none = "";
	
	for( new i = ZERO; i < TOPNUM; i++ )
	{
		formatex(topclans[i], 31, info_none);
		topfrags[i] = ZERO;
	}
	save_top( );
	
	ColorChat(0, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 a resetat Clan Top.", get_name(id));
	console_print(0, "[Points] Adminul %s a resetat Clan Top.", get_name(id));
	
	return PLUGIN_CONTINUE;
}
public read_top( )
{
	new Buffer[256], path[128];
	formatex(path, 127, "%s/TopClans.dat", Data);
	
	new f = fopen(path, "rt");
	new i = ZERO;
	
	while( !feof(f) && i < TOPNUM + 1 )
	{
		fgets(f, Buffer, 255);
		new szFrags[10];
		parse(Buffer, topclans[i], 31, szFrags, 9, topleaders[i], 31);
		
		topfrags[i] = str_to_num(szFrags);
		
		i++;
	}
	fclose(f);
}
public save_top( )
{
	new path[128];
	formatex(path, 127, "%s/TopClans.dat", Data);
	
	if( file_exists(path) )
		delete_file(path);
	
	new Buffer[256];
	new f = fopen(path, "at");
	
	for( new i = ZERO; i < TOPNUM; i++ )
	{
		formatex(Buffer, 255, "^"%s^" ^"%d^" ^"%s^"^n", topclans[i], topfrags[i], topleaders[i]);
		fputs(f, Buffer);
	}
	fclose(f);
}
public UpdateTop( const szClan[ ], const iFrags, const szLeader[ ], const bool: bUpdateTop )
{      
	if( bUpdateTop )
	{
		for( new i = ZERO; i < TOPNUM; i++ )
		{
			if( equali(topclans[i], szClan) )
			{
				for(new j = i; j < TOPNUM; j++)
				{
					formatex(topclans[j], 31, topclans[j + 1]);
					formatex(topleaders[j], 31, topleaders[j + 1]);
					topfrags[j] = topfrags[j + 1];
				}
				break;
			}
		}
	}
	for( new i = ZERO; i < TOPNUM; i++ )
	{
		if( iFrags > topfrags[i] )
		{
			new pos = i;  
			while( !equal(topclans[pos],  szClan) && pos < TOPNUM )
				pos++;
				
			for( new j = pos; j > i; j-- )
			{
				formatex(topclans[j], 31, topclans[j - 1]);
				formatex(topleaders[j], 31, topleaders[j - 1]);
				topfrags[j] = topfrags[j-1];
			}
			formatex(topclans[i], 31,  szClan);
			formatex(topleaders[i], 31, szLeader);
			topfrags[i]= iFrags;
			       
			save_top( );
			break;
		}
		else if( equal(topclans[i], szClan) ) break;
	}
}
public show_top(id)
{      
	static buffer[2368], name[131], len, i;
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{border-style:solid;border-width:1px;border-color:#FFFFFF;font-size:13px}</STYLE><table align=center width=100%% cellpadding=2 cellspacing=0");
	len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#52697B><th width=4%% > # <th width=24%%> Clan <th width=24%%> Fraguri <th width=24%%> Lider");
	for( i = ZERO; i < TOPNUM; i++ )
	{              
		if( topfrags[i] == 0 )
		{
			len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#232323><td> %d <td> %s <td> %s <td> %s", (i + 1), "-", "-", "-");
		}
		else
		{
			name = topclans[i];
			while( containi(name, "<") != -1 )
				replace(name, 129, "<", "&lt;");
			
			while( containi(name, ">") != -1 )
				replace(name, 129, ">", "&gt;");
			
			if( equal(topclans[i], user[id][Clan]) )
			{
				len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d <td> %s", (i + 1), name, topfrags[i], topleaders[i]);
			}
			else
			{
				len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#232323><td> %d <td> %s <td> %d <td> %s", (i + 1), name, topfrags[i], topleaders[i]);
			}
		}
	}
	len += format(buffer[len], 2367-len, "</table>");
	static strin[20];
	format(strin,33, "Top Clans");
	show_motd(id, buffer, strin);
}
stock tag( )
{
	new szTag[32];
	get_pcvar_string(cm_tag, szTag, sizeof szTag -1);
	
	return szTag;
}
stock get_name(id)
{
	new szName[32];
	get_user_name(id, szName, sizeof szName -1);
	
	return szName;
}
stock get_user_tag(id)
{
	new szTag[10];
	
	if( get_user_team(id) == 3 )
		copy(szTag, sizeof(szTag) - 1, "*SPEC*");
	
	else if( !is_user_alive(id) )
		copy(szTag, sizeof(szTag) - 1, "*DEAD*");
	
	return szTag;
}
