/**
 * Initializes the queue and returns a new handle to it that must be closed.
 */
public Handle Queue_Init() {
    Handle queueHandle = CreateArray();
    ClearArray(queueHandle);
    return queueHandle;
}

/**
 * Push a Client to the end of the Queue (don't add a client if already in queue).
 */
public void Queue_Enqueue(Handle queueHandle, int client) {
    if (Queue_Find(queueHandle, client) == -1)
        PushArrayCell(queueHandle, client);
}

public void Queue_EnqueueFront(Handle queueHandle, int client) {
    if (Queue_Find(queueHandle, client) != -1)
        return;

    if (GetArraySize(queueHandle) == 0) {
        Queue_Enqueue(queueHandle, client);
    } else {
        ShiftArrayUp(queueHandle, 0);
        SetArrayCell(queueHandle, 0, client);
    }
}

/**
 * Finds a client in the Queue and returns their index.
 */
public int Queue_Find(Handle queueHandle, int client) {
    return FindValueInArray(queueHandle, client);
}

/**
 * Drops a client from the Queue.
 */
public void Queue_Drop(Handle queueHandle, int client) {
    new index = Queue_Find(queueHandle, client);
    if (index != -1)
        RemoveFromArray(queueHandle, index);
}

/**
 * Get queue length, does not validate clients in queue.
 */
public int Queue_Length(Handle queueHandle) {
    return GetArraySize(queueHandle);
}

/**
 * Test if queue is empty.
 */
public bool Queue_IsEmpty(Handle queueHandle) {
    return Queue_Length(queueHandle) == 0;
}

/**
 * Peeks the head of the queue.
 */
public int Queue_Peek(Handle queueHandle) {
    return GetArrayCell(queueHandle, 0);
}

/**
 * Fetch next client from queue.
 */
public int Queue_Dequeue(Handle queueHandle) {
    int val = Queue_Peek(queueHandle);
    RemoveFromArray(queueHandle, 0);
    return val;
}

/**
 * Closes the handle for the queue.
 */
public void Queue_Destroy(Handle queueHandle) {
    CloseHandle(queueHandle);
}
