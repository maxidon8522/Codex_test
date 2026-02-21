# World Gallery Frontend

Interactive prototype for the World Gallery project, built with React, Vite, Tailwind CSS, and `react-globe.gl`.

## Getting started

```bash
npm install
npm run dev
```

The development server runs on `http://localhost:5173` by default.

## Current state

- Tailwind-based layout scaffold with hero, checklist, and milestones.
- Responsive globe preview showcasing the sample pins defined in `src/App.jsx`.
- Auto-rotating camera, click-to-open placeholder routes, and card summaries for each pin.

## Next implementation milestones

1. **Routing & project pages** – introduce React Router with `/gallery/:slug` detail views backed by mock markdown content.
2. **Firebase integration** – connect Firestore for live pin data, configure security rules from `World_Gallery_Project_Proposal.txt`, and hydrate the globe from the database.
3. **Admin workspace** – gate admin mode behind Firebase Auth (Google), create CRUD forms for pins, and handle thumbnail uploads via Firebase Storage.
4. **Testing & deployment** – add smoke tests for globe rendering and auth flows, then publish to Firebase Hosting or Vercel with CI build verification.
