# Recommendation App Example

A complete example application demonstrating the Polyglot App Framework capabilities.

## 🎯 Overview

This example builds a recommendation system using multiple programming languages:

- **Frontend**: React (TypeScript) - User interface
- **API Gateway**: TypeScript/Node.js - Request routing and orchestration
- **AI Engine**: Python - Machine learning and recommendations
- **Database**: Go - High-performance data storage
- **Mobile**: Flutter - Cross-platform mobile app

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   React     │    │  Flutter    │    │   Mobile    │
│   Web UI    │    │   Mobile    │    │   Native    │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌─────────────┐
                    │ TypeScript  │
                    │ API Gateway │
                    └─────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Python    │    │     Go      │    │  Interop    │
│   AI Engine │    │  Database   │    │   Server    │
└─────────────┘    └─────────────┘    └─────────────┘
```

## 🚀 Quick Start

### 1. Setup the Example
```bash
cd examples/recommendation-app
./scripts/setup.sh
```

### 2. Start Development
```bash
./scripts/dev.sh
```

### 3. Access the Application
- **Web UI**: http://localhost:3000
- **API**: http://localhost:3001
- **AI Engine**: http://localhost:5000
- **Database**: http://localhost:8080
- **Interop Server**: http://localhost:4000

### 4. Test the Application
```bash
./scripts/test.sh
```

## 📁 Project Structure

```
recommendation-app/
├── ui/
│   ├── web/                 # React web application
│   └── mobile/              # Flutter mobile application
├── logic/
│   └── typescript/          # TypeScript API gateway
├── ai/
│   ├── models/              # ML models
│   ├── data/                # Training data
│   └── src/                 # Python AI engine
├── db-layer/
│   └── go/                  # Go database service
├── tests/
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── e2e/                 # End-to-end tests
├── scripts/                 # Build and deployment scripts
└── docs/                    # Documentation
```

## 🎨 Features

### 1. User Interface (React)
- Modern, responsive web interface
- Real-time recommendations
- User preference management
- Interactive charts and visualizations

### 2. API Gateway (TypeScript)
- Request routing and load balancing
- Authentication and authorization
- Rate limiting and caching
- Cross-language communication

### 3. AI Engine (Python)
- Collaborative filtering algorithms
- Content-based recommendations
- Real-time model updates
- A/B testing framework

### 4. Database (Go)
- High-performance data storage
- Real-time analytics
- Data synchronization
- Backup and recovery

### 5. Mobile App (Flutter)
- Cross-platform mobile application
- Offline capability
- Push notifications
- Native performance

## 🔧 Implementation Details

### Web UI (React)

```tsx
// ui/web/src/components/RecommendationCard.tsx
import React from 'react';
import { useInterop } from '@polyglot/web-ui';

interface Recommendation {
  id: number;
  title: string;
  score: number;
  category: string;
}

export const RecommendationCard: React.FC<{ rec: Recommendation }> = ({ rec }) => {
  const { call } = useInterop();

  const handleLike = async () => {
    await call('python-ai', 'recordFeedback', {
      userId: 123,
      itemId: rec.id,
      action: 'like'
    });
  };

  return (
    <div className="recommendation-card">
      <h3>{rec.title}</h3>
      <p>Score: {rec.score.toFixed(2)}</p>
      <p>Category: {rec.category}</p>
      <button onClick={handleLike}>Like</button>
    </div>
  );
};
```

### API Gateway (TypeScript)

```typescript
// logic/typescript/src/routes/recommendations.ts
import express from 'express';
import { createInteropClient } from '../../../meta/interop/client';

const router = express.Router();
const interop = createInteropClient({
  moduleName: 'api-gateway',
  port: 3001
});

router.post('/recommendations', async (req, res) => {
  try {
    const { userId, preferences, limit = 10 } = req.body;

    // Get user profile from database
    const userProfile = await interop.call('go-db', 'getUserProfile', { userId });

    // Get recommendations from AI engine
    const recommendations = await interop.call('python-ai', 'getRecommendations', {
      userId,
      preferences,
      userProfile,
      limit
    });

    // Save recommendation history
    await interop.send('go-db', 'saveRecommendationHistory', {
      userId,
      recommendations,
      timestamp: new Date().toISOString()
    });

    res.json({
      success: true,
      recommendations,
      metadata: {
        model: 'collaborative-filtering',
        version: '1.0.0',
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;
```

### AI Engine (Python)

```python
# ai/src/recommendation_engine.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from typing import List, Dict, Any
import asyncio

class RecommendationEngine:
    def __init__(self):
        self.user_item_matrix = None
        self.item_features = None
        self.model = None
        
    async def initialize(self):
        """Initialize the recommendation engine"""
        # Load data from database
        data = await self.load_data()
        self.user_item_matrix = self.create_user_item_matrix(data)
        self.item_features = self.extract_item_features(data)
        self.model = self.train_collaborative_filtering()
        
    def get_recommendations(self, user_id: int, preferences: List[str], 
                          user_profile: Dict[str, Any], limit: int = 10) -> List[Dict[str, Any]]:
        """Generate recommendations for a user"""
        
        # Collaborative filtering
        cf_recommendations = self.collaborative_filtering(user_id, limit)
        
        # Content-based filtering
        cb_recommendations = self.content_based_filtering(preferences, limit)
        
        # Hybrid approach
        hybrid_recommendations = self.hybrid_recommendations(
            cf_recommendations, cb_recommendations, user_profile
        )
        
        return hybrid_recommendations[:limit]
    
    def collaborative_filtering(self, user_id: int, limit: int) -> List[Dict[str, Any]]:
        """Collaborative filtering using user-item matrix"""
        if user_id not in self.user_item_matrix.index:
            return []
            
        user_similarities = cosine_similarity(
            self.user_item_matrix.loc[[user_id]], 
            self.user_item_matrix
        )[0]
        
        similar_users = np.argsort(user_similarities)[::-1][1:11]
        
        recommendations = []
        for similar_user in similar_users:
            user_items = self.user_item_matrix.iloc[similar_user]
            liked_items = user_items[user_items > 0].index
            recommendations.extend(liked_items)
            
        return [{'id': item_id, 'score': 0.8, 'method': 'collaborative'} 
                for item_id in set(recommendations)][:limit]
    
    def content_based_filtering(self, preferences: List[str], limit: int) -> List[Dict[str, Any]]:
        """Content-based filtering using item features"""
        if not preferences:
            return []
            
        relevant_items = []
        for preference in preferences:
            matching_items = self.item_features[
                self.item_features['category'].str.contains(preference, case=False)
            ]
            relevant_items.extend(matching_items.index.tolist())
            
        return [{'id': item_id, 'score': 0.7, 'method': 'content'} 
                for item_id in set(relevant_items)][:limit]
    
    def hybrid_recommendations(self, cf_recs: List[Dict], cb_recs: List[Dict], 
                             user_profile: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Combine collaborative and content-based recommendations"""
        all_recommendations = {}
        
        # Combine recommendations with weights
        for rec in cf_recs:
            item_id = rec['id']
            if item_id not in all_recommendations:
                all_recommendations[item_id] = {'id': item_id, 'score': 0, 'methods': []}
            all_recommendations[item_id]['score'] += rec['score'] * 0.6
            all_recommendations[item_id]['methods'].append(rec['method'])
            
        for rec in cb_recs:
            item_id = rec['id']
            if item_id not in all_recommendations:
                all_recommendations[item_id] = {'id': item_id, 'score': 0, 'methods': []}
            all_recommendations[item_id]['score'] += rec['score'] * 0.4
            all_recommendations[item_id]['methods'].append(rec['method'])
        
        # Sort by score and return
        sorted_recs = sorted(all_recommendations.values(), 
                           key=lambda x: x['score'], reverse=True)
        return sorted_recs
```

### Database (Go)

```go
// db-layer/go/src/database.go
package main

import (
    "database/sql"
    "encoding/json"
    "log"
    "time"
    _ "github.com/lib/pq"
)

type Database struct {
    db *sql.DB
}

type User struct {
    ID       int       `json:"id"`
    Name     string    `json:"name"`
    Email    string    `json:"email"`
    Created  time.Time `json:"created"`
    Updated  time.Time `json:"updated"`
}

type Item struct {
    ID       int       `json:"id"`
    Title    string    `json:"title"`
    Category string    `json:"category"`
    Features json.RawMessage `json:"features"`
}

type Interaction struct {
    UserID    int       `json:"user_id"`
    ItemID    int       `json:"item_id"`
    Action    string    `json:"action"`
    Timestamp time.Time `json:"timestamp"`
}

func NewDatabase(connectionString string) (*Database, error) {
    db, err := sql.Open("postgres", connectionString)
    if err != nil {
        return nil, err
    }
    
    if err := db.Ping(); err != nil {
        return nil, err
    }
    
    return &Database{db: db}, nil
}

func (d *Database) GetUserProfile(userID int) (map[string]interface{}, error) {
    query := `
        SELECT u.id, u.name, u.email, 
               COUNT(i.id) as interaction_count,
               AVG(CASE WHEN i.action = 'like' THEN 1 ELSE 0 END) as like_ratio
        FROM users u
        LEFT JOIN interactions i ON u.id = i.user_id
        WHERE u.id = $1
        GROUP BY u.id, u.name, u.email
    `
    
    var user User
    var interactionCount int
    var likeRatio float64
    
    err := d.db.QueryRow(query, userID).Scan(
        &user.ID, &user.Name, &user.Email, &interactionCount, &likeRatio,
    )
    if err != nil {
        return nil, err
    }
    
    return map[string]interface{}{
        "id": user.ID,
        "name": user.Name,
        "email": user.Email,
        "interaction_count": interactionCount,
        "like_ratio": likeRatio,
    }, nil
}

func (d *Database) SaveRecommendationHistory(userID int, recommendations []map[string]interface{}) error {
    query := `
        INSERT INTO recommendation_history (user_id, recommendations, created_at)
        VALUES ($1, $2, $3)
    `
    
    recommendationsJSON, err := json.Marshal(recommendations)
    if err != nil {
        return err
    }
    
    _, err = d.db.Exec(query, userID, recommendationsJSON, time.Now())
    return err
}

func (d *Database) GetUserInteractions(userID int) ([]Interaction, error) {
    query := `
        SELECT user_id, item_id, action, timestamp
        FROM interactions
        WHERE user_id = $1
        ORDER BY timestamp DESC
    `
    
    rows, err := d.db.Query(query, userID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var interactions []Interaction
    for rows.Next() {
        var interaction Interaction
        err := rows.Scan(&interaction.UserID, &interaction.ItemID, 
                        &interaction.Action, &interaction.Timestamp)
        if err != nil {
            return nil, err
        }
        interactions = append(interactions, interaction)
    }
    
    return interactions, nil
}

func (d *Database) RecordInteraction(userID, itemID int, action string) error {
    query := `
        INSERT INTO interactions (user_id, item_id, action, timestamp)
        VALUES ($1, $2, $3, $4)
    `
    
    _, err := d.db.Exec(query, userID, itemID, action, time.Now())
    return err
}
```

### Mobile App (Flutter)

```dart
// ui/mobile/lib/screens/recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:polyglot_mobile/interop_widget.dart';

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<Map<String, dynamic>> recommendations = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final interop = useInterop();
      final result = await interop.call('typescript-api', 'getRecommendations', {
        'userId': 123,
        'preferences': ['tech', 'ai'],
        'limit': 10,
      });

      setState(() {
        recommendations = List<Map<String, dynamic>>.from(result['recommendations']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recommendations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendations'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(rec['title']),
                    subtitle: Text('Score: ${rec['score'].toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: Icon(Icons.thumb_up),
                      onPressed: () => _likeRecommendation(rec['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _likeRecommendation(int itemId) async {
    try {
      final interop = useInterop();
      await interop.call('python-ai', 'recordFeedback', {
        'userId': 123,
        'itemId': itemId,
        'action': 'like',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recommendation liked!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording feedback: $e')),
      );
    }
  }
}
```

## 🧪 Testing

### Unit Tests

```typescript
// tests/unit/recommendation-engine.test.ts
import { RecommendationEngine } from '../../ai/src/recommendation_engine';

describe('RecommendationEngine', () => {
  let engine: RecommendationEngine;

  beforeEach(async () => {
    engine = new RecommendationEngine();
    await engine.initialize();
  });

  test('should generate recommendations for user', async () => {
    const recommendations = await engine.getRecommendations(
      123, 
      ['tech', 'ai'], 
      { id: 123, name: 'John' }, 
      5
    );

    expect(recommendations).toHaveLength(5);
    expect(recommendations[0]).toHaveProperty('id');
    expect(recommendations[0]).toHaveProperty('score');
  });

  test('should handle empty preferences', async () => {
    const recommendations = await engine.getRecommendations(
      123, 
      [], 
      { id: 123, name: 'John' }, 
      5
    );

    expect(recommendations.length).toBeGreaterThan(0);
  });
});
```

### Integration Tests

```python
# tests/integration/test_recommendation_flow.py
import pytest
import asyncio
from polyglot_interop_client import create_interop_client, InteropConfig

@pytest.mark.asyncio
async def test_recommendation_flow():
    """Test complete recommendation flow across all modules"""
    
    # Initialize clients
    ts_client = create_interop_client(InteropConfig(
        module_name="test-ts-client",
        port=3001
    ))
    
    py_client = create_interop_client(InteropConfig(
        module_name="test-py-client", 
        port=5000
    ))
    
    go_client = create_interop_client(InteropConfig(
        module_name="test-go-client",
        port=8080
    ))
    
    async with ts_client, py_client, go_client:
        # 1. Get user profile from database
        user_profile = await go_client.call("getUserProfile", {"userId": 123})
        assert user_profile is not None
        
        # 2. Get recommendations from AI engine
        recommendations = await py_client.call("getRecommendations", {
            "userId": 123,
            "preferences": ["tech", "ai"],
            "limit": 5
        })
        assert len(recommendations["recommendations"]) == 5
        
        # 3. Save recommendation history
        result = await go_client.call("saveRecommendationHistory", {
            "userId": 123,
            "recommendations": recommendations["recommendations"]
        })
        assert result["success"] is True
        
        # 4. Test API gateway integration
        api_result = await ts_client.call("getRecommendations", {
            "userId": 123,
            "preferences": ["tech"],
            "limit": 3
        })
        assert api_result["success"] is True
        assert len(api_result["recommendations"]) == 3
```

### End-to-End Tests

```typescript
// tests/e2e/recommendation-app.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Recommendation App E2E', () => {
  test('should display recommendations', async ({ page }) => {
    // Navigate to the app
    await page.goto('http://localhost:3000');
    
    // Wait for the page to load
    await page.waitForSelector('h1');
    
    // Click the get recommendations button
    await page.click('button:has-text("Get Recommendations")');
    
    // Wait for recommendations to load
    await page.waitForSelector('ul li', { timeout: 10000 });
    
    // Verify recommendations are displayed
    const recommendations = await page.$$('ul li');
    expect(recommendations.length).toBeGreaterThan(0);
    
    // Check that recommendation cards have expected content
    const firstRec = await page.$('ul li:first-child');
    const text = await firstRec.textContent();
    expect(text).toContain('Score:');
  });

  test('should handle user interactions', async ({ page }) => {
    await page.goto('http://localhost:3000');
    
    // Get recommendations first
    await page.click('button:has-text("Get Recommendations")');
    await page.waitForSelector('ul li');
    
    // Like a recommendation
    await page.click('ul li:first-child button');
    
    // Verify feedback is recorded
    await page.waitForSelector('.success-message', { timeout: 5000 });
  });
});
```

## 🚀 Deployment

### Local Deployment
```bash
# Build all modules
./scripts/build.sh all

# Deploy locally
./scripts/deploy.sh local

# Check status
./scripts/deploy.sh status
```

### Cloud Deployment
```bash
# Deploy to AWS
./scripts/deploy.sh aws

# Deploy to Google Cloud
./scripts/deploy.sh gcp

# Deploy to Azure
./scripts/deploy.sh azure
```

### Mobile Deployment
```bash
# Build and deploy Android
./scripts/build.sh flutter
./scripts/deploy.sh android

# Build and deploy iOS
./scripts/deploy.sh ios
```

## 📊 Monitoring

### Health Checks
```bash
# Check all services
./scripts/deploy.sh health

# Monitor deployment
./scripts/deploy.sh monitor
```

### Logs
```bash
# View all logs
tail -f logs/*.log

# View specific service logs
tail -f logs/typescript-api.log
tail -f logs/python-ai.log
tail -f logs/go-db.log
```

## 🔧 Configuration

### Environment Variables
```bash
# .env
NODE_ENV=production
PYTHON_ENV=production
GO_ENV=production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=recommendations
DB_USER=polyglot
DB_PASSWORD=secure_password

# AI Model
MODEL_PATH=/app/models/recommendation_model.pkl
MODEL_VERSION=1.0.0

# Interop Server
INTEROP_SERVER_URL=http://localhost:4000
INTEROP_AUTH_TOKEN=your_auth_token
```

### Docker Configuration
```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: recommendation-web:latest
    ports:
      - "3000:80"
    environment:
      - API_URL=http://api:3001
    depends_on:
      - api

  api:
    image: recommendation-api:latest
    ports:
      - "3001:3001"
    environment:
      - DB_HOST=db
      - AI_HOST=ai
    depends_on:
      - db
      - ai

  ai:
    image: recommendation-ai:latest
    ports:
      - "5000:5000"
    environment:
      - MODEL_PATH=/app/models
    volumes:
      - ./models:/app/models

  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=recommendations
      - POSTGRES_USER=polyglot
      - POSTGRES_PASSWORD=secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  interop:
    image: polyglot-interop:latest
    ports:
      - "4000:4000"

volumes:
  postgres_data:
```

## 🎯 Performance Optimization

### Caching Strategy
```typescript
// logic/typescript/src/cache/redis.ts
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
});

export class CacheManager {
  static async getRecommendations(userId: number): Promise<any> {
    const key = `recommendations:${userId}`;
    const cached = await redis.get(key);
    return cached ? JSON.parse(cached) : null;
  }

  static async setRecommendations(userId: number, recommendations: any): Promise<void> {
    const key = `recommendations:${userId}`;
    await redis.setex(key, 3600, JSON.stringify(recommendations)); // 1 hour TTL
  }
}
```

### Database Optimization
```go
// db-layer/go/src/optimization.go
package main

import (
    "context"
    "time"
)

func (d *Database) GetUserInteractionsOptimized(userID int) ([]Interaction, error) {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    query := `
        SELECT user_id, item_id, action, timestamp
        FROM interactions
        WHERE user_id = $1
        ORDER BY timestamp DESC
        LIMIT 1000
    `
    
    rows, err := d.db.QueryContext(ctx, query, userID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var interactions []Interaction
    for rows.Next() {
        var interaction Interaction
        err := rows.Scan(&interaction.UserID, &interaction.ItemID, 
                        &interaction.Action, &interaction.Timestamp)
        if err != nil {
            return nil, err
        }
        interactions = append(interactions, interaction)
    }
    
    return interactions, nil
}
```

## 🔒 Security

### Authentication
```typescript
// logic/typescript/src/middleware/auth.ts
import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

export const authenticateToken = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET!, (err: any, user: any) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};
```

### Rate Limiting
```typescript
// logic/typescript/src/middleware/rateLimit.ts
import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
});
```

## 📈 Analytics

### Usage Tracking
```typescript
// logic/typescript/src/analytics/tracker.ts
export class AnalyticsTracker {
  static async trackRecommendationView(userId: number, recommendations: any[]) {
    await fetch('http://analytics:8080/track', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event: 'recommendation_view',
        userId,
        recommendations: recommendations.map(r => r.id),
        timestamp: new Date().toISOString()
      })
    });
  }

  static async trackRecommendationClick(userId: number, itemId: number) {
    await fetch('http://analytics:8080/track', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event: 'recommendation_click',
        userId,
        itemId,
        timestamp: new Date().toISOString()
      })
    });
  }
}
```

## 🎉 Conclusion

This example demonstrates the full power of the Polyglot App Framework:

- **Multi-language architecture** with seamless communication
- **Scalable design** that can handle high traffic
- **Comprehensive testing** across all layers
- **Production-ready deployment** with monitoring
- **Security best practices** implemented throughout
- **Performance optimization** for real-world usage

The recommendation system showcases how different languages can work together:
- **TypeScript** for API orchestration and type safety
- **Python** for machine learning and data processing
- **Go** for high-performance database operations
- **React** for responsive web interfaces
- **Flutter** for cross-platform mobile apps

This architecture can be extended to build any type of application that benefits from using the right tool for each job! 