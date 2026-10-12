import React from 'react';
import type { TranslationContent } from '../data/translations';
import { GooglePlayButton } from './GooglePlayButton';

interface HeroProps {
  t: TranslationContent;
  lang: 'en' | 'ar';
}

export const Hero: React.FC<HeroProps> = ({ t, lang }) => {
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
              <div
                style={{
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  backgroundColor: '#FFFFFF',
                }}
              />
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
              <span>{lang === 'ar' ? 'حزمة أندرويد:' : 'Android Package:'} </span>
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
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              position: 'relative',
            }}
          >
            {/* Friendly Card with Onboarding Image from Flutter App */}
            <div
              style={{
                position: 'relative',
                width: '100%',
                maxWidth: '420px',
                backgroundColor: '#FFFFFF',
                borderRadius: '32px',
                padding: '28px',
                boxShadow:
                  '0 24px 50px -12px rgba(11, 40, 70, 0.35), 0 0 0 1px rgba(255, 255, 255, 0.3)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                textAlign: 'center',
              }}
            >
              {/* Top status bar inside card */}
              <div
                style={{
                  width: '100%',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '16px',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    fontSize: '0.82rem',
                    fontWeight: 700,
                    color: '#12263F',
                  }}
                >
                  <img
                    src="/assets/logo.png"
                    alt="Dalely"
                    style={{ width: '22px', height: '22px', borderRadius: '6px' }}
                  />
                  <span>{lang === 'ar' ? 'دليلى' : 'Dalely'}</span>
                </div>

                {/* Distance pill (Coral theme accent) */}
                <div
                  style={{
                    backgroundColor: '#FF8A65',
                    color: '#12263F',
                    fontSize: '0.78rem',
                    fontWeight: 800,
                    padding: '4px 12px',
                    borderRadius: '9999px',
                    boxShadow: '0 2px 8px rgba(255, 138, 101, 0.3)',
                  }}
                >
                  {t.hero.distancePill}
                </div>
              </div>

              {/* Onboarding Image from onboarding_screen.dart */}
              <div
                style={{
                  width: '100%',
                  maxHeight: '260px',
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  margin: '8px 0 16px',
                }}
              >
                <img
                  src="/assets/onboarding_1.png"
                  alt="Dalely Car Finder"
                  style={{
                    maxWidth: '100%',
                    maxHeight: '250px',
                    objectFit: 'contain',
                    borderRadius: '16px',
                  }}
                />
              </div>

              {/* Bottom Friendly Note */}
              <div
                style={{
                  width: '100%',
                  backgroundColor: '#F3F9FF',
                  borderRadius: '16px',
                  padding: '10px 14px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <span
                  style={{
                    fontSize: '0.82rem',
                    fontWeight: 700,
                    color: '#0B6FBF',
                  }}
                >
                  🚗 {t.hero.carParkedBadge}
                </span>
                <span
                  style={{
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    color: '#5B738E',
                  }}
                >
                  {lang === 'ar' ? 'محلياً على جهازك' : '100% on device'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
