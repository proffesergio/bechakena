# Renew the GitHub deployment token

GitHub Actions authenticates with the `VERCEL_TOKEN` repository secret. A local
Vercel CLI login uses separate credentials, so signing in locally does not renew
the CI token. To renew GitHub automatic deployment access:

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

## Deploy the packaged site

This Vercel project uses the **Other** framework preset. A plain `vercel --prod`
uploads the source tree, which is not a deployable website here. It can report
**Ready** while `/` and `/demo/` return 404. The repository's `vercel.json`
now rejects source builds with a packaging message, before they can replace the
working production deployment.

Use the [Showcase deploy workflow](https://github.com/proffesergio/bechakena/actions/workflows/showcase.yml)
for the complete Flutter and Next build. For an already built and validated
checkout, package and deploy from the repository root:

```sh
python3 scripts/prepare_vercel.py
vercel deploy --prebuilt --prod
python3 scripts/check_deployment.py https://bkpos.vercel.app/
```

The CLI must be signed in to the project owner account. The `--prebuilt` flag
deploys `.vercel/output`; it bypasses the source-build guard. CI runs the same
health check before recording a successful GitHub deployment. It checks that
the current package's homepage and demo HTML are live, that the Flutter files
load, and that WebAssembly MIME and cross-origin isolation headers are correct.

An **expired or invalid `VERCEL_TOKEN`** fails authentication before Vercel can
deploy; renew the GitHub secret using the steps above. A **source deployment**
is a separate command mistake: it reaches the Vercel build and fails with the
packaging instructions. Renewing the token does not turn a source upload into
the required prebuilt package.

Official guidance: [Vercel access tokens](https://vercel.com/kb/guide/how-do-i-use-a-vercel-api-access-token).
