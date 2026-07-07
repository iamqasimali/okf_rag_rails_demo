class RagSeedData
  BASE_SNIPPETS = [
    [ "TICKET-1001", "A Growth customer fixed Slack approval timeouts by removing the old Flowbase Slack app install, reconnecting OAuth from workspace settings, and replaying failed runs after 10 minutes." ],
    [ "TICKET-1002", "CSV exports created before March 2026 used the workspace timezone label but UTC timestamps. Support advised re-exporting after the export worker patch." ],
    [ "TICKET-1003", "A customer using Salesforce sandbox refreshes saw duplicate contact triggers. The workaround was to rotate the Salesforce webhook secret and pause automations during sandbox refresh." ],
    [ "TICKET-1004", "Zapier handoff failures usually happened when the receiving zap expected a legacy field named customer_email. Mapping email_address to customer_email resolved the issue." ],
    [ "TICKET-1005", "Webhook retries that show HTTP 409 are usually idempotency conflicts. The support note recommends checking whether the downstream service already accepted the first request." ],
    [ "TICKET-1006", "One customer reported Monday digest emails arriving twice after changing locale settings. Re-saving notification preferences generated a single scheduler row." ],
    [ "TICKET-1007", "When a workflow pauses at the approval step without errors, the most common cause is an approver who lost their paid seat after a team import." ],
    [ "TICKET-1008", "Customers importing HubSpot lists over 50,000 rows should split the import by lifecycle stage to avoid rate-limit backoff stretching syncs past two hours." ],
    [ "TICKET-1009", "A public-sector customer needed payroll automation restored before a deadline. Support escalated as P3-to-P1 exception because payroll was blocked." ],
    [ "TICKET-1010", "API tokens scoped before the permissions redesign may lack automation:run. Creating a fresh token fixed 403 responses from the Runs API." ],
    [ "TICKET-1011", "If a browser extension injects custom CSS, the rule builder can appear to hide the operator dropdown. Incognito mode confirmed the issue for two customers." ],
    [ "TICKET-1012", "A customer saw Teams notifications fail only for private channels. The fix was adding the Flowbase bot to the private channel explicitly." ],
    [ "TICKET-1013", "Long-running enrichment jobs may display stale progress until the batch checkpoint updates. This is cosmetic unless no checkpoint appears after 30 minutes." ],
    [ "TICKET-1014", "A forum user resolved Airtable attachment sync failures by reducing attachment filenames below 120 characters before importing records." ],
    [ "TICKET-1015", "SAML login loops often trace back to IdP clock skew over five minutes. Correcting NTP on the identity provider stopped the redirects." ],
    [ "TICKET-1016", "A customer asked why retry counts differed between the UI and audit export. Engineering confirmed the UI excludes manual replays while export includes them." ],
    [ "TICKET-1017", "When Gmail triggers stop after a password reset, reconnecting Google OAuth is required because the refresh token is invalidated by some tenant policies." ],
    [ "TICKET-1018", "A beta user found that nested JSON preview truncates after five levels, but the full payload is still available to Liquid templates." ]
  ].freeze

  PRODUCTS = %w[Slack Salesforce HubSpot Gmail Teams Airtable Zendesk Asana Jira Stripe].freeze
  SYMPTOMS = [
    "OAuth refresh loop",
    "CSV timezone mismatch",
    "duplicate webhook delivery",
    "approval timeout",
    "stale progress indicator",
    "permission denied response",
    "private-channel notification failure",
    "bulk import backoff",
    "SAML redirect loop",
    "audit export discrepancy"
  ].freeze
  FIXES = [
    "reconnect the integration and replay failed runs after the provider confirms token rotation",
    "split the batch by lifecycle stage and retry after the rate-limit window",
    "rotate the webhook secret and verify idempotency keys on the downstream service",
    "create a fresh API token with automation:run and audit:read scopes",
    "remove the stale scheduler row by re-saving notification preferences",
    "add the Flowbase bot explicitly to the private channel",
    "correct identity-provider clock skew and retry SAML login",
    "re-export after the worker checkpoint completes",
    "pause automations during sandbox refresh and resume after sync",
    "shorten attachment filenames before importing records"
  ].freeze

  def self.base = BASE_SNIPPETS

  def self.generated(count)
    count.times.map do |index|
      product = PRODUCTS[index % PRODUCTS.size]
      symptom = SYMPTOMS[(index / PRODUCTS.size) % SYMPTOMS.size]
      fix = FIXES[(index / (PRODUCTS.size * SYMPTOMS.size)) % FIXES.size]
      severity = %w[P1 P2 P3 P4][index % 4]
      source = format("LOAD-%05d", index + 1)
      content = "#{severity} support-history note for #{product}: customer reported #{symptom} after a workspace import. Prior resolution was to #{fix}. Agent note ##{index + 1} also says to capture provider request IDs before escalating."

      [ source, content ]
    end
  end
end
