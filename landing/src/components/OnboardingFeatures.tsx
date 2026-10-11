import React from 'react';
import type { TranslationContent } from '../data/translations';

interface OnboardingFeaturesProps {
  t: TranslationContent;
}

export const OnboardingFeatures: React.FC<OnboardingFeaturesProps> = ({ t }) => {
  return (
    <section id="how-it-works" style={{ padding: '80px 0', backgroundColor: 'var(--bg-main)' }}>
      <div className="container">
        {/* Section Header */}
        <div className="section-header">
          <div className="badge" style={{ marginBottom: '16px' }}>
            <span>{t.onboarding.badge}</span>
          </div>
          <h2 className="section-title">{t.onboarding.title}</h2>
          <p className="section-subtitle">{t.onboarding.subtitle}</p>
        </div>

        {/* 3 Steps Grid featuring Onboarding Illustrations */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(310px, 1fr))',
            gap: '32px',
          }}
        >
          {t.onboarding.steps.map((step, idx) => (
            <div
              key={step.id}
              className="glass-card"
              style={{
                display: 'flex',
                flexDirection: 'column',
                overflow: 'hidden',
                borderRadius: '28px',
                padding: '24px',
                backgroundColor: 'var(--bg-surface)',
                border: '1px solid var(--border-light)',
                transition: 'transform 0.3s ease, box-shadow 0.3s ease',
              }}
            >
              {/* Image Preview Container */}
              <div
                style={{
                  backgroundColor: idx === 0 ? '#F3F9FF' : idx === 1 ? '#F0FBF6' : '#FAF5FF',
                  borderRadius: '20px',
                  padding: '20px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  minHeight: '220px',
                  marginBottom: '20px',
                }}
              >
                <img
                  src={step.image}
                  alt={step.title}
                  style={{
                    maxHeight: '190px',
                    maxWidth: '100%',
                    objectFit: 'contain',
                    transition: 'transform 0.3s ease',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.transform = 'scale(1.05)')}
                  onMouseLeave={(e) => (e.currentTarget.style.transform = 'scale(1)')}
                />
              </div>

              {/* Step Pill */}
              <div style={{ marginBottom: '12px' }}>
                <span
                  style={{
                    display: 'inline-block',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    padding: '4px 12px',
                    borderRadius: '9999px',
                    backgroundColor: 'var(--bg-subtle)',
                    color: 'var(--primary)',
                  }}
                >
                  {step.highlight}
                </span>
              </div>

              {/* Step Title */}
              <h3
                style={{
                  fontSize: '1.3rem',
                  fontWeight: 800,
                  marginBottom: '10px',
                  color: 'var(--text-main)',
                  lineHeight: 1.3,
                }}
              >
                {step.title}
              </h3>

              {/* Step Body */}
              <p
                style={{
                  fontSize: '0.98rem',
                  color: 'var(--text-muted)',
                  lineHeight: 1.6,
                  flex: 1,
                }}
              >
                {step.body}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
