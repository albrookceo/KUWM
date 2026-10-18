# Keeping up with Marcus

Static site for **KeepingUpWithMarcus.com**.

## Structure

- `index.html` — landing page
- `styles.css` — styles (light and dark mode via CSS variables)
- `CNAME` — custom domain for GitHub Pages (remove if hosting elsewhere)

## Preview locally

No build step is needed. Open `index.html` in a browser, or run a local server:

```sh
python3 -m http.server 8000
```

Then visit http://localhost:8000.

## Deploying

The site is plain HTML/CSS, so it works on any static host. For GitHub Pages:
push this folder to a repo, enable Pages from the main branch root, and set the
custom domain in the Pages settings (the `CNAME` file already contains it).
Then point the domain's DNS records at GitHub Pages.
