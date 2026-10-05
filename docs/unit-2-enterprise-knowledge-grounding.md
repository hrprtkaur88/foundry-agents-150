# Unit 2: Enterprise Knowledge and Grounding

## Overview

In this unit, you'll give **Lightbulb-Agent** information it can retrieve and cite. You will compare three ways to provide evidence:

1. **Grounding with Bing Search** for current public information
2. **Uploaded files** for quick, agent-specific grounding
3. **Foundry IQ knowledge bases** for reusable, curated enterprise knowledge backed by Azure AI Search

The required path uses uploaded SmartGlow files. An optional exercise shows how the same information can be managed as a reusable Foundry IQ knowledge base.

> **📝 Note:** The portal experience used for the optional Foundry IQ exercise is preview and might not be available in every environment.

---

## Prerequisites

Before starting this unit, make sure you have:

- ✅ Completed [Unit 1](./unit-1-agent-scope-and-boundaries.md)
- ✅ Access to **Lightbulb-Agent** in the Foundry playground
- ✅ Access to the deployed workshop **Grounding with Bing Search** resource
- ✅ The workshop files:
  - [`assets/lightbulb-manual.md`](./assets/lightbulb-manual.md)
  - [`assets/smartglow-support-policy.md`](./assets/smartglow-support-policy.md)
  - [`assets/smartglow-operations-runbook.md`](./assets/smartglow-operations-runbook.md)

The optional Foundry IQ exercise also requires a connected **Azure AI Search S1** service. Azure AI Search is not required for the core workshop path.

---

## Concept: Select the Source Before the Tool

| Source pattern | Use it for | Simple example |
|---|---|---|
| **Grounding with Bing Search** | Current public information | Recent smart-home news |
| **Uploaded files** | A small set of approved documents used by an agent | SmartGlow product and support files |
| **Foundry IQ knowledge base** | Curated knowledge reused across agents | A shared company support knowledge base |

Think of these as different shelves in a company library. Public web grounding is the news shelf, uploaded files are a folder prepared for one team, and Foundry IQ is a managed collection that many teams can reuse.

### How to Choose Evidence

The newest document does not automatically answer every question. **Use the source responsible for the subject.** A newer support policy can replace the support section of an older manual without replacing the manual's product specifications.

1. Use the source responsible for the subject and cite the evidence used.
2. Use the public web only for current public information; never substitute it for configured SmartGlow knowledge.
3. If evidence is missing or authority is unclear, state the gap instead of guessing.

| Subject | Authoritative source | Authority note |
|---|---|---|
| Product behavior and capabilities | [`lightbulb-manual.md`](./assets/lightbulb-manual.md), version 1.0 | Governs specifications, supported colors, state behavior, and feature limitations |
| Participant support and deployment actions | [`smartglow-support-policy.md`](./assets/smartglow-support-policy.md), version 2.0 | Supersedes conflicting manual guidance for support, deployment, and warranty claims |
| Health checks and incident response | [`smartglow-operations-runbook.md`](./assets/smartglow-operations-runbook.md), version 1.1 | Governs support-owner troubleshooting, escalation, and operational procedures |

An explicit supersession statement controls only the subjects it covers. If authoritative sources still conflict, show the conflict and request human clarification.

---

## Steps

### Step 1: Add Current Public Knowledge

The workshop uses **Grounding with Bing Search** to let the agent look things up on the public web.

You do not need to create anything in Azure for this step. The `azd up` template already deployed the Bing resource (`infra/modules/bing-grounding.bicep`) and created a project connection to it. You only attach the tool to the agent.

1. Open **Build** > **Agents** > **Lightbulb-Agent**.
2. In **Tools**, select **Add**, then choose **Grounding with Bing Search** from **Configured** or **Catalog**.
3. Select the workshop Bing connection created by `azd up`. It is named `grounding-with-bing`.
4. Check that no other web tool is turned on. You want exactly one route to the public web, so you can tell where an answer came from.
5. Save the agent and start a new conversation.
6. Test:

   ```
   What are the latest developments in smart-home lighting? Cite the public sources you used.
   ```

The answer should include links to current public pages. If it does not, the tool is probably not attached — recheck steps 2 and 3.

Now ask:

```
What colors does the SmartGlow 101 support?
```

The agent might find a confident answer on the public web. The answer could even be correct, but the public web is not the approved source for SmartGlow product information.

This is like finding a company policy through an internet search instead of using the approved employee portal. The information might match, but you cannot rely on it as the company's authoritative source.

> **⚠️ Important:** When the agent uses Grounding with Bing Search, the search query is sent to the Bing service outside the Azure compliance and geographic boundary. The Microsoft Data Protection Addendum does not apply to this service; its own terms of use and usage-based charges apply. Owning the Bing resource gives your organization visibility, access control, cost attribution, and the ability to remove the connection, but it does not keep the query inside your Azure tenant. Before production use, decide what information may appear in search queries, avoid sending confidential or personal data, and confirm the design with your security and compliance owners.

### Step 2: Upload the SmartGlow Workshop Files

1. Review the product manual, support policy, and operations runbook. Notice that each document answers a different kind of question.
2. In the agent's **Tools** or **Knowledge** area, choose the portal option for uploading files or file search.
3. Upload all three workshop files and wait for processing to finish:
   - `lightbulb-manual.md`
   - `smartglow-support-policy.md`
   - `smartglow-operations-runbook.md`
4. Save the agent.
5. Add this **source rule** to the agent instructions:

   ```
   For SmartGlow facts, use only the configured SmartGlow files or Foundry IQ knowledge base. Do not use public web search, GitHub search, model knowledge, or a similarly named repository as a fallback. Cite the configured document used. If the configured sources do not contain the answer, say what evidence is missing instead of searching the public web.
   ```

   This rule says which sources are allowed for SmartGlow facts.

6. Test:

   ```
   What colors does the SmartGlow 101 support, and can I set brightness to 50%?
   ```

The answer should name the five supported colors, explain that brightness control is unavailable, and cite `lightbulb-manual.md`. Compare this citation with the public-web answer from Step 1.

### Step 3: Apply Source Authority

Append this rule below the source rule from Step 2:

```
For SmartGlow questions, use the source responsible for the subject. Use Product Manual version 1.0 for product behavior and capabilities, Support Policy version 2.0 for participant support and deployment actions, and Operations Runbook version 1.1 for support-owner troubleshooting and incident response. If the sources conflict outside these subjects, show the conflict and ask for human clarification.
```

Save the agent and start a new conversation.

#### Test 1: Use Multiple Sources

```
My SmartGlow 101 was on and blue. After the service restarted, it returned to off and white. The web application loads, but my agent can no longer control the light. What happened, what should I do, and what should the support owner check?
```

Check which source supports each part:

| Part of the answer | Expected source |
|---|---|
| Why the light reset | Product Manual version 1.0 |
| What the participant should do | Support Policy version 2.0 |
| What support should check | Operations Runbook version 1.1 |

> **📝 Note: what this test does and does not prove.** Each part of this question belongs to a *different* document, so ordinary relevance-based retrieval usually routes it correctly — **this test normally passes even without the rule you just added.** That is expected. It shows the agent can assemble one answer from several sources, which is worth seeing, but it is not evidence that source authority is working. Test 2 is the one that measures the rule.

#### Test 2: Resolve a Real Conflict

The three documents are not merely different topics. Two of them **contradict each other on the same subject**, in three separate places:

| Product Manual v1.0 says | Where | Support Policy v2.0 says |
|---|---|---|
| "Run the deployment command: `azd up`" | *Getting Started*, Step 1 | Participants must not run `azd up` |
| "You may need to re-run `azd up` if the deployment failed" | *Troubleshooting FAQ* | Report the issue to the support owner instead |
| "To file a warranty claim, simply restart your deployment by running `azd up`" | *How to Make a Warranty Claim* | Report failures to the support owner rather than redeploying |

The third row is the sharpest: Policy v2.0 names **warranty claims** as one of the subjects it supersedes, and the manual's entire warranty procedure is "run `azd up`." Both documents answer "how do I, the participant, get a working environment?" Only the precedence rule decides which one wins. Run:

```
My environment is broken. The product manual's Getting Started section says to run `azd up` to deploy the SmartGlow 101. Should I run it now to fix my environment?
```

A correct answer:

1. Says **no**, do not run `azd up`.
2. Cites **Support Policy version 2.0**, not the manual.
3. States that the policy supersedes the manual for participant support and deployment actions.
4. Gives the policy's actual procedure — check the assigned identity, capture the links, report to the support owner, continue with the demonstration.

A strong answer does one more thing: it **names the conflict out loud** rather than silently picking a side. "The manual says X, the policy says Y, the policy supersedes it here" is more auditable than a bare "no," because a reviewer can see which rule was applied.

**Follow-up worth running:** ask `How do I file a warranty claim?` The manual's warranty procedure is literally "run `azd up`," and Policy v2.0 lists warranty claims among the subjects it supersedes. This is the narrowest, cleanest version of the conflict.

**Now remove the precedence rule you added at the start of Step 3, save, and run the same prompt in a new conversation.** Keep the Step 2 source rule in place, so you change only one variable.

Expect a *subtler* difference than you might predict. In testing, the agent still found the right answer without the rule — because the supersession is written inside the policy document itself ("It supersedes support and warranty-claim instructions in Product Manual version 1.0"), so it can be retrieved rather than instructed. What degraded was everything around the answer:

| | With the rule | Without it |
|---|---|---|
| Verdict | "No, not as a participant" | "Probably not" |
| Scope | Assumes the workshop context | Asks which kind of environment you have |
| The forbidden action | Stays closed | **Reopened** — "if this is your own self-managed deployment, re-running it may help" |

That last row is the risk. The answer is not wrong, but it hands the policy decision back to the person the policy exists to constrain, and a user skimming for permission will find it in the second branch.

**The honest lesson:** here the rule buys decisiveness and correct scope assumption, not source selection. That is a real benefit and a smaller one than "the agent gets it wrong without the rule." Two things follow, and both matter more than the rule itself:

- **Write precedence into the documents, not only into the prompt.** The policy's own supersession sentence did most of the work, and it keeps working for every agent that retrieves it and for the humans who read it.
- **Instructions still matter for how an answer is delivered** — how decisive it is, what context it assumes, and whether it leaves a forbidden door open.

If your run differs from the table above, that is worth recording rather than correcting. Model behavior is not deterministic, and the point of this test is that you now have a way to *observe* the rule's contribution instead of assuming it.

#### Test 3: Recognize Missing Evidence

```
What is SmartGlow's policy for international warranty transfers?
```

The agent should say that the configured sources do not provide this policy and should direct the user to the policy owner. It should not guess or search the public web for a private company policy.

### Optional Step 4: Try Foundry IQ

> **📝 Note:** This optional exercise requires Azure AI Search and Foundry IQ. If a prepared knowledge base exists, open it instead of creating another one. If indexing does not complete, reconnect the uploaded files and continue to Step 5.

1. In the Foundry project, open **Build** > **Knowledge** and select the connected workshop **Azure AI Search S1** service.
2. Create or open the knowledge base named `smartglow-workshop-kb`.
3. If you are creating it, add the three SmartGlow files as knowledge sources and wait for indexing to complete.
4. Add `smartglow-workshop-kb` to **Lightbulb-Agent** and temporarily remove the duplicate uploaded-file connection.
5. Save the agent and rerun one Step 3 test. Confirm that the answer still uses the correct sources.

Uploaded files and Foundry IQ are separate configurations. Adding a knowledge base does not automatically remove or convert previously uploaded files.

### Step 5: Make the Enterprise Decision

You have now seen three source patterns:

| Need | Suggested pattern |
|---|---|
| Current public information | Grounding with Bing Search |
| A small set of documents for one agent | Uploaded files |
| Curated knowledge shared across agents | Foundry IQ knowledge base |

In an enterprise workload, also ask who owns the information, who is allowed to access it, where it is processed, and how it will be kept current.

### Enterprise Takeaway

Retrieval can find relevant information, but relevance does not make a source authoritative. Use approved company knowledge for company facts, use the public web for public information, and check citations before trusting the answer.

---

## Summary

You connected public and company-approved information, taught the agent which source controls each subject, and tested how it handles missing evidence. You may also have compared uploaded files with a reusable Foundry IQ knowledge base.

### What's Next

In **[Unit 3: Instructions and Capability Routing](./unit-3-instructions-and-capability-routing.md)**, you'll turn these source decisions into a concise routing contract.

All later units use the configured SmartGlow knowledge source and do not require Azure AI Search specifically.

---

## Key Concepts

- **Grounding** — Basing an answer on retrieved evidence rather than model training alone.
- **Grounding with Bing Search** — Web grounding through a Bing resource your organization creates, connects, and governs.
- **File Search** — Retrieval over uploaded files in a project vector store, useful for narrow or agent-specific knowledge.
- **Foundry IQ** — A managed knowledge layer for reusable, multi-source, permission-aware retrieval.
- **Source Authority** — Using the source responsible for the subject rather than automatically choosing the newest or highest-ranked result.
- **Citation Fidelity** — Whether claims can be traced to the evidence actually used.
