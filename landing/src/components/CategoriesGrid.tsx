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

        <div className="categories-items-grid">
          {t.categories.items.map((cat, idx) => (
            <div
              key={idx}
              className="glass-card"
              style={{
                padding: '16px 14px',
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                borderRadius: '18px',
                backgroundColor: 'var(--bg-surface)',
                border: '1px solid var(--border-light)',
                transition: 'transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease',
                minWidth: 0,
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
                  width: '42px',
                  height: '42px',
                  borderRadius: '12px',
                  backgroundColor: `${cat.color}15`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '1.3rem',
                  flexShrink: 0,
                  border: `1.5px solid ${cat.color}35`,
                }}
              >
                {cat.icon}
              </div>

              <div style={{ minWidth: 0, flex: 1 }}>
                <div
                  style={{
                    fontSize: '0.95rem',
                    fontWeight: 700,
                    color: 'var(--text-main)',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
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

