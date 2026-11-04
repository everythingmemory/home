// Copyright (c) 2026 ConcurAI
// SPDX-License-Identifier: BUSL-1.1
import React from 'react';
import clsx from 'clsx';
import {ThemeClassNames} from '@docusaurus/theme-common';
import {useDoc} from '@docusaurus/plugin-content-docs/client';
import Heading from '@theme/Heading';
import MDXContent from '@theme/MDXContent';

const KIND = {
  concept: 'Concept',
  tutorial: 'Tutorial',
  'how-to': 'How-to',
  reference: 'Reference',
  explanation: 'Explanation',
};

export default function DocItemContent({children}) {
  const {metadata, frontMatter} = useDoc();
  const kind = frontMatter.kind;
  const verified = frontMatter.verified_against;
  const eyebrow = [
    KIND[kind],
    frontMatter.group,
    frontMatter.status === 'planned'
      ? 'Planned'
      : verified
        ? `Verified against ${verified}`
        : 'Draft · not yet verified',
  ].filter(Boolean);

  return (
    <div className={clsx(ThemeClassNames.docs.docMarkdown, 'markdown', kind && `kind-${kind}`)}>
      <header className="page-head">
        <div className="eyebrow">
          {eyebrow.map((part, i) => (
            <React.Fragment key={part}>
              {i > 0 && <span className="dot" />}
              <span>{part}</span>
            </React.Fragment>
          ))}
        </div>
        <Heading as="h1">{metadata.title}</Heading>
        {frontMatter.lede && <p className="lede">{frontMatter.lede}</p>}
      </header>
      <MDXContent>{children}</MDXContent>
    </div>
  );
}
