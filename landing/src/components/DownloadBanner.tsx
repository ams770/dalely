import React from 'react';
import type { TranslationContent } from '../data/translations';
import { GooglePlayButton } from './GooglePlayButton';

interface DownloadBannerProps {
  t: TranslationContent;
}

export const DownloadBanner: React.FC<DownloadBannerProps> = ({ t }) => {
  return (
    <section id="download" style={{ padding: '80px 0', backgroundColor: 'var(--bg-main)' }}>
      <div className="container">
        <div
          style={{
            background: 'linear-gradient(135deg, #12263F 0%, #0F1E33 100%)',
            color: '#FFFFFF',
            borderRadius: '32px',
            padding: '56px 32px',
            textAlign: 'center',
            position: 'relative',
            overflow: 'hidden',
            boxShadow: '0 20px 50px -10px rgba(18, 38, 63, 0.4)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
          }}
        >
          {/* Subtle Glow Circle */}
          <div
            style={{
              position: 'absolute',
              top: '-50px',
              left: '50%',
              transform: 'translateX(-50%)',
              width: '320px',
              height: '320px',
              borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(26, 147, 234, 0.25) 0%, transparent 70%)',
              filter: 'blur(40px)',
              pointerEvents: 'none',
            }}
          />

          <div style={{ position: 'relative', zIndex: 1, maxWidth: '600px', margin: '0 auto' }}>
            {/* Friendly Car Graphic */}
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '20px',
              }}
            >
              <img
                src="/assets/car.png"
                alt="Car"
                style={{ height: '64px', objectFit: 'contain' }}
              />
            </div>

            {/* Pill Badge */}
            <div style={{ marginBottom: '16px' }}>
              <span
                style={{
                  display: 'inline-block',
                  padding: '6px 16px',
                  borderRadius: '9999px',
                  backgroundColor: 'rgba(255, 255, 255, 0.12)',
                  color: '#93C5FD',
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  backdropFilter: 'blur(8px)',
                }}
              >
                {t.ctaBanner.badge}
              </span>
            </div>

            {/* Title */}
            <h2
              style={{
                fontSize: 'clamp(1.9rem, 4vw, 2.6rem)',
                fontWeight: 900,
                letterSpacing: '-0.02em',
                marginBottom: '14px',
                lineHeight: 1.25,
                color: '#FFFFFF',
              }}
            >
              {t.ctaBanner.title}
            </h2>

            {/* Subtitle */}
            <p
              style={{
                fontSize: '1.05rem',
                color: '#94A3B8',
                marginBottom: '32px',
                lineHeight: 1.6,
              }}
            >
              {t.ctaBanner.subtitle}
            </p>

            {/* Only Android Google Play button */}
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '12px',
                marginBottom: '20px',
              }}
            >
              <GooglePlayButton
                variant="light"
                size="large"
                smallText={t.hero.googlePlayBtn}
                largeText={t.hero.googlePlaySub}
              />

              <div
                style={{
                  fontSize: '0.8rem',
                  color: '#94A3B8',
                  fontFamily: 'monospace',
                }}
              >
                {t.ctaBanner.packageName}
              </div>
            </div>

            {/* Note */}
            <div style={{ fontSize: '0.82rem', color: '#64748B' }}>
              {t.ctaBanner.note}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
