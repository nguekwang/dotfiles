---
name: tech-layer-selection
description: Choosing which technology layer to build on — web frontend stack, tooling, and CLI vs GUI interface. Use whenever you are deciding whether to add a frontend framework, a build/tooling layer, or a GUI-based workflow.
---

# Technology Layer Selection

Build on layers that do not move. Lower layers are stable because they are the substrate everything else depends on; their cost of change is paid by the whole ecosystem, so they barely move. Higher layers are non-essential and fluid: they restate what the lower layers already do, in a vocabulary that turns over every few years. Dancing on those higher layers is prohibited.

This principle resolves into three rules, one per domain: the web frontend, tooling, and the interface.

## Web Frontend Stack — Vanilla.js Only

Write the web frontend in HTML, CSS, and JavaScript only. No frontend framework or its dialect (React, Vue, Svelte, Angular, JSX, SolidJS, and the like) is permitted.

The justification is a capability argument, not a taste argument.

- A frontend framework adds no capability over Vanilla.js. Every framework compiles down to the same DOM API and Web API that Vanilla.js calls directly. What a framework can render, mutate, or schedule, plain HTML / CSS / JavaScript can render, mutate, or schedule.
- A framework adds ergonomics, not power. Ergonomics is a higher layer, and higher layers are the fluid ones this dogma forbids dancing on.
- The browser platform (HTML, CSS, the DOM, the Web API) is the lower, stable layer. Code written against it does not rot when a framework's major version breaks.

The single exception axis is capability, not convenience: if a feature is genuinely impossible against the raw browser platform, document the gap before reaching higher. By the argument above, no such feature is known to exist.

## Tooling — Lower Layer Stable, Higher Layer Forbidden, Fast Package Managers Allowed

Apply the same rule to tooling, with one carve-out.

- Do not chase higher-layer tooling churn. Build and abstraction layers that restate the platform in a turnover-prone vocabulary are forbidden, on the same grounds as frontend frameworks.
- Fast package managers that preserve compatibility and ship a lockfile are allowed. Tools such as `bun` and `uv` are permitted because they are drop-in accelerators of an existing, stable layer: they keep the upstream contract (npm / PyPI semantics) and pin it deterministically through a lockfile. They speed up the lower layer rather than introducing a new higher one.

The test for any tool is therefore: does it preserve the lower-layer contract and pin it with a lockfile, or does it ask you to dance on a new layer? Allow the former, forbid the latter.

## Interface — CLI over GUI

Prefer the command line. When a task can be done from the CLI or a configuration file, do it there, and do not present a GUI as the path.

This is the layer principle applied to the interface, not a separate rule. A CLI is the lower, stable layer; a GUI restates it in a layout that turns over between versions, the fluid higher layer this dogma forbids. A CLI is also text, so it is scriptable, composable through pipes, diffable, and version-controllable, which suits Infrastructure as Code; a sequence of clicks cannot be committed, replayed, or reviewed.

- When documenting a setup, present the file edits and commands that complete it. Do not instruct the user to open a settings GUI.
- When a package exists only to provide a configuration GUI, treat it as optional and omit it from the required set. State the configuration-file path the GUI would have edited, and edit that file directly per the `config-file-editing` skill.
- The single exception axis is capability: if a task is genuinely impossible without a GUI, document the gap before reaching for one.
