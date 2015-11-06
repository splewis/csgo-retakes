#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include "include/retakes.inc"
#include "retakes/generic.sp"

#pragma semicolon 1

#define MENU_TIME_LENGTH 15

int nade_price_for_hegrenade = 300;
int nade_price_for_flashbang = 200;
int nade_price_for_smokegrenade = 500;
int nade_price_for_molotov = 400;
int nade_price_for_incgrenade = 600;
int nade_price_for_decoy = 50;

int gun_price_for_p250 = 300;
int gun_price_for_cz = 500;
int gun_price_for_fiveseven = 500;
int gun_price_for_tec9 = 500;
int gun_price_for_deagle = 700;
int gun_price_for_elite = 500;

int kit_price = 400;
int kevlar_price = 650;

int  g_Pistolchoice[MAXPLAYERS+1];
int  g_Sidechoice[MAXPLAYERS+1];
bool g_SilencedM4[MAXPLAYERS+1];
bool g_AwpChoice[MAXPLAYERS+1];
Handle g_hPISTOLChoiceCookie = INVALID_HANDLE;
Handle g_hSIDEChoiceCookie = INVALID_HANDLE;
Handle g_hM4ChoiceCookie = INVALID_HANDLE;
Handle g_hAwpChoiceCookie = INVALID_HANDLE;

//new convars
Handle g_h_sm_retakes_weapon_mimic_competitive_pistol_rounds = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_primary_enabled = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_enabled = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_hegrenade_ct_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_hegrenade_t_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_flashbang_ct_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_flashbang_t_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_smokegrenade_ct_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_smokegrenade_t_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_molotov_ct_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_molotov_t_max = INVALID_HANDLE;
//Handle g_h_sm_retakes_weapon_helmet_enabled = INVALID_HANDLE;
//Handle g_h_sm_retakes_weapon_kevlar_enabled = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_awp_team_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_pistolrounds  = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_deagle_enabled  = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_cz_enabled  = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_p250_enabled  = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_tec9_fiveseven_enabled = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_dual_elite_enabled = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_decoy_ct_max = INVALID_HANDLE;
Handle g_h_sm_retakes_weapon_nades_decoy_t_max = INVALID_HANDLE;

int nades_hegrenade_ct_count = 0;
int nades_hegrenade_t_count = 0;
int nades_flashbang_ct_count = 0;
int nades_flashbang_t_count = 0;
int nades_smokegrenade_ct_count = 0;
int nades_smokegrenade_t_count = 0;
int nades_molotov_ct_count = 0;
int nades_molotov_t_count = 0;
int nades_decoy_ct_count = 0;
int nades_decoy_t_count = 0;

public Plugin myinfo = {
    name = "CS:GO Retakes: Customised Weapon Allocator for splewis retakes plugin,",
    author = "BatMen and Gdk",
    description = "Defines convars to customize weapon allocator of splewis retakes plugin",
    version = "4.3.0",
    url = "https://github.com/RavageCS/csgo-retakes-splewis-convar-weapon-allocator"
};

public void OnPluginStart() {
    g_hPISTOLChoiceCookie = RegClientCookie("retakes_pistolchoice", "", CookieAccess_Private);
    g_hSIDEChoiceCookie = RegClientCookie("retakes_sidearmchoice", "", CookieAccess_Private);
    g_hM4ChoiceCookie  = RegClientCookie("retakes_m4choice", "", CookieAccess_Private);
    g_hAwpChoiceCookie = RegClientCookie("retakes_awpchoice", "", CookieAccess_Private);
    RegConsoleCmd("sm_guns", Command_GunsMenu, "Opens the retakes weapons menu");

    //new convars
    g_h_sm_retakes_weapon_mimic_competitive_pistol_rounds = CreateConVar("sm_retakes_weapon_mimic_competitive_pistol_rounds", "1", "Whether pistol rounds are like 800$ rounds");
    g_h_sm_retakes_weapon_primary_enabled = CreateConVar("sm_retakes_weapon_primary_enabled", "1", "Whether the players can have primary weapon");
    g_h_sm_retakes_weapon_nades_enabled = CreateConVar("sm_retakes_weapon_nades_enabled", "1", "Whether the players can have nades");
    g_h_sm_retakes_weapon_nades_hegrenade_ct_max = CreateConVar("sm_retakes_weapon_nades_hegrenade_ct_max", "1", "Number of hegrenade CT team can have");
    g_h_sm_retakes_weapon_nades_hegrenade_t_max = CreateConVar("sm_retakes_weapon_nades_hegrenade_t_max", "1", "Number of hegrenade T team can have");
    g_h_sm_retakes_weapon_nades_flashbang_ct_max = CreateConVar("sm_retakes_weapon_nades_flashbang_ct_max", "2", "Number of flashbang CT team can have");
    g_h_sm_retakes_weapon_nades_flashbang_t_max = CreateConVar("sm_retakes_weapon_nades_flashbang_t_max", "1", "Number of flashbang T team can have");
    g_h_sm_retakes_weapon_nades_smokegrenade_ct_max = CreateConVar("sm_retakes_weapon_nades_smokegrenade_ct_max", "1", "Number of smokegrenade CT team can have");
    g_h_sm_retakes_weapon_nades_smokegrenade_t_max = CreateConVar("sm_retakes_weapon_nades_smokegrenade_t_max", "1", "Number of smokegrenade T team can have");
    g_h_sm_retakes_weapon_nades_molotov_ct_max = CreateConVar("sm_retakes_weapon_nades_molotov_ct_max", "1", "Number of molotov CT team can have");
    g_h_sm_retakes_weapon_nades_molotov_t_max = CreateConVar("sm_retakes_weapon_nades_molotov_t_max", "1", "Number of molotov T team can have");
//  g_h_sm_retakes_weapon_helmet_enabled = CreateConVar("sm_retakes_weapon_helmet_enabled", "1", "Whether the players have helmet");
//  g_h_sm_retakes_weapon_kevlar_enabled = CreateConVar("sm_retakes_weapon_kevlar_enabled", "1", "Whether the players have kevlar");
    g_h_sm_retakes_weapon_awp_team_max = CreateConVar("sm_retakes_weapon_awp_team_max", "1", "The max number of AWP per team (0 = no awp)");
    g_h_sm_retakes_weapon_pistolrounds = CreateConVar("sm_retakes_weapon_pistolrounds", "5", "The number of pistol rounds (0 = no pistol round)");
    g_h_sm_retakes_weapon_deagle_enabled = CreateConVar("sm_retakes_weapon_deagle_enabled", "1", "Whether the players can choose deagle");
    g_h_sm_retakes_weapon_cz_enabled = CreateConVar("sm_retakes_weapon_cz_enabled", "1", "Whether the players can choose CZ");
    g_h_sm_retakes_weapon_p250_enabled = CreateConVar("sm_retakes_weapon_p250_enabled", "1", "Whether the players can choose P250");
    g_h_sm_retakes_weapon_tec9_fiveseven_enabled = CreateConVar("sm_retakes_weapon_tec9_fiveseven_enabled", "1", "Whether the players can choose Tec9/Five seven");
    g_h_sm_retakes_weapon_dual_elite_enabled = CreateConVar("sm_retakes_weapon_dual_elite_enabled", "1", "Whether the players can choose Dual Elite");
    g_h_sm_retakes_weapon_nades_decoy_ct_max = CreateConVar("sm_retakes_weapon_nades_decoy_ct_max", "1", "Number of decoys CT team can have");
    g_h_sm_retakes_weapon_nades_decoy_t_max = CreateConVar("sm_retakes_weapon_nades_decoy_t_max", "1", "Number of decoys T team can have");

    /** Create/Execute retakes cvars **/
    AutoExecConfig(true, "retakes_allocator", "sourcemod/retakes");

}

public void OnClientConnected(int client) {
    g_Pistolchoice[client] = 1;
    g_Sidechoice[client] = 1;
    g_SilencedM4[client] = false;
    g_AwpChoice[client] = false;
}

public Action Command_GunsMenu(int client, int args) {
	if (GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) != 1 && 
		GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) != 1 &&
                GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) != 1 &&
		GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) != 1 && 
                GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) != 1)
                GiveWeaponMenu(client);
	else
		GivePistolMenu(client);
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
    char gunsChatCommands[][] = { "/gun", "/guns", "gun", "guns", ".gun", ".guns", ".setup", "!gun", "!guns", "gnus" };
    for (int i = 0; i < sizeof(gunsChatCommands); i++) {
        if (strcmp(args[0], gunsChatCommands[i], false) == 0) {
            if (GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) != 1 && 
                GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) != 1 &&
                GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) != 1 && 
                GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) != 1)
                GiveWeaponMenu(client);
            else
                GivePistolMenu(client);
            break;
        }
    }

    return Plugin_Continue;
}

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
    WeaponAllocator(tPlayers, ctPlayers, bombsite);
}

/**
 * Updates client weapon settings according to their cookies.
 */
public void OnClientCookiesCached(int client) {
    if (IsFakeClient(client))
        return;

    g_Pistolchoice[client]  = GetCookieInt (client, g_hPISTOLChoiceCookie);
    g_Sidechoice[client]  = GetCookieInt (client, g_hSIDEChoiceCookie);
    g_SilencedM4[client] = GetCookieBool(client, g_hM4ChoiceCookie);
    g_AwpChoice[client]  = GetCookieBool(client, g_hAwpChoiceCookie);
}

public void WeaponAllocator(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) 
{
    	int tCount = GetArraySize(tPlayers);
    	int ctCount = GetArraySize(ctPlayers);

	nades_hegrenade_ct_count = 0;
	nades_hegrenade_t_count = 0;
	nades_flashbang_ct_count = 0;
	nades_flashbang_t_count = 0;
	nades_smokegrenade_ct_count = 0;
	nades_smokegrenade_t_count = 0;
	nades_molotov_ct_count = 0;
	nades_molotov_t_count = 0;
	nades_decoy_ct_count = 0;
	nades_decoy_t_count = 0;

    	bool isPistolRound = GetConVarInt(g_h_sm_retakes_weapon_primary_enabled) == 0 || Retakes_GetRetakeRoundsPlayed() < GetConVarInt(g_h_sm_retakes_weapon_pistolrounds);
    	bool mimicCompetitivePistolRounds = GetConVarInt(g_h_sm_retakes_weapon_mimic_competitive_pistol_rounds) == 1;

    	char primary[WEAPON_STRING_LENGTH];
    	char secondary[WEAPON_STRING_LENGTH];
    	char nades[NADE_STRING_LENGTH];

    	int health = 100;
    	int kevlar = 100;
    	bool helmet = true;
    	bool kit = true;
    	int numkits = 0;
 
    	int odds = 0;

    	int awp_given = 0;
    	bool giveTAwp = true;
    	bool giveCTAwp = true;
    	
	if (GetConVarInt(g_h_sm_retakes_weapon_awp_team_max) < 1)
    	{
        	giveTAwp = false;
        	giveCTAwp = false;
    	}
    	int dollars_for_mimic_competitive_pistol_rounds = 800;


//T players
    	for (int i = 0; i < tCount; i++) 
	{
        	int client = GetArrayCell(tPlayers, i);
      		dollars_for_mimic_competitive_pistol_rounds = 800;
		primary = "";

//T gun round
        	if (!isPistolRound)
        	{
            		int randGiveAwp = GetRandomInt(0, 1);
			
			kit = false;
			kevlar = 100;
			helmet = true;
			health = 100;

            		if (giveTAwp && g_AwpChoice[client] && randGiveAwp == 1 && awp_given < GetConVarInt(g_h_sm_retakes_weapon_awp_team_max)) 
			{
                		primary = "weapon_awp";
                		giveTAwp = false;
				awp_given = awp_given + 1;
            		} 
			else 
			{
                		primary = "weapon_ak47";
            		}
			
//Gun round pistols
			if (g_Sidechoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
				secondary = "weapon_p250";
			}
			else if (g_Sidechoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_tec9";
        		}
        		else if (g_Sidechoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
        		}
        		else if (g_Sidechoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
			}
			else if (g_Sidechoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
        		}		
			else
			{
				secondary = "weapon_glock";
			}
        	}
	
//T Pistol round non competitive
		if(isPistolRound && !mimicCompetitivePistolRounds)
		{
			kit = false;
			kevlar = 100;
			helmet = false;
			health = 100;
			if (g_Pistolchoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
            			secondary = "weapon_p250";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_p250;
        		}
        		else if (g_Pistolchoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_tec9";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_tec9;
        		}
        		else if (g_Pistolchoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_cz;
        		}
        		else if (g_Pistolchoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_elite;
			}
			else if (g_Pistolchoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_deagle;
        		}		
			else
			{
				secondary = "weapon_glock";
			}
		}
	
//T Pistol round competitive
		if(isPistolRound && mimicCompetitivePistolRounds)
		{
        		kit = false;
			helmet = false;
			health = 100;
			kevlar = 0;

			if (g_Pistolchoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
            			secondary = "weapon_p250";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_p250;
        		}
        		else if (g_Pistolchoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_tec9";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_tec9;
        		}
        		else if (g_Pistolchoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_cz;
        		}
        		else if (g_Pistolchoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_elite;
			}
			else if (g_Pistolchoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_deagle;
        		}		
			else
			{
				secondary = "weapon_glock";
			}
		
			if(dollars_for_mimic_competitive_pistol_rounds >= kevlar_price)
			{
				kevlar = 100;
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - kevlar_price;
			}
			else if(dollars_for_mimic_competitive_pistol_rounds < kevlar_price)
			{
				kevlar = 0;
			}
		}
	
		if(!isPistolRound || !mimicCompetitivePistolRounds)
		{
			kit = false;
			kevlar = 100;
			helmet = true;
			health = 100;	

			if (g_Sidechoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
				secondary = "weapon_p250";
			}
			else if (g_Sidechoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_tec9";
        		}
        		else if (g_Sidechoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
        		}
        		else if (g_Sidechoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
			}
			else if (g_Sidechoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
        		}		
			else
			{
				secondary = "weapon_glock";
			}
		}
        
        	SetNades(nades, true, mimicCompetitivePistolRounds && isPistolRound, dollars_for_mimic_competitive_pistol_rounds);
		
		//Testing
		//new String:moneyT[12];
		//IntToString(dollars_for_mimic_competitive_pistol_rounds, moneyT, 12);
		//PrintToChatAll("MoneyT: %s", moneyT);

		//Make sure to give armor if no nades are given
		if(isPistolRound && mimicCompetitivePistolRounds && dollars_for_mimic_competitive_pistol_rounds >= kevlar_price)
		{
			kevlar = true;
			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - kevlar_price;
		}
		
        	Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
	}

//Ct players
	awp_given = 0;
	
	for (int i = 0; i < ctCount; i++) 
	{
		int client = GetArrayCell(ctPlayers, i);
		dollars_for_mimic_competitive_pistol_rounds = 800;
		primary = "";
		
//CT gun round
        	if (!isPistolRound)
        	{
			kit = true;
			kevlar = 100;
			helmet = true;
			health = 100;

			int randGiveAwp = GetRandomInt(0, 1);

           		if (giveCTAwp && g_AwpChoice[client] && randGiveAwp == 1 && awp_given < GetConVarInt(g_h_sm_retakes_weapon_awp_team_max)) 
			{
                		primary = "weapon_awp";
                		giveCTAwp = false;
				awp_given = awp_given + 1;
            		} 
			else if (g_SilencedM4[client]) 
			{
                		primary = "weapon_m4a1_silencer";
            		} 
			else 
			{
                		primary = "weapon_m4a1";
            		}
//Gun round pistols
			if (g_Sidechoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
				secondary = "weapon_p250";
			}
			else if (g_Sidechoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_fiveseven";
        		}
        		else if (g_Sidechoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
        		}
        		else if (g_Sidechoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
			}
			else if (g_Sidechoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
        		}		
			else
			{
				secondary = "weapon_hkp2000";
			}
        	}

//CT Pistol round non competitive
		if(isPistolRound && !mimicCompetitivePistolRounds)
		{
			kit = true;
			kevlar = 100;
			helmet = false;
			health = 100;
		
			if (g_Pistolchoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
            			secondary = "weapon_p250";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_p250;
        		}
        		else if (g_Pistolchoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_fiveseven";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_tec9;
        		}
        		else if (g_Pistolchoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_cz;
        		}
        		else if (g_Pistolchoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_elite;
			}
			else if (g_Pistolchoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_deagle;
        		}		
			else
			{
				secondary = "weapon_hkp2000";
			}
		}

//CT Pistol round competitive
		if(isPistolRound && mimicCompetitivePistolRounds)
		{
        		kevlar = 0;
			kit = false;
			helmet = false;
			health = 100;

			//Testing
			//new String:testCt[12];	
			//new String:testT[12];
			//IntToString(ctCount, testCt, 12);
			//IntToString(tCount, testT, 12);
			//PrintToChatAll("CT Count: %s", testCt);
			//PrintToChatAll("T Count: %s", testT);

			if (g_Pistolchoice[client] == 2 && GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        		{
            			secondary = "weapon_p250";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_p250;
        		}
        		else if (g_Pistolchoice[client] == 3 && GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_fiveseven";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_fiveseven;
        		}
        		else if (g_Pistolchoice[client] == 4 && GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_cz;
        		}
        		else if (g_Pistolchoice[client] == 5 && GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_elite;
			}
			else if (g_Pistolchoice[client] == 6 && GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
				dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - gun_price_for_deagle;
        		}		
			else
			{
				secondary = "weapon_hkp2000";
				if(dollars_for_mimic_competitive_pistol_rounds >= kevlar_price)
				{
					odds = GetRandomInt(1,4);
                 			// 75% to have kevlar if money before kit and nades
                 			if (odds < 4)
                 			{
                        			kevlar = 100;
                        			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - kevlar_price;
                 			}
					else
					{
						kevlar = 0;
					}
				}
				else if(dollars_for_mimic_competitive_pistol_rounds < kevlar_price)
				{
					kevlar = 0;
				}
			}
			if(dollars_for_mimic_competitive_pistol_rounds >= kit_price)
        		{
				int rand = GetRandomInt(1, 4);
				//75% to have a kit
				if(rand < 4)
				{
					kit = true;
					numkits++;
                			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - kit_price;
				}
			}
			else if(dollars_for_mimic_competitive_pistol_rounds < kit_price)
			{
				kit = false;
			}
			
			//If there are no kits, give one if there are 2-4 ct's
			if(ctCount > 1 && ctCount < 5 && numkits < 1)
			{
				kit = true;
				numkits++;
			}
		
		}
	
        	SetNades(nades, false, mimicCompetitivePistolRounds && isPistolRound, dollars_for_mimic_competitive_pistol_rounds);
		
		//Testing
		//new String:money[12];	
		//IntToString(dollars_for_mimic_competitive_pistol_rounds, money, 12);
		//PrintToChatAll("Money: %s", money);

		//Make sure to give armor if no nades or kit are given
		if(isPistolRound && mimicCompetitivePistolRounds && dollars_for_mimic_competitive_pistol_rounds >= kevlar_price)
		{
			kevlar = true;
			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - kevlar_price;
		}
		
        	Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
    	}
}

static void SetNades(char nades[NADE_STRING_LENGTH], bool terrorist, bool competitivePistolRound, int dollars_for_mimic_competitive_pistol_rounds) {
    nades = "";
    if (GetConVarInt(g_h_sm_retakes_weapon_nades_enabled) == 1)
    {
        int max_hegrenade_allow = terrorist ? GetConVarInt(g_h_sm_retakes_weapon_nades_hegrenade_t_max) : GetConVarInt(g_h_sm_retakes_weapon_nades_hegrenade_ct_max);
        int max_flashbang_allow = terrorist ? GetConVarInt(g_h_sm_retakes_weapon_nades_flashbang_t_max) : GetConVarInt(g_h_sm_retakes_weapon_nades_flashbang_ct_max);
        int max_smokegrenade_allow = terrorist ? GetConVarInt(g_h_sm_retakes_weapon_nades_smokegrenade_t_max) : GetConVarInt(g_h_sm_retakes_weapon_nades_smokegrenade_ct_max);
        int max_molotov_allow = terrorist ? GetConVarInt(g_h_sm_retakes_weapon_nades_molotov_t_max) : GetConVarInt(g_h_sm_retakes_weapon_nades_molotov_ct_max);
	int max_decoy_allow = terrorist ? GetConVarInt(g_h_sm_retakes_weapon_nades_decoy_t_max) : GetConVarInt(g_h_sm_retakes_weapon_nades_decoy_ct_max);

	//bool isPistolRound = GetConVarInt(g_h_sm_retakes_weapon_primary_enabled) == 0 || Retakes_GetRetakeRoundsPlayed() < GetConVarInt(g_h_sm_retakes_weapon_pistolrounds);	

        int he_number = 0;
        int smoke_number = 0;
        int flashbang_number = 0;
        int molotov_number = 0;
	int decoy_number = 0;


        int maxgrenades = GetConVarInt(FindConVar("ammo_grenade_limit_total"));
        int maxflashbang = GetConVarInt(FindConVar("ammo_grenade_limit_flashbang"));

        int rand;
	int randgive = 0;
        int indice = 0;
        // be sure to spend all the money on pistol rounds
        for(int i=0; i < 10; i++)
        {
            rand = GetRandomInt(1, 4);

            if (maxgrenades <= indice)
                break;

            if (!competitivePistolRound && indice >= 2)
                break;

            switch(rand) {
		
		//Add chance to give no nade of that type except on comp pistol rounds
		case 1:
			if ((terrorist ? nades_smokegrenade_t_count : nades_smokegrenade_ct_count) < max_smokegrenade_allow && smoke_number == 0)
			{
				randgive = GetRandomInt(1, 3);
				if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds >= nade_price_for_smokegrenade)
					randgive = 1;
				if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds < nade_price_for_smokegrenade)
					randgive = 10;

                    		if(randgive < 2)
				{
						nades[indice] = 's';
                        			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - nade_price_for_smokegrenade;
                        			smoke_number++;
                        			if (terrorist)
							nades_smokegrenade_t_count++;
						else
                            				nades_smokegrenade_ct_count++;
				}
				indice++;
			}
			
		case 2:
			if ((terrorist ? nades_hegrenade_t_count : nades_hegrenade_ct_count) < max_hegrenade_allow && he_number == 0)
                    	{
				randgive = GetRandomInt(1, 2);
				if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds >= nade_price_for_hegrenade)
					randgive = 1;
				if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds < nade_price_for_hegrenade)
					randgive = 10;

				if(randgive < 2)
				{
                      			nades[indice] = 'h';
                        		dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - nade_price_for_hegrenade;
                        		he_number++;
                        		if (terrorist)
                            			nades_hegrenade_t_count++;
                        		else
                            			nades_hegrenade_ct_count++;
				}
				indice++;
                   	}			

                case 3:
			if ((terrorist ? nades_flashbang_t_count : nades_flashbang_ct_count) < max_flashbang_allow && flashbang_number < maxflashbang)
                    	{
				randgive = GetRandomInt(1, 2);
				if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds >= nade_price_for_flashbang)
					randgive = 1;
				if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds < nade_price_for_flashbang)
					randgive = 10;

				if(randgive < 2)
				{
                        		nades[indice] = 'f';
                        		dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - nade_price_for_flashbang;
                        		flashbang_number++;
                        		if (terrorist)
                            			nades_flashbang_t_count++;
                        		else
                           			nades_flashbang_ct_count++;
				}
				indice++;
                   	}

                case 4:
			if ((terrorist ? nades_molotov_t_count : nades_molotov_ct_count) < max_molotov_allow && molotov_number == 0)
                    	{
				//Change percent to 20%
				randgive = GetRandomInt(1, 5);
				
				if(terrorist)
				{
					if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds >= nade_price_for_molotov)
						randgive = 1;
					if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds < nade_price_for_molotov)
						randgive = 10;
				}
				else
				{
					if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds >= nade_price_for_incgrenade)
						randgive = 1;
					if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds < nade_price_for_incgrenade)
						randgive = 10;
				}

                    		if(randgive < 2)
				{	
                        		nades[indice] = terrorist ? 'm' : 'i';
                        		if (terrorist)
                            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - nade_price_for_molotov;
                        		else
                            			dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - nade_price_for_incgrenade;
                        		molotov_number++;
                        		if (terrorist)
                            			nades_molotov_t_count++;
                        		else
                            			nades_molotov_ct_count++;
				}
				else if(randgive > 4 && (terrorist ? nades_decoy_t_count : nades_decoy_ct_count) < max_decoy_allow && decoy_number == 0) //sometimes give decoy
				{
					if(competitivePistolRound && dollars_for_mimic_competitive_pistol_rounds >= nade_price_for_decoy || !competitivePistolRound)
					{
						nades[indice] = 'd';
						dollars_for_mimic_competitive_pistol_rounds = dollars_for_mimic_competitive_pistol_rounds - nade_price_for_decoy;
						if (terrorist)
                            				nades_decoy_t_count++;
                        			else
                            				nades_decoy_ct_count++;
					}
				}
				indice++;
                    	}
            }//switch(rand)

        }//for(int i=0; i < 10; i++)
    }//if (GetConVarInt(g_h_sm_retakes_weapon_nades_enabled) == 1)
}//static void SetNades

public void GivePistolMenu(int client) {
	Handle menu = CreateMenu(MenuHandler_PISTOL);
	SetMenuTitle(menu, "Select pistol round weapon:");
	AddMenuInt(menu, 1, "Glock/P2000/USP-S");
	if (GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
		AddMenuInt(menu, 2, "p250");
    	if (GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
    		AddMenuInt(menu, 3, "Fiveseven/Tec-9");
    	if (GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
       	 	AddMenuInt(menu, 4, "CZ75");
	if (GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
       	 	AddMenuInt(menu, 5, "Dual Elite");
   	if (GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
        	AddMenuInt(menu, 6, "Deagle");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_PISTOL(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        int gunchoice = GetMenuInt(menu, param2);
        g_Pistolchoice[client] = gunchoice;
        SetCookieInt(client, g_hPISTOLChoiceCookie, gunchoice);
        GiveWeaponMenu(client);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void GiveWeaponMenu(int client) {
    Handle menu = CreateMenu(MenuHandler_M4);
    SetMenuTitle(menu, "Select a CT rifle:");
    AddMenuBool(menu, false, "M4A4");
    AddMenuBool(menu, true, "M4A1-S");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_M4(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        bool useSilenced = GetMenuBool(menu, param2);
        g_SilencedM4[client] = useSilenced;
        SetCookieBool(client, g_hM4ChoiceCookie, useSilenced);
        if (GetConVarInt(g_h_sm_retakes_weapon_awp_team_max) > 0)
            GiveAwpMenu(client);
        else
            CloseHandle(menu);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void GiveAwpMenu(int client) {
    Handle menu = CreateMenu(MenuHandler_AWP);
    SetMenuTitle(menu, "Allow yourself to receive AWPs?");
    AddMenuBool(menu, true, "Yes");
    AddMenuBool(menu, false, "No");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_AWP(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        bool allowAwps = GetMenuBool(menu, param2);
        g_AwpChoice[client] = allowAwps;
        SetCookieBool(client, g_hAwpChoiceCookie, allowAwps);
	GiveSidearmMenu(client);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void GiveSidearmMenu(int client) {
	Handle menu = CreateMenu(MenuHandler_SIDE);
	SetMenuTitle(menu, "Select pistol for gun rounds:");
    	AddMenuInt(menu, 1, "Glock/P2000/USP-S");
    	if (GetConVarInt(g_h_sm_retakes_weapon_p250_enabled) == 1)
        	AddMenuInt(menu, 2, "P250");
    	if (GetConVarInt(g_h_sm_retakes_weapon_tec9_fiveseven_enabled) == 1)
       		AddMenuInt(menu, 3, "Fiveseven/Tec-9");
    	if (GetConVarInt(g_h_sm_retakes_weapon_cz_enabled) == 1)
        	AddMenuInt(menu, 4, "CZ75");
    	if (GetConVarInt(g_h_sm_retakes_weapon_dual_elite_enabled) == 1)
       		AddMenuInt(menu, 5, "Dual Elite");
	if (GetConVarInt(g_h_sm_retakes_weapon_deagle_enabled) == 1)
        	AddMenuInt(menu, 6, "Deagle");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_SIDE(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        int gunchoice = GetMenuInt(menu, param2);
        g_Sidechoice[client] = gunchoice;
        SetCookieInt(client, g_hSIDEChoiceCookie, gunchoice);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

