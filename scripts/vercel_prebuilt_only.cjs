// Source deployments cannot build this Flutter + Next showcase on Vercel.
console.error(
  'Source deployment blocked: this project requires a packaged Vercel Build Output.\n' +
  'Build Flutter and the static site, run python3 scripts/prepare_vercel.py,\n' +
  'then deploy the .vercel/output package with vercel deploy --prebuilt --prod.\n' +
  'See .github/workflows/showcase.yml for the complete build sequence.'
);
process.exit(1);
