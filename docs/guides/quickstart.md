# Polyglot App Framework - Quick Start Guide

Get up and running with the Polyglot App Framework in minutes!

## 🚀 Prerequisites

Before you begin, make sure you have the following installed:

- **Node.js** (v16 or higher)
- **Python** (v3.8 or higher)
- **Go** (v1.19 or higher)
- **Docker** and **Docker Compose**
- **Git**

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/my-polyglot-app.git
cd my-polyglot-app
```

### 2. Run the Setup Script
```bash
./scripts/setup.sh
```

This script will:
- Install all required language runtimes
- Set up development tools
- Create necessary directories
- Configure the framework

### 3. Verify Installation
```bash
# Check if all tools are installed
node --version
python3 --version
go version
docker --version
```

## 🏃‍♂️ Quick Start

### 1. Start Development Environment
```bash
./scripts/dev.sh
```

This will start all development servers:
- **Web UI** (React): http://localhost:3000
- **API** (TypeScript): http://localhost:3001
- **AI** (Python): http://localhost:5000
- **Database** (Go): http://localhost:8080
- **Interop Server**: http://localhost:4000

### 2. Check Status
```bash
./scripts/dev.sh status
```

### 3. Run Tests
```bash
./scripts/test.sh
```

### 4. Build for Production
```bash
./scripts/build.sh
```

### 5. Deploy Locally
```bash
./scripts/deploy.sh local
```

## 🎯 Your First Polyglot App

Let's create a simple recommendation system using multiple languages:

### 1. Create TypeScript API
```typescript
// logic/typescript/src/server.ts
import express from 'express';
import { createInteropClient } from '../../meta/interop/client';

const app = express();
app.use(express.json());

const interop = createInteropClient({
  moduleName: 'typescript-api',
  port: 3001
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/recommendations', async (req, res) => {
  try {
    const { userId, preferences } = req.body;
    
    // Call Python AI module
    const aiResult = await interop.call('python-ai', 'recommend', {
      userId,
      preferences
    });
    
    // Save to Go database
    await interop.send('go-db', 'saveRecommendation', {
      userId,
      recommendations: aiResult.recommendations
    });
    
    res.json(aiResult);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3001, () => {
  console.log('TypeScript API running on port 3001');
});
```

### 2. Create Python AI Module
```python
# ai/app.py
from flask import Flask, request, jsonify
from meta.interop.client import create_interop_client, InteropConfig
import asyncio

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'timestamp': datetime.now().isoformat()})

@app.route('/rpc', methods=['POST'])
def rpc_handler():
    data = request.json
    method = data.get('method')
    params = data.get('params', {})
    
    if method == 'recommend':
        result = recommend(params.get('userId'), params.get('preferences', []))
        return jsonify(result)
    
    return jsonify({'error': 'Method not found'}), 404

def recommend(user_id, preferences):
    # Simple recommendation logic
    recommendations = [
        {'id': 1, 'title': 'AI Basics', 'score': 0.95},
        {'id': 2, 'title': 'Machine Learning', 'score': 0.87},
        {'id': 3, 'title': 'Data Science', 'score': 0.82}
    ]
    
    # Filter based on preferences
    if preferences:
        recommendations = [r for r in recommendations if any(p in r['title'].lower() for p in preferences)]
    
    return {'recommendations': recommendations}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### 3. Create Go Database Module
```go
// db-layer/go/main.go
package main

import (
    "encoding/json"
    "log"
    "net/http"
    "github.com/gin-gonic/gin"
)

type Recommendation struct {
    UserID          int                    `json:"userId"`
    Recommendations []map[string]interface{} `json:"recommendations"`
}

func main() {
    r := gin.Default()
    
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "status": "ok",
            "timestamp": time.Now().Format(time.RFC3339),
        })
    })
    
    r.POST("/rpc", func(c *gin.Context) {
        var data map[string]interface{}
        if err := c.BindJSON(&data); err != nil {
            c.JSON(400, gin.H{"error": err.Error()})
            return
        }
        
        method := data["method"].(string)
        params := data["params"].(map[string]interface{})
        
        switch method {
        case "saveRecommendation":
            saveRecommendation(params)
            c.JSON(200, gin.H{"success": true})
        default:
            c.JSON(404, gin.H{"error": "Method not found"})
        }
    })
    
    r.Run(":8080")
}

func saveRecommendation(params map[string]interface{}) {
    // Simple in-memory storage (replace with real database)
    log.Printf("Saving recommendation: %+v", params)
}
```

### 4. Create React Web UI
```tsx
// ui/web/src/App.tsx
import React, { useState } from 'react';
import './App.css';

function App() {
  const [recommendations, setRecommendations] = useState([]);
  const [loading, setLoading] = useState(false);

  const getRecommendations = async () => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:3001/recommendations', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: 123,
          preferences: ['tech', 'ai']
        }),
      });
      
      const data = await response.json();
      setRecommendations(data.recommendations);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Polyglot Recommendation App</h1>
        <button onClick={getRecommendations} disabled={loading}>
          {loading ? 'Loading...' : 'Get Recommendations'}
        </button>
        
        {recommendations.length > 0 && (
          <div>
            <h2>Recommendations:</h2>
            <ul>
              {recommendations.map((rec: any) => (
                <li key={rec.id}>
                  {rec.title} (Score: {rec.score})
                </li>
              ))}
            </ul>
          </div>
        )}
      </header>
    </div>
  );
}

export default App;
```

## 🔧 Configuration

### Framework Configuration
Edit `appfusion.json` to customize your setup:

```json
{
  "name": "my-polyglot-app",
  "version": "0.1",
  "modules": {
    "ui": {
      "web": "react",
      "mobile": "flutter"
    },
    "logic": {
      "web": "typescript",
      "mobile": "kotlin"
    },
    "ai": "python",
    "db": ["go", "node"],
    "tests": ["typescript", "python"]
  },
  "platforms": ["web", "android", "ios"],
  "interop": {
    "method": "json",
    "data-format": "json"
  }
}
```

### Environment Variables
Create `.env` files for each module:

```bash
# .env
INTEROP_SERVER_URL=http://localhost:4000
NODE_ENV=development
```

## 🧪 Testing

### Run All Tests
```bash
./scripts/test.sh all
```

### Run Specific Test Types
```bash
./scripts/test.sh unit      # Unit tests only
./scripts/test.sh integration  # Integration tests only
./scripts/test.sh e2e        # End-to-end tests only
```

### View Test Reports
```bash
open test-reports/summary.html
```

## 🚀 Deployment

### Local Deployment
```bash
./scripts/deploy.sh local
```

### Cloud Deployment
```bash
# AWS
./scripts/deploy.sh aws

# Google Cloud
./scripts/deploy.sh gcp

# Azure
./scripts/deploy.sh azure
```

### Mobile Deployment
```bash
# Android
./scripts/deploy.sh android

# iOS
./scripts/deploy.sh ios
```

## 📊 Monitoring

### Check Service Health
```bash
./scripts/deploy.sh health
```

### Monitor Deployment
```bash
./scripts/deploy.sh monitor
```

### View Logs
```bash
tail -f logs/*.log
```

## 🔍 Debugging

### Development Mode
```bash
# Start with debug logging
DEBUG=* ./scripts/dev.sh

# Start specific module
./scripts/dev.sh typescript
```

### Interop Server Debug
```bash
# Check interop server status
curl http://localhost:4000/health

# List registered modules
curl http://localhost:4000/modules
```

## 📚 Next Steps

1. **Explore the Documentation**:
   - [API Reference](./api.md)
   - [Testing Guide](./testing.md)
   - [Deployment Guide](./deployment.md)

2. **Customize Your App**:
   - Add new language modules
   - Implement your business logic
   - Create custom UI components

3. **Scale Your Application**:
   - Add authentication
   - Implement caching
   - Set up monitoring
   - Configure CI/CD

4. **Join the Community**:
   - Report issues on GitHub
   - Contribute to the framework
   - Share your polyglot apps

## 🆘 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>
```

**Module Not Found**
```bash
# Check if module is registered
curl http://localhost:4000/modules

# Restart interop server
./scripts/dev.sh stop
./scripts/dev.sh interop
```

**Build Failures**
```bash
# Clean and rebuild
rm -rf build dist
./scripts/build.sh all
```

**Docker Issues**
```bash
# Clean Docker
docker system prune -a

# Rebuild images
./scripts/build.sh docker
```

### Getting Help

- **Documentation**: Check the docs folder
- **Issues**: Create an issue on GitHub
- **Discussions**: Join our community forum
- **Examples**: Check the examples folder

## 🎉 Congratulations!

You've successfully set up your first polyglot application! You now have:

- ✅ A working multi-language application
- ✅ Cross-language communication
- ✅ Unified testing framework
- ✅ Deployment automation
- ✅ Development tools

Start building amazing applications that leverage the best of each programming language! 