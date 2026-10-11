import React from 'react';
import type { TranslationContent } from '../data/translations';

interface CategoriesGridProps {
  t: TranslationContent;
}

export const CategoriesGrid: React.FC<CategoriesGridProps> = ({ t }) => {
  return (
    <section id="categories" style={{ padding: '80px 0', backgroundColor: 'var(--bg-main)' }}>
      <div className="container">
        <div className="section-header">
          <div className="badge" style={{ marginBottom: '16px' }}>
            <span>{t.categories.badge}</span>
          </div>
          <h2 className="section-title">{t.categories.title}</h2>
          <p className="section-subtitle">{t.categories.subtitle}</p>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))',
            gap: '16px',
          }}
        >
          {t.categories.items.map((cat, idx) => (
            <div
              key={idx}
              className="glass-card"
              style={{
                padding: '18px 16px',
                display: 'flex',
                alignItems: 'center',
                gap: '14px',
                borderRadius: '20px',
                backgroundColor: 'var(--bg-surface)',
                border: '1px solid var(--border-light)',
                transition: 'transform 0.2s ease, border-color 0.2s ease',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.borderColor = cat.color;
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.borderColor = 'var(--border-light)';
              }}
            >
              <div
                style={{
                  width: '44px',
                  height: '44px',
                  borderRadius: '14px',
                  backgroundColor: `${cat.color}15`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '1.4rem',
                  flexShrink: 0,
                  border: `1.5px solid ${cat.color}35`,
                }}
              >
                {cat.icon}
              </div>

              <div>
                <div
                  style={{
                    fontSize: '1rem',
                    fontWeight: 700,
                    color: 'var(--text-main)',
                  }}
                >
                  {cat.name}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
