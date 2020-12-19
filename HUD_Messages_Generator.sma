#include <amxmodx>

#define PLUGIN "Hud Messages Generator"
#define VERSION "1.0"

#pragma semicolon 1

new color_red[33];
new color_green[33];
new color_blue[33];
new color_add[33];
new add_to[33];
new Float:position_vertical[33];
new Float:position_horizontal[33];
new hud_effect[33];
new hud_message[33][192];

new bool:IsShowMenu = false;

new const AddTo[6][] =
{
	"",
	"Red",
	"Green",
	"Blue",
	"Up/Down",
	"Left/Right"
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Rap^^") ;

	register_clcmd("say /hud", "HudMenu");
	register_clcmd("setmsg", "cmdMSJ");
}

public client_putinserver(id)
{
	color_red[id] = 255;
	color_green[id] = 255;
	color_blue[id] = 255;
	color_add[id] = 10;
	add_to[id] = 1;
	position_vertical[id] = 0.50;
	position_horizontal[id] = 0.50;
	hud_effect[id] = 0;
}

public HudMenu(id) ShowMenu(id, 0);

public ShowMenu(id, page)
{
	IsShowMenu = true;

	new colormsg[64],msgomg[64],msgupdown[64];
	formatex(colormsg, sizeof (colormsg) -1, "\rHud Message Generator^n\wRed \r%d \wGreen\r %d\w Blue \r%d", color_red[id], color_green[id], color_blue[id]);
	formatex(msgomg, sizeof (msgomg) -1, "\wIncrease/Decrease to \r%s", AddTo[add_to[id] ]);
	formatex(msgupdown, sizeof (msgupdown) -1, "\wIncrease/Decrease Colors by \r%d", color_add[id]);

	new menu = menu_create(colormsg, "ShowMenuHandler");
	menu_additem(menu, msgomg, "1", 0);
	menu_additem(menu, msgupdown, "2", 0);
	menu_additem(menu, "\wIncrease", "3", 0);
	menu_additem(menu, "\wDecrease", "4", 0);
	menu_additem(menu, "\wSet Message", "5", 0);
	menu_additem(menu, "\wShow Message", "6", 0);
	//menu_additem(menu, msgupdown, "7", 0);
	//menu_additem(menu, "\yNext Page", "8", 0);
	//menu_setprop(menu, MPROP_EXITNAME, "\wExit");

	menu_display(id, menu, page);

}

public ShowMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		IsShowMenu = false;
		return 1;
	}

	new data[6], iName[64];
	new iaccess, callback;

	menu_item_getinfo(menu, item, iaccess, data,5, iName, 63, callback);

	new key = str_to_num(data);
	new page = floatround(str_to_float(data)/7.0001, floatround_floor);

	switch(key)
	{
		case 1:
		{
			if(++add_to[id] >= 6)
			{
				add_to[id] = 1;
			}

			ShowMenu(id,page);
		}
		case 2:
		{
			if(++color_add[id] > 20)
			{
				color_add[id] = 1;
			}
			ShowMenu(id,page);
		}
		case 3:
		{
			Increase(id);
			ShowHUD(id);
			ShowMenu(id,page);
		}
		case 4:
		{
			Decrease(id);
			ShowHUD(id);
			ShowMenu(id,page);
		}
		case 5:
		{
			client_print(id, print_chat, "Introdu mesajul in say-ul deschis.");
			client_cmd(id,"messagemode setmsg");
			ShowMenu(id,page);
		}
		case 6:
		{
			ShowHUD(id);
			ShowMenu(id,page);
		}

	}
	return PLUGIN_CONTINUE;
}
public Increase(id)
{
	switch(add_to[id])
	{
		case 1:
		{
			color_red[id] += color_add[id];
			if(color_red[id] > 255)
			{
				color_red[id] = 255;
			}
		}
		case 2:
		{
			color_green[id] += color_add[id];
			if(color_green[id] > 255)
			{
				color_green[id] = 255;
			}
		}
		case 3:
		{
			color_blue[id] += color_add[id];
			if(color_blue[id] > 255)
			{
				color_blue[id] = 255;
			}
		}
		case 4:
		{
			position_vertical[id] += 0.01;
			if(position_vertical[id] > 1.0)
			{
				position_vertical[id] = 1.0;
			}
		}
		case 5:
		{
			position_horizontal[id] += 0.01;
			if(position_horizontal[id] > 1.0)
			{
				position_horizontal[id] = 1.0;
			}
		}
	}
}
public Decrease(id)
{
	switch(add_to[id])
	{
		case 1:
		{
			color_red[id] -= color_add[id];
			if(color_red[id] < 0)
			{
				color_red[id] = 0;
			}
		}
		case 2:
		{
			color_green[id] -= color_add[id];
			if(color_green[id] < 0)
			{
				color_green[id] = 0;
			}
		}
		case 3:
		{
			color_blue[id] -= color_add[id];
			if(color_blue[id] < 0)
			{
				color_blue[id] = 0;
			}
		}
		case 4:
		{
			position_vertical[id] -= 0.01;
			if(position_vertical[id] < 0.0)
			{
				position_vertical[id] = 0.0;
			}
		}
		case 5:
		{
			position_horizontal[id] -= 0.01;
			if(position_horizontal[id] < 0.0 )
			{
				position_horizontal[id] = 0.0;
			}
		}
	}
}
public ShowHUD(id)
{
	if(!IsShowMenu)
	{
		return PLUGIN_HANDLED;
	}

	set_hudmessage(color_red[id], color_green[id], color_blue[id], position_horizontal[id], position_vertical[id], hud_effect[id], 5.0, 5.0);
	show_hudmessage(id, "%s", hud_message[id]);

	//set_task(5.0,"ShowHUD");

	return PLUGIN_CONTINUE;
}

public cmdMSJ(id)
{
	static arg[192];
	read_argv(1, arg, sizeof (arg) -1);

	if ( !strlen(arg) )
	{
		client_print(id,print_chat, "You can't set a blank message ! Please type a new one.");
		client_cmd(id,"messagemode setmsg");
		return PLUGIN_HANDLED;
	}

	formatex(hud_message[id], sizeof(hud_message[]) -1, "%s",arg);
	client_print(id,print_chat,"mesajul este %s",hud_message[id]);
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
