import React from 'react';

interface HeroPreviewCardProps {
  lang: 'en' | 'ar';
}

export const HeroPreviewCard: React.FC<HeroPreviewCardProps> = ({ }) => {

  return (
    <div className="hero-preview-wrapper">
      {/* Soft Ambient Glow */}
      <div className="hero-clean-glow" />

      {/* Clean, Friendly Showcase Card */}
      <div className="hero-clean-card">

    

      
      </div>
    </div>
  );
};

