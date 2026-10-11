import React from 'react';
import { MapPin, Navigation, Share2 } from 'lucide-react';
import type { TranslationContent } from '../data/translations';

interface SpotActionsSectionProps {
  t: TranslationContent;
}

export const SpotActionsSection: React.FC<SpotActionsSectionProps> = ({ t }) => {
  const getIcon = (iconName: string) => {
    switch (iconName) {
      case 'MapPin':
        return <MapPin size={28} color="#1A93EA" />;
      case 'Navigation':
        return <Navigation size={28} color="#FF8A65" />;
      case 'Share2':
        return <Share2 size={28} color="#10B981" />;
      default:
        return <MapPin size={28} color="#1A93EA" />;
    }
  };

  return (
    <section id="features" style={{ padding: '80px 0', backgroundColor: 'var(--bg-surface)' }}>
      <div className="container">
        <div className="section-header">
          <div className="badge" style={{ marginBottom: '16px' }}>
            <span>{t.actions.badge}</span>
          </div>
          <h2 className="section-title">{t.actions.title}</h2>
          <p className="section-subtitle">{t.actions.subtitle}</p>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            gap: '28px',
          }}
        >
          {t.actions.items.map((item, index) => (
            <div
              key={index}
              style={{
                backgroundColor: 'var(--bg-main)',
                borderRadius: '24px',
                padding: '32px 28px',
                border: '1px solid var(--border-light)',
                display: 'flex',
                flexDirection: 'column',
                gap: '16px',
                transition: 'transform 0.25s ease, border-color 0.25s ease',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-4px)';
                e.currentTarget.style.borderColor = 'var(--primary)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.borderColor = 'var(--border-light)';
              }}
            >
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <div
                  style={{
                    width: '56px',
                    height: '56px',
                    borderRadius: '18px',
                    backgroundColor: 'var(--bg-surface)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.04)',
                  }}
                >
                  {getIcon(item.icon)}
                </div>

                <span
                  style={{
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    padding: '4px 10px',
                    borderRadius: '9999px',
                    backgroundColor: 'var(--bg-surface)',
                    color: 'var(--text-muted)',
                    border: '1px solid var(--border-light)',
                  }}
                >
                  {item.badgeText}
                </span>
              </div>

              <div>
                <h3
                  style={{
                    fontSize: '1.25rem',
                    fontWeight: 800,
                    marginBottom: '8px',
                    color: 'var(--text-main)',
                  }}
                >
                  {item.title}
                </h3>
                <p
                  style={{
                    fontSize: '0.95rem',
                    color: 'var(--text-muted)',
                    lineHeight: 1.6,
                  }}
                >
                  {item.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
