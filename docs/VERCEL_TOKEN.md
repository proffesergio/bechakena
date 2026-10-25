# Renew the GitHub deployment token

The Vercel CLI is signed in to the correct BechaKena account, but Vercel rejected
creating a CI token through that login (HTTP 403). No GitHub secret was changed.
The CLI login can still deploy the validated build directly. To restore future
GitHub automatic deployments:

1. Open [Vercel account tokens](https://vercel.com/account/tokens) while signed
   in as the account that owns `n3rd-s-projects/bechakena`.
2. Create a token named **BechaKena GitHub Actions**. Choose **n3rd's projects**
   (`n3rd-s-projects`) as the scope. Use a project restriction to **bechakena**
   if offered. Choose an expiration date and save a reminder to renew it.
3. Open [BechaKena GitHub Actions secrets](https://github.com/proffesergio/bechakena/settings/secrets/actions).
   Edit **VERCEL_TOKEN**, paste the new token and save. Keep the token out of
   source files, terminal commands and chat. Alternatively, run the following
   command and paste at its hidden prompt:

   ```powershell
   gh secret set VERCEL_TOKEN --repo proffesergio/bechakena
   ```

4. Keep **VERCEL_ORG_ID** set to `team_ShhTOS82fiGBY3W8Yo5SuXc4` and
   **VERCEL_PROJECT_ID** set to `prj_K1hGUhXyY1oCmXsIICr4EEiv1bCm`.
   These are identifiers, not authentication credentials.
5. Open [Showcase deploy](https://github.com/proffesergio/bechakena/actions/workflows/showcase.yml),
   choose **Run workflow**, branch **main**, and target **production**. Confirm
   the job succeeds and both `https://bkpos.vercel.app/` and `/demo/` work.

The existing workflow run retains the secret loaded when it started. After
changing the secret, start a new run rather than waiting for the old job.

Official guidance: [Vercel access tokens](https://vercel.com/kb/guide/how-do-i-use-a-vercel-api-access-token).
