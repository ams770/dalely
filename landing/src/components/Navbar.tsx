import { useState } from 'react';
import { Globe, Sun, Moon, Menu, X, ShieldCheck } from 'lucide-react';
import type { TranslationContent } from '../data/translations';
import { PLAY_STORE_URL } from '../data/translations';

interface NavbarProps {
  t: TranslationContent;
  lang: 'en' | 'ar';
  onToggleLang: () => void;
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
  onNavigatePrivacy: () => void;
  onNavigateHome: () => void;
  isPrivacyPage: boolean;
}

export const Navbar: React.FC<NavbarProps> = ({
  t,
  lang,
  onToggleLang,
  theme,
  onToggleTheme,
  onNavigatePrivacy,
  onNavigateHome,
  isPrivacyPage,
}) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleNavClick = (anchorId: string) => {
    setMobileMenuOpen(false);
    if (isPrivacyPage) {
      onNavigateHome();
      setTimeout(() => {
        const el = document.getElementById(anchorId);
        el?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    } else {
      const el = document.getElementById(anchorId);
      el?.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <header
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        backgroundColor: 'var(--nav-bg)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        borderBottom: '1px solid var(--border-light)',
        transition: 'all 0.3s ease',
      }}
    >
      <div
        className="container"
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          height: '74px',
        }}
      >
        {/* Brand Logo & Name */}
        <button
          onClick={onNavigateHome}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            textAlign: 'start',
            cursor: 'pointer',
          }}
        >
          <img
            src="/assets/logo.png"
            alt="Dalely Logo"
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '12px',
              objectFit: 'contain',
            }}
          />
          <div>
            <div
              style={{
                fontSize: '1.2rem',
                fontWeight: 800,
                color: 'var(--text-main)',
                lineHeight: 1.1,
                letterSpacing: '-0.02em',
              }}
            >
              {lang === 'ar' ? 'دليلى' : 'Dalely'}
            </div>
            <span
              style={{
                fontSize: '0.72rem',
                color: 'var(--text-muted)',
                fontWeight: 600,
              }}
            >
              {lang === 'ar' ? 'مكان سيارتك وأماكنك' : 'Spot & Car Finder'}
            </span>
          </div>
        </button>

        {/* Desktop Nav Links */}
        {!isPrivacyPage && (
          <nav
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '26px',
            }}
            className="desktop-nav"
          >
            <button
              onClick={() => handleNavClick('how-it-works')}
              style={{
                fontSize: '0.92rem',
                fontWeight: 600,
                color: 'var(--text-muted)',
                transition: 'color 0.2s',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-muted)')}
            >
              {t.nav.howItWorks}
            </button>
            <button
              onClick={() => handleNavClick('features')}
              style={{
                fontSize: '0.92rem',
                fontWeight: 600,
                color: 'var(--text-muted)',
                transition: 'color 0.2s',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-muted)')}
            >
              {t.nav.features}
            </button>
            <button
              onClick={() => handleNavClick('categories')}
              style={{
                fontSize: '0.92rem',
                fontWeight: 600,
                color: 'var(--text-muted)',
                transition: 'color 0.2s',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-muted)')}
            >
              {t.nav.categories}
            </button>
            <button
              onClick={() => handleNavClick('faq')}
              style={{
                fontSize: '0.92rem',
                fontWeight: 600,
                color: 'var(--text-muted)',
                transition: 'color 0.2s',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-muted)')}
            >
              {t.nav.faq}
            </button>
            <button
              onClick={onNavigatePrivacy}
              style={{
                fontSize: '0.92rem',
                fontWeight: 600,
                color: 'var(--text-muted)',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                transition: 'color 0.2s',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--text-muted)')}
            >
              <ShieldCheck size={16} />
              {t.nav.privacyPolicy}
            </button>
          </nav>
        )}

        {/* Action Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* Language Switcher */}
          <button
            onClick={onToggleLang}
            title={lang === 'en' ? 'التحويل للعربية' : 'Switch to English'}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              padding: '7px 12px',
              borderRadius: '9999px',
              backgroundColor: 'var(--bg-subtle)',
              border: '1px solid var(--border-light)',
              color: 'var(--text-main)',
              fontSize: '0.85rem',
              fontWeight: 700,
              transition: 'all 0.2s ease',
            }}
          >
            <Globe size={15} />
            <span>{lang === 'en' ? 'العربية' : 'English'}</span>
          </button>

          {/* Theme Switcher */}
          <button
            onClick={onToggleTheme}
            aria-label="Toggle Theme"
            style={{
              width: '36px',
              height: '36px',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              borderRadius: '50%',
              backgroundColor: 'var(--bg-subtle)',
              border: '1px solid var(--border-light)',
              color: 'var(--text-main)',
              transition: 'all 0.2s ease',
            }}
          >
            {theme === 'light' ? <Moon size={17} /> : <Sun size={17} />}
          </button>

          {/* Google Play CTA Button */}
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="desktop-cta"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: 'var(--primary)',
              color: '#FFFFFF',
              fontWeight: 700,
              fontSize: '0.88rem',
              padding: '9px 18px',
              borderRadius: '9999px',
              boxShadow: '0 4px 14px var(--primary-glow)',
              transition: 'all 0.2s ease',
            }}
          >
            <svg viewBox="0 0 512 512" width="16" height="16">
              <path fill="#FFFFFF" d="M47.7 13.9C39.6 22.5 35 35.8 35 52.3v407.4c0 16.5 4.6 29.8 12.7 38.4l2.1 2.1 228.1-228.1v-5.4L49.8 11.8l-2.1 2.1z"/>
              <path fill="#FFFFFF" opacity="0.9" d="M352.8 328.7l-74.9-74.9v-5.4l74.9-74.9 1.7 1 88.8 50.5c25.4 14.4 25.4 38.1 0 52.6l-88.8 50.1-1.7 1.1z"/>
              <path fill="#FFFFFF" opacity="0.8" d="M354.5 327.6L277.9 251 49.8 479.1c8.3 8.8 22.1 9.9 37.6 1.1l267.1-152.6z"/>
              <path fill="#FFFFFF" opacity="0.85" d="M354.5 184.4L87.4 31.8c-15.5-8.8-29.3-7.7-37.6 1.1L277.9 261l76.6-76.6z"/>
            </svg>
            <span>{t.nav.getGooglePlay}</span>
          </a>

          {/* Mobile Menu Toggle */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="mobile-menu-btn"
            style={{
              width: '36px',
              height: '36px',
              display: 'none',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--text-main)',
            }}
          >
            {mobileMenuOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div
          style={{
            padding: '16px 20px 24px',
            backgroundColor: 'var(--bg-surface)',
            borderBottom: '1px solid var(--border-light)',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
          }}
        >
          <button
            onClick={() => handleNavClick('how-it-works')}
            style={{
              textAlign: 'start',
              padding: '10px 0',
              fontWeight: 600,
              fontSize: '1rem',
              borderBottom: '1px solid var(--border-light)',
            }}
          >
            {t.nav.howItWorks}
          </button>
          <button
            onClick={() => handleNavClick('features')}
            style={{
              textAlign: 'start',
              padding: '10px 0',
              fontWeight: 600,
              fontSize: '1rem',
              borderBottom: '1px solid var(--border-light)',
            }}
          >
            {t.nav.features}
          </button>
          <button
            onClick={() => handleNavClick('categories')}
            style={{
              textAlign: 'start',
              padding: '10px 0',
              fontWeight: 600,
              fontSize: '1rem',
              borderBottom: '1px solid var(--border-light)',
            }}
          >
            {t.nav.categories}
          </button>
          <button
            onClick={() => handleNavClick('faq')}
            style={{
              textAlign: 'start',
              padding: '10px 0',
              fontWeight: 600,
              fontSize: '1rem',
              borderBottom: '1px solid var(--border-light)',
            }}
          >
            {t.nav.faq}
          </button>
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              onNavigatePrivacy();
            }}
            style={{
              textAlign: 'start',
              padding: '10px 0',
              fontWeight: 600,
              fontSize: '1rem',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              color: 'var(--primary)',
            }}
          >
            <ShieldCheck size={18} />
            {t.nav.privacyPolicy}
          </button>
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              marginTop: '6px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              backgroundColor: 'var(--primary)',
              color: '#FFFFFF',
              padding: '12px',
              borderRadius: '14px',
              fontWeight: 700,
            }}
          >
            {t.nav.getGooglePlay}
          </a>
        </div>
      )}

      <style>{`
        @media (max-width: 900px) {
          .desktop-nav { display: none !important; }
          .desktop-cta { display: none !important; }
          .mobile-menu-btn { display: inline-flex !important; }
        }
      `}</style>
    </header>
  );
};
