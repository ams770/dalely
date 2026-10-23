import React from 'react';
import type { TranslationContent } from '../data/translations';
import { GooglePlayButton } from './GooglePlayButton';

interface HeroProps {
  t: TranslationContent;
  lang: 'en' | 'ar';
}

export const Hero: React.FC<HeroProps> = ({ t }) => {
  return (
    <section
      style={{
        position: 'relative',
        backgroundColor: '#1A93EA',
        color: '#FFFFFF',
        padding: '64px 0 80px',
        overflow: 'hidden',
      }}
    >
      <div className="container">
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
            gap: '48px',
            alignItems: 'center',
          }}
        >
          {/* Left Column: Small amount of friendly text & Android Store CTA */}
          <div style={{ maxWidth: '540px' }}>
            {/* Friendly Badge */}
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '6px 14px',
                borderRadius: '9999px',
                backgroundColor: 'rgba(255, 255, 255, 0.18)',
                color: '#FFFFFF',
                fontSize: '0.85rem',
                fontWeight: 600,
                marginBottom: '20px',
                backdropFilter: 'blur(8px)',
              }}
            >
              <span>{t.hero.badge}</span>
            </div>

            {/* Main Title - Short and punchy */}
            <h1
              style={{
                fontSize: 'clamp(2.2rem, 4.5vw, 3.4rem)',
                fontWeight: 900,
                lineHeight: 1.2,
                letterSpacing: '-0.02em',
                marginBottom: '16px',
                color: '#FFFFFF',
              }}
            >
              {t.hero.title}
            </h1>

            {/* Subtitle - Light text, short & friendly */}
            <p
              style={{
                fontSize: '1.15rem',
                color: 'rgba(255, 255, 255, 0.92)',
                lineHeight: 1.6,
                marginBottom: '32px',
                maxWidth: '480px',
              }}
            >
              {t.hero.subtitle}
            </p>

            {/* Only Android Google Play button */}
            <div
              style={{
                display: 'flex',
                flexWrap: 'wrap',
                alignItems: 'center',
                gap: '16px',
                marginBottom: '16px',
              }}
            >
              <GooglePlayButton
                variant="light"
                size="large"
                smallText={t.hero.googlePlayBtn}
                largeText={t.hero.googlePlaySub}
              />


            </div>

            {/* Package Name note */}
            <div
              style={{
                fontSize: '0.8rem',
                color: 'rgba(255, 255, 255, 0.75)',
                fontWeight: 500,
                marginTop: '4px',
              }}
            >
              <code
                style={{
                  fontFamily: 'monospace',
                  backgroundColor: 'rgba(0, 0, 0, 0.18)',
                  padding: '2px 8px',
                  borderRadius: '6px',
                  color: '#FFFFFF',
                }}
              >
                {t.hero.packageName}
              </code>
            </div>
          </div>

          {/* Right Column: Friendly Onboarding Image & Distance Card */}
          <img
            src="/assets/onboarding_2.png"
            alt="Dalely Car Finder"
            style={{
              maxWidth: '100%',
              maxHeight: '450px',
              objectFit: 'contain',
              borderRadius: '16px',
            }}
          />
        </div>
      </div>
    </section>
  );
};
