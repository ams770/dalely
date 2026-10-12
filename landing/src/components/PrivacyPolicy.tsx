import React from 'react';
import {
  ShieldCheck,
  ArrowLeft,
  ArrowRight,
  Database,
  ServerOff,
  UserX,
  MapPin,
  Mail,
  Phone,
  MessageCircle,
} from 'lucide-react';
import type { TranslationContent } from '../data/translations';
import { CONTACT_EMAIL, CONTACT_PHONE, WHATSAPP_URL } from '../data/translations';

interface PrivacyPolicyProps {
  t: TranslationContent;
  lang: 'en' | 'ar';
  onBack: () => void;
}

export const PrivacyPolicy: React.FC<PrivacyPolicyProps> = ({ t, lang, onBack }) => {
  const BackIcon = lang === 'ar' ? ArrowRight : ArrowLeft;
  const p = t.privacyPage;

  return (
    <div style={{ padding: '60px 0 100px', backgroundColor: 'var(--bg-main)' }}>
      <div className="container" style={{ maxWidth: '860px' }}>
        {/* Back Button */}
        <button
          onClick={onBack}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            color: 'var(--primary)',
            fontWeight: 700,
            fontSize: '0.95rem',
            marginBottom: '32px',
            padding: '8px 16px',
            borderRadius: 'var(--radius-full)',
            backgroundColor: 'var(--bg-surface)',
            border: '1px solid var(--border-light)',
          }}
        >
          <BackIcon size={18} />
          <span>{p.backToHome}</span>
        </button>

        {/* Title Header */}
        <div style={{ marginBottom: '40px' }}>
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '6px 14px',
              borderRadius: 'var(--radius-full)',
              backgroundColor: 'rgba(26, 147, 234, 0.12)',
              color: 'var(--primary)',
              fontSize: '0.85rem',
              fontWeight: 700,
              marginBottom: '16px',
            }}
          >
            <ShieldCheck size={16} />
            <span>{lang === 'ar' ? 'شفافية وأمان كامل' : 'Privacy-First Architecture'}</span>
          </div>

          <h1
            style={{
              fontSize: 'clamp(2.2rem, 4vw, 3rem)',
              fontWeight: 900,
              color: 'var(--text-main)',
              marginBottom: '12px',
              letterSpacing: '-0.02em',
            }}
          >
            {p.title}
          </h1>

          <div style={{ color: 'var(--text-muted)', fontSize: '0.92rem', fontWeight: 600 }}>
            {p.lastUpdated}
          </div>
        </div>

        {/* Executive Summary Cards */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
            gap: '14px',
            marginBottom: '40px',
          }}
        >
          <div
            className="glass-card"
            style={{
              padding: '18px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              borderRadius: '16px',
            }}
          >
            <Database size={24} color="#1A93EA" />
            <div>
              <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>
                {lang === 'ar' ? 'تخزين محلي' : 'Local Storage'}
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                {lang === 'ar' ? 'ذاكرة الهاتف (Hive)' : 'On-Device (Hive)'}
              </div>
            </div>
          </div>

          <div
            className="glass-card"
            style={{
              padding: '18px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              borderRadius: '16px',
            }}
          >
            <ServerOff size={24} color="#10B981" />
            <div>
              <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>
                {lang === 'ar' ? 'بدون سيرفرات' : 'Zero Servers'}
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                {lang === 'ar' ? 'لا توجد سحابة مركزية' : 'No Cloud Tracking'}
              </div>
            </div>
          </div>

          <div
            className="glass-card"
            style={{
              padding: '18px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              borderRadius: '16px',
            }}
          >
            <UserX size={24} color="#FF8A65" />
            <div>
              <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>
                {lang === 'ar' ? 'بدون حسابات' : 'No Accounts'}
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                {lang === 'ar' ? 'لا نطلب أي إيميل' : 'No Email or Phone'}
              </div>
            </div>
          </div>

          <div
            className="glass-card"
            style={{
              padding: '18px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              borderRadius: '16px',
            }}
          >
            <MapPin size={24} color="#8B5CF6" />
            <div>
              <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>
                {lang === 'ar' ? 'الموقع محلياً' : 'Local GPS'}
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                {lang === 'ar' ? 'أثناء الاستخدام فقط' : 'Foreground Only'}
              </div>
            </div>
          </div>
        </div>

        {/* Intro Paragraph */}
        <div
          className="glass-card"
          style={{
            padding: '28px',
            borderRadius: '20px',
            backgroundColor: 'var(--bg-subtle)',
            border: '1px solid var(--border-primary)',
            color: 'var(--text-main)',
            fontSize: '1.05rem',
            lineHeight: 1.75,
            marginBottom: '48px',
            fontWeight: 500,
          }}
        >
          {p.intro}
        </div>

        {/* Policy Sections */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '36px' }}>
          {p.sections.map((sec, idx) => (
            <div
              key={idx}
              className="glass-card"
              style={{
                padding: '32px',
                borderRadius: '20px',
              }}
            >
              <h2
                style={{
                  fontSize: '1.35rem',
                  fontWeight: 800,
                  color: 'var(--text-main)',
                  marginBottom: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                }}
              >
                <span>{sec.heading}</span>
              </h2>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {sec.content.map((paragraph, pIdx) => (
                  <p
                    key={pIdx}
                    style={{
                      fontSize: '1rem',
                      color: 'var(--text-muted)',
                      lineHeight: 1.75,
                    }}
                  >
                    {paragraph}
                  </p>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Contact Banner */}
        <div
          className="glass-card"
          style={{
            marginTop: '48px',
            padding: '28px 32px',
            borderRadius: '20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '20px',
            backgroundColor: 'var(--bg-surface)',
            border: '1px solid var(--border-primary)',
          }}
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <div style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              {lang === 'ar' ? 'للتواصل المباشر والاستفسارات:' : 'Direct Developer Contact:'}
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '20px' }}>
              <a
                href={`mailto:${CONTACT_EMAIL}`}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  fontWeight: 800,
                  fontSize: '1rem',
                  color: 'var(--primary)',
                }}
              >
                <Mail size={18} />
                <span>{CONTACT_EMAIL}</span>
              </a>

              <a
                href={WHATSAPP_URL}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  fontWeight: 800,
                  fontSize: '1rem',
                  color: 'var(--text-main)',
                  direction: 'ltr',
                }}
              >
                <MessageCircle size={18} color="#25D366" />
                <span>WhatsApp: {CONTACT_PHONE}</span>
              </a>

              <a
                href={`tel:${CONTACT_PHONE}`}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  fontWeight: 800,
                  fontSize: '1rem',
                  color: 'var(--text-main)',
                  direction: 'ltr',
                }}
              >
                <Phone size={18} color="var(--primary)" />
                <span>{CONTACT_PHONE}</span>
              </a>
            </div>
          </div>

          <button onClick={onBack} className="btn-primary" style={{ padding: '10px 24px' }}>
            {p.backToHome}
          </button>
        </div>
      </div>
    </div>
  );
};
