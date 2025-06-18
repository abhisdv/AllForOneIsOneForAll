const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');
const http = require('http');

class PolyglotInteropServer {
    constructor(port = 4000) {
        this.port = port;
        this.app = express();
        this.server = http.createServer(this.app);
        this.wss = new WebSocket.Server({ server: this.server });
        
        // Registry for language modules
        this.modules = new Map();
        
        // Message queue for async communication
        this.messageQueue = [];
        
        this.setupMiddleware();
        this.setupRoutes();
        this.setupWebSocket();
    }
    
    setupMiddleware() {
        this.app.use(cors());
        this.app.use(express.json());
        this.app.use(express.urlencoded({ extended: true }));
    }
    
    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'ok',
                timestamp: new Date().toISOString(),
                modules: Array.from(this.modules.keys()),
                queueSize: this.messageQueue.length
            });
        });
        
        // Register a module
        this.app.post('/register', (req, res) => {
            const { name, language, endpoints, port } = req.body;
            
            if (!name || !language) {
                return res.status(400).json({
                    error: 'Module name and language are required'
                });
            }
            
            this.modules.set(name, {
                name,
                language,
                endpoints: endpoints || [],
                port: port || null,
                registeredAt: new Date().toISOString(),
                lastSeen: new Date().toISOString()
            });
            
            console.log(`Module registered: ${name} (${language})`);
            res.json({
                success: true,
                message: `Module ${name} registered successfully`
            });
        });
        
        // Unregister a module
        this.app.delete('/register/:name', (req, res) => {
            const { name } = req.params;
            
            if (this.modules.has(name)) {
                this.modules.delete(name);
                console.log(`Module unregistered: ${name}`);
                res.json({
                    success: true,
                    message: `Module ${name} unregistered successfully`
                });
            } else {
                res.status(404).json({
                    error: `Module ${name} not found`
                });
            }
        });
        
        // List all modules
        this.app.get('/modules', (req, res) => {
            res.json({
                modules: Array.from(this.modules.values()),
                total: this.modules.size
            });
        });
        
        // JSON-RPC endpoint for synchronous calls
        this.app.post('/rpc', async (req, res) => {
            const { method, params, target } = req.body;
            
            if (!method || !target) {
                return res.status(400).json({
                    error: 'Method and target are required'
                });
            }
            
            const targetModule = this.modules.get(target);
            if (!targetModule) {
                return res.status(404).json({
                    error: `Target module ${target} not found`
                });
            }
            
            try {
                const result = await this.callModule(target, method, params);
                res.json({
                    success: true,
                    result,
                    timestamp: new Date().toISOString()
                });
            } catch (error) {
                res.status(500).json({
                    error: error.message,
                    timestamp: new Date().toISOString()
                });
            }
        });
        
        // Send message to queue (async)
        this.app.post('/queue', (req, res) => {
            const { target, method, params, priority = 0 } = req.body;
            
            if (!target || !method) {
                return res.status(400).json({
                    error: 'Target and method are required'
                });
            }
            
            const message = {
                id: this.generateMessageId(),
                target,
                method,
                params,
                priority,
                timestamp: new Date().toISOString(),
                status: 'queued'
            };
            
            this.messageQueue.push(message);
            this.messageQueue.sort((a, b) => b.priority - a.priority);
            
            console.log(`Message queued: ${message.id} -> ${target}.${method}`);
            
            res.json({
                success: true,
                messageId: message.id,
                queueSize: this.messageQueue.length
            });
        });
        
        // Get queue status
        this.app.get('/queue', (req, res) => {
            res.json({
                queue: this.messageQueue,
                size: this.messageQueue.length
            });
        });
        
        // Process queue
        this.app.post('/queue/process', async (req, res) => {
            const { limit = 10 } = req.body;
            const processed = [];
            
            for (let i = 0; i < Math.min(limit, this.messageQueue.length); i++) {
                const message = this.messageQueue.shift();
                if (message) {
                    try {
                        const result = await this.callModule(message.target, message.method, message.params);
                        message.status = 'completed';
                        message.result = result;
                        message.completedAt = new Date().toISOString();
                        processed.push(message);
                    } catch (error) {
                        message.status = 'failed';
                        message.error = error.message;
                        message.failedAt = new Date().toISOString();
                        processed.push(message);
                    }
                }
            }
            
            res.json({
                processed: processed.length,
                remaining: this.messageQueue.length,
                results: processed
            });
        });
    }
    
    setupWebSocket() {
        this.wss.on('connection', (ws, req) => {
            console.log('WebSocket client connected');
            
            // Send current modules list
            ws.send(JSON.stringify({
                type: 'modules',
                data: Array.from(this.modules.values())
            }));
            
            ws.on('message', async (data) => {
                try {
                    const message = JSON.parse(data);
                    
                    switch (message.type) {
                        case 'call':
                            const result = await this.callModule(message.target, message.method, message.params);
                            ws.send(JSON.stringify({
                                type: 'response',
                                id: message.id,
                                result
                            }));
                            break;
                            
                        case 'subscribe':
                            // Subscribe to module events
                            ws.send(JSON.stringify({
                                type: 'subscribed',
                                target: message.target
                            }));
                            break;
                            
                        default:
                            ws.send(JSON.stringify({
                                type: 'error',
                                error: 'Unknown message type'
                            }));
                    }
                } catch (error) {
                    ws.send(JSON.stringify({
                        type: 'error',
                        error: error.message
                    }));
                }
            });
            
            ws.on('close', () => {
                console.log('WebSocket client disconnected');
            });
        });
    }
    
    async callModule(target, method, params = {}) {
        const module = this.modules.get(target);
        if (!module) {
            throw new Error(`Module ${target} not found`);
        }
        
        // Update last seen
        module.lastSeen = new Date().toISOString();
        
        // Try to call the module via HTTP if port is available
        if (module.port) {
            try {
                const response = await fetch(`http://localhost:${module.port}/rpc`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        method,
                        params
                    })
                });
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
                
                const result = await response.json();
                return result;
            } catch (error) {
                console.error(`Failed to call ${target}.${method}:`, error.message);
                throw error;
            }
        }
        
        // Fallback: return a mock response for demo purposes
        return {
            success: true,
            data: `Mock response from ${target}.${method}`,
            params,
            timestamp: new Date().toISOString()
        };
    }
    
    generateMessageId() {
        return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    start() {
        this.server.listen(this.port, () => {
            console.log(`🚀 Polyglot Interop Server running on port ${this.port}`);
            console.log(`📡 WebSocket available at ws://localhost:${this.port}`);
            console.log(`🌐 HTTP API available at http://localhost:${this.port}`);
            console.log(`💚 Health check: http://localhost:${this.port}/health`);
        });
    }
    
    stop() {
        this.server.close(() => {
            console.log('Polyglot Interop Server stopped');
        });
    }
}

// Start the server if this file is run directly
if (require.main === module) {
    const server = new PolyglotInteropServer();
    server.start();
    
    // Graceful shutdown
    process.on('SIGINT', () => {
        console.log('\nShutting down gracefully...');
        server.stop();
        process.exit(0);
    });
}

module.exports = PolyglotInteropServer; 