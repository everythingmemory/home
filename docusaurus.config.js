// Copyright (c) 2026 ConcurAI
// SPDX-License-Identifier: BUSL-1.1
const fs = require('fs');
const path = require('path');
const {themes} = require('prism-react-renderer');

function plannedPages(dir, root = dir, out = []) {
  for (const entry of fs.readdirSync(dir, {withFileTypes: true})) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) plannedPages(full, root, out);
    else if (/\.mdx?$/.test(entry.name)) {
      const head = fs.readFileSync(full, 'utf8').split('\n---', 1)[0];
      if (/^status:\s*planned\s*$/m.test(head)) out.push(path.relative(root, full));
    }
  }
  return out;
}
const showPlanned = process.env.SHOW_PLANNED === '1';
const DEFAULT_EXCLUDE = [
  '**/_*.{js,jsx,ts,tsx,md,mdx}',
  '**/_*/**',
  '**/*.test.{js,jsx,ts,tsx}',
  '**/__tests__/**',
];
const exclude = [
  ...DEFAULT_EXCLUDE,
  ...(showPlanned ? [] : plannedPages(path.join(__dirname, 'docs'))),
];

module.exports = {
  title: 'Everything Memory',
  tagline: 'A system of record for AI agents',
  url: process.env.DOCS_URL || 'https://everythingmemory.ai',
  baseUrl: process.env.DOCS_BASE_URL || '/',
  trailingSlash: true,
  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',
  markdown: {mermaid: true, hooks: {onBrokenMarkdownLinks: 'throw'}},
  i18n: {defaultLocale: 'en', locales: ['en']},

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/docs',
          sidebarPath: require.resolve('./sidebars.js'),
          exclude,
          breadcrumbs: true,
        },
        blog: false,
        theme: {customCss: require.resolve('./src/css/custom.css')},
      },
    ],
  ],

  themes: [
    '@docusaurus/theme-mermaid',
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {hashed: true, indexBlog: false, docsRouteBasePath: '/', highlightSearchTermsOnTargetPage: false},
    ],
  ],

  themeConfig: {
    colorMode: {defaultMode: 'light', respectPrefersColorScheme: true},
    navbar: {
      title: 'Everything Memory',
      items: [
        {to: '/docs/', label: 'Docs', position: 'left'},
        {to: '/docs/reference/', label: 'Reference', position: 'left'},
        {href: 'https://github.com/everythingmemory/home', label: 'Get started', position: 'right'},
        {href: 'https://everythingmemory.ai/ememory/register/', label: 'Register', position: 'right'},
      ],
    },
    docs: {sidebar: {hideable: false, autoCollapseCategories: true}},
    tableOfContents: {minHeadingLevel: 2, maxHeadingLevel: 3},
    prism: {theme: themes.github, darkTheme: themes.vsDark, additionalLanguages: ['bash', 'json', 'yaml']},
    footer: {
      copyright: 'Everything Memory is made by ConcurAI.',
    },
  },
};
