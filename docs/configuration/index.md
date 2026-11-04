---
title: "Configuration Options"
sidebar_position: 0
kind: reference
status: drafted
verified_against: null
lede: "The settings an operator sets, one page per area. The pipeline profiles and their plugins are under advanced settings."
---

import DocCardList from '@theme/DocCardList';

Settings are environment variables, set in `local.env` beside the compose file. A value in the **Shipped** column is what the settings template or the compose file sets; **Engine default** is what the engine uses when the variable is absent. Changing a setting takes effect when the stack restarts.

<DocCardList />
