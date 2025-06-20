# Polyglot App Framework API Reference

## Overview

The Polyglot App Framework provides a comprehensive API for building applications using multiple programming languages. This document covers all the APIs available across different language modules.

## Table of Contents

1. [Interop Server API](#interop-server-api)
2. [TypeScript Client API](#typescript-client-api)
3. [Python Client API](#python-client-api)
4. [Go Client API](#go-client-api)
5. [Web UI API](#web-ui-api)
6. [Mobile API](#mobile-api)
7. [AI Module API](#ai-module-api)
8. [Database API](#database-api)

## Interop Server API

The Interop Server is the central communication hub for all language modules.

### Base URL
```
http://localhost:4000
```

### Endpoints

#### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "modules": ["typescript-module", "python-ai", "go-db"],
  "queueSize": 5
}
```

#### Register Module
```http
POST /register
Content-Type: application/json

{
  "name": "my-module",
  "language": "typescript",
  "endpoints": ["rpc"],
  "port": 3001
}
```

**Response:**
```json
{
  "success": true,
  "message": "Module my-module registered successfully"
}
```

#### Unregister Module
```http
DELETE /register/{moduleName}
```

#### List Modules
```http
GET /modules
```

**Response:**
```json
{
  "modules": [
    {
      "name": "typescript-module",
      "language": "typescript",
      "endpoints": ["rpc"],
      "port": 3001,
      "registeredAt": "2024-01-15T10:30:00Z",
      "lastSeen": "2024-01-15T10:35:00Z"
    }
  ],
  "total": 1
}
```

#### RPC Call
```http
POST /rpc
Content-Type: application/json

{
  "target": "python-ai",
  "method": "recommend",
  "params": {
    "userId": 123,
    "preferences": ["tech", "science"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "result": {
    "recommendations": [
      {"id": 1, "title": "AI Basics", "score": 0.95},
      {"id": 2, "title": "Machine Learning", "score": 0.87}
    ]
  },
  "timestamp": "2024-01-15T10:35:00Z"
}
```

#### Queue Message
```http
POST /queue
Content-Type: application/json

{
  "target": "go-db",
  "method": "saveData",
  "params": {
    "table": "users",
    "data": {"name": "John", "email": "john@example.com"}
  },
  "priority": 1
}
```

**Response:**
```json
{
  "success": true,
  "messageId": "msg_1705312500_abc123def",
  "queueSize": 6
}
```

#### Get Queue
```http
GET /queue
```

#### Process Queue
```http
POST /queue/process
Content-Type: application/json

{
  "limit": 10
}
```

## TypeScript Client API

### Installation
```bash
npm install @polyglot/interop-client
```

### Basic Usage
```typescript
import { createInteropClient } from '@polyglot/interop-client';

const client = createInteropClient({
  moduleName: 'my-typescript-module',
  port: 3001
});

await client.init();
```

### Methods

#### `init(): Promise<void>`
Initialize the client and register with the interop server.

#### `register(): Promise<void>`
Register this module with the interop server.

#### `unregister(): Promise<void>`
Unregister this module from the interop server.

#### `call(target: string, method: string, params?: any): Promise<any>`
Make a synchronous RPC call to another module.

```typescript
const result = await client.call('python-ai', 'recommend', {
  userId: 123,
  preferences: ['tech', 'science']
});
```

#### `send(target: string, method: string, params?: any, priority?: number): Promise<string>`
Send an asynchronous message to another module.

```typescript
const messageId = await client.send('go-db', 'saveData', {
  table: 'users',
  data: { name: 'John', email: 'john@example.com' }
}, 1);
```

#### `getQueue(): Promise<InteropMessage[]>`
Get the current message queue.

#### `processQueue(limit?: number): Promise<any[]>`
Process messages from the queue.

#### `getModules(): Promise<ModuleInfo[]>`
Get list of all registered modules.

#### `health(): Promise<any>`
Check server health.

#### `sendWebSocket(target: string, method: string, params?: any): Promise<any>`
Send a WebSocket message and wait for response.

#### `subscribe(target: string): void`
Subscribe to module events.

#### `close(): Promise<void>`
Close the client and cleanup.

## Python Client API

### Installation
```bash
pip install polyglot-interop-client
```

### Basic Usage
```python
from polyglot_interop_client import create_interop_client, InteropConfig

config = InteropConfig(
    module_name="my-python-module",
    port=5000
)

async with create_interop_client(config) as client:
    # Use the client
    pass
```

### Methods

#### `init() -> None`
Initialize the client and register with the interop server.

#### `register() -> None`
Register this module with the interop server.

#### `unregister() -> None`
Unregister this module from the interop server.

#### `call(target: str, method: str, params: Dict[str, Any] = None) -> Any`
Make a synchronous RPC call to another module.

```python
result = await client.call("typescript-module", "processData", {
    "data": [1, 2, 3, 4, 5]
})
```

#### `send(target: str, method: str, params: Dict[str, Any] = None, priority: int = 0) -> str`
Send an asynchronous message to another module.

```python
message_id = await client.send("go-module", "saveData", {
    "table": "users",
    "data": {"name": "John", "email": "john@example.com"}
}, priority=1)
```

#### `get_queue() -> List[InteropMessage]`
Get the current message queue.

#### `process_queue(limit: int = 10) -> List[Any]`
Process messages from the queue.

#### `get_modules() -> List[ModuleInfo]`
Get list of all registered modules.

#### `health() -> Dict[str, Any]`
Check server health.

#### `send_websocket(target: str, method: str, params: Dict[str, Any] = None) -> Any`
Send a WebSocket message and wait for response.

#### `subscribe(target: str) -> None`
Subscribe to module events.

#### `close() -> None`
Close the client and cleanup.

## Go Client API

### Installation
```bash
go get github.com/polyglot/interop-client
```

### Basic Usage
```go
package main

import (
    "log"
    "github.com/polyglot/interop-client"
)

func main() {
    client := interop.NewClient(&interop.Config{
        ServerURL:   "http://localhost:4000",
        ModuleName:  "my-go-module",
        Language:    "go",
        Port:        8080,
        AutoRegister: true,
    })
    
    defer client.Close()
    
    if err := client.Init(); err != nil {
        log.Fatal(err)
    }
}
```

### Methods

#### `Init() error`
Initialize the client and register with the interop server.

#### `Register() error`
Register this module with the interop server.

#### `Unregister() error`
Unregister this module from the interop server.

#### `Call(target, method string, params interface{}) (interface{}, error)`
Make a synchronous RPC call to another module.

```go
result, err := client.Call("python-ai", "recommend", map[string]interface{}{
    "userId": 123,
    "preferences": []string{"tech", "science"},
})
```

#### `Send(target, method string, params interface{}, priority int) (string, error)`
Send an asynchronous message to another module.

```go
messageID, err := client.Send("typescript-module", "saveData", map[string]interface{}{
    "table": "users",
    "data": map[string]interface{}{
        "name": "John",
        "email": "john@example.com",
    },
}, 1)
```

#### `GetQueue() ([]InteropMessage, error)`
Get the current message queue.

#### `ProcessQueue(limit int) ([]interface{}, error)`
Process messages from the queue.

#### `GetModules() ([]ModuleInfo, error)`
Get list of all registered modules.

#### `Health() (map[string]interface{}, error)`
Check server health.

#### `Close() error`
Close the client and cleanup.

## Web UI API

### React Components

#### `InteropProvider`
Context provider for interop functionality.

```tsx
import { InteropProvider } from '@polyglot/web-ui';

function App() {
  return (
    <InteropProvider>
      <YourApp />
    </InteropProvider>
  );
}
```

#### `useInterop()`
Hook for accessing interop functionality.

```tsx
import { useInterop } from '@polyglot/web-ui';

function MyComponent() {
  const { call, send, modules } = useInterop();
  
  const handleRecommend = async () => {
    const result = await call('python-ai', 'recommend', {
      userId: 123,
      preferences: ['tech']
    });
    console.log(result);
  };
  
  return (
    <button onClick={handleRecommend}>
      Get Recommendations
    </button>
  );
}
```

#### `ModuleStatus`
Component for displaying module status.

```tsx
import { ModuleStatus } from '@polyglot/web-ui';

function Dashboard() {
  return (
    <div>
      <h2>Module Status</h2>
      <ModuleStatus />
    </div>
  );
}
```

## Mobile API

### Flutter Widgets

#### `InteropWidget`
Widget for interop functionality.

```dart
import 'package:polyglot_mobile/interop_widget.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InteropWidget(
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}
```

#### `useInterop()`
Hook for accessing interop functionality.

```dart
import 'package:polyglot_mobile/hooks.dart';

class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final interop = useInterop();
    
    return ElevatedButton(
      onPressed: () async {
        final result = await interop.call('python-ai', 'recommend', {
          'userId': 123,
          'preferences': ['tech']
        });
        print(result);
      },
      child: Text('Get Recommendations'),
    );
  }
}
```

## AI Module API

### Python AI Functions

#### `recommend(user_id: int, preferences: List[str]) -> Dict[str, Any]`
Generate recommendations based on user preferences.

```python
from ai.recommend import recommend

result = recommend(user_id=123, preferences=['tech', 'science'])
# Returns: {"recommendations": [...]}
```

#### `analyze_sentiment(text: str) -> Dict[str, Any]`
Analyze sentiment of text.

```python
from ai.sentiment import analyze_sentiment

result = analyze_sentiment("I love this product!")
# Returns: {"sentiment": "positive", "score": 0.95}
```

#### `generate_text(prompt: str, max_length: int = 100) -> str`
Generate text based on prompt.

```python
from ai.generator import generate_text

text = generate_text("Write a short story about", max_length=200)
```

## Database API

### Go Database Functions

#### `SaveData(table: string, data: map[string]interface{}) error`
Save data to database.

```go
err := db.SaveData("users", map[string]interface{}{
    "name": "John",
    "email": "john@example.com",
})
```

#### `GetData(table: string, id: string) (map[string]interface{}, error)`
Get data from database.

```go
data, err := db.GetData("users", "123")
```

#### `QueryData(table: string, query: map[string]interface{}) ([]map[string]interface{}, error)`
Query data from database.

```go
results, err := db.QueryData("users", map[string]interface{}{
    "age": map[string]interface{}{"$gt": 18},
})
```

#### `DeleteData(table: string, id: string) error`
Delete data from database.

```go
err := db.DeleteData("users", "123")
```

## Error Handling

All APIs return structured errors with the following format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2024-01-15T10:35:00Z",
  "details": {
    "additional": "error details"
  }
}
```

Common error codes:
- `MODULE_NOT_FOUND`: Target module not registered
- `METHOD_NOT_FOUND`: Method not available on target module
- `INVALID_PARAMS`: Invalid parameters provided
- `TIMEOUT`: Request timed out
- `NETWORK_ERROR`: Network communication error

## Rate Limiting

The interop server implements rate limiting:
- 100 requests per minute per module
- 1000 requests per hour per module
- Burst limit of 10 requests per second

## Authentication

For production deployments, add authentication:

```typescript
const client = createInteropClient({
  moduleName: 'my-module',
  auth: {
    token: 'your-auth-token',
    type: 'bearer'
  }
});
```

## WebSocket Events

The interop server supports real-time events:

```typescript
// Subscribe to module events
client.subscribe('python-ai');

// Listen for events
client.on('module_event', (event) => {
  console.log('Module event:', event);
});
```

Event types:
- `module_registered`: New module registered
- `module_unregistered`: Module unregistered
- `message_queued`: New message in queue
- `message_processed`: Message processed
- `error`: Error occurred 