import React from 'react';
import { APP_STORE_URL } from '../data/translations';

interface AppStoreButtonProps {
  variant?: 'light' | 'dark' | 'outline';
  size?: 'normal' | 'large';
  smallText?: string;
  largeText?: string;
}

export const AppStoreButton: React.FC<AppStoreButtonProps> = ({
  variant = 'light',
  size = 'normal',
  smallText = 'Download on the',
  largeText = 'App Store',
}) => {
  const isLight = variant === 'light';
  const isLarge = size === 'large';

  return (
    <a
      href={APP_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className="app-store-btn"
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '12px',
        backgroundColor: isLight ? '#FFFFFF' : '#12263F',
        color: isLight ? '#12263F' : '#FFFFFF',
        padding: isLarge ? '12px 28px' : '10px 22px',
        borderRadius: '16px',
        border: isLight ? 'none' : '1px solid rgba(255, 255, 255, 0.15)',
        boxShadow: isLight
          ? '0 10px 24px -4px rgba(0, 0, 0, 0.18), 0 2px 6px rgba(0, 0, 0, 0.08)'
          : '0 8px 20px -4px rgba(18, 38, 63, 0.3)',
        transition: 'all 0.25s cubic-bezier(0.16, 1, 0.3, 1)',
        textDecoration: 'none',
        cursor: 'pointer',
      }}
    >
      {/* Official Apple Vector Icon */}
      <svg
        viewBox="0 0 24 24"
        width={isLarge ? '28' : '24'}
        height={isLarge ? '28' : '24'}
        fill="currentColor"
        style={{ flexShrink: 0 }}
      >
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 1.01-2.87-.96.04-2.08.64-2.73 1.4-.58.67-1.09 1.74-1.05 2.78 1.07.08 2.15-.56 2.77-1.31z" />
      </svg>

      <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.15 }}>
        <span
          className="store-btn-subtitle"
          style={{
            fontSize: isLarge ? '0.72rem' : '0.68rem',
            letterSpacing: '0.06em',
            textTransform: 'uppercase',
            fontWeight: 700,
            opacity: isLight ? 0.65 : 0.75,
          }}
        >
          {smallText}
        </span>
        <span
          className="store-btn-title"
          style={{
            fontSize: isLarge ? '1.2rem' : '1.05rem',
            fontWeight: 800,
            letterSpacing: '-0.02em',
          }}
        >
          {largeText}
        </span>
      </div>
    </a>
  );
};
