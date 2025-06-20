import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [activeSection, setActiveSection] = useState('hero');
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    setIsLoaded(true);
  }, []);

  const scrollToSection = (sectionId) => {
    setActiveSection(sectionId);
    document.getElementById(sectionId).scrollIntoView({ behavior: 'smooth' });
  };

  const features = [
    {
      icon: "🌐",
      title: "Multi-Language Support",
      description: "Write different parts of your app in the best language for each task - React, Flutter, TypeScript, Python, Go, and more."
    },
    {
      icon: "🧪",
      title: "Unified Testing",
      description: "Cross-language test orchestration and reporting with comprehensive coverage across all modules."
    },
    {
      icon: "🔗",
      title: "Smart Interop",
      description: "Seamless communication between language modules using JSON-RPC and message queues."
    },
    {
      icon: "🤖",
      title: "AI-Powered Development",
      description: "Automated code generation, testing, and documentation with intelligent assistance."
    },
    {
      icon: "🚀",
      title: "Multi-Platform Deployment",
      description: "Web, mobile, and backend deployment automation with Docker, Kubernetes, and cloud platforms."
    },
    {
      icon: "⚡",
      title: "High Performance",
      description: "Optimized for speed and scalability with efficient cross-language communication."
    }
  ];

  const techStack = [
    { name: "React", icon: "⚛️", color: "#61DAFB" },
    { name: "Flutter", icon: "📱", color: "#02569B" },
    { name: "TypeScript", icon: "🔷", color: "#3178C6" },
    { name: "Python", icon: "🐍", color: "#3776AB" },
    { name: "Go", icon: "🔵", color: "#00ADD8" },
    { name: "Kotlin", icon: "🔶", color: "#7F52FF" }
  ];

  const quickStartSteps = [
    {
      step: "1",
      title: "Install Dependencies",
      command: "./scripts/setup.sh",
      description: "Install all language runtimes and development tools"
    },
    {
      step: "2",
      title: "Start Development",
      command: "./scripts/dev.sh",
      description: "Launch all development servers simultaneously"
    },
    {
      step: "3",
      title: "Run Tests",
      command: "./scripts/test.sh",
      description: "Execute comprehensive cross-language test suite"
    },
    {
      step: "4",
      title: "Deploy",
      command: "./scripts/deploy.sh",
      description: "Deploy to multiple platforms with one command"
    }
  ];

  return (
    <div className={`App ${isLoaded ? 'loaded' : ''}`}>
      {/* Navigation */}
      <nav className="navbar">
        <div className="nav-container">
          <div className="nav-logo">
            <span className="logo-icon">🔄</span>
            <span className="logo-text">AllForOneIsOneForAll</span>
          </div>
          <div className="nav-links">
            <button onClick={() => scrollToSection('hero')} className={activeSection === 'hero' ? 'active' : ''}>Home</button>
            <button onClick={() => scrollToSection('features')} className={activeSection === 'features' ? 'active' : ''}>Features</button>
            <button onClick={() => scrollToSection('tech')} className={activeSection === 'tech' ? 'active' : ''}>Tech Stack</button>
            <button onClick={() => scrollToSection('quickstart')} className={activeSection === 'quickstart' ? 'active' : ''}>Quick Start</button>
            <button onClick={() => scrollToSection('docs')} className={activeSection === 'docs' ? 'active' : ''}>Documentation</button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section id="hero" className="hero-section">
        <div className="hero-content">
          <div className="hero-text">
            <h1 className="hero-title">
              <span className="title-main">AllForOneIsOneForAll</span>
              <span className="title-sub">Polyglot Framework</span>
            </h1>
            <p className="hero-description">
              Build powerful applications using multiple programming languages with unified development workflows, 
              intelligent automation, and seamless cross-language communication.
            </p>
            <div className="hero-buttons">
              <button className="btn-primary" onClick={() => scrollToSection('quickstart')}>
                🚀 Get Started
              </button>
              <button className="btn-secondary" onClick={() => scrollToSection('docs')}>
                📚 View Documentation
              </button>
            </div>
          </div>
          <div className="hero-visual">
            <div className="framework-diagram">
              <div className="layer ui-layer">
                <span>📱 UI Layer</span>
                <div className="tech-badges">
                  <span className="tech-badge">React</span>
                  <span className="tech-badge">Flutter</span>
                </div>
              </div>
              <div className="layer logic-layer">
                <span>🧠 Logic Layer</span>
                <div className="tech-badges">
                  <span className="tech-badge">TypeScript</span>
                  <span className="tech-badge">Kotlin</span>
                </div>
              </div>
              <div className="layer ai-layer">
                <span>🤖 AI Layer</span>
                <div className="tech-badges">
                  <span className="tech-badge">Python</span>
                </div>
              </div>
              <div className="layer db-layer">
                <span>🗄️ Data Layer</span>
                <div className="tech-badges">
                  <span className="tech-badge">Go</span>
                  <span className="tech-badge">Node.js</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="features-section">
        <div className="container">
          <h2 className="section-title">✨ Framework Features</h2>
          <div className="features-grid">
            {features.map((feature, index) => (
              <div key={index} className="feature-card">
                <div className="feature-icon">{feature.icon}</div>
                <h3 className="feature-title">{feature.title}</h3>
                <p className="feature-description">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Tech Stack Section */}
      <section id="tech" className="tech-section">
        <div className="container">
          <h2 className="section-title">🛠️ Technology Stack</h2>
          <div className="tech-grid">
            {techStack.map((tech, index) => (
              <div key={index} className="tech-card" style={{ borderColor: tech.color }}>
                <div className="tech-icon">{tech.icon}</div>
                <h3 className="tech-name">{tech.name}</h3>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Quick Start Section */}
      <section id="quickstart" className="quickstart-section">
        <div className="container">
          <h2 className="section-title">⚡ Quick Start</h2>
          <div className="quickstart-steps">
            {quickStartSteps.map((step, index) => (
              <div key={index} className="step-card">
                <div className="step-number">{step.step}</div>
                <div className="step-content">
                  <h3 className="step-title">{step.title}</h3>
                  <div className="step-command">
                    <code>{step.command}</code>
                  </div>
                  <p className="step-description">{step.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Documentation Section */}
      <section id="docs" className="docs-section">
        <div className="container">
          <h2 className="section-title">📚 Documentation</h2>
          <div className="docs-grid">
            <div className="doc-card">
              <div className="doc-icon">🚀</div>
              <h3>Quick Start Guide</h3>
              <p>Get up and running in minutes with our comprehensive quick start guide.</p>
              <button className="doc-link">Read Guide →</button>
            </div>
            <div className="doc-card">
              <div className="doc-icon">🏗️</div>
              <h3>Architecture Overview</h3>
              <p>Understand the system design and structure of the polyglot framework.</p>
              <button className="doc-link">View Architecture →</button>
            </div>
            <div className="doc-card">
              <div className="doc-icon">📋</div>
              <h3>API Reference</h3>
              <p>Complete API documentation for all language modules and interop features.</p>
              <button className="doc-link">Browse API →</button>
            </div>
            <div className="doc-card">
              <div className="doc-icon">🛠️</div>
              <h3>Development Guide</h3>
              <p>Learn how to contribute and extend the framework with new features.</p>
              <button className="doc-link">Start Contributing →</button>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-section">
              <h3>AllForOneIsOneForAll</h3>
              <p>Building the future of polyglot development</p>
            </div>
            <div className="footer-section">
              <h4>Quick Links</h4>
              <ul>
                <li><button onClick={() => scrollToSection('hero')}>Home</button></li>
                <li><button onClick={() => scrollToSection('features')}>Features</button></li>
                <li><button onClick={() => scrollToSection('quickstart')}>Quick Start</button></li>
                <li><button onClick={() => scrollToSection('docs')}>Documentation</button></li>
              </ul>
            </div>
            <div className="footer-section">
              <h4>Resources</h4>
              <ul>
                <li><a href="https://github.com" target="_blank" rel="noopener noreferrer">GitHub</a></li>
                <li><a href="https://discord.gg" target="_blank" rel="noopener noreferrer">Discord</a></li>
                <li><a href="https://twitter.com" target="_blank" rel="noopener noreferrer">Twitter</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <p>&copy; 2024 AllForOneIsOneForAll Framework. Built with ❤️ using React.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App; 