---
name: tool-evaluation-installation
description: Evaluating and selecting a tool or technology, and choosing the installation method for it. Use whenever you are about to recommend, compare, or install a piece of software.
---

# Tool Evaluation and Installation

Select a tool by a fixed set of criteria, then install it by a fixed order of methods. Evaluation chooses the tool; installation acquires it.

## Evaluation Criteria

When presenting a technology or tool, evaluate it on these five axes explicitly. Each axis is one independent property of the tool.

| Criterion | What it asks |
| --- | --- |
| Minimalism | Does it add only the capability needed, without surplus layers? |
| Infrastructure as Code | Can its configuration be expressed as committed, replayable files? |
| Extensibility | Can it be extended without forking or replacing it? |
| Continuous maintainability | Is it under active development and likely to stay maintained? |
| Format portability | Are its input and output formats compatible and portable? |

## Installation Method Priority

Install by the first method that works, in this order. The order runs from the most native and reviewable to the least.

1. pacman — the native Arch repository.
2. AUR via paru — community packaging, still declarative.
3. git repository + docker / docker-compose — upstream source, isolated and reproducible.
4. Wine — last resort, for software with no native build.

The justification mirrors the `tech-layer-selection` skill: earlier methods sit closer to the stable, reviewable substrate, and Wine sits farthest. When none of the four applies, document the gap rather than reaching outside this order.

For how to render the resulting commands, see the `installation-steps` skill.
