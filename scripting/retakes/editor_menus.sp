stock void GiveEditorMenu(int client, int menuPosition=-1) {
    Menu menu = new Menu(EditorMenuHandler);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "Retakes spawn editor");
    AddMenuItem(menu, "end_edit", "Exit edit mode");
    AddMenuItem(menu, "show_spawns", "Show spawns");
    AddMenuItem(menu, "add_spawn", "Add a spawn");
    AddMenuItem(menu, "delete_nearest_spawn", "Delete nearest spawn");
    AddMenuItem(menu, "save_spawns", "Save spawns");
    AddMenuItem(menu, "delete_map_spawns", "Delete all map spawns");
    AddMenuItem(menu, "reload_spawns", "Reload map spawns (discared current changes)");

    if (menuPosition == -1) {
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    } else {
        DisplayMenuAtItem(menu, client, menuPosition, MENU_TIME_FOREVER);
    }
}

public int EditorMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char choice[64];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        int menuPosition = GetMenuSelectionPosition();

        if (StrEqual(choice, "end_edit")) {
            Retakes_MessageToAll("Exiting edit mode.");
            g_EditMode = false;
            ServerCommand("mp_warmup_end");

        } else if (StrEqual(choice, "add_spawn")) {
            GiveNewSpawnMenu(client);

        } else if (StrEqual(choice, "show_spawns")) {
            GiveShowSpawnsMenu(client);

        } else if (StrEqual(choice, "delete_nearest_spawn")) {
            DeleteClosestSpawn(client);
            GiveEditorMenu(client, menuPosition);

        } else if (StrEqual(choice, "delete_map_spawns")) {
            DeleteMapSpawns();
            GiveEditorMenu(client, menuPosition);

        } else if (StrEqual(choice, "save_spawns")) {
            SaveSpawns();
            GiveEditorMenu(client, menuPosition);

        }  else if (StrEqual(choice, "reload_spawns")) {
            ReloadSpawns();
            GiveEditorMenu(client, menuPosition);

        } else {
            LogError("[EditorMenuHandler] unknown info string = %s", choice);
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

public void GiveNewSpawnMenu(int client) {
    Menu menu = new Menu(GiveNewSpawnMenuHandler);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "Spawn settings");
    AddMenuOption(menu, "finish", "Finish spawn");
    AddMenuOption(menu, "team", "Team: %s", TEAMSTRING(g_SpawnTeams[g_NumSpawns]));
    AddMenuOption(menu, "site", "Bombsite: %s", SITESTRING(g_SpawnSites[g_NumSpawns]));

    char typeString[128];
    if (g_SpawnTypes[g_NumSpawns] == SpawnType_Normal) {
        Format(typeString, sizeof(typeString), "Normal");
    } else if (g_SpawnTypes[g_NumSpawns] == SpawnType_OnlyWithBomb) {
        Format(typeString, sizeof(typeString), "Bomb-carrier only");
    } else {
        Format(typeString, sizeof(typeString), "Never bomb-carrier");
    }
    if (g_SpawnTeams[g_NumSpawns] == CS_TEAM_CT) {
        AddMenuOptionDisabled(menu, "type", "T spawn type: %s", typeString);
    } else {
        AddMenuOption(menu, "type", "T spawn type: %s", typeString);
    }

    AddMenuOption(menu, "back", "Back");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int GiveNewSpawnMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char choice[64];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        if (StrEqual(choice, "finish")) {
            FinishSpawn();
            GiveNewSpawnMenu(client);
        } else if (StrEqual(choice, "team")) {
            g_SpawnTeams[g_NumSpawns] = GetOtherTeam(g_SpawnTeams[g_NumSpawns]);
            GiveNewSpawnMenu(client);
        } else if (StrEqual(choice, "site")) {
            g_SpawnSites[g_NumSpawns] = GetOtherSite(g_SpawnSites[g_NumSpawns]);
            GiveNewSpawnMenu(client);
        } else if (StrEqual(choice, "type")) {
            g_SpawnTypes[g_NumSpawns] = NextSpawnType(g_DisplaySpawnMode);
            GiveNewSpawnMenu(client);
        } else if (StrEqual(choice, "back")) {
            GiveEditorMenu(client);
        }  else {
            LogError("[NewSpawnMenuHandler] unknown info string = %s", choice);
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

public void GiveShowSpawnsMenu(int client) {
    Menu menu = new Menu(ShowSpawnsMenuHandler);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "Show spawn points");
    AddMenuOption(menu, "site", "Bombsite: %s", SITESTRING(g_ShowingSite));

    char typeString[128];
    if (g_DisplaySpawnMode == SpawnType_Normal) {
        Format(typeString, sizeof(typeString), "All spawns");
    } else if (g_DisplaySpawnMode == SpawnType_OnlyWithBomb) {
        Format(typeString, sizeof(typeString), "Only bomb-carrier spawns");
    } else {
        Format(typeString, sizeof(typeString), "Never bomb-carrier spawns");
    }
    AddMenuOption(menu, "type", "T spawn type: %s", typeString);

    AddMenuOption(menu, "back", "Back");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int ShowSpawnsMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char choice[64];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        if (StrEqual(choice, "site")) {
            ShowSpawns(GetOtherSite(g_ShowingSite));
            GiveShowSpawnsMenu(client);
        } else if (StrEqual(choice, "back")) {
            GiveEditorMenu(client);
        } else if (StrEqual(choice, "type")) {
            g_SpawnTypes[g_NumSpawns] = NextSpawnType(g_DisplaySpawnMode);
            GiveShowSpawnsMenu(client);
        } else {
            LogError("[ShowSpawnsMenuHandler]: unknown info string = %s", choice);
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

public SpawnType NextSpawnType(SpawnType type) {
    if (type == SpawnType_Normal) {
        return SpawnType_OnlyWithBomb;
    } else if (type == SpawnType_OnlyWithBomb) {
        return SpawnType_NeverWithBomb;
    } else {
        return SpawnType_Normal;
    }
}
