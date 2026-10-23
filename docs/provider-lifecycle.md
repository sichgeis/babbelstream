# Provider Lifecycle Follow-Up

Reviewed against [official OpenAI API deprecations](https://developers.openai.com/api/docs/deprecations) on 2026-10-23. These are planned repository work milestones, not an automated monitor or a provider change.

| Current use | Official notice | Required follow-up |
| --- | --- | --- |
| Mini transcription hedge: `gpt-4o-mini-transcribe` | Removal 2027-02-26, announced 2026-08-26 | Approve and validate a replacement hedge, including latency, cost, deadlines, language and cancellation behavior |
| Optional primary `gpt-4o-transcribe` | Removal 2027-02-26 | Inventory explicit selections; validate replacement before changing saved choices |
| Cleanup default `gpt-4o-mini` | The dated `gpt-4o-mini-2024-07-18` snapshot is listed for removal 2027-01-14, announced 2026-10-14 | Confirm how the official alias and each company proxy alias resolve; approve a cleanup replacement and test the existing chat-completions/prompt contract |
| Primary default `gpt-transcribe` | Listed as a recommended transcription replacement in the notice | Still verify actual account/proxy availability and response/language contract; do not infer access from the name |

Official model IDs and a company proxy's aliases are separate contracts. An `openai/` routing prefix is a wire namespace, not evidence that a proxy alias tracks OpenAI's current model, retirement schedule or cost. IT must confirm the approved alias mapping, availability and pricing. The project must not silently replace defaults, explicit selections, endpoints or costs.

## Planned Delivery Milestones

- By **2026-11-13**: the maintainer/IT inventory applied primary, hedge and cleanup IDs/aliases, owners, supported endpoints and shutdown dates. No real secrets or private dictation content is needed for the inventory.
- By **2026-12-04**: approve a bounded migration feature spec, replacement choices and cost/destination implications. Official notice recommendations are candidates, not authorization to change the app.
- By **2026-12-18**: complete fixture and explicitly authorized real-provider cleanup acceptance, leaving rollback time before 2027-01-14.
- By **2027-02-05**: complete the corresponding transcription/hedge migration and human smoke gate before 2027-02-26.

Keep provider fixtures, supported picker choices, fallback policy, model-specific multipart fields, release notes and support matrix synchronized. A models-list response may help inventory availability/shutdown metadata but never proves transcription works. Recheck the official notice and company contract when migration starts; do not rely indefinitely on this dated note.
