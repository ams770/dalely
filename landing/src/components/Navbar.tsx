import { useState } from 'react';
import { Globe, Sun, Moon, Menu, X, ShieldCheck } from 'lucide-react';
import type { TranslationContent } from '../data/translations';

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
            className="mobile-nav-link"
            style={{
              textAlign: 'start',
              padding: '12px 0',
              fontWeight: 600,
              fontSize: '1rem',
              color: 'var(--text-main)',
              borderBottom: '1px solid var(--border-light)',
              background: 'none',
              cursor: 'pointer',
              display: 'block',
              width: '100%',
              transition: 'color 0.2s ease',
            }}
          >
            {t.nav.howItWorks}
          </button>
          <button
            onClick={() => handleNavClick('features')}
            className="mobile-nav-link"
            style={{
              textAlign: 'start',
              padding: '12px 0',
              fontWeight: 600,
              fontSize: '1rem',
              color: 'var(--text-main)',
              borderBottom: '1px solid var(--border-light)',
              background: 'none',
              cursor: 'pointer',
              display: 'block',
              width: '100%',
              transition: 'color 0.2s ease',
            }}
          >
            {t.nav.features}
          </button>
       
          <button
            onClick={() => handleNavClick('faq')}
            className="mobile-nav-link"
            style={{
              textAlign: 'start',
              padding: '12px 0',
              fontWeight: 600,
              fontSize: '1rem',
              color: 'var(--text-main)',
              borderBottom: '1px solid var(--border-light)',
              background: 'none',
              cursor: 'pointer',
              display: 'block',
              width: '100%',
              transition: 'color 0.2s ease',
            }}
          >
            {t.nav.faq}
          </button>
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              onNavigatePrivacy();
            }}
            className="mobile-nav-link"
            style={{
              textAlign: 'start',
              padding: '12px 0',
              fontWeight: 600,
              fontSize: '1rem',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              color: 'var(--primary)',
              background: 'none',
              cursor: 'pointer',
              width: '100%',
              transition: 'opacity 0.2s ease',
            }}
          >
            <ShieldCheck size={18} />
            {t.nav.privacyPolicy}
          </button>

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
