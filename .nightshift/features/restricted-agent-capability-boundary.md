---
status: exploring
---

# Restricted agent capability boundary

Give the agent read-only access limited to what its task needs and a small set of structured operation tools mediated by the bootstrapper. Aim to enforce permitted reads, writes, helper execution, and network access outside the prompt, with no unrestricted shell or alternative tool route around the boundary. Each generated package declares its capabilities; trusted helpers validate arguments, and the agent cannot modify the enforcing policy or helpers. Connected to [Composable AI bootstrap builder](composable-bootstrap-builder.md). Open questions: host-specific tool restrictions, OS isolation, approval and privilege boundaries, and preserving useful agent flexibility. Captured 2026-10-21.
