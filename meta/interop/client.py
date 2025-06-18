"""
Polyglot Interop Client for Python
Provides easy-to-use methods for cross-language communication
"""

import asyncio
import json
import time
import uuid
from typing import Any, Dict, List, Optional, Callable
import aiohttp
import websockets
from dataclasses import dataclass
from datetime import datetime


@dataclass
class InteropConfig:
    server_url: str = "http://localhost:4000"
    module_name: str = "python-module"
    language: str = "python"
    port: Optional[int] = None
    auto_register: bool = True


@dataclass
class InteropMessage:
    id: str
    target: str
    method: str
    params: Dict[str, Any]
    priority: int = 0
    timestamp: str = ""
    status: str = "queued"
    result: Optional[Any] = None
    error: Optional[str] = None


@dataclass
class ModuleInfo:
    name: str
    language: str
    endpoints: List[str]
    port: Optional[int]
    registered_at: str
    last_seen: str


class PolyglotInteropClient:
    """Python client for the Polyglot Interop Server"""
    
    def __init__(self, config: InteropConfig = None):
        self.config = config or InteropConfig()
        self.session: Optional[aiohttp.ClientSession] = None
        self.websocket: Optional[websockets.WebSocketServerProtocol] = None
        self.message_handlers: Dict[str, Callable] = {}
        self.running = False
        
    async def __aenter__(self):
        await self.init()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()
    
    async def init(self) -> None:
        """Initialize the client and optionally register with the interop server"""
        self.session = aiohttp.ClientSession()
        
        if self.config.auto_register:
            await self.register()
            
        await self.connect_websocket()
    
    async def register(self) -> None:
        """Register this module with the interop server"""
        try:
            async with self.session.post(
                f"{self.config.server_url}/register",
                json={
                    "name": self.config.module_name,
                    "language": self.config.language,
                    "endpoints": ["rpc"],
                    "port": self.config.port
                }
            ) as response:
                if response.status != 200:
                    raise Exception(f"Registration failed: {response.status}")
                
                result = await response.json()
                print(f"✅ Module registered: {result['message']}")
                
        except Exception as e:
            print(f"❌ Registration failed: {e}")
            raise
    
    async def unregister(self) -> None:
        """Unregister this module from the interop server"""
        try:
            async with self.session.delete(
                f"{self.config.server_url}/register/{self.config.module_name}"
            ) as response:
                if response.status != 200:
                    raise Exception(f"Unregistration failed: {response.status}")
                
                result = await response.json()
                print(f"✅ Module unregistered: {result['message']}")
                
        except Exception as e:
            print(f"❌ Unregistration failed: {e}")
            raise
    
    async def call(self, target: str, method: str, params: Dict[str, Any] = None) -> Any:
        """Call a method on another module synchronously"""
        if params is None:
            params = {}
            
        try:
            async with self.session.post(
                f"{self.config.server_url}/rpc",
                json={
                    "target": target,
                    "method": method,
                    "params": params
                }
            ) as response:
                if response.status != 200:
                    raise Exception(f"RPC call failed: {response.status}")
                
                result = await response.json()
                return result["result"]
                
        except Exception as e:
            print(f"❌ RPC call to {target}.{method} failed: {e}")
            raise
    
    async def send(self, target: str, method: str, params: Dict[str, Any] = None, priority: int = 0) -> str:
        """Send a message to another module asynchronously"""
        if params is None:
            params = {}
            
        try:
            async with self.session.post(
                f"{self.config.server_url}/queue",
                json={
                    "target": target,
                    "method": method,
                    "params": params,
                    "priority": priority
                }
            ) as response:
                if response.status != 200:
                    raise Exception(f"Message send failed: {response.status}")
                
                result = await response.json()
                print(f"📤 Message queued: {result['messageId']} -> {target}.{method}")
                return result["messageId"]
                
        except Exception as e:
            print(f"❌ Message send to {target}.{method} failed: {e}")
            raise
    
    async def get_queue(self) -> List[InteropMessage]:
        """Get the current message queue"""
        try:
            async with self.session.get(f"{self.config.server_url}/queue") as response:
                if response.status != 200:
                    raise Exception(f"Failed to get queue: {response.status}")
                
                result = await response.json()
                return [InteropMessage(**msg) for msg in result["queue"]]
                
        except Exception as e:
            print(f"❌ Failed to get queue: {e}")
            raise
    
    async def process_queue(self, limit: int = 10) -> List[Any]:
        """Process messages from the queue"""
        try:
            async with self.session.post(
                f"{self.config.server_url}/queue/process",
                json={"limit": limit}
            ) as response:
                if response.status != 200:
                    raise Exception(f"Queue processing failed: {response.status}")
                
                result = await response.json()
                print(f"📋 Processed {result['processed']} messages, {result['remaining']} remaining")
                return result["results"]
                
        except Exception as e:
            print(f"❌ Queue processing failed: {e}")
            raise
    
    async def get_modules(self) -> List[ModuleInfo]:
        """Get list of all registered modules"""
        try:
            async with self.session.get(f"{self.config.server_url}/modules") as response:
                if response.status != 200:
                    raise Exception(f"Failed to get modules: {response.status}")
                
                result = await response.json()
                return [ModuleInfo(**module) for module in result["modules"]]
                
        except Exception as e:
            print(f"❌ Failed to get modules: {e}")
            raise
    
    async def health(self) -> Dict[str, Any]:
        """Check server health"""
        try:
            async with self.session.get(f"{self.config.server_url}/health") as response:
                if response.status != 200:
                    raise Exception(f"Health check failed: {response.status}")
                
                return await response.json()
                
        except Exception as e:
            print(f"❌ Health check failed: {e}")
            raise
    
    async def connect_websocket(self) -> None:
        """Connect to WebSocket for real-time communication"""
        ws_url = self.config.server_url.replace("http", "ws")
        
        try:
            self.websocket = await websockets.connect(ws_url)
            print("🔌 WebSocket connected")
            
            # Start listening for messages
            asyncio.create_task(self._websocket_listener())
            
        except Exception as e:
            print(f"❌ Failed to connect WebSocket: {e}")
    
    async def _websocket_listener(self) -> None:
        """Listen for WebSocket messages"""
        if not self.websocket:
            return
            
        try:
            async for message in self.websocket:
                try:
                    data = json.loads(message)
                    await self._handle_websocket_message(data)
                except json.JSONDecodeError as e:
                    print(f"❌ Failed to parse WebSocket message: {e}")
                    
        except websockets.exceptions.ConnectionClosed:
            print("🔌 WebSocket disconnected")
            # Attempt to reconnect after 5 seconds
            await asyncio.sleep(5)
            await self.connect_websocket()
        except Exception as e:
            print(f"❌ WebSocket error: {e}")
    
    async def _handle_websocket_message(self, message: Dict[str, Any]) -> None:
        """Handle incoming WebSocket messages"""
        msg_type = message.get("type")
        
        if msg_type == "modules":
            print(f"📋 Available modules: {message['data']}")
            
        elif msg_type == "response":
            message_id = message.get("id")
            if message_id in self.message_handlers:
                handler = self.message_handlers.pop(message_id)
                handler(message["result"])
                
        elif msg_type == "error":
            print(f"❌ WebSocket error: {message['error']}")
            
        else:
            print(f"📨 Unknown WebSocket message: {message}")
    
    async def send_websocket(self, target: str, method: str, params: Dict[str, Any] = None) -> Any:
        """Send a WebSocket message and wait for response"""
        if not self.websocket:
            raise Exception("WebSocket not connected")
            
        if params is None:
            params = {}
            
        message_id = f"ws_{int(time.time() * 1000)}_{uuid.uuid4().hex[:8]}"
        
        # Set up response handler
        future = asyncio.Future()
        self.message_handlers[message_id] = future.set_result
        
        # Send message
        await self.websocket.send(json.dumps({
            "type": "call",
            "id": message_id,
            "target": target,
            "method": method,
            "params": params
        }))
        
        # Wait for response with timeout
        try:
            result = await asyncio.wait_for(future, timeout=10.0)
            return result
        except asyncio.TimeoutError:
            self.message_handlers.pop(message_id, None)
            raise Exception("WebSocket call timeout")
    
    def subscribe(self, target: str) -> None:
        """Subscribe to module events"""
        if not self.websocket:
            raise Exception("WebSocket not connected")
            
        asyncio.create_task(self.websocket.send(json.dumps({
            "type": "subscribe",
            "target": target
        })))
    
    async def close(self) -> None:
        """Close the client and cleanup"""
        if self.websocket:
            await self.websocket.close()
            self.websocket = None
            
        if self.session:
            await self.session.close()
            self.session = None
            
        if self.config.auto_register:
            await self.unregister()


# Convenience function to create a client
def create_interop_client(config: InteropConfig = None) -> PolyglotInteropClient:
    return PolyglotInteropClient(config)


# Example usage:
"""
async def main():
    config = InteropConfig(
        module_name="my-python-module",
        port=5000
    )
    
    async with create_interop_client(config) as client:
        # Call TypeScript module
        result = await client.call("typescript-module", "processData", {
            "data": [1, 2, 3, 4, 5]
        })
        
        # Send async message to Go module
        await client.send("go-module", "saveData", {
            "table": "users",
            "data": {"name": "John", "email": "john@example.com"}
        })
        
        # Get all modules
        modules = await client.get_modules()
        print(f"Available modules: {modules}")

# Run the example
# asyncio.run(main())
""" 