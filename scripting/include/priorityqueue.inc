#if defined _priorityqueue_included
  #endinput
#endif
#define _priorityqueue_included

/**
 * Initializes the queue and returns a handle to it that must be closed.
 */
stock ArrayList PQ_Init() {
    ArrayList queueHandle = new ArrayList(2);
    return queueHandle;
}

/**
 * Adds a player and a value to the queue.
 * If the player is already in the queue, their score is updated in place.
 */
stock void PQ_Enqueue(ArrayList queueHandle, int client, int value) {
    int index = PQ_FindClient(queueHandle, client);

    // if they're not already in, put them at the end
    if (index == -1) {
        index = queueHandle.Length;
        queueHandle.Push(client);
        queueHandle.Set(index, client, 0);
    }

    // set their value
    queueHandle.Set(index, value, 1);
}

/**
 * Selects the player with the max value in the queue and removes them, returning their client index.
 */
stock int PQ_Dequeue(ArrayList queueHandle) {
    int maxIndex = -1;
    int maxClient = -1;
    int maxScore = -1;

    for (int i = 0; i < queueHandle.Length; i++) {
        int client = queueHandle.Get(i, 0);
        int score = queueHandle.Get(i, 1);
        if (maxIndex == -1 || score > maxScore) {
            maxIndex = i;
            maxClient = client;
            maxScore = score;
        }
    }
    if (maxIndex != -1) {
        queueHandle.Erase(maxIndex);
    }
    return maxClient;
}

/**
 * Finds an index of the client in the queue. Returns -1 if the client isn't in it.
 */
stock int PQ_FindClient(ArrayList queueHandle, int client) {
    for (int i = 0; i < queueHandle.Length; i++) {
        int c = queueHandle.Get(i, 0);
        if (client == c)
            return i;
    }
    return -1;
}

/**
 * Drops a client from the queue completely.
 */
stock void PQ_DropFromQueue(ArrayList queueHandle, int client) {
    int index = PQ_FindClient(queueHandle, client);
    if (index != -1)
        queueHandle.Erase(index);
}

/**
 * Returns the current size of the queue.
 */
stock int PQ_GetSize(ArrayList queueHandle) {
    return queueHandle.Length;
}

/**
 * Returns is the queu is empty.
 */
stock bool PQ_IsEmpty(ArrayList queueHandle) {
    return PQ_GetSize(queueHandle) == 0;
}

/**
 * Clears all entires in a queue.
 */
stock void PQ_Clear(ArrayList queueHandle) {
    queueHandle.Clear();
}

/**
 * Clears the Handle for a queue.
 */
stock void PQ_Destroy(ArrayList queueHandle) {
    delete queueHandle;
}
