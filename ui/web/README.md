# 🌐 AllForOneIsOneForAll - Web UI

This is the web interface for the AllForOneIsOneForAll polyglot framework, featuring a beautiful intro page that showcases the framework's capabilities.

## 🚀 Live Demo

Visit the live website: **[https://abhishek.dharmman.github.io/my-polyglot-app](https://abhishek.dharmman.github.io/my-polyglot-app)**

## 🛠️ Local Development

### Prerequisites
- Node.js (version 16 or higher)
- npm or yarn

### Installation
```bash
# Install dependencies
npm install

# Start development server
npm start
```

The website will be available at `http://localhost:3000`

### Build for Production
```bash
# Create production build
npm run build

# Preview production build locally
npx serve -s build
```

## 🚀 Deployment

### GitHub Pages (Automatic)

This project is configured for automatic deployment to GitHub Pages. Every push to the `main` branch will trigger a deployment.

#### Manual Deployment
```bash
# Deploy to GitHub Pages
npm run deploy
```

### Other Hosting Options

#### Netlify (Free)
1. Connect your GitHub repository to Netlify
2. Set build command: `cd ui/web && npm install && npm run build`
3. Set publish directory: `ui/web/build`

#### Vercel (Free)
1. Connect your GitHub repository to Vercel
2. Set root directory: `ui/web`
3. Vercel will automatically detect React and deploy

#### Firebase Hosting (Free)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init hosting

# Build and deploy
cd ui/web && npm run build
firebase deploy
```

## 📁 Project Structure

```
ui/web/
├── public/                 # Static files
│   ├── index.html         # Main HTML template
│   └── favicon.ico        # Website icon
├── src/                   # React source code
│   ├── App.js            # Main React component
│   ├── App.css           # Styles for the intro page
│   ├── index.js          # React entry point
│   └── components/       # Reusable components
└── package.json          # Dependencies and scripts
```

## 🎨 Features

- **Responsive Design**: Works perfectly on desktop, tablet, and mobile
- **Modern UI**: Beautiful gradient design with smooth animations
- **Interactive Elements**: Hover effects and smooth scrolling navigation
- **Framework Showcase**: Visual representation of the polyglot architecture
- **Documentation Links**: Direct links to organized documentation
- **Quick Start Guide**: Step-by-step getting started instructions

## 🔧 Customization

### Colors
The main color scheme uses a purple gradient (`#667eea` to `#764ba2`). You can customize this in `src/App.css`:

```css
/* Main gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Button gradients */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Content
Update the content in `src/App.js`:
- Features list
- Technology stack
- Quick start steps
- Documentation links

### Styling
Modify `src/App.css` to change:
- Typography
- Layout
- Animations
- Responsive breakpoints

## 📱 Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `npm start`
5. Submit a pull request

## 📄 License

This project is part of the AllForOneIsOneForAll framework and follows the same license terms.

---

Built with ❤️ using React and the AllForOneIsOneForAll framework. 