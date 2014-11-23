#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include "include/retakes.inc"
#include "retakes/generic.sp"

#define MENU_TIME_LENGTH 15

bool g_SilencedM4[MAXPLAYERS+1];
bool g_AwpChoice[MAXPLAYERS+1];
Handle g_hM4ChoiceCookie = INVALID_HANDLE;
Handle g_hAwpChoiceCookie = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "CS:GO Retakes: standard weapon allocator",
    author = "splewis",
    description = "Defines a simple weapon allocation policy and lets players set weapon preferences",
    version = PLUGIN_VERSION,
    url = "https://github.com/splewis/csgo-retakes"
};

public void OnPluginStart() {
    g_hM4ChoiceCookie = RegClientCookie("retakes_m4choice", "", CookieAccess_Private);
    g_hAwpChoiceCookie = RegClientCookie("retakes_awpchoice", "", CookieAccess_Private);
}

public void OnClientConnected(client) {
    g_SilencedM4[client] = false;
    g_AwpChoice[client] = false;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
    char gunsChatCommands[][] = { "gun", "guns", ".gun", ".guns", ".setup", "!gun", "!guns", "gnus" };
    for (int i = 0; i < sizeof(gunsChatCommands); i++) {
        if (strcmp(args[0], gunsChatCommands[i], false) == 0) {
            GiveRifleMenu(client);
            break;
        }
    }

    return Plugin_Continue;
}

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
    RifleAllocator(tPlayers, ctPlayers, bombsite);
}

/**
 * Updates client weapon settings according to their cookies.
 */
public OnClientCookiesCached(client) {
    if (IsFakeClient(client))
        return;

    g_SilencedM4[client] = GetCookieBool(client, g_hM4ChoiceCookie);
    g_AwpChoice[client] = GetCookieBool(client, g_hAwpChoiceCookie);
}

public RifleAllocator(Handle tPlayers, Handle ctPlayers, Bombsite bombsite) {
    int tCount = GetArraySize(tPlayers);
    int ctCount = GetArraySize(ctPlayers);

    char primary[WEAPON_STRING_LENGTH];
    char secondary[WEAPON_STRING_LENGTH];
    char nades[NADE_STRING_LENGTH];
    int health = 100;
    int kevlar = 100;
    bool helmet = true;
    bool kit = true;

    for (int i = 0; i < tCount; i++) {
        int client = GetArrayCell(tPlayers, i);

        primary = "weapon_ak47";
        secondary = "weapon_glock";
        health = 100;
        kevlar = 100;
        helmet = true;
        kit = false;

        Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
    }

    for (int i = 0; i < ctCount; i++) {
        int client = GetArrayCell(ctPlayers, i);

        primary = "weapon_m4a1";
        secondary = "weapon_hkp2000";
        nades = "";
        kit = true;
        health = 100;
        kevlar = 100;
        helmet = true;

        Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
    }
}

public GiveRifleMenu(int client) {
    Handle menu = CreateMenu(MenuHandler_M4);
    SetMenuTitle(menu, "Select a CT rifle:");
    AddMenuBool(menu, false, "M4A4");
    AddMenuBool(menu, true, "M4A1-S");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public MenuHandler_M4(Handle menu, MenuAction action, param1, param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        bool useSilenced = GetMenuBool(menu, param2);
        g_SilencedM4[client] = useSilenced;
        SetCookieBool(client, g_hM4ChoiceCookie, useSilenced);
        GiveAwpMenu(client);
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

public MenuHandler_AWP(Handle menu, MenuAction action, param1, param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        bool allowAwps = GetMenuBool(menu, param2);
        g_AwpChoice[client] = allowAwps;
        SetCookieBool(client, g_hAwpChoiceCookie, allowAwps);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}
