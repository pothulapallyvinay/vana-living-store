// src/lib/seo.ts
// SEO meta tag helpers

import { site, seo } from '../config/site';

export interface SEOMeta {
  title: string;
  description: string;
  canonical: string;
  ogImage?: string;
  noIndex?: boolean;
  jsonLd?: Record<string, unknown>;
}

export function buildMeta(opts: Partial<SEOMeta> & { path: string }): SEOMeta {
  return {
    title: opts.title ?? seo.defaultTitle,
    description: opts.description ?? seo.defaultDescription,
    canonical: `${site.url}${opts.path}`,
    ogImage: opts.ogImage ?? `${site.url}/og-default.jpg`,
    noIndex: opts.noIndex ?? false,
    jsonLd: opts.jsonLd,
  };
}

export function productJsonLd(product: {
  name: string;
  description: string;
  slug: string;
  price_paise: number | null;
  images: string[];
  sku: string;
}): Record<string, unknown> | null {
  if (!product.price_paise) return null; // Don't include schema without price

  const priceRupees = (product.price_paise / 100).toFixed(2);

  return {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: product.description,
    sku: product.sku,
    brand: {
      '@type': 'Brand',
      name: site.name,
    },
    image: (product.images || []).map((p) => {
      if (!p) return '';
      if (p.startsWith('http')) return p;
      const cleanPath = p.startsWith('/') ? p : '/' + p;
      return `${site.url}${cleanPath}`;
    }),
    offers: {
      '@type': 'Offer',
      priceCurrency: 'INR',
      price: priceRupees,
      availability: 'https://schema.org/InStock',
      url: `${site.url}/products/${product.slug}`,
      seller: {
        '@type': 'Organization',
        name: site.name,
      },
    },
  };
}

export function breadcrumbJsonLd(
  items: { name: string; url: string }[]
): Record<string, unknown> {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: (items || []).map((item, i) => ({
      '@type': 'ListItem',
      position: i + 1,
      name: item.name,
      item: item.url,
    })),
  };
}

export const generateBreadcrumbsJsonLd = breadcrumbJsonLd;
export const generateProductJsonLd = productJsonLd;

export function organizationJsonLd(): Record<string, unknown> {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: site.name,
    url: site.url,
    logo: `${site.url}/logo.svg`,
    contactPoint: {
      '@type': 'ContactPoint',
      contactType: 'customer service',
      email: site.supportEmail,
    },
    sameAs: [site.instagram, site.facebook].filter(Boolean),
  };
}

export function websiteJsonLd(): Record<string, unknown> {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: site.name,
    url: site.url,
    potentialAction: {
      '@type': 'SearchAction',
      target: {
        '@type': 'EntryPoint',
        urlTemplate: `${site.url}/collections/all?q={search_term_string}`,
      },
      'query-input': 'required name=search_term_string',
    },
  };
}
