public Action Command_ReloadSpawns(int client, int args) {
    ReloadSpawns();
    return Plugin_Handled;
}

public Action Command_SaveSpawns(int client, int args) {
    SaveSpawns();
    return Plugin_Handled;
}

public Action Command_Bomb(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    g_ShowingBombSpawns = !g_ShowingBombSpawns;
    if (g_ShowingBombSpawns)
        Retakes_MessageToAll("Now showing only bomb-site spawns");
    else
        Retakes_MessageToAll("Now showing all spawns");

    return Plugin_Handled;
}

public Action Command_EditSpawns(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    if (!g_EditMode) {
        g_EditMode = true;
        g_DirtySpawns = true;
        StartPausedWarmup();
        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && !IsFakeClient(i)) {
                MovePlayerToEditMode(i);
            }
        }

        Retakes_MessageToAll("Edit mode launched, basic commands:");
        Retakes_MessageToAll("!edit to bring up the editor menu");
        Retakes_MessageToAll("!show <a/b> to display spawn points for a site");
        Retakes_MessageToAll("!new <ct/t> <a/b> to add a spawn point");
        Retakes_MessageToAll("!delete to delete the nearest spawn");
        Retakes_MessageToAll("!save to save the spawn points now (otherwise done on map change)");
    }

    GiveEditorMenu(client);

    return Plugin_Handled;
}

public Action Command_AddSpawn(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    char arg1[32];
    char arg2[32];
    if (args >= 2 && GetCmdArg(1, arg1, sizeof(arg1)) && GetCmdArg(2, arg2, sizeof(arg2))) {
        int team;
        if (StrEqual(arg1, "CT", false)) {
            team = CS_TEAM_CT;
        } else if (StrEqual(arg1, "T", false)) {
            team = CS_TEAM_T;
        } else {
            ReplyToCommand(client, "Invalid team name: %s", arg1);
            return Plugin_Handled;
        }

        Bombsite site;
        if (StrEqual(arg2, "A", false)) {
            site = BombsiteA;
        } else if (StrEqual(arg2, "B", false)) {
            site = BombsiteB;
        } else {
            ReplyToCommand(client, "Invalid bomb site name: %s", arg2);
            return Plugin_Handled;
        }

        g_SpawnTeams[g_NumSpawns] = team;
        g_SpawnSites[g_NumSpawns] = site;
        GetClientAbsOrigin(client, g_SpawnPoints[g_NumSpawns]);
        GetClientEyeAngles(client, g_SpawnAngles[g_NumSpawns]);
        FinishSpawn();
    } else {
        NewSpawnMenu(client);
    }

    return Plugin_Handled;
}

public Action Command_Show(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    if (!g_EditMode) {
        Retakes_Message(client, "You aren't in edit mode!");
        return Plugin_Handled;
    }

    char arg1[32];
    if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1))) {
        if (StrEqual(arg1, "a", false)) {
            Retakes_MessageToAll("Showing spawns for bombsite \x04A.");
            g_ShowingSite = BombsiteA;
        } else {
            Retakes_MessageToAll("Showing spawns for bombsite \x04B.");
            g_ShowingSite = BombsiteB;
        }

        int ct_count = 0;
        int t_count = 0;
        for (int i = 0; i < g_NumSpawns; i++) {
            if (!g_SpawnDeleted[i] && g_SpawnSites[i] == g_ShowingSite) {
                if (g_SpawnTeams[i] == CS_TEAM_CT)
                    ct_count++;
                else
                    t_count++;
            }
        }
        Retakes_MessageToAll("Found %d CT spawns.", ct_count);
        Retakes_MessageToAll("Found %d T spawns.", t_count);

        g_ShowingBombSpawns = false;
        g_EditMode = true;
        g_ShowingSpawns = true;
    } else {
        ReplyToCommand(client, "Usage: sm_show <site>");
    }
    return Plugin_Handled;
}

public Action Command_NoBomb(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    int closest = FindClosestSpawn(client, CS_TEAM_T);
    if (closest >= 0) {
        Retakes_MessageToAll("Swapping nobomb status for spawn %d.", closest);
        g_SpawnNoBomb[closest] = !g_SpawnNoBomb[closest];
    }
    return Plugin_Handled;
}
public Action Command_OnlyBomb(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    int closest = FindClosestSpawn(client, CS_TEAM_T);
    if (closest >= 0) {
        Retakes_MessageToAll("Swapping onlybomb status for spawn %d.", closest);
        g_SpawnOnlyBomb[closest] = !g_SpawnOnlyBomb[closest];
    }
    return Plugin_Handled;
}

public Action Command_DeleteSpawn(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    DeleteClosestSpawn(client);
    return Plugin_Handled;
}

public Action Command_DeleteMapSpawns(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    for (int i = 0; i < g_NumSpawns; i++) {
        g_SpawnDeleted[i] = true;
    }

    Retakes_MessageToAll("All spawns for this map have been deleted");
    return Plugin_Handled;
}

public Action Command_IterateSpawns(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    int startIndex = 0;
    char buf[32];
    if (args >= 1 && GetCmdArg(1, buf, sizeof(buf))) {
        startIndex = StringToInt(buf);
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientSerial(client));
    pack.WriteCell(startIndex);
    CreateTimer(2.0, Timer_IterateSpawns, pack);
    return Plugin_Handled;
}

public Action Timer_IterateSpawns(Handle timer, Handle data) {
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int serial = pack.ReadCell();
    int spawnIndex = pack.ReadCell();
    int client = GetClientFromSerial(serial);
    delete pack;

    if (!IsPlayer(client))
        return Plugin_Handled;

    FakeClientCommand(client, "sm_goto %d", spawnIndex);

    spawnIndex++;
    while (g_SpawnDeleted[spawnIndex] && spawnIndex < g_NumSpawns) {
        spawnIndex++;
    }

    if (!g_SpawnDeleted[spawnIndex] && !g_SpawnDeleted[spawnIndex]) {
        pack = new DataPack();
        pack.WriteCell(serial);
        pack.WriteCell(spawnIndex);
        CreateTimer(2.0, Timer_IterateSpawns, pack);
    }

    return Plugin_Handled;
}

public Action Command_GotoSpawn(int client, int args) {
    if (g_hEditorEnabled.IntValue == 0) {
        Retakes_Message(client, "The editor is currently disabled.");
        return Plugin_Handled;
    }

    char buf[32];
    if (args >= 1 && GetCmdArg(1, buf, sizeof(buf))) {
        int index = StringToInt(buf);
        if (index < g_NumSpawns && !g_SpawnDeleted[index]) {
            Retakes_Message(client, "Teleporting to spawn {GREEN}%d", index);
            Retakes_Message(client, "   Team: {MOSS_GREEN}%s", TEAMSTRING(g_SpawnTeams[index]));
            Retakes_Message(client, "   Site: {MOSS_GREEN}%s", SITESTRING(g_SpawnSites[index]));
            MoveToSpawn(client, index);
        }
    }

    return Plugin_Handled;
}
