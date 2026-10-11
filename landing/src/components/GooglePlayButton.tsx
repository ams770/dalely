import React from 'react';
import { PLAY_STORE_URL } from '../data/translations';

interface GooglePlayButtonProps {
  variant?: 'light' | 'dark' | 'outline';
  size?: 'normal' | 'large';
  smallText?: string;
  largeText?: string;
}

export const GooglePlayButton: React.FC<GooglePlayButtonProps> = ({
  variant = 'light',
  size = 'normal',
  smallText = 'GET IT ON',
  largeText = 'Google Play',
}) => {
  const isLight = variant === 'light';
  const isLarge = size === 'large';

  return (
    <a
      href={PLAY_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className="google-play-btn"
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
      {/* Official Multicolor Google Play Vector Icon */}
      <svg
        viewBox="0 0 512 512"
        width={isLarge ? '30' : '26'}
        height={isLarge ? '30' : '26'}
        style={{ flexShrink: 0 }}
      >
        <path
          fill="#4285F4"
          d="M47.7 13.9C39.6 22.5 35 35.8 35 52.3v407.4c0 16.5 4.6 29.8 12.7 38.4l2.1 2.1 228.1-228.1v-5.4L49.8 11.8l-2.1 2.1z"
        />
        <path
          fill="#FBBC04"
          d="M352.8 328.7l-74.9-74.9v-5.4l74.9-74.9 1.7 1 88.8 50.5c25.4 14.4 25.4 38.1 0 52.6l-88.8 50.1-1.7 1.1z"
        />
        <path
          fill="#EA4335"
          d="M354.5 327.6L277.9 251 49.8 479.1c8.3 8.8 22.1 9.9 37.6 1.1l267.1-152.6z"
        />
        <path
          fill="#34A853"
          d="M354.5 184.4L87.4 31.8c-15.5-8.8-29.3-7.7-37.6 1.1L277.9 261l76.6-76.6z"
        />
      </svg>

      <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.15 }}>
        <span
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
