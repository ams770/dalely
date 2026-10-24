import React from 'react';
import type { TranslationContent } from '../data/translations';
import { GooglePlayButton } from './GooglePlayButton';
import { AppStoreButton } from './AppStoreButton';

interface HeroProps {
  t: TranslationContent;
  lang: 'en' | 'ar';
}

export const Hero: React.FC<HeroProps> = ({ t, lang }) => {
  const isAr = lang === 'ar';

  return (
    <section className="hero-section">
      <div className="container">
        <div className="hero-layout">
          {/* Left Column (Desktop) / Centered Hero (Mobile) */}
          <div className="hero-content-col">
            {/* Friendly Live Pill Badge */}
            <div className="hero-badge-pill">
              <span>{t.hero.badge}</span>
            </div>

            {/* Main Title */}
            <h1 className="hero-main-title">
              {t.hero.title}
            </h1>

            {/* Subtitle */}
            <p className="hero-main-subtitle">
              {t.hero.subtitle}
            </p>

            {/* Dual CTA Buttons (App Store & Google Play) */}
            <div className="hero-cta-group">
              <AppStoreButton
                variant="light"
                size="large"
                smallText={t.hero.appStoreBtn}
                largeText={t.hero.appStoreSub}
              />
              <GooglePlayButton
                variant="light"
                size="large"
                smallText={t.hero.googlePlayBtn}
                largeText={t.hero.googlePlaySub}
              />
            </div>


          </div>

          {/* Right Column (Desktop) / Below Content (Mobile): Interactive Hero Live Radar Card */}
          {/* <HeroPreviewCard lang={lang} /> */}
          {/* Friendly Car Illustration Stage */}
          <div >
            <img
              src="/assets/car.png"
              alt={isAr ? 'مكان ركن السيارة' : 'Parked Car'}
            className="hero-clean-car-img"
            />
          </div>
        </div>
      </div>
    </section>
  );
};
