import { useState, useEffect } from 'react';
import { translations } from './data/translations';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { OnboardingFeatures } from './components/OnboardingFeatures';
import { SpotActionsSection } from './components/SpotActionsSection';
import { FaqSection } from './components/FaqSection';
import { DownloadBanner } from './components/DownloadBanner';
import { PrivacyPolicy } from './components/PrivacyPolicy';
import { Footer } from './components/Footer';

export function App() {
  const [lang, setLang] = useState<'en' | 'ar'>(() => {
    const saved = localStorage.getItem('dalely_lang');
    if (saved === 'en' || saved === 'ar') return saved;
    const browserLang = navigator.language.toLowerCase();
    return browserLang.startsWith('ar') ? 'ar' : 'en';
  });

  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    const saved = localStorage.getItem('dalely_theme');
    if (saved === 'light' || saved === 'dark') return saved;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  });

  const [view, setView] = useState<'home' | 'privacy'>(() => {
    return window.location.hash === '#privacy' ? 'privacy' : 'home';
  });

  useEffect(() => {
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;
    localStorage.setItem('dalely_lang', lang);
  }, [lang]);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('dalely_theme', theme);
  }, [theme]);

  useEffect(() => {
    const handleHashChange = () => {
      if (window.location.hash === '#privacy') {
        setView('privacy');
        window.scrollTo({ top: 0, behavior: 'smooth' });
      } else {
        setView('home');
      }
    };
    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }, []);

  const toggleLang = () => {
    setLang((prev) => (prev === 'en' ? 'ar' : 'en'));
  };

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  };

  const navigateToPrivacy = () => {
    window.location.hash = 'privacy';
    setView('privacy');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const navigateToHome = () => {
    window.location.hash = '';
    setView('home');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const t = translations[lang];

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar
        t={t}
        lang={lang}
        onToggleLang={toggleLang}
        theme={theme}
        onToggleTheme={toggleTheme}
        onNavigatePrivacy={navigateToPrivacy}
        onNavigateHome={navigateToHome}
        isPrivacyPage={view === 'privacy'}
      />

      <main style={{ flex: 1 }}>
        {view === 'home' ? (
          <>
            <Hero t={t} lang={lang} />
            <OnboardingFeatures t={t} />
            <SpotActionsSection t={t} />
            {/* <CategoriesGrid t={t} /> */}
            <FaqSection t={t} />
            <DownloadBanner t={t} />
          </>
        ) : (
          <PrivacyPolicy t={t} lang={lang} onBack={navigateToHome} />
        )}
      </main>

      <Footer
        t={t}
        lang={lang}
        onNavigatePrivacy={navigateToPrivacy}
        onNavigateHome={navigateToHome}
        onToggleLang={toggleLang}
      />
    </div>
  );
}

export default App;
