import { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import type { TranslationContent } from '../data/translations';

interface FaqSectionProps {
  t: TranslationContent;
}

export const FaqSection: React.FC<FaqSectionProps> = ({ t }) => {
  const [openIndices, setOpenIndices] = useState<number[]>([0]);

  const toggleAccordion = (idx: number) => {
    setOpenIndices((prev) =>
      prev.includes(idx) ? prev.filter((i) => i !== idx) : [...prev, idx]
    );
  };

  return (
    <section
      id="faq"
      style={{
        padding: '80px 0',
        backgroundColor: 'var(--bg-main)',
        borderTop: '1px solid var(--border-light)',
      }}
    >
      <div className="container" style={{ maxWidth: '820px' }}>
        <div className="section-header">
          <div className="badge" style={{ marginBottom: '16px' }}>
            <span>{t.faq.badge}</span>
          </div>
          <h2 className="section-title">{t.faq.title}</h2>
          <p className="section-subtitle">{t.faq.subtitle}</p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {t.faq.items.map((item, idx) => {
            const isOpen = openIndices.includes(idx);
            return (
              <div
                key={idx}
                className="glass-card"
                style={{
                  borderRadius: '20px',
                  overflow: 'hidden',
                  transition: 'all 0.2s ease',
                  backgroundColor: 'var(--bg-surface)',
                  border: isOpen ? '1px solid var(--border-primary)' : '1px solid var(--border-light)',
                }}
              >
                <button
                  onClick={() => toggleAccordion(idx)}
                  style={{
                    width: '100%',
                    padding: '20px 24px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    gap: '16px',
                    textAlign: 'start',
                    fontWeight: 700,
                    fontSize: '1.05rem',
                    color: 'var(--text-main)',
                  }}
                >
                  <span>{item.question}</span>
                  <div
                    style={{
                      transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                      transition: 'transform 0.25s ease',
                      color: isOpen ? 'var(--primary)' : 'var(--text-muted)',
                      flexShrink: 0,
                    }}
                  >
                    <ChevronDown size={20} />
                  </div>
                </button>

                {isOpen && (
                  <div
                    style={{
                      padding: '0 24px 20px',
                      color: 'var(--text-muted)',
                      fontSize: '0.95rem',
                      lineHeight: 1.65,
                    }}
                  >
                    {item.answer}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
