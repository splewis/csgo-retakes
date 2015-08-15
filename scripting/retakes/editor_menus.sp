stock void GiveEditorMenu(int client, int menuPosition=-1) {
    Menu menu = CreateMenu(EditorMenuHandler);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "Retakes spawn editor");
    AddMenuItem(menu, "show_spawns", "Show spawns");
    AddMenuItem(menu, "add_spawn", "Add a spawn");
    AddMenuItem(menu, "delete_nearest_spawn", "Delete nearest spawn");
    AddMenuItem(menu, "save_spawns", "Save spawns");
    AddMenuItem(menu, "delete_map_spawns", "Delete all map spawns");
    AddMenuItem(menu, "reload_spawns", "Reload map spawns (reset current changes)");

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

        if (StrEqual(choice, "add_spawn")) {
            NewSpawnMenu(client);

        } else if (StrEqual(choice, "show_spawns")) {
            ShowSpawnsMenu(client);

        } else if (StrEqual(choice, "delete_nearest_spawn")) {
            DeleteClosestSpawn(client);
            GiveEditorMenu(client, menuPosition);

        } else if (StrEqual(choice, "delete_map_spawns")) {
            DeleteClosestSpawn(client);
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
        CloseHandle(menu);
    }
}

public void NewSpawnMenu(int client) {
    Menu menu = new Menu(NewSpawnMenuHandler);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "Spawn settings");
    AddMenuItem(menu, "finish", "Finish spawn");
    AddMenuOption(menu, "team", "Team: %s", TEAMSTRING(g_SpawnTeams[g_NumSpawns]));
    AddMenuOption(menu, "site", "Bombsite: %s", SITESTRING(g_SpawnSites[g_NumSpawns]));
    // TODO: add nobomb/bombonly status here if team == T
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int NewSpawnMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        char choice[64];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        if (StrEqual(choice, "finish")) {
            FinishSpawn();
        } else if (StrEqual(choice, "team")) {
            g_SpawnTeams[g_NumSpawns] = GetOtherTeam(g_SpawnTeams[g_NumSpawns]);
        } else if (StrEqual(choice, "site")) {
            g_SpawnSites[g_NumSpawns] = GetOtherSite(g_SpawnSites[g_NumSpawns]);
        } else {
            LogError("[NewSpawnMenuHandler] unknown info string = %s", choice);
        }
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void ShowSpawnsMenu(int client) {
    Menu menu = new Menu(ShowSpawnsMenuHandler);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "Show spawn points");
    AddMenuOption(menu, "site", "Bombsite: %s", SITESTRING(g_ShowingSite));
    // TODO: add nobomb/bombonly status here
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int ShowSpawnsMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        char choice[64];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        if (StrEqual(choice, "site")) {
            g_ShowingSite = GetOtherSite(g_ShowingSite);
        } else {
            LogError("[ShowSpawnsMenuHandler]: unknown info string = %s", choice);
        }
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}
