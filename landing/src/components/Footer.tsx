import React from 'react';
import { ShieldCheck, Heart, Mail, Phone, MessageCircle } from 'lucide-react';
import type { TranslationContent } from '../data/translations';
import { PLAY_STORE_URL, APP_STORE_URL, CONTACT_EMAIL, CONTACT_PHONE, WHATSAPP_URL } from '../data/translations';

interface FooterProps {
  t: TranslationContent;
  lang: 'en' | 'ar';
  onNavigatePrivacy: () => void;
  onNavigateHome: () => void;
  onToggleLang: () => void;
}

export const Footer: React.FC<FooterProps> = ({
  t,
  lang,
  onNavigatePrivacy,
  onNavigateHome,
  onToggleLang,
}) => {
  return (
    <footer
      style={{
        backgroundColor: 'var(--bg-surface)',
        borderTop: '1px solid var(--border-light)',
        padding: '60px 0 36px',
      }}
    >
      <div className="container">
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '40px',
            marginBottom: '48px',
          }}
        >
          {/* Brand Col */}
          <div style={{ maxWidth: '320px' }}>
            <button
              onClick={onNavigateHome}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                marginBottom: '14px',
                textAlign: 'start',
                cursor: 'pointer',
              }}
            >
              <img
                src="/assets/logo.png"
                alt="Dalely Logo"
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '10px',
                }}
              />
              <span
                style={{
                  fontSize: '1.2rem',
                  fontWeight: 800,
                  color: 'var(--text-main)',
                }}
              >
                {lang === 'ar' ? 'دليلى' : 'Dalely'}
              </span>
            </button>

            <p
              style={{
                fontSize: '0.9rem',
                color: 'var(--text-muted)',
                lineHeight: 1.6,
                marginBottom: '18px',
              }}
            >
              {t.footer.tagline}
            </p>

            <button
              onClick={onToggleLang}
              style={{
                fontSize: '0.85rem',
                fontWeight: 700,
                color: 'var(--primary)',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                cursor: 'pointer',
              }}
            >
              🌐 {lang === 'en' ? 'التحويل للغة العربية' : 'Switch to English'}
            </button>
          </div>

          {/* Quick Links */}
          <div>
            <div
              style={{
                fontSize: '0.95rem',
                fontWeight: 800,
                color: 'var(--text-main)',
                marginBottom: '16px',
              }}
            >
              {t.footer.quickLinks}
            </div>
            <ul
              style={{
                listStyle: 'none',
                display: 'flex',
                flexDirection: 'column',
                gap: '12px',
                fontSize: '0.9rem',
                color: 'var(--text-muted)',
              }}
            >
              <li>
                <a href="#how-it-works" style={{ transition: 'color 0.2s' }}>
                  {t.nav.howItWorks}
                </a>
              </li>
              <li>
                <a href="#features" style={{ transition: 'color 0.2s' }}>
                  {t.nav.features}
                </a>
              </li>
              <li>
                <a href="#categories" style={{ transition: 'color 0.2s' }}>
                  {t.nav.categories}
                </a>
              </li>
              <li>
                <a href="#faq" style={{ transition: 'color 0.2s' }}>
                  {t.nav.faq}
                </a>
              </li>
            </ul>
          </div>

          {/* Android Store & Privacy */}
          <div>
            <div
              style={{
                fontSize: '0.95rem',
                fontWeight: 800,
                color: 'var(--text-main)',
                marginBottom: '16px',
              }}
            >
              {lang === 'ar' ? 'التحميل والخصوصية' : 'Download & Privacy'}
            </div>
            <ul
              style={{
                listStyle: 'none',
                display: 'flex',
                flexDirection: 'column',
                gap: '12px',
                fontSize: '0.9rem',
                color: 'var(--text-muted)',
              }}
            >
              <li>
                <a
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    color: 'var(--primary)',
                    fontWeight: 700,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                >
                  <span>App Store</span>
                </a>
              </li>
              <li>
                <a
                  href={PLAY_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    color: 'var(--primary)',
                    fontWeight: 700,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                >
                  <span>Google Play</span>
                </a>
              </li>
              <li>
                <button
                  onClick={onNavigatePrivacy}
                  style={{
                    color: 'var(--text-main)',
                    fontWeight: 600,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    cursor: 'pointer',
                  }}
                >
                  <ShieldCheck size={16} color="var(--primary)" />
                  <span>{t.footer.privacyPolicy}</span>
                </button>
              </li>
              <li>
                <a
                  href={`mailto:${CONTACT_EMAIL}`}
                  style={{
                    color: 'var(--text-main)',
                    fontWeight: 600,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                >
                  <Mail size={15} color="var(--primary)" />
                  <span>{CONTACT_EMAIL}</span>
                </a>
              </li>
              <li>
                <a
                  href={WHATSAPP_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    color: 'var(--text-main)',
                    fontWeight: 600,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    direction: 'ltr',
                  }}
                >
                  <MessageCircle size={15} color="#25D366" />
                  <span>{CONTACT_PHONE}</span>
                </a>
              </li>
              <li>
                <a
                  href={`tel:${CONTACT_PHONE}`}
                  style={{
                    color: 'var(--text-main)',
                    fontWeight: 600,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    direction: 'ltr',
                  }}
                >
                  <Phone size={15} color="var(--primary)" />
                  <span>{CONTACT_PHONE}</span>
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div
          style={{
            paddingTop: '28px',
            borderTop: '1px solid var(--border-light)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '16px',
            fontSize: '0.85rem',
            color: 'var(--text-muted)',
          }}
        >
          <div>{t.footer.copyright}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span>Made with</span>
            <Heart size={14} color="#EF4444" fill="#EF4444" />
            <span>for private, simple daily navigation</span>
          </div>
        </div>
      </div>
    </footer>
  );
};
