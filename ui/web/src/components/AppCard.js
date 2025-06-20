import React from 'react';

function AppCard({ name, description, icon, color, url }) {
  const handleClick = () => {
    if (url && url !== '#') {
      window.open(url, '_blank');
    } else {
      alert(`🚀 ${name} - Coming Soon!`);
    }
  };

  return (
    <div 
      className="app-card"
      onClick={handleClick}
      style={{ '--card-color': color }}
    >
      <div className="app-icon">
        <span role="img" aria-label={name}>
          {icon}
        </span>
      </div>
      <div className="app-info">
        <h3 className="app-name">{name}</h3>
        <p className="app-description">{description}</p>
      </div>
      <div className="app-arrow">
        <span>→</span>
      </div>
    </div>
  );
}

export default AppCard; 