// Polyglot Interop Client for TypeScript/JavaScript
// Provides easy-to-use methods for cross-language communication

export interface InteropConfig {
    serverUrl?: string;
    moduleName?: string;
    language?: string;
    port?: number;
    autoRegister?: boolean;
}

export interface InteropMessage {
    id: string;
    target: string;
    method: string;
    params: any;
    priority?: number;
    timestamp: string;
    status: 'queued' | 'completed' | 'failed';
    result?: any;
    error?: string;
}

export interface ModuleInfo {
    name: string;
    language: string;
    endpoints: string[];
    port: number | null;
    registeredAt: string;
    lastSeen: string;
}

export class PolyglotInteropClient {
    private serverUrl: string;
    private moduleName: string;
    private language: string;
    private port: number | null;
    private autoRegister: boolean;
    private ws: WebSocket | null = null;
    private messageHandlers: Map<string, (data: any) => void> = new Map();

    constructor(config: InteropConfig = {}) {
        this.serverUrl = config.serverUrl || 'http://localhost:4000';
        this.moduleName = config.moduleName || 'typescript-module';
        this.language = config.language || 'typescript';
        this.port = config.port || null;
        this.autoRegister = config.autoRegister !== false;
    }

    /**
     * Initialize the client and optionally register with the interop server
     */
    async init(): Promise<void> {
        if (this.autoRegister) {
            await this.register();
        }
        
        this.connectWebSocket();
    }

    /**
     * Register this module with the interop server
     */
    async register(): Promise<void> {
        try {
            const response = await fetch(`${this.serverUrl}/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    name: this.moduleName,
                    language: this.language,
                    endpoints: ['rpc'],
                    port: this.port
                })
            });

            if (!response.ok) {
                throw new Error(`Registration failed: ${response.statusText}`);
            }

            const result = await response.json();
            console.log(`✅ Module registered: ${result.message}`);
        } catch (error) {
            console.error('❌ Registration failed:', error);
            throw error;
        }
    }

    /**
     * Unregister this module from the interop server
     */
    async unregister(): Promise<void> {
        try {
            const response = await fetch(`${this.serverUrl}/register/${this.moduleName}`, {
                method: 'DELETE'
            });

            if (!response.ok) {
                throw new Error(`Unregistration failed: ${response.statusText}`);
            }

            const result = await response.json();
            console.log(`✅ Module unregistered: ${result.message}`);
        } catch (error) {
            console.error('❌ Unregistration failed:', error);
            throw error;
        }
    }

    /**
     * Call a method on another module synchronously
     */
    async call(target: string, method: string, params: any = {}): Promise<any> {
        try {
            const response = await fetch(`${this.serverUrl}/rpc`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    target,
                    method,
                    params
                })
            });

            if (!response.ok) {
                throw new Error(`RPC call failed: ${response.statusText}`);
            }

            const result = await response.json();
            return result.result;
        } catch (error) {
            console.error(`❌ RPC call to ${target}.${method} failed:`, error);
            throw error;
        }
    }

    /**
     * Send a message to another module asynchronously
     */
    async send(target: string, method: string, params: any = {}, priority: number = 0): Promise<string> {
        try {
            const response = await fetch(`${this.serverUrl}/queue`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    target,
                    method,
                    params,
                    priority
                })
            });

            if (!response.ok) {
                throw new Error(`Message send failed: ${response.statusText}`);
            }

            const result = await response.json();
            console.log(`📤 Message queued: ${result.messageId} -> ${target}.${method}`);
            return result.messageId;
        } catch (error) {
            console.error(`❌ Message send to ${target}.${method} failed:`, error);
            throw error;
        }
    }

    /**
     * Get the current message queue
     */
    async getQueue(): Promise<InteropMessage[]> {
        try {
            const response = await fetch(`${this.serverUrl}/queue`);
            
            if (!response.ok) {
                throw new Error(`Failed to get queue: ${response.statusText}`);
            }

            const result = await response.json();
            return result.queue;
        } catch (error) {
            console.error('❌ Failed to get queue:', error);
            throw error;
        }
    }

    /**
     * Process messages from the queue
     */
    async processQueue(limit: number = 10): Promise<any[]> {
        try {
            const response = await fetch(`${this.serverUrl}/queue/process`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ limit })
            });

            if (!response.ok) {
                throw new Error(`Queue processing failed: ${response.statusText}`);
            }

            const result = await response.json();
            console.log(`📋 Processed ${result.processed} messages, ${result.remaining} remaining`);
            return result.results;
        } catch (error) {
            console.error('❌ Queue processing failed:', error);
            throw error;
        }
    }

    /**
     * Get list of all registered modules
     */
    async getModules(): Promise<ModuleInfo[]> {
        try {
            const response = await fetch(`${this.serverUrl}/modules`);
            
            if (!response.ok) {
                throw new Error(`Failed to get modules: ${response.statusText}`);
            }

            const result = await response.json();
            return result.modules;
        } catch (error) {
            console.error('❌ Failed to get modules:', error);
            throw error;
        }
    }

    /**
     * Check server health
     */
    async health(): Promise<any> {
        try {
            const response = await fetch(`${this.serverUrl}/health`);
            
            if (!response.ok) {
                throw new Error(`Health check failed: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('❌ Health check failed:', error);
            throw error;
        }
    }

    /**
     * Connect to WebSocket for real-time communication
     */
    private connectWebSocket(): void {
        const wsUrl = this.serverUrl.replace('http', 'ws');
        
        try {
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('🔌 WebSocket connected');
            };
            
            this.ws.onmessage = (event) => {
                try {
                    const message = JSON.parse(event.data);
                    this.handleWebSocketMessage(message);
                } catch (error) {
                    console.error('❌ Failed to parse WebSocket message:', error);
                }
            };
            
            this.ws.onclose = () => {
                console.log('🔌 WebSocket disconnected');
                // Attempt to reconnect after 5 seconds
                setTimeout(() => this.connectWebSocket(), 5000);
            };
            
            this.ws.onerror = (error) => {
                console.error('❌ WebSocket error:', error);
            };
        } catch (error) {
            console.error('❌ Failed to connect WebSocket:', error);
        }
    }

    /**
     * Handle incoming WebSocket messages
     */
    private handleWebSocketMessage(message: any): void {
        switch (message.type) {
            case 'modules':
                console.log('📋 Available modules:', message.data);
                break;
                
            case 'response':
                const handler = this.messageHandlers.get(message.id);
                if (handler) {
                    handler(message.result);
                    this.messageHandlers.delete(message.id);
                }
                break;
                
            case 'error':
                console.error('❌ WebSocket error:', message.error);
                break;
                
            default:
                console.log('📨 Unknown WebSocket message:', message);
        }
    }

    /**
     * Send a WebSocket message and wait for response
     */
    async sendWebSocket(target: string, method: string, params: any = {}): Promise<any> {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('WebSocket not connected');
        }

        return new Promise((resolve, reject) => {
            const messageId = `ws_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            // Set up response handler
            this.messageHandlers.set(messageId, resolve);
            
            // Send message
            this.ws!.send(JSON.stringify({
                type: 'call',
                id: messageId,
                target,
                method,
                params
            }));
            
            // Timeout after 10 seconds
            setTimeout(() => {
                this.messageHandlers.delete(messageId);
                reject(new Error('WebSocket call timeout'));
            }, 10000);
        });
    }

    /**
     * Subscribe to module events
     */
    subscribe(target: string): void {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('WebSocket not connected');
        }

        this.ws.send(JSON.stringify({
            type: 'subscribe',
            target
        }));
    }

    /**
     * Close the client and cleanup
     */
    async close(): Promise<void> {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
        
        if (this.autoRegister) {
            await this.unregister();
        }
    }
}

// Convenience function to create a client
export function createInteropClient(config: InteropConfig = {}): PolyglotInteropClient {
    return new PolyglotInteropClient(config);
}

// Example usage:
/*
const client = createInteropClient({
    moduleName: 'my-typescript-module',
    port: 3001
});

await client.init();

// Call Python AI module
const result = await client.call('python-ai', 'recommend', {
    userId: 123,
    preferences: ['tech', 'science']
});

// Send async message to Go DB module
await client.send('go-db', 'saveData', {
    table: 'users',
    data: { name: 'John', email: 'john@example.com' }
});

await client.close();
*/ 