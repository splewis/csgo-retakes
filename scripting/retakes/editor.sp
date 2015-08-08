int g_iBeamSprite = 0;
int g_iHaloSprite = 0;
Bombsite g_ShowingSite = BombsiteA;
bool g_ShowingBombSpawns = false;

public Action Command_ReloadSpawns(int client, int args) {
    g_NumSpawns = ParseSpawns();
    Retakes_Message(client, "Imported %d map spawns.", g_NumSpawns);
    return Plugin_Handled;
}

public Action Command_SaveSpawns(int client, int args) {
    WriteSpawns();
    Retakes_Message(client, "Map spawns saved.");
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

public void MovePlayerToEditMode(int client) {
    SwitchPlayerTeam(client, CS_TEAM_CT);
    CS_RespawnPlayer(client);
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
        Retakes_MessageToAll("!show <a/b> to display spawn points for a site");
        Retakes_MessageToAll("!new <ct/t> <a/b> to add a spawn point");
        Retakes_MessageToAll("!delete to delete the nearest spawn");
        Retakes_MessageToAll("!save to save the spawn points now (otherwise done on map change)");
    }

    return Plugin_Handled;
}

public Action Command_AddPlayer(int client, int args) {
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
        TeamMenu(client);
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

public Action Command_DeleteAllSpawns(int client, int args) {
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
            char teamStr[4] = "CT";
            char siteStr[4];
            GetSiteString(g_SpawnSites[index], siteStr, sizeof(siteStr));
            if (g_SpawnTeams[index] == CS_TEAM_T)
                teamStr = "T";

            Retakes_Message(client, "Teleporting to spawn {GREEN}%d", index);
            Retakes_Message(client, "   Team: \x05%s", teamStr);
            Retakes_Message(client, "   Site: \x05%s", siteStr);
            MoveToSpawn(client, index);
        }
    }

    return Plugin_Handled;
}

public Action Timer_ShowSpawns(Handle timer) {
    if (!g_ShowingSpawns || g_hEditorEnabled.IntValue == 0)
        return Plugin_Continue;

    g_iBeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
    g_iHaloSprite = PrecacheModel("sprites/halo.vmt", true);
    float origin[3];
    float angle[3];

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsValidClient(i) || IsFakeClient(i))
            continue;

        for (int j = 0; j < g_NumSpawns; j++) {
            origin = g_SpawnPoints[j];
            angle = g_SpawnPoints[j];
            if (SpawnFilter(j))
                DisplaySpawnPoint(i, origin, angle, 40.0, g_SpawnTeams[j] == CS_TEAM_CT);
        }
    }

    return Plugin_Continue;
}

stock bool SpawnFilter(int i, int teamFilter=-1) {
    bool showing = !g_SpawnDeleted[i] && g_ShowingSite == g_SpawnSites[i] && (!g_ShowingBombSpawns || CanBombCarrierSpawn(i));
    if (teamFilter == -1)
        return showing;
    else
        return showing && g_SpawnTeams[i] == teamFilter;
}

public void TeamMenu(int client) {
    Handle menu = CreateMenu(TeamHandler);
    SetMenuExitButton(menu, false);
    SetMenuTitle(menu, "Which team is this player on");
    AddMenuBool(menu, true, "CT");
    AddMenuBool(menu, false, "T");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int TeamHandler(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        bool ct = GetMenuBool(menu, param2);
        g_SpawnTeams[g_NumSpawns] = ct ? CS_TEAM_CT : CS_TEAM_T;
        GetClientAbsOrigin(client, g_SpawnPoints[g_NumSpawns]);
        GetClientEyeAngles(client, g_SpawnAngles[g_NumSpawns]);
        BombsiteMenu(client);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void BombsiteMenu(int client) {
    Handle menu = CreateMenu(BombsiteHandler);
    SetMenuExitButton(menu, false);
    SetMenuTitle(menu, "Which bombsite is this spawn for?");
    AddMenuBool(menu, true, "A");
    AddMenuBool(menu, false, "B");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int BombsiteHandler(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        bool aSite = GetMenuBool(menu, param2);
        g_SpawnSites[g_NumSpawns] = aSite ? BombsiteA : BombsiteB;
        FinishSpawn();
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void FinishSpawn() {
    char bombsite[4];
    bombsite = (g_SpawnSites[g_NumSpawns] == BombsiteA) ? "A" : "B";
    char team[4];
    team = (g_SpawnTeams[g_NumSpawns] == CS_TEAM_CT) ? "CT" : "T";
    g_SpawnDeleted[g_NumSpawns] = false;
    g_SpawnOnlyBomb[g_NumSpawns] = false;
    g_SpawnNoBomb[g_NumSpawns] = false;
    g_NumSpawns++;
    Retakes_MessageToAll("Finished adding %s spawn for %s.", team, bombsite);
}

public void DisplaySpawnPoint(int client, const float position[3], const float angles[3], float size, bool ct) {
    float direction[3];

    GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(direction, size/2);
    AddVectors(position, direction, direction);

    int r, g, b, a;
    if (ct) {
        r = 0;
        g = 0;
        b = 255;
        a = 255;
    } else {
        r = 255;
        g = 0;
        b = 0;
        a = 255;
    }

    TE_Start("BeamRingPoint");
    TE_WriteVector("m_vecCenter", position);
    TE_WriteFloat("m_flStartRadius", 10.0);
    TE_WriteFloat("m_flEndRadius", size);
    TE_WriteNum("m_nModelIndex", g_iBeamSprite);
    TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", 1.0);
    TE_WriteFloat("m_fWidth", 1.0);
    TE_WriteFloat("m_fEndWidth", 1.0);
    TE_WriteFloat("m_fAmplitude", 0.0);
    TE_WriteNum("r", r);
    TE_WriteNum("g", g);
    TE_WriteNum("b", b);
    TE_WriteNum("a", a);
    TE_WriteNum("m_nSpeed", 50);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", 0);
    TE_SendToClient(client);

    TE_Start("BeamPoints");
    TE_WriteVector("m_vecStartPoint", position);
    TE_WriteVector("m_vecEndPoint", direction);
    TE_WriteNum("m_nModelIndex", g_iBeamSprite);
    TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", 1.0);
    TE_WriteFloat("m_fWidth", 1.0);
    TE_WriteFloat("m_fEndWidth", 1.0);
    TE_WriteFloat("m_fAmplitude", 0.0);
    TE_WriteNum("r", r);
    TE_WriteNum("g", g);
    TE_WriteNum("b", b);
    TE_WriteNum("a", a);
    TE_WriteNum("m_nSpeed", 50);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", 0);
    TE_SendToClient(client);
}

stock int FindClosestSpawn(int client, int teamFilter=-1) {
    int closest = -1;
    float minDist = 0.0;
    for (int i = 0; i < g_NumSpawns; i++) {
        if (!SpawnFilter(i, teamFilter))
            continue;

        float origin[3];
        origin = g_SpawnPoints[i];

        float playerOrigin[3];
        GetClientAbsOrigin(client, playerOrigin);

        float dist = GetVectorDistance(origin, playerOrigin);
        if (closest < 0 || dist < minDist) {
            minDist = dist;
            closest = i;
        }
    }
    return closest;
}

public void DeleteClosestSpawn(int client) {
    int closest = FindClosestSpawn(client);
    if (closest >= 0) {
        Retakes_MessageToAll("Deleted spawn %d", closest);
        g_SpawnDeleted[closest] = true;
    }
}
